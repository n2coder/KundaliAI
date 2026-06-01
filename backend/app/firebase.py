import json
import logging
import firebase_admin
from firebase_admin import credentials, auth as _firebase_auth
from .config import settings

logger = logging.getLogger(__name__)


def _init() -> None:
    if firebase_admin._apps:
        return
    try:
        sa = json.loads(settings.firebase_service_account_json)
        if sa.get("type") == "service_account":
            firebase_admin.initialize_app(credentials.Certificate(sa))
            logger.info("Firebase Admin SDK initialised")
        else:
            # Dev/test: initialise without credentials (verify will fail gracefully)
            firebase_admin.initialize_app()
            logger.warning("Firebase initialised without service account — token verification disabled")
    except Exception as exc:
        logger.error("Firebase init error: %s", exc)
        firebase_admin.initialize_app()


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
