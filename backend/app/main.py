from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import logging

from .config import settings
from .database import engine
from .models import Base

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Create tables (dev only — production uses Alembic migrations)
    if not settings.is_production:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
    logger.info("KundliAI API started")
    yield
    await engine.dispose()
    logger.info("KundliAI API shutdown")


app = FastAPI(
    title="KundliAI API",
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs" if not settings.is_production else None,
    redoc_url=None,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"] if not settings.is_production else ["https://kundliai.com"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Routers (imported lazily so startup errors surface cleanly) ───────────────
from .routers import auth, users, birth_chart, horoscope, chat, today, insights, remedies, payments, whatsapp, admin  # noqa: E402
from .routers import transits, compatibility  # noqa: E402

app.include_router(auth.router,          prefix="/api/v1/auth",          tags=["auth"])
app.include_router(users.router,         prefix="/api/v1/users",         tags=["users"])
app.include_router(birth_chart.router,   prefix="/api/v1/birth-chart",   tags=["birth_chart"])
app.include_router(horoscope.router,     prefix="/api/v1/horoscope",     tags=["horoscope"])
app.include_router(chat.router,          prefix="/api/v1/chat",          tags=["chat"])
app.include_router(today.router,         prefix="/api/v1/today",         tags=["today"])
app.include_router(insights.router,      prefix="/api/v1/insights",      tags=["insights"])
app.include_router(remedies.router,      prefix="/api/v1/remedies",      tags=["remedies"])
app.include_router(payments.router,      prefix="/api/v1/payments",      tags=["payments"])
app.include_router(whatsapp.router,      prefix="/api/v1/whatsapp",      tags=["whatsapp"])
app.include_router(admin.router,         prefix="/api/v1/admin",         tags=["admin"])
app.include_router(transits.router,      prefix="/api/v1/transits",      tags=["transits"])
app.include_router(compatibility.router, prefix="/api/v1/compatibility", tags=["compatibility"])


@app.get("/health", tags=["meta"])
async def health():
    return {"status": "ok", "version": "1.0.0"}
