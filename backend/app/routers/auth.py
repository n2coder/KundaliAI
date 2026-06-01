from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from ..database import get_db
from ..dependencies import get_current_user
from ..firebase import verify_firebase_token
from ..models import User
from ..schemas.user import UserOut
from ..services import auth_service

router = APIRouter()


# ── Request / Response schemas ────────────────────────────────────────────────

class VerifyRequest(BaseModel):
    firebase_token: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserOut


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.post(
    "/verify",
    response_model=TokenResponse,
    summary="Exchange Firebase ID token for KundliAI JWT",
)
async def verify(body: VerifyRequest, db: AsyncSession = Depends(get_db)):
    """
    Called immediately after Firebase phone OTP verification succeeds on the app.
    1. Verifies the Firebase ID token.
    2. Upserts the user (new = 15-day trial; existing = touch last_active_at).
    3. Returns our own 30-day JWT so the app never sends Firebase tokens again.
    """
    try:
        claims = verify_firebase_token(body.firebase_token)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=str(exc))

    phone: str | None = claims.get("phone_number")
    if not phone:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Firebase token is missing phone_number claim — only phone auth is supported",
        )

    user = await auth_service.upsert_user(
        phone=phone,
        firebase_uid=claims["uid"],
        db=db,
    )
    token = auth_service.create_access_token(user.id)
    return TokenResponse(access_token=token, user=UserOut.model_validate(user))


@router.get(
    "/me",
    response_model=UserOut,
    summary="Get the authenticated user's profile",
)
async def me(current_user: User = Depends(get_current_user)):
    """Returns the full user profile for the bearer token provided."""
    return UserOut.model_validate(current_user)
