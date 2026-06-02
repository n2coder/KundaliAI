#!/bin/bash
set -e

# Run DB migrations on every startup (safe — skips already-applied)
alembic upgrade head

# NOTE: the Celery worker and beat scheduler run as their own dedicated
# services (see render.yaml / docker-compose.yml). Do NOT start them here —
# doing so spawns a SECOND beat scheduler, which fires every scheduled job
# twice (double OpenAI spend, duplicate WhatsApp sends).

# Start FastAPI in foreground (keeps container alive)
exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}
