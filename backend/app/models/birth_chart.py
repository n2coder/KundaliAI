from __future__ import annotations
import uuid
from datetime import datetime, date, time
from sqlalchemy import String, Date, Time, Float, DateTime, Integer, func, ForeignKey, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID, JSONB
from .base import Base


class BirthChart(Base):
    """Computed chart for a specific user — 1:1 with User."""
    __tablename__ = "birth_charts"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), unique=True, index=True
    )

    # Chart data (pyswisseph output stored as JSONB)
    chart_data: Mapped[dict] = mapped_column(JSONB, nullable=False)
    # Structure: {planets: [...], houses: [...], dasha: [...], ayanamsa: float, ascendant: str}

    # Derived fields for quick queries (avoids parsing JSONB for every request)
    sun_sign: Mapped[str | None] = mapped_column(String(20))
    moon_sign: Mapped[str | None] = mapped_column(String(20))
    ascendant: Mapped[str | None] = mapped_column(String(20))
    current_dasha: Mapped[str | None] = mapped_column(String(40))

    computed_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    user: Mapped["User"] = relationship("User", back_populates="birth_chart")


class BirthChartCache(Base):
    """
    Two-layer cache layer 2: canonical birth params → computed chart JSONB.
    lat/lng rounded to 3 decimal places; date+time exact.
    """
    __tablename__ = "birth_chart_cache"
    __table_args__ = (
        UniqueConstraint("dob", "tob", "lat", "lng", name="uq_birth_chart_cache_params"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    dob: Mapped[date] = mapped_column(Date, nullable=False)
    tob: Mapped[time] = mapped_column(Time, nullable=False)
    lat: Mapped[float] = mapped_column(Float, nullable=False)
    lng: Mapped[float] = mapped_column(Float, nullable=False)
    chart_data: Mapped[dict] = mapped_column(JSONB, nullable=False)
    hit_count: Mapped[int] = mapped_column(Integer, default=1)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    last_hit_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


class PlaceGeoCache(Base):
    """
    Two-layer cache layer 1: city name → lat/lng.
    Avoids repeated Google Geocoding API calls for common city names.
    """
    __tablename__ = "place_geocache"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    place_name: Mapped[str] = mapped_column(String(200), unique=True, nullable=False, index=True)
    lat: Mapped[float] = mapped_column(Float, nullable=False)
    lng: Mapped[float] = mapped_column(Float, nullable=False)
    hit_count: Mapped[int] = mapped_column(Integer, default=1)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    last_hit_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


from .user import User  # noqa: E402
