from __future__ import annotations
import uuid
from datetime import datetime, timedelta, timezone

from jose import jwt
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from ..config import settings
from ..models import User
from ..models.user import SubscriptionStatus

_JWT_ALGORITHM = "HS256"
_JWT_EXPIRE_DAYS = 30


def create_access_token(user_id: uuid.UUID) -> str:
    expire = datetime.now(timezone.utc) + timedelta(days=_JWT_EXPIRE_DAYS)
    return jwt.encode(
        {"sub": str(user_id), "exp": expire},
        settings.secret_key,
        algorithm=_JWT_ALGORITHM,
    )


def decode_access_token(token: str) -> str:
    """Returns user_id str. Raises JWTError on invalid/expired token."""
    payload = jwt.decode(token, settings.secret_key, algorithms=[_JWT_ALGORITHM])
    return payload["sub"]


async def upsert_user(phone: str, firebase_uid: str, db: AsyncSession) -> User:
    """
    Find or create a user by firebase_uid (falling back to phone).
    New users get a 15-day trial. Expired trials are auto-downgraded.
    Returns the user with birth_chart eagerly loaded.
    """
    now = datetime.now(timezone.utc)

    # Prefer firebase_uid lookup; fall back to phone for migrated accounts
    result = await db.execute(
        select(User)
        .options(selectinload(User.birth_chart))
        .where(User.firebase_uid == firebase_uid)
    )
    user = result.scalar_one_or_none()

    if user is None:
        result = await db.execute(
            select(User)
            .options(selectinload(User.birth_chart))
            .where(User.phone == phone)
        )
        user = result.scalar_one_or_none()

    if user is None:
        user = User(
            phone=phone,
            firebase_uid=firebase_uid,
            subscription_status=SubscriptionStatus.trial,
            trial_ends_at=now + timedelta(days=15),
            last_active_at=now,
        )
        db.add(user)
        await db.flush()  # get user.id without committing
        # Refresh with relationship for the response
        await db.refresh(user, attribute_names=["birth_chart"])
    else:
        if user.firebase_uid is None:
            user.firebase_uid = firebase_uid
        user.last_active_at = now
        # Auto-expire trial
        if (
            user.subscription_status == SubscriptionStatus.trial
            and user.trial_ends_at
            and user.trial_ends_at < now
        ):
            user.subscription_status = SubscriptionStatus.expired

    await db.commit()
    await db.refresh(user)
    # Re-load relationship after refresh
    await db.refresh(user, attribute_names=["birth_chart"])
    return user
