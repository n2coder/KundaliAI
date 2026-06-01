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

    # Auto-trigger chart computation when all birth fields become complete
    birth_fields_touched = _BIRTH_FIELDS & changes.keys()
    if birth_fields_touched and _birth_details_complete(current_user):
        _enqueue_chart(str(current_user.id))

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


def _enqueue_chart(user_id: str) -> None:
    try:
        from ..tasks.chart_compute import compute_chart_for_user
        compute_chart_for_user.delay(user_id)
    except Exception:
        pass  # Celery unavailable in test/dev — chart can be triggered manually
