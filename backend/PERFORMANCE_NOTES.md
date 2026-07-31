# Performance Notes — P2.7

Captured against a local Postgres 16 seeded with 5,000 users and 20,023 auth
sessions (~4 per user, ~70% revoked — realistic-ish shape for an
active-user-with-history scenario), to give the query planner enough rows to
choose a real plan rather than defaulting to a full seq scan on a tiny table.

## Login-by-email lookup (`users.email`)

Unaffected by this migration — already backed by the existing
`ix_users_email` unique index from migration 0001.

```
EXPLAIN ANALYZE SELECT * FROM users WHERE email = 'perf-user-2500@example.com';

 Index Scan using ix_users_email on users  (cost=0.28..8.29 rows=1 width=710) (actual time=0.018..0.019 rows=1 loops=1)
   Index Cond: ((email)::text = 'perf-user-2500@example.com'::text)
 Planning Time: 0.662 ms
 Execution Time: 0.042 ms
```

Confirms **Index Scan**, not Seq Scan — the login query is index-backed as
RELEASE_BUILD.md expected.

## Active-session-by-user lookup (`auth_sessions.user_id WHERE revoked_at IS NULL`)

This is the query pattern the new partial index (migration
`0004_partial_idx_active_sess`) targets — "does this user have an active
session" / a future "list active sessions" feature. Captured **before**
(dropping the index temporarily) and **after** on the same seeded data:

**Before** (falls back to the existing non-partial `ix_auth_sessions_user_id`,
then filters out revoked rows in a heap re-check):
```
EXPLAIN ANALYZE SELECT * FROM auth_sessions WHERE user_id = '<uuid>' AND revoked_at IS NULL;

 Bitmap Heap Scan on auth_sessions  (cost=4.56..110.35 rows=1 width=558) (actual time=0.074..0.075 rows=2 loops=1)
   Recheck Cond: (user_id = '<uuid>'::uuid)
   Filter: (revoked_at IS NULL)
   Rows Removed by Filter: 2
   Heap Blocks: exact=1
   ->  Bitmap Index Scan on ix_auth_sessions_user_id  (cost=0.00..4.56 rows=37 width=0) (actual time=0.044..0.044 rows=4 loops=1)
         Index Cond: (user_id = '<uuid>'::uuid)
 Planning Time: 1.183 ms
 Execution Time: 0.202 ms
```

**After** (partial index applied):
```
EXPLAIN ANALYZE SELECT * FROM auth_sessions WHERE user_id = '<uuid>' AND revoked_at IS NULL;

 Index Scan using ix_auth_sessions_active_by_user on auth_sessions  (cost=0.28..8.29 rows=1 width=558) (actual time=0.061..0.062 rows=2 loops=1)
   Index Cond: (user_id = '<uuid>'::uuid)
 Planning Time: 0.795 ms
 Execution Time: 0.114 ms
```

Planner cost dropped from `4.56..110.35` to `0.28..8.29`, and the plan
changed from a bitmap-scan-then-filter (fetches every session row for the
user, revoked or not, then discards the revoked ones) to a direct index scan
that only ever touches active rows. At this seeded scale (4 sessions/user)
the absolute wall-clock difference is sub-millisecond either way — the real
benefit is that the partial index **stays small and cheap as revoked/expired
sessions accumulate** over a user's lifetime (years of logins/logouts),
whereas the non-partial index and the heap re-check both grow with total
session history, not just active sessions.

## Connection pool

`db_pool_size=5`, `db_max_overflow=5` per process (`app/core/config.py`,
applied in `app/db/session.py`). With `UVICORN_WORKERS=2` (docker-compose.yml
default), that's up to `2 * (5+5) = 20` backend connections at peak, plus
whatever `celery-worker`/`celery-beat` each open with their own default pool —
comfortably under Postgres's default `max_connections=100` with headroom for
other processes on this shared VPS. Documented here rather than left as an
unexamined default; revisit both numbers together if worker count changes.

## What's still open

This covers the two specific queries RELEASE_BUILD.md named and the pool
size question. It does **not** replace the auth-endpoint load test
(tracked separately, task P2.15) — these are query-plan-level checks on a
seeded local DB, not a measurement of the API under concurrent load.
