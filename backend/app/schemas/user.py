from __future__ import annotations
from datetime import date, time, datetime
from uuid import UUID
from pydantic import BaseModel, ConfigDict, model_validator


class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    phone: str
    name: str | None
    language: str
    dob: date | None
    tob: time | None
    birth_place: str | None
    birth_lat: float | None
    birth_lng: float | None
    whatsapp_enabled: bool
    whatsapp_delivery_time: str | None
    subscription_status: str
    trial_ends_at: datetime | None
    subscription_ends_at: datetime | None
    has_birth_chart: bool
    created_at: datetime

    @model_validator(mode="before")
    @classmethod
    def _inject_has_birth_chart(cls, v):
        """
        When validating from an ORM User object, pull the already-loaded
        birth_chart relationship to compute has_birth_chart.
        selectinload must be used when fetching the user so the attribute
        is synchronously available here.
        """
        if hasattr(v, "__table__"):
            row = {col: getattr(v, col) for col in v.__table__.c.keys()}
            row["has_birth_chart"] = v.birth_chart is not None
            return row
        # dict path (e.g. from tests)
        if isinstance(v, dict) and "has_birth_chart" not in v:
            v["has_birth_chart"] = False
        return v


class UserUpdate(BaseModel):
    name: str | None = None
    language: str | None = None
    dob: date | None = None
    tob: time | None = None
    birth_place: str | None = None
    birth_lat: float | None = None
    birth_lng: float | None = None
    whatsapp_enabled: bool | None = None
    whatsapp_delivery_time: str | None = None
