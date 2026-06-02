from __future__ import annotations
import uuid
from datetime import date, datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..models import User, ChatMessage
from ..models.birth_chart import BirthChart
from ..models.chat_message import MessageRole
from .openai_client import chat_complete
from .horoscope_service import _chart_summary  # reuse chart summary builder

_MODEL = "gpt-4o-mini"
_HISTORY_LIMIT = 10  # last N messages (user + assistant combined)

_LANG_INSTRUCTION = {
    "en": "Respond in English.",
    "hi": "Respond in Hindi (Devanagari script). Be warm and natural.",
}


async def chat(
    user: User,
    birth_chart: BirthChart | None,
    content: str,
    topic: str | None,
    db: AsyncSession,
) -> ChatMessage:
    lang = user.language.value if hasattr(user.language, "value") else str(user.language)

    # Load rolling history
    history = await _load_history(user.id, db)

    # Build OpenAI messages
    system_msg = _build_system(birth_chart, topic, lang, user.dob)
    messages = [{"role": "system", "content": system_msg}]
    for msg in history:
        messages.append({"role": msg.role.value, "content": msg.content})
    messages.append({"role": "user", "content": content})

    # Call GPT-4o-mini
    assistant_reply = await chat_complete(
        messages,
        model=_MODEL,
        max_tokens=280,  # hard ceiling; the prompt keeps replies far shorter
        temperature=0.7,
    )

    # Persist both messages
    now = datetime.now(timezone.utc)
    user_msg = ChatMessage(
        user_id=user.id,
        role=MessageRole.user,
        content=content,
        topic=topic,
    )
    assistant_msg = ChatMessage(
        user_id=user.id,
        role=MessageRole.assistant,
        content=assistant_reply,
        topic=topic,
    )
    db.add(user_msg)
    db.add(assistant_msg)
    await db.commit()
    await db.refresh(assistant_msg)
    return assistant_msg


async def get_history(user_id: uuid.UUID, db: AsyncSession) -> list[ChatMessage]:
    return await _load_history(user_id, db)


async def _load_history(user_id: uuid.UUID, db: AsyncSession) -> list[ChatMessage]:
    result = await db.execute(
        select(ChatMessage)
        .where(ChatMessage.user_id == user_id, ChatMessage.is_deleted.is_(False))
        .order_by(ChatMessage.created_at.desc())
        .limit(_HISTORY_LIMIT)
    )
    # Return in chronological order for the prompt
    return list(reversed(result.scalars().all()))


def _build_system(birth_chart: BirthChart | None, topic: str | None, lang: str, dob: date | None) -> str:
    lang_instr = _LANG_INSTRUCTION.get(lang, _LANG_INSTRUCTION["en"])

    if birth_chart is None:
        chart_section = (
            "The user has not yet provided their birth details. "
            "Answer general Vedic astrology questions warmly. "
            "Gently encourage them to add their birth chart for personalised guidance."
        )
    else:
        chart_section = (
            "The user's personalised birth chart:\n"
            + _chart_summary(birth_chart.chart_data, dob)
        )

    topic_section = (
        f"\nThe user is focused on: {topic}. Keep the reply centred on this, briefly."
        if topic
        else ""
    )

    return (
        "You are Jyotish, a warm Vedic astrology guide in the KundliAI chat.\n"
        f"{chart_section}{topic_section}\n\n"
        "Guidelines:\n"
        "- Keep it SHORT — 2 to 4 sentences, under ~70 words. This is a quick chat, not an essay or a report.\n"
        "- Open with the direct answer. Add at most ONE astrological reason (a planet, house, or dasha) "
        "and only if it truly sharpens the point — never list several placements.\n"
        "- Plain, warm, conversational. No preamble, no restating their question, no formal sign-off.\n"
        "- Encouraging but honest — no false promises.\n"
        "- If the topic really needs more depth, give the gist in 1–2 sentences and end by offering to go "
        "deeper (e.g. 'Want me to break it down?') rather than dumping everything at once.\n"
        f"- {lang_instr}"
    )
