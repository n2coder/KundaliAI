# Code Quality Audit — KundliAI

**Date:** 2026-06-02
**Reviewer scope:** backend (FastAPI/Celery/SQLAlchemy), mobile (Flutter/Riverpod), infra config.

Severity legend: 🔴 Blocker · 🟠 High · 🟡 Medium · 🟢 Low / polish

---

## 1. Overall assessment

**Strengths**
- Clean, conventional layering: `routers/` (HTTP) → `services/` (logic) → `models/` (ORM) → `tasks/` (Celery). Easy to navigate.
- Modern async stack: SQLAlchemy 2.0 typed `Mapped[]` models, async sessions, Pydantic v2, FastAPI 0.111.
- **Two-layer cache** for the only two expensive idempotent operations is genuinely good design:
  - `place_geocache` (city → lat/lng) avoids repeat Google Geocoding spend (`geocode_service.py`).
  - `birth_chart_cache` (dob/tob/lat/lng → chart JSONB) means identical birth params compute once globally (`chart_service.get_or_compute_chart`).
- Chart stored as JSONB with denormalised `sun_sign/moon_sign/ascendant/current_dasha` columns for cheap queries (`models/birth_chart.py`).
- Payment webhook is idempotent via a unique-`razorpay_payment_id` guard (`payment_service.handle_subscription_charged:64`).
- Per-feature Flutter structure (`features/<x>/data` + `presentation`), Riverpod, Dio token-rebuild provider, JWT in `flutter_secure_storage` — solid mobile foundation.
- Secrets are gitignored (`backend/.env` is excluded); `render.yaml` uses `sync: false` for all secrets.

**Headline weaknesses:** duplicated background workers in prod, a broken nightly batch, no connection pooling for the web app, no tests, no rate limiting/abuse controls, and a stale-Dasha domain bug. Details below.

---

## 2. 🔴 Blockers

### 2.1 Duplicate Celery Beat & workers in production
**Files:** `backend/start.sh`, `backend/Dockerfile`, `render.yaml`

`render.yaml` defines three services: `kundliai-api` (web, built from `Dockerfile`), `kundliai-worker` (from `Dockerfile.worker`), and `kundliai-beat` (from `Dockerfile.beat`). Good separation — **except** the web `Dockerfile` runs `start.sh`, which does:

```bash
alembic upgrade head
celery -A app.tasks.celery_app worker ... &   # extra worker inside web container
celery -A app.tasks.celery_app beat   ... &   # SECOND beat scheduler
exec uvicorn app.main:app ...
```

So in production there are **two Beat schedulers running concurrently** (web + dedicated `kundliai-beat`). Every entry in `beat_schedule` fires **twice**:
- `horoscope_batch.generate_all` → ~2× OpenAI cost.
- `whatsapp_batch.dispatch_all` → **users receive the daily horoscope twice on WhatsApp.** Meta penalises duplicate/spammy template sends; risks number quality rating downgrade or block.
- `score_batch` / `insight_batch` → double work, double cost.

**Fix:** `start.sh` should run **only** migrations + uvicorn. Let the dedicated `worker`/`beat` Render services own background execution:
```bash
#!/bin/bash
set -e
alembic upgrade head
exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}
```
(`docker-compose.yml` already does this correctly with separate `api`/`worker`/`beat` services — only `start.sh` is wrong.)

---

### 2.2 Nightly horoscope batch raises on every user
**File:** `backend/app/tasks/horoscope_batch.py:28-58`

```python
result = await db.execute(select(User).where(...))   # session A
users = result.scalars().all()
# session A closes here (end of `async with`)
for user in users:
    async with AsyncSessionLocal() as db:             # session B
        if user.birth_chart is None:                  # ← lazy load on detached object
            continue
        await get_or_generate(user=user, birth_chart=user.birth_chart, db=db, ...)
```

`User.birth_chart` is `lazy="select"` (`models/user.py:67`) and was **not** eager-loaded in the query. Accessing it after session A closed triggers a lazy load with no session → async SQLAlchemy raises `MissingGreenlet`/`DetachedInstanceError`. The surrounding `try/except` swallows it and logs `"Horoscope batch failed for user ..."`. Net effect: **pre-generation produces nothing**, defeating locked decision #11 (deliver from DB at the user's preferred time). The subsequent WhatsApp batch then finds no row and silently sends nothing.

Secondary bug: even if the relationship were loaded, `get_or_generate` is handed a `user` bound to session A but a `db` = session B; commits/refreshes operate on a foreign-session instance.

**Fix:** eager-load and keep one session per user iteration end-to-end:
```python
async with AsyncSessionLocal() as db:
    users = (await db.execute(
        select(User)
        .options(selectinload(User.birth_chart))
        .where(User.subscription_status.in_([trial, active]))
    )).scalars().all()
    for user in users:
        if user.birth_chart is None:
            continue
        await get_or_generate(user, user.birth_chart, daily, tomorrow, db)
```
(See also report 3 — this loop should be chunked/concurrent for scale.)

---

### 2.3 `NullPool` applied to the web engine
**File:** `backend/app/database.py:5-9`

```python
engine = create_async_engine(
    settings.database_url,
    poolclass=NullPool,   # "Celery workers fork — NullPool avoids inherited connections"
)
```

This single engine is imported by **both** the FastAPI app and the Celery tasks. `NullPool` disables connection pooling entirely: every HTTP request opens a new asyncpg connection, does TLS + auth handshake to Neon, then closes it. At even modest concurrency this:
- adds 20–80 ms+ per request,
- hammers Neon's connection ceiling (free/launch tiers cap concurrent connections),
- negates the benefit of async.

The fork-safety concern is real **for Celery**, not for the web app.

**Fix:** give the web app a pooled engine and the worker a `NullPool` engine (or point the web app at Neon's PgBouncer pooler URL and keep a small `AsyncAdaptedQueuePool`). Simplest: pool by default, and in the Celery worker bootstrap dispose/recreate the engine per process, or set `NullPool` only when `RUNNING_IN_CELERY` env is set.

---

## 3. 🟠 High priority

### 3.1 No rate limiting / trial-abuse prevention (decision #14 unimplemented)
**Files:** `routers/auth.py`, whole backend (grep for `rate`/`limiter`/`fingerprint` → 0 hits)

Locked decision #14 specified OTP rate limiting (Redis) + device fingerprint (`device_info_plus`) + trial-used flag. None exists:
- `/auth/verify` has no throttle — OTP-verify spam, enumeration, and automated trial farming are open.
- 15-day **full-access** trial (decision #15) with no device/identity binding means a user can re-register with a fresh phone number for unlimited free premium.
- `device_info_plus` is declared in `pubspec.yaml` but never sent to or stored by the backend.

**Fix:** add `slowapi` (or a Redis token-bucket dependency) on `/auth/verify`; capture a device fingerprint at signup, store it on `users`, and gate trial eligibility on `(phone | device | fingerprint) not seen before`.

### 3.2 Current Dasha is frozen at compute time (domain correctness)
**Files:** `chart_service._vimshottari_dasha:165`, `chart_compute.py`, consumers in `horoscope_service`/`today_service`

The Vimshottari Dasha is computed using `date.today()` **at the moment the chart is first computed**, then stored permanently in `birth_chart.chart_data` (and `birth_chart_cache`). The chart is only recomputed when birth details change. So:
- "mahadasha_remaining_years" / "antardasha_remaining_years" steadily drift and become wrong.
- Eventually the user crosses into a new Mahadasha but the app still shows the old one — for an astrology product this is a visible correctness failure, and Dasha timing is precisely what the chat/horoscope prompts lean on.

**Fix:** store only birth-invariant data (planet longitudes, nakshatra, ascendant) in the cache; compute the *current* Dasha at read-time from the cached Moon longitude + birth date. This also keeps `birth_chart_cache` correctly birth-keyed (the cache is currently polluted with a time-dependent value, so two users with identical birth params but cached on different days would legitimately differ — yet the cache returns whichever was stored first).

### 3.3 OpenAI calls: synchronous in request path, no timeout, no retry
**Files:** `openai_client.py`, `horoscope_service._generate`, `chat_service.chat`, `insight_service._generate`

- `AsyncOpenAI(api_key=...)` is created with **no `timeout` and no `max_retries` override**. A slow/stalled OpenAI response holds the request (and a DB connection) open.
- `GET /horoscope/daily` generates on demand if the nightly batch didn't pre-fill (and per §2.2, it never does today). So the user waits the full GPT latency (hundreds of tokens) inline.
- `tenacity` is in `requirements.txt` but used nowhere — retries/backoff were intended but not wired.
- `chat.completions.create(...).choices[0].message.content.strip()` will raise `AttributeError` if the model returns `content=None` (e.g. refusal/length-stop). No guard.

**Fix:** `AsyncOpenAI(timeout=20, max_retries=2)`; wrap calls in `tenacity` retry with jittered backoff on `RateLimitError`/`APITimeoutError`; null-check `content`; keep daily horoscope strictly DB-served (return a friendly "generating" state if missing rather than blocking).

### 3.4 Firebase initialises without credentials in production
**File:** `firebase.py:10-24`

On any error parsing the service-account JSON — or if it's the default `"{}"` — the code calls `firebase_admin.initialize_app()` with no credentials and logs a warning, then continues to boot. In production this means token verification silently misbehaves instead of the app refusing to start. Combined with `verify_firebase_token` mapping every unknown failure to a generic `ValueError`, misconfiguration surfaces as "all logins fail" with no clear signal.

**Fix:** if `settings.is_production` and the service account is missing/invalid, raise on startup (fail fast).

### 3.5 No automated tests
**Files:** none in `backend/` (no `pytest.ini`, `conftest.py`, `tests/`); mobile has only the default `test/widget_test.dart`.

For an app that (a) takes money via Razorpay and (b) makes astrological claims, the absence of tests is a real risk. Highest-value targets:
- `payment_service` webhook handlers (idempotency, status transitions, signature verify).
- `chart_service` (golden charts: known birth data → expected planet signs/ascendant/dasha).
- `auth_service.upsert_user` (trial creation, trial expiry, firebase_uid backfill).
- Batch tasks (the §2.2 bug would have been caught instantly).

---

## 4. 🟡 Medium

| # | Issue | Location | Note |
|---|-------|----------|------|
| 4.1 | Razorpay webhook signature check **returns `True`** when secret is unset | `payment_service.verify_webhook_signature:26` | Convenient in dev, dangerous if deployed without the secret. Hard-fail when `settings.is_production`. |
| 4.2 | CORS dev config uses `allow_origins=["*"]` **with** `allow_credentials=True` | `main.py:33-39` | Browsers reject this combination; also overly broad. Use explicit dev origins. |
| 4.3 | Daily/weekly/monthly horoscope generated **on-demand synchronously** | `routers/horoscope.py` | See §3.3. Acceptable only once the batch (§2.2) actually works. |
| 4.4 | Panchang (tithi/yoga/karana) sampled at **noon only** | `today_service._compute_panchang:144` | These change through the day; a single snapshot is an approximation, not muhurta-grade. Fine for a daily card if disclaimed. |
| 4.5 | Moshier ephemeris (`FLG_MOSEPH`) instead of Swiss Ephemeris files | `chart_service.py:85`, `today_service.py:147` | Lower precision (esp. Moon/outer planets over wide date ranges). Acceptable to avoid shipping ephemeris files, but document the accuracy trade-off; advanced users will compare against other apps. |
| 4.6 | `BirthChart.chart_data` comment says `dasha: [...]` (list) but it's a dict | `models/birth_chart.py:21` | Doc/code drift; harmless but misleading. |
| 4.7 | JWT: 30-day HS256, no refresh token, no revocation/`jti` blocklist | `auth_service.py:14-30` | A leaked token is valid 30 days. Acceptable MVP; add refresh + server-side revocation before scale. |
| 4.8 | Admin auth = one shared static API key | `routers/admin.py:26` | No per-admin identity, audit trail, or rotation. React admin dashboard (decision #17) is not yet built. |
| 4.9 | `upsert_user` does `commit` → `refresh` → `refresh(birth_chart)` (3 round-trips) | `auth_service.py:81-84` | Redundant; one `refresh` after commit with eager-load suffices. Minor latency on the hot login path. |
| 4.10| No structured logging, request IDs, or error tracking (Sentry) | global | Hard to debug prod. Add JSON logging + Sentry before launch. |

---

## 5. 🟢 Low / polish

- **`payments.py:49`** — `__import__("app.config", fromlist=["settings"]).settings.razorpay_key_id` is an unnecessary dynamic import; `from ..config import settings` is already used elsewhere. Replace.
- **Duplicated language helper** — `user.language.value if hasattr(user.language, "value") else str(user.language)` is copy-pasted in `horoscope_service`, `chat_service`, `insight_service`, `whatsapp_batch`, `horoscope.py`, `admin.py`. Extract to a `User.lang` property or a single util.
- **`from datetime import datetime, timezone` inside a function** — `whatsapp_batch.py:95`. Move to module top.
- **`_chart_summary` imported across services** with a leading underscore (`from .horoscope_service import _chart_summary`) — promote to a public function in a shared `chart_summary.py` to avoid importing private names.
- **`orjson`** is a dependency but FastAPI isn't configured to use `ORJSONResponse` as default response class — either wire it (`default_response_class=ORJSONResponse`) or drop the dep.
- **`pubspec.yaml`**: `lottie`, `cached_network_image`, `flutter_svg`, `pin_code_fields` declared — confirm each is actually used; prune unused to shrink the bundle.
- **Mobile** `ApiEndpoints.baseUrl` hardcodes `http://10.0.2.2:8000` fallback — fine for dev, but ensure release builds always pass `--dart-define=API_BASE_URL=https://...` (a cleartext-HTTP fallback in a shipped APK would be a security finding).

---

## 6. Quick-win checklist (in priority order)

1. Trim `start.sh` to migrations + uvicorn only (§2.1). *5-minute fix, prevents duplicate WhatsApp sends.*
2. Fix `horoscope_batch` session/eager-load (§2.2).
3. Split web (pooled) vs worker (`NullPool`) DB engines (§2.3).
4. Add `slowapi` rate limit on `/auth/verify` + device-fingerprint trial gate (§3.1).
5. Move current-Dasha computation to read-time (§3.2).
6. `AsyncOpenAI(timeout=20, max_retries=2)` + tenacity + null-content guard (§3.3).
7. Fail-fast Firebase init in production (§3.4).
8. Hard-fail Razorpay signature verify in production (§4.1).
9. Seed a `tests/` suite starting with payments + chart golden tests (§3.5).
