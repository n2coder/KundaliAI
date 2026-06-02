import json
import logging
import firebase_admin
from firebase_admin import credentials, auth as _firebase_auth
from .config import settings

logger = logging.getLogger(__name__)


def _init() -> None:
    if firebase_admin._apps:
        return

    # Parse the service account JSON (env-provided).
    sa: object | None = None
    parse_error: Exception | None = None
    try:
        sa = json.loads(settings.firebase_service_account_json)
    except (json.JSONDecodeError, TypeError) as exc:
        parse_error = exc

    is_valid_sa = isinstance(sa, dict) and sa.get("type") == "service_account"

    if is_valid_sa:
        # A bad-but-present key (e.g. malformed private_key) will raise here and
        # propagate — which is correct in every environment: if you supplied a
        # key, it must work.
        firebase_admin.initialize_app(credentials.Certificate(sa))
        logger.info("Firebase Admin SDK initialised")
        return

    # No usable service account.
    if settings.is_production:
        # Fail fast: booting credential-less in prod means EVERY phone-auth
        # verification silently fails. Refuse to start so the misconfiguration
        # surfaces at deploy time, not as mysterious 401s for real users.
        reason = f"invalid JSON ({parse_error})" if parse_error else "missing / not a service_account"
        raise RuntimeError(
            "FIREBASE_SERVICE_ACCOUNT_JSON is required in production but is "
            f"{reason}. Refusing to start."
        )

    # Dev/test only: boot without credentials so local runs need no key.
    # Token verification will fail until a real key is provided.
    firebase_admin.initialize_app()
    logger.warning(
        "Firebase initialised WITHOUT a service account (dev mode) — token "
        "verification will fail. Set FIREBASE_SERVICE_ACCOUNT_JSON for real auth."
    )


_init()


def verify_firebase_token(id_token: str) -> dict:
    """
    Verify a Firebase ID token and return its decoded claims.
    Raises ValueError with a safe message on any failure.
    """
    try:
        return _firebase_auth.verify_id_token(id_token)
    except _firebase_auth.ExpiredIdTokenError:
        raise ValueError("Firebase token has expired")
    except _firebase_auth.InvalidIdTokenError:
        raise ValueError("Firebase token is invalid")
    except Exception as exc:
        raise ValueError(f"Token verification failed: {exc}")
