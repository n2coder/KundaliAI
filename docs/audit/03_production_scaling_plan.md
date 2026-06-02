# Production Scaling Plan — KundliAI

**Date:** 2026-06-02
**Target market:** India, freemium (free tier + ₹30/mo premium, 15-day full trial).

This plan assumes the report 1 blockers are fixed first — none of the scaling work matters while Beat is duplicated, the nightly batch is broken, and the web app has no connection pool.

---

## 1. Workload shape

KundliAI has two very different load profiles that must scale independently:

1. **Interactive (request path):** auth, `/today`, `/horoscope/*`, `/chat`, `/insights`, `/birth-chart`. Latency-sensitive. Spiky around morning (people check their day) and whenever a WhatsApp message lands.
2. **Batch (nightly fan-out):** for every active user, one OpenAI call (horoscope) + one Meta API call (WhatsApp) + score/insight precompute. This is **O(N) per night** and is the real scaling cliff.

The expensive resources are, in order: **OpenAI tokens**, **Meta WhatsApp conversations**, **Postgres connections**, **Celery worker throughput**.

---

## 2. Capacity model (back-of-envelope)

Assume *A* = active+trial users with a birth chart (the only ones who get nightly content).

| Resource | Per active user / night | At A=1k | A=10k | A=100k |
|----------|------------------------|---------|--------|--------|
| OpenAI daily-horoscope calls | 1 (~600–800 tok out) | 1k | 10k | 100k |
| OpenAI monthly insight calls | 4 / month ≈ 0.13/day | ~130 | ~1.3k | ~13k |
| WhatsApp template messages | 1 | 1k | 10k | 100k |
| Chart computes (one-time/user) | ~0 steady state | — | — | — |

**Nightly batch time, current serial design:** the batch loops users **sequentially**, awaiting one GPT call (~1–3 s) each. At 10k users that's **3–8 hours in a single task on one worker** — it won't finish before the 07:00 WhatsApp dispatch. This is the first thing that breaks past a few thousand users.

**WhatsApp cost:** marketing/utility template conversations are billed per conversation by Meta (India utility ≈ ₹0.10–0.35 range, varies). At 100k/day that's ₹10k–35k/day in WhatsApp alone — model this against the ₹30/mo ARPU before scaling delivery to free users.

---

## 3. Bottlenecks & fixes by tier

### Tier 0 — Correctness (before launch)
Fix the three blockers (report 1 §2). Without these, "scaling" means scaling duplicate sends and failed batches. **Status: done** — `start.sh` no longer double-runs worker/beat, the nightly batch session bug is fixed, and the web engine is pooled. Celery was also "quieted" for the per-command Redis broker (no result backend, `--without-gossip/-mingle/-heartbeat`, `worker_enable_remote_control=False`, `polling_interval=5s`) — see the decision note below.

> **Architecture decision (2026-06-02): keep Celery + Redis; scale the *Redis billing model*, not the broker.**
> The queue is retained because Tiers B/C depend on distributed task fan-out (per-user/per-chunk subtasks across worker replicas), retries, and durability — none of which Render Cron + `BackgroundTasks` provide. The thing that doesn't scale is **Upstash's per-command pricing**, not Redis itself. So the lever is a billing-model switch (pay-as-you-go → fixed-price Redis), not Redis removal. The quieting config above keeps pay-as-you-go viable until that switch.

### Tier A — 0 → ~5k active users (single small deployment)
Current Render topology (1 web + 1 worker + 1 beat + Redis) is adequate **once fixed**, with these changes:

- **DB pooling (report 1 §2.3):** web engine `AsyncAdaptedQueuePool` (pool_size≈10, max_overflow≈10) pointed at **Neon's pooled (PgBouncer) connection string**; worker keeps `NullPool`. Neon's pooler is essential — direct connections are scarce.
- **Make the nightly batch concurrent:** replace the serial loop with bounded concurrency:
  ```python
  sem = asyncio.Semaphore(10)        # ≈ OpenAI concurrency you can afford
  async def one(user): 
      async with sem: await get_or_generate(...)
  await asyncio.gather(*(one(u) for u in users))
  ```
  This alone takes a 10k-user run from hours to ~15–25 min.
- **OpenAI resilience:** `timeout`, `max_retries`, tenacity backoff on 429 (report 1 §3.3). Respect your OpenAI org rate limits — set the semaphore below your RPM/TPM ceiling.
- **Redis — switch billing model, not the broker.** Today you're on Upstash pay-as-you-go (per-command), which is cheapest at near-zero volume and punishing under load. The quieting config (Tier 0) keeps idle command burn low enough for the free tier *now*. The **scale lever** is to move to a **fixed-price Redis** (Upstash fixed plan, Render Key Value, or a small dedicated Redis with persistence) the moment command volume makes per-command billing more expensive than the flat fee — at which point command count stops mattering and you can re-enable monitoring (`worker_send_task_events`, gossip, Flower) freely. Do **not** drop Redis: Tiers B/C need the queue.
  - **Watch `visibility_timeout` (3600s) vs task duration.** Redis redelivers any task that outruns the visibility timeout → duplicate execution. Safe now (short tasks) and safe after fan-out (short subtasks), but **unsafe in the middle** where the still-monolithic nightly batch loops thousands of users in a single >1h task. Fanning the batch out (Tier B) removes the risk; until then, ensure no single task approaches 3600s (or raise the timeout above the worst-case batch runtime).
- **Observability:** add Sentry + structured JSON logs + a `/metrics` (Prometheus) endpoint. You cannot scale what you cannot see.

### Tier B — ~5k → ~50k active users (horizontal + fan-out)
- **Web:** scale `kundliai-api` to ≥2 replicas behind Render's LB; the app is stateless (JWT, no session affinity) so this is free. Tune uvicorn workers per instance to CPU.
- **Batch fan-out → per-user subtasks:** stop running one giant task. Beat enqueues a *dispatcher* that chunks users (e.g. 200/chunk) into many `generate_chunk` / `send_chunk` tasks. Scale `kundliai-worker` replicas/concurrency to drain the queue in your window. This is the key architectural change for batch scale.
- **Idempotency + checkpointing:** each per-user task must be safely retryable (it already is for horoscope via the get-or-generate guard; ensure WhatsApp send checks `whatsapp_sent`/delivery row before resending — it does).
- **WhatsApp throughput:** Meta enforces per-number throughput tiers (1k → 10k → 100k+ unique recipients/24h) tied to your phone-number quality rating. Plan tier upgrades ahead of growth; spread sends across the allowed window; keep duplicate sends at zero (Tier 0) to protect the quality rating. Consider the Gupshup fallback path (decision #2) behind the single `WhatsAppProvider` abstraction for redundancy/throughput.
- **DB:** add a Neon **read replica** for read-heavy endpoints (`/today`, `/horoscope` reads, admin stats). Add indexes for the hot query shapes: `horoscopes(user_id, period, for_date)`, `chat_messages(user_id, is_deleted, created_at desc)`, `whatsapp_deliveries(meta_message_id)`, `today_data(user_id, for_date)`, `insight_predictions(user_id, category, period_start)`. Verify each composite exists in a migration (currently only single-column/unique constraints are guaranteed).
- **Cost control on OpenAI:** the `birth_chart_cache` already dedupes chart compute globally. Apply the same idea to horoscopes for free-tier users by **bucketing**: generate one horoscope per (sun_sign × period × date × language) for free users and personalise only paid users — cuts free-tier GPT spend by ~100× (12 signs vs N users). This is the single biggest lever on AI cost.

### Tier C — 50k → 500k+ active users
- **Dedicated queues** by workload (`ai`, `whatsapp`, `compute`) with separate worker pools and autoscaling, so a WhatsApp backlog can't starve interactive chart computes.
- **Move chat to streaming** (SSE) so users see tokens immediately; cap per-user daily message budget to bound cost.
- **Postgres:** consider partitioning high-volume time-series tables (`horoscopes`, `chat_messages`, `whatsapp_deliveries`, `daily_scores`) by month, with a retention/archival policy (e.g. drop horoscope bodies older than 90 days — they're regenerable). Watch JSONB bloat on `chart_data`.
- **Caching layer:** Redis cache for `/today` and current-Dasha computations (cheap, deterministic, per-day) to offload Postgres.
- **Multi-region** only if latency data justifies it; India-single-region is fine to ~500k.

---

## 4. Reliability & operational gaps to close before scale

| Area | Current | Needed |
|------|---------|--------|
| Connection pooling | ✅ web pooled / worker NullPool (fixed) | point web at Neon PgBouncer URL when connections tighten |
| Batch design | single serial task | bounded-concurrency now → per-user fan-out later |
| OpenAI calls | no timeout/retry, in request path | timeout+retry+backoff; strictly DB-served reads |
| Beat durability | ✅ single beat (duplicate removed) | durable fixed-price broker before scale |
| Redis billing | Upstash per-command (quieted) | switch to fixed-price Redis when command volume justifies it; keep the broker |
| Task redelivery | `visibility_timeout=3600` + monolithic batch | fan out batch so no single task nears the timeout |
| Worker monitoring | gossip/events disabled (cost) | re-enable events + Flower after fixed-price Redis switch |
| Secrets | `.env` local, `sync:false` on Render | + secret rotation policy; fail-fast on missing prod secrets |
| Error tracking | none | Sentry + alerting on batch failure counts |
| Health checks | `/health` static `{ok}` | deepen to check DB + Redis reachability for LB decisions |
| Rate limiting | none | `slowapi`/Redis on `/auth/verify`, `/chat`, `/birth-chart/geocode` (Google cost) |
| Tests/CI | none | unit + golden chart + webhook tests gating deploys |
| DB backups | Neon default | verify PITR enabled + restore drill |
| Admin | static API key, dashboard unbuilt | build React admin (decision #17), real admin auth + audit |

---

## 5. Cost levers (ranked by impact)

1. **Bucket free-tier horoscopes by sign** (Tier B) — ~100× reduction in free-tier GPT calls. Biggest lever.
2. **Keep daily horoscopes DB-served** (fix batch) — avoids paying GPT latency+tokens on every request.
3. **Cap chat history at 10 + per-user daily message budget** — bounds the open-ended chat cost (history cap already implemented; budget not).
4. **WhatsApp only for paid + opted-in users**, or use cheaper utility templates, to keep Meta conversation spend below ARPU.
5. **gpt-4o-mini everywhere except premium deep reports** (decision #6) — already the case; guard against accidental model upgrades.
6. **Global `birth_chart_cache` + `place_geocache`** — already implemented; preserve them.

---

## 6. Recommended scaling roadmap (sequenced)

```
Phase 0 (pre-launch, ~1 week)
  └─ ✅ Fix 3 blockers · ✅ DB pool · ✅ quiet Celery for per-command Redis
     · OpenAI timeout/retry · rate limit /auth · Sentry · seed tests

Phase 1 (launch → 5k)
  └─ Concurrent (semaphore) batch · health-check depth · hot-path indexes
     · read-time Dasha · WhatsApp opt-in gating
     · (trigger) switch Upstash → fixed-price Redis when commands > flat-fee break-even

Phase 2 (5k → 50k)
  └─ Per-user task fan-out · web replicas · Neon read replica
     · sign-bucketed free horoscopes · Meta throughput tier upgrades · Gupshup fallback wired

Phase 3 (50k → 500k+)
  └─ Dedicated queues + worker autoscaling · streaming chat + budgets
     · table partitioning + retention · Redis read cache · capacity-based region review
```

**Bottom line:** the architecture is fundamentally sound and the caching instincts are good. Scaling is gated less by raw infra and more by (a) fixing the batch/Beat/pooling defects, (b) turning the serial nightly loop into a fan-out, and (c) controlling OpenAI + WhatsApp unit economics via sign-bucketing and opt-in gating. Do those and the same Render+Neon+Redis shape comfortably carries you to ~50k active users.
