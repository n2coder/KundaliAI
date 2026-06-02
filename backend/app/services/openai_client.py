import logging

from openai import (
    AsyncOpenAI,
    APIConnectionError,
    APITimeoutError,
    InternalServerError,
    RateLimitError,
)
from tenacity import (
    retry,
    retry_if_exception_type,
    stop_after_attempt,
    wait_exponential_jitter,
    before_sleep_log,
)

from ..config import settings

logger = logging.getLogger(__name__)

_DEFAULT_MODEL = "gpt-4o-mini"
_client: AsyncOpenAI | None = None

# Transient failures worth retrying. Auth/bad-request (4xx) errors are NOT here —
# retrying those just wastes time and money.
_RETRYABLE = (APITimeoutError, APIConnectionError, RateLimitError, InternalServerError)


def get_client() -> AsyncOpenAI:
    global _client
    if _client is None:
        # SDK-level retries disabled: we own the retry policy in chat_complete()
        # via tenacity, so behaviour is explicit and there's no hidden
        # double-retry (SDK × tenacity) blowing up latency on the request path.
        _client = AsyncOpenAI(
            api_key=settings.openai_api_key,
            timeout=30.0,
            max_retries=0,
        )
    return _client


@retry(
    reraise=True,
    stop=stop_after_attempt(3),
    wait=wait_exponential_jitter(initial=1, max=10),
    retry=retry_if_exception_type(_RETRYABLE),
    before_sleep=before_sleep_log(logger, logging.WARNING),
)
async def chat_complete(
    messages: list[dict],
    *,
    model: str | None = None,
    max_tokens: int,
    temperature: float,
    response_format: dict | None = None,
) -> str:
    """
    Single entry point for chat completions.

    - Bounded timeout (30s) so a stalled OpenAI call never pins a request/worker.
    - Exponential-jitter retry (up to 3 attempts) on transient errors only.
    - Guarantees a non-None string back (raises ValueError on empty content,
      which is far clearer than the AttributeError a raw `.content.strip()`
      would throw on a refusal/length-stop).
    """
    kwargs: dict = {
        "model": model or _DEFAULT_MODEL,
        "messages": messages,
        "max_tokens": max_tokens,
        "temperature": temperature,
    }
    if response_format is not None:
        kwargs["response_format"] = response_format

    resp = await get_client().chat.completions.create(**kwargs)
    content = resp.choices[0].message.content
    if content is None:
        raise ValueError("OpenAI returned empty content")
    return content.strip()
