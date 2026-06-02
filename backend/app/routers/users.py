from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import update, delete
from sqlalchemy.ext.asyncio import AsyncSession

from ..database import get_db
from ..dependencies import get_current_user
from ..models import User, ChatMessage
from ..schemas.user import UserOut, UserUpdate

router = APIRouter()

_BIRTH_FIELDS = {"dob", "tob", "birth_lat", "birth_lng"}


@router.patch(
    "/me",
    response_model=UserOut,
    summary="Update profile, birth details, or WhatsApp settings",
)
async def update_me(
    body: UserUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    changes = body.model_dump(exclude_none=True)
    if not changes:
        return UserOut.model_validate(current_user)

    for field, value in changes.items():
        setattr(current_user, field, value)

    await db.commit()
    await db.refresh(current_user)
    await db.refresh(current_user, attribute_names=["birth_chart"])

    # Recompute the chart synchronously when birth fields change and are complete
    # (Celery-independent — see birth_chart.compute for rationale).
    birth_fields_touched = _BIRTH_FIELDS & changes.keys()
    if birth_fields_touched and _birth_details_complete(current_user):
        from ..services import chart_service
        await chart_service.compute_and_store_chart(
            current_user,
            current_user.dob,
            current_user.tob,
            current_user.birth_lat,
            current_user.birth_lng,
            db,
        )

    return UserOut.model_validate(current_user)


@router.delete(
    "/me",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Permanently delete account and all data",
)
async def delete_me(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await db.delete(current_user)
    await db.commit()


@router.post(
    "/me/clear-chat",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Clear chat history (soft delete)",
)
async def clear_chat(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await db.execute(
        update(ChatMessage)
        .where(ChatMessage.user_id == current_user.id)
        .values(is_deleted=True)
    )
    await db.commit()


# ── Helpers ───────────────────────────────────────────────────────────────────

def _birth_details_complete(user: User) -> bool:
    return all([user.dob, user.tob, user.birth_lat, user.birth_lng])
