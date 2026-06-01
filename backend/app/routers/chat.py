from __future__ import annotations
from datetime import datetime
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from ..database import get_db
from ..dependencies import get_current_user
from ..config import settings
from ..models import User
from ..services import chat_service

router = APIRouter()


# ── Schemas ───────────────────────────────────────────────────────────────────

class ChatMessageIn(BaseModel):
    content: str = Field(..., min_length=1, max_length=1000)
    topic: str | None = Field(
        None,
        description="Optional life area, e.g. 'Career & Finance'. "
                    "Passed by the Guidance screen when navigating to chat.",
    )


class ChatMessageOut(BaseModel):
    id: UUID
    role: str
    content: str
    topic: str | None
    created_at: datetime

    model_config = {"from_attributes": True}


class ChatResponse(BaseModel):
    reply: ChatMessageOut


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.post(
    "/message",
    response_model=ChatResponse,
    summary="Send a message and receive an AI Vedic astrology response",
)
async def send_message(
    body: ChatMessageIn,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if not settings.openai_api_key:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="AI chat is temporarily unavailable — OpenAI key not configured",
        )
    assistant_msg = await chat_service.chat(
        user=current_user,
        birth_chart=current_user.birth_chart,
        content=body.content,
        topic=body.topic,
        db=db,
    )
    return ChatResponse(reply=ChatMessageOut.model_validate(assistant_msg))


@router.get(
    "/history",
    response_model=list[ChatMessageOut],
    summary="Get last 10 chat messages (non-deleted)",
)
async def get_history(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    messages = await chat_service.get_history(current_user.id, db)
    return [ChatMessageOut.model_validate(m) for m in messages]
