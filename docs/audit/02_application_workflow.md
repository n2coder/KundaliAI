# Application Workflow — KundliAI

**Date:** 2026-06-02

This report documents how the system actually behaves end-to-end, as built. It is written from the code, not the design docs, so it reflects current reality (including the bugs flagged in report 1, marked ⚠).

---

## 1. System topology

```
                 ┌─────────────────────────────┐
   Flutter App   │  FastAPI (kundliai-api)      │
  (Riverpod/Dio) │  routers → services → ORM    │
   firebase_auth │                              │
        │        └───────┬───────────┬──────────┘
        │ Firebase OTP   │ asyncpg   │ enqueue (.delay)
        ▼                ▼           ▼
   Firebase Auth    PostgreSQL    Redis (broker + result)
                     (Neon)          │
                                     ├── kundliai-worker (Celery)
                                     └── kundliai-beat   (Celery Beat schedule)
                                            │
   External: OpenAI (GPT-4o-mini) · Google Geocoding · Meta WhatsApp Cloud API · Razorpay
```

**API surface** (`main.py`): `/api/v1/{auth, users, birth-chart, horoscope, chat, today, insights, remedies, payments, whatsapp, admin, transits, compatibility}` + `/health`.

---

## 2. Authentication & onboarding

```
App: Firebase phone OTP  ──►  Firebase returns ID token
App: POST /auth/verify { firebase_token }
        │
        ▼
verify_firebase_token()  ── Firebase Admin verifies signature/expiry
        │  extracts phone_number + uid claims
        ▼
auth_service.upsert_user(phone, firebase_uid)
        │  • new user  → SubscriptionStatus.trial, trial_ends_at = now + 15 days
        │  • existing  → touch last_active_at; backfill firebase_uid;
        │                auto-expire trial if trial_ends_at < now
        ▼
create_access_token(user.id)  ── 30-day HS256 JWT (sub = user_id)
        ▼
returns { access_token, user }   ── app stores JWT in flutter_secure_storage
```

- App thereafter sends `Authorization: Bearer <our-JWT>`; Firebase tokens are never sent again (`auth_provider.dart`).
- `get_current_user` decodes the JWT, loads the user **with `selectinload(birth_chart)`** (`dependencies.py:31`).
- `get_current_active_user` additionally 402s if subscription is `expired`/`cancelled` — used to gate premium endpoints.
- On app cold-start, `AuthNotifier._init` reads the stored JWT and calls `/auth/me`; on 401 it clears the token, on network error it keeps it for retry.

⚠ **Gaps:** no rate limit on `/auth/verify`; no device fingerprint; trial is re-obtainable with a new phone number (report 1 §3.1).

---

## 3. Birth-details → chart computation (async)

```
App: POST /birth-chart/compute { name?, dob, tob, birth_place, [lat,lng] }
        │
        ▼
if lat/lng missing → geocode_service.geocode(place)
        │   1) check place_geocache (city → lat/lng)   ── cache hit ++counter
        │   2) miss → Google Geocoding API → store rounded(3dp)
        ▼
persist dob/tob/place/lat/lng onto users row  → commit
        ▼
compute_chart_for_user.delay(user_id)   ── Celery task (non-fatal if broker down)
        ▼
returns 202 { status: enqueued|saved, message }
```

Celery worker (`chart_compute._async_compute`):
```
load User + birth_chart (selectinload)
get_or_compute_chart(dob, tob, lat, lng):
    1) check birth_chart_cache (dob,tob,lat,lng) ── global cache, hit ++counter
    2) miss → compute_vedic_chart():
         • Lahiri sidereal, Moshier ephemeris, whole-sign houses
         • planets Sun..Saturn + Rahu(true node) + Ketu(=Rahu+180°)
         • ascendant from Placidus ascmc − ayanamsa
         • Vimshottari mahadasha/antardasha  ⚠ uses date.today() (report 1 §3.2)
       → store in birth_chart_cache
upsert per-user BirthChart row (chart_data JSONB + denormalised sun/moon/asc/dasha)
```

The 1:1 `BirthChart` row is what every downstream feature reads. The shared `birth_chart_cache` means two users born at the same place/instant compute the chart only once globally.

---

## 4. Horoscope (daily / weekly / monthly)

**Intended (decision #11):** Beat pre-generates tomorrow's daily horoscope at 23:30 IST → stored in `horoscopes` → served instantly from DB → optionally pushed via WhatsApp at 07:00 IST.

**Actual request flow** (`routers/horoscope.py` → `horoscope_service.get_or_generate`):
```
GET /horoscope/daily   (requires birth_chart)
   → look up horoscopes(user, period=daily, for_date=today)
   → if row + content in user's language exists → return it
   → else generate now: GPT-4o-mini with _chart_summary(chart) as system prompt
        period-specific length (daily 150-200w / weekly 250-300w / monthly 400-500w)
        language en|hi → store content_en/content_hi → return
```

- Bilingual: a row can hold both `content_en` and `content_hi`; generation fills only the requested language lazily.
- ⚠ Because the nightly batch is broken (report 1 §2.2), **every** daily request currently falls through to synchronous GPT generation (latency + cost in the request path, report 1 §3.3).

---

## 5. AI chat ("Jyotish" guide)

```
POST /chat/message { content, topic? }
   → _load_history: last 10 non-deleted messages, chronological  (decision #18)
   → system prompt = persona + _chart_summary(chart or "no chart yet") + optional topic focus
   → messages = [system] + history + [user]
   → GPT-4o-mini (max_tokens 400, temp 0.7)
   → persist BOTH user + assistant messages → return assistant message
GET /chat/history → same rolling window
```

Full history is stored in `chat_messages` (soft-delete via `is_deleted`); only the last 10 are sent to the model to cap token cost. Works without a birth chart (general mode that nudges the user to add birth details).

---

## 6. Today / Panchang

```
GET /today  → today_service.get_or_compute_today(user, birth_chart)
   → cached per (user, date) in today_data; return if present
   → else compute via pyswisseph:
        panchang: tithi, nakshatra, yoga, karana, vara, sunrise, sunset  (sampled at noon ⚠)
        muhurtas: Brahma, Abhijit, Rahu Kalam, Yamaganda, Gulika (from sunrise/sunset octants)
        lucky color/number/direction/gem by weekday
        mantra from user's NATAL moon nakshatra lord (falls back to today's if no chart)
   → store + return
```

Location: user's birth lat/lng, else Mumbai fallback (`_DEFAULT_LAT/LNG`). All static-table driven (no AI), so cheap and deterministic.

---

## 7. Insights, Remedies, Transits, Compatibility

- **Insights** (`insight_service`): monthly per-category (career/love/money/health) GPT-4o-mini call returning **JSON** (`response_format=json_object`) with `{score, content, best_periods}`; cached per (user, category, month_start). Falls back to `{score:0.5, content:""}` on error. Intended to be pre-generated on the 1st of the month by `insight_batch`.
- **Remedies** (`remedy_service`): **pure rule engine, no AI.** Triggers on debilitated planets (sign-based table), always adds one Rahu + one Ketu mantra, adds Saturn ritual if Saturn in 7th/10th, always appends Gayatri; capped at 6. Fully deterministic and free.
- **Transits / Compatibility**: dedicated routers/services (pyswisseph-based) exposed at `/transits` and `/compatibility`.

---

## 8. Payments (Razorpay subscriptions)

```
POST /payments/create-subscription
   → 400 if already active; 503 if gateway unconfigured
   → razorpay.subscription.create(plan_id_monthly, total_count=12, notes={user_id})
   → returns { subscription_id, short_url, status }  → app opens checkout

Razorpay → POST /payments/webhook  (HMAC-SHA256 verified ⚠ skipped if secret unset)
   subscription.charged  → idempotent (unique payment_id) → record Payment,
                           user.status=active, subscription_ends_at = now+32d
   subscription.cancelled → status=cancelled
   subscription.completed/expired → status=expired

GET /payments/status → returns status + trial/subscription end dates
```

Status gating is enforced app-side and via `get_current_active_user` (402 on expired/cancelled). MRR is approximated in admin stats as `active * ₹30`.

---

## 9. WhatsApp delivery

```
Beat 01:30 UTC (07:00 IST) → whatsapp_batch.dispatch_all
   for each user where whatsapp_enabled AND status in (trial, active):
      load today's daily Horoscope (whatsapp_sent=False)
      pick content_hi/content_en by language → choose template (daily_horoscope_hi/_en)
      create WhatsAppDelivery(status=queued)
      POST graph.facebook.com/v19.0/{phone_id}/messages  (template, body param ≤1000 chars)
      success → delivery.sent + meta_message_id + horoscope.whatsapp_sent=True
      failure → delivery.failed + error_message

Meta → GET /whatsapp/webhook  (hub.challenge verification)
Meta → POST /whatsapp/webhook  (status callbacks)
      delivered → delivery.delivered ; failed → delivery.failed(+error) ; sent/read → no-op
      always returns 200 (never trigger Meta retries)
```

⚠ Depends entirely on the nightly horoscope batch having produced rows; with that broken (§2.2) plus duplicate Beat (§2.1), the live behaviour is "either nothing sends, or everything sends twice" depending on which bug dominates.

---

## 10. Scheduled jobs (Celery Beat)

| Task | Schedule (UTC) | IST | Purpose |
|------|----------------|-----|---------|
| `horoscope_batch.generate_all` | 18:00 | 23:30 | Pre-generate tomorrow's daily horoscope for trial+active users ⚠ |
| `score_batch.compute_all` | 18:15 | 23:45 | Daily compatibility/score precompute |
| `insight_batch.generate_all` | 18:30 (day 1) | 00:00 | Monthly per-category insights |
| `whatsapp_batch.dispatch_all` | 01:30 | 07:00 | Send daily horoscope via WhatsApp |

`celery_app.py` is timezone `Asia/Kolkata` with `enable_utc=True`; cron values are written in UTC with IST noted in comments. Redis TLS (`rediss://`) auto-detected with `ssl_cert_reqs=CERT_NONE`.

---

## 11. Data model (core tables)

- `users` (PK uuid; unique phone, unique firebase_uid; subscription_status indexed; birth fields; whatsapp prefs).
- `birth_charts` (1:1 user, JSONB chart_data + denormalised signs/dasha).
- `birth_chart_cache` (global, unique dob/tob/lat/lng) · `place_geocache` (unique place_name) — the two cost-savers.
- `horoscopes` (per user/period/date, content_en + content_hi, whatsapp_sent flag).
- `chat_messages` (full history, role enum, soft-delete).
- `insight_predictions` · `daily_scores` · `today_data` · `whatsapp_deliveries` · `payments`.

Migrations via Alembic (async `env.py`); a single `initial_schema` revision covers all tables. `start.sh` runs `alembic upgrade head` on boot. In non-production, `lifespan` also `create_all`s as a convenience.

---

## 12. Workflow risks summary

| Flow | Status | Risk |
|------|--------|------|
| Auth / onboarding | ✅ works | abuse controls missing |
| Geocode + chart compute | ✅ works, well-cached | Dasha staleness (read-time fix needed) |
| Daily horoscope | ⚠ batch broken → falls back to slow on-demand | latency + cost in request path |
| WhatsApp delivery | ⚠ depends on broken batch + duplicate Beat | nothing-or-double sends |
| Chat | ✅ works | no per-user token budget/limit |
| Insights/Remedies/Today | ✅ works | panchang noon-sampling approximation |
| Payments | ✅ works, idempotent | signature skip when secret unset |
