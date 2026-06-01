"""
Monthly batch: generate insight predictions for all active users.
Runs on the 1st of each month at 00:00 IST via Celery Beat.
Full implementation in v1.1 — stub logs a placeholder for now.
"""
import logging
from .celery_app import celery_app

logger = logging.getLogger(__name__)


@celery_app.task
def generate_all() -> None:
    logger.info("Insight batch triggered — full implementation in v1.1")
