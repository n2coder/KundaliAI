#!/bin/bash
set -e

# Start Celery worker in background
celery -A app.tasks.celery_app worker --loglevel=info --concurrency=2 &

# Start Celery beat in background
celery -A app.tasks.celery_app beat --loglevel=info &

# Start FastAPI in foreground (keeps container alive)
exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}
