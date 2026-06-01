from __future__ import annotations
from datetime import date, timedelta

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from ..database import get_db
from ..dependencies import get_current_user
from ..models import User
from ..models.horoscope import HoroscopePeriod
from ..services import horoscope_service

router = APIRouter()


# ── Schemas ───────────────────────────────────────────────────────────────────

class HoroscopeOut(BaseModel):
    period: str
    for_date: date
    language: str
    content: str

    @classmethod
    def from_orm_lang(cls, h, lang: str) -> "HoroscopeOut":
        content = h.content_hi if lang == "hi" else h.content_en
        return cls(
            period=h.period.value if hasattr(h.period, "value") else str(h.period),
            for_date=h.for_date,
            language=lang,
            content=content or "",
        )


class WhatsAppSettingIn(BaseModel):
    enabled: bool
    delivery_time: str | None = None  # "07:00" 24h format


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.get(
    "/daily",
    response_model=HoroscopeOut,
    summary="Today's daily horoscope (generated on demand, cached in DB)",
)
async def daily(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    _require_birth_chart(current_user)
    h = await horoscope_service.get_or_generate(
        user=current_user,
        birth_chart=current_user.birth_chart,
        period=HoroscopePeriod.daily,
        for_date=date.today(),
        db=db,
    )
    return HoroscopeOut.from_orm_lang(h, _lang(current_user))


@router.get(
    "/weekly",
    response_model=HoroscopeOut,
    summary="This week's horoscope (Monday of current week)",
)
async def weekly(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    _require_birth_chart(current_user)
    week_start = date.today() - timedelta(days=date.today().weekday())
    h = await horoscope_service.get_or_generate(
        user=current_user,
        birth_chart=current_user.birth_chart,
        period=HoroscopePeriod.weekly,
        for_date=week_start,
        db=db,
    )
    return HoroscopeOut.from_orm_lang(h, _lang(current_user))


@router.get(
    "/monthly",
    response_model=HoroscopeOut,
    summary="This month's horoscope",
)
async def monthly(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    _require_birth_chart(current_user)
    month_start = date.today().replace(day=1)
    h = await horoscope_service.get_or_generate(
        user=current_user,
        birth_chart=current_user.birth_chart,
        period=HoroscopePeriod.monthly,
        for_date=month_start,
        db=db,
    )
    return HoroscopeOut.from_orm_lang(h, _lang(current_user))


@router.patch(
    "/whatsapp",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Toggle WhatsApp daily horoscope delivery",
)
async def update_whatsapp(
    body: WhatsAppSettingIn,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    current_user.whatsapp_enabled = body.enabled
    if body.delivery_time is not None:
        current_user.whatsapp_delivery_time = body.delivery_time
    await db.commit()


# ── Helpers ───────────────────────────────────────────────────────────────────

def _require_birth_chart(user: User) -> None:
    if user.birth_chart is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Birth chart not found. Submit birth details first via POST /birth-chart/compute",
        )


def _lang(user: User) -> str:
    return user.language.value if hasattr(user.language, "value") else str(user.language)
