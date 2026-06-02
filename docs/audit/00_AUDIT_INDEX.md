# KundliAI — Production Readiness Audit

**Audited:** 2026-06-02
**Scope:** `backend/` (FastAPI + Celery), `mobile/` (Flutter), deployment config (`render.yaml`, Docker, nginx)
**Codebase size:** 44 backend Python modules, 50 Flutter Dart files, 1 Alembic migration

---

## Reports

| # | Report | What it covers |
|---|--------|----------------|
| 1 | [Code Quality Audit](01_code_quality_audit.md) | Bugs, security gaps, domain-correctness issues, smells, test coverage |
| 2 | [Application Workflow](02_application_workflow.md) | End-to-end flows: auth, onboarding, horoscope, chat, payments, WhatsApp, batch jobs |
| 3 | [Production Scaling Plan](03_production_scaling_plan.md) | Capacity model, bottlenecks, phased scaling roadmap, cost model |

---

## Executive summary

The codebase is **well-structured and feature-complete** for an MVP. Clean layered architecture (routers → services → models), sensible use of async SQLAlchemy, a two-layer cache for the two expensive external calls (geocoding, chart compute), JSONB chart storage, and a thoughtful Celery batch design. The Vedic engine (pyswisseph) is real, not stubbed.

However, **it is not production-ready as deployed today.** There are three blocking issues and several high-priority gaps:

### 🔴 Blockers (fix before any real launch)
1. **Duplicate Celery Beat in production** — the web container's `start.sh` runs `worker` *and* `beat` in the background, *while* `render.yaml` also defines dedicated `worker` and `beat` services. Result: **every scheduled job fires twice** → double OpenAI spend, **users receive duplicate WhatsApp messages** (Meta spam-flag risk), double batch runs. (`backend/start.sh`, `render.yaml`)
2. **Nightly horoscope batch is broken** — `horoscope_batch._async_generate_all` reads `user.birth_chart` (a lazy relationship) on a User loaded in an already-closed session, which raises under async SQLAlchemy. The core "pre-generate at night, deliver from DB" feature (locked decision #11) effectively fails for every user; the error is swallowed and logged. (`backend/app/tasks/horoscope_batch.py:45`)
3. **`NullPool` on the shared web engine** — every HTTP request opens and tears down a fresh Postgres connection (no pooling), set globally "for Celery." Under load this exhausts Neon connection limits and adds latency to every request. (`backend/app/database.py:8`)

### 🟠 High priority
- **No trial-abuse prevention or rate limiting** despite locked decision #14 (OTP throttle + device fingerprint). 15-day full trial + free re-registration = open abuse vector. (`device_info_plus` is in pubspec but unused server-side.)
- **Current Dasha is frozen at chart-compute time** and read from cache forever, so Mahadasha/Antardasha "remaining years" go stale and eventually wrong. (`chart_service._vimshottari_dasha` uses `date.today()` at compute, never refreshed.)
- **Zero automated tests** on a codebase that handles payments and astrological correctness.
- **OpenAI calls have no timeout/retry** and daily horoscope generates **synchronously in the request path** (`tenacity` is a dependency but unused).
- **Firebase falls back to credential-less init in production** instead of failing fast — silent auth breakage risk.

See report 1 for the full list with severities and fixes.
