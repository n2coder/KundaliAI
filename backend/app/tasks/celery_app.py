import ssl
from celery import Celery
from celery.schedules import crontab
from ..config import settings

# No result backend: we never call .get() on a task result, and on a
# per-command-billed broker (Upstash) storing + expiring every result is
# pure waste. Fire-and-forget only.
celery_app = Celery(
    "kundliai",
    broker=settings.celery_broker_url,
    include=[
        "app.tasks.horoscope_batch",
        "app.tasks.insight_batch",
        "app.tasks.whatsapp_batch",
        "app.tasks.score_batch",
        "app.tasks.chart_compute",
    ],
)

_ssl_conf = (
    {"ssl_cert_reqs": ssl.CERT_NONE}
    if settings.redis_url.startswith("rediss://")
    else {}
)

celery_app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    timezone="Asia/Kolkata",
    enable_utc=True,
    broker_use_ssl=_ssl_conf or None,

    # ── Upstash command-budget controls ──────────────────────────────────────
    # Don't store results (no .get() anywhere) — avoids SET/EXPIRE per task.
    task_ignore_result=True,
    # Disable the pidbox control mailbox — kills its ~1 cmd/s idle poll.
    worker_enable_remote_control=False,
    # Disable task event publishing (gossip/monitoring chatter).
    worker_send_task_events=False,
    # Poll the broker less aggressively when idle. Tasks are scheduled/async
    # (chart compute is fetched via polling GET /birth-chart), so a few extra
    # seconds of pickup latency is fine and cuts idle BRPOP commands sharply.
    broker_transport_options={
        "visibility_timeout": 3600,
        "polling_interval": 5.0,
    },
)

celery_app.conf.beat_schedule = {
    # Nightly horoscope pre-gen: 11:30 PM IST
    "nightly-horoscope-batch": {
        "task": "app.tasks.horoscope_batch.generate_all",
        "schedule": crontab(hour=18, minute=0),  # 18:00 UTC = 23:30 IST
    },
    # Monthly insight predictions: 1st of each month at midnight IST
    "monthly-insight-batch": {
        "task": "app.tasks.insight_batch.generate_all",
        "schedule": crontab(hour=18, minute=30, day_of_month=1),
    },
    # WhatsApp delivery: 1:30 AM UTC = 7:00 AM IST default window
    "whatsapp-morning-dispatch": {
        "task": "app.tasks.whatsapp_batch.dispatch_all",
        "schedule": crontab(hour=1, minute=30),
    },
    # Daily scores: midnight IST
    "daily-score-batch": {
        "task": "app.tasks.score_batch.compute_all",
        "schedule": crontab(hour=18, minute=15),
    },
}
