from __future__ import annotations
import uuid
from datetime import date, datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, status
from fastapi.security import APIKeyHeader
from pydantic import BaseModel
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from ..config import settings
from ..database import get_db
from ..models import User, BirthChart
from ..models.horoscope import Horoscope
from ..models.payment import Payment, PaymentStatus
from ..models.user import SubscriptionStatus
from ..models.whatsapp_delivery import WhatsAppDelivery, DeliveryStatus

router = APIRouter()
_admin_key_header = APIKeyHeader(name="X-Admin-Key", auto_error=False)


# ── Auth ──────────────────────────────────────────────────────────────────────

async def require_admin(key: str | None = Depends(_admin_key_header)) -> None:
    if not key or key != settings.admin_api_key:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Invalid or missing admin key",
        )


# ── Schemas ───────────────────────────────────────────────────────────────────

class DashboardStats(BaseModel):
    total_users: int
    trial: int
    active: int
    expired: int
    cancelled: int
    users_with_birth_chart: int
    horoscopes_generated_today: int
    whatsapp_sent_today: int
    payments_captured_total: int
    mrr_inr: int  # active * ₹30


class UserAdminOut(BaseModel):
    id: uuid.UUID
    phone: str
    name: str | None
    language: str
    subscription_status: str
    has_birth_chart: bool
    whatsapp_enabled: bool
    created_at: datetime
    last_active_at: datetime | None


class SubscriptionOverride(BaseModel):
    subscription_status: str
    subscription_ends_at: datetime | None = None


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.get(
    "/stats",
    response_model=DashboardStats,
    summary="Dashboard KPIs",
    dependencies=[Depends(require_admin)],
)
async def get_stats(db: AsyncSession = Depends(get_db)):
    today = date.today()

    async def count(model, *where):
        q = select(func.count(model.id))
        for clause in where:
            q = q.where(clause)
        return (await db.scalar(q)) or 0

    total = await count(User)
    trial = await count(User, User.subscription_status == SubscriptionStatus.trial)
    active = await count(User, User.subscription_status == SubscriptionStatus.active)
    expired = await count(User, User.subscription_status == SubscriptionStatus.expired)
    cancelled = await count(User, User.subscription_status == SubscriptionStatus.cancelled)
    with_chart = await count(BirthChart)
    horoscopes_today = await count(Horoscope, Horoscope.for_date == today)
    wa_today = await count(
        WhatsAppDelivery,
        WhatsAppDelivery.for_date == today,
        WhatsAppDelivery.status == DeliveryStatus.sent,
    )
    payments_total = await count(Payment, Payment.status == PaymentStatus.captured)

    return DashboardStats(
        total_users=total,
        trial=trial,
        active=active,
        expired=expired,
        cancelled=cancelled,
        users_with_birth_chart=with_chart,
        horoscopes_generated_today=horoscopes_today,
        whatsapp_sent_today=wa_today,
        payments_captured_total=payments_total,
        mrr_inr=active * 30,
    )


@router.get(
    "/users",
    response_model=list[UserAdminOut],
    summary="List users with pagination",
    dependencies=[Depends(require_admin)],
)
async def list_users(
    offset: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
    subscription_status: str | None = Query(None),
    db: AsyncSession = Depends(get_db),
):
    q = select(User).options(selectinload(User.birth_chart)).offset(offset).limit(limit)
    if subscription_status:
        try:
            status_enum = SubscriptionStatus(subscription_status)
            q = q.where(User.subscription_status == status_enum)
        except ValueError:
            raise HTTPException(status_code=422, detail=f"Invalid status: {subscription_status}")

    result = await db.execute(q)
    users = result.scalars().all()
    return [_user_to_admin_out(u) for u in users]


@router.get(
    "/users/{user_id}",
    response_model=UserAdminOut,
    summary="Get user detail",
    dependencies=[Depends(require_admin)],
)
async def get_user(user_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(User).options(selectinload(User.birth_chart)).where(User.id == user_id)
    )
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return _user_to_admin_out(user)


@router.patch(
    "/users/{user_id}/subscription",
    response_model=UserAdminOut,
    summary="Manually override subscription status",
    dependencies=[Depends(require_admin)],
)
async def override_subscription(
    user_id: uuid.UUID,
    body: SubscriptionOverride,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(User).options(selectinload(User.birth_chart)).where(User.id == user_id)
    )
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    try:
        user.subscription_status = SubscriptionStatus(body.subscription_status)
    except ValueError:
        raise HTTPException(status_code=422, detail=f"Invalid status: {body.subscription_status}")

    if body.subscription_ends_at:
        user.subscription_ends_at = body.subscription_ends_at

    await db.commit()
    await db.refresh(user)
    await db.refresh(user, attribute_names=["birth_chart"])
    return _user_to_admin_out(user)


# ── Helper ────────────────────────────────────────────────────────────────────

def _user_to_admin_out(u: User) -> UserAdminOut:
    lang = u.language.value if hasattr(u.language, "value") else str(u.language)
    return UserAdminOut(
        id=u.id,
        phone=u.phone,
        name=u.name,
        language=lang,
        subscription_status=u.subscription_status.value,
        has_birth_chart=u.birth_chart is not None,
        whatsapp_enabled=u.whatsapp_enabled,
        created_at=u.created_at,
        last_active_at=u.last_active_at,
    )
