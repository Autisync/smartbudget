# Secret Rotation Runbook — Postgres password, JWT signing key, SMTP password

## Why this exists

Commit `279c570` ("security(backend): scrub real secrets from .env.example…") removed live
credential values from the tracked `.env.example` file, but they remain permanently retrievable
by anyone with read access to this repository's git history via `git log`/`git show`:

- `POSTGRES_PASSWORD` — a real production database password
- `JWT_SECRET_KEY` — the real HS256 signing key for every access/refresh token
- `SMTP_PASSWORD` — a real mail-provider credential (same value as the Postgres password —
  password reuse across services, itself worth fixing by not reusing the new values either)

**As of this writing, it is not confirmed whether these were ever rotated on the live server.**
If the JWT secret specifically was never rotated, anyone with repo access can forge a valid
access or refresh token for *any* user account — a full authentication bypass, not just a data
leak. This runbook exists so that rotation can happen in one deliberate, low-risk pass rather
than as a rushed reaction later.

**This runbook is a set of manual steps for a human with server access to run while awake.**
No part of it was executed automatically — see `backend/scripts/rotate_secrets.sh`, which only
generates new values locally and never touches the live server.

## Impact — read this before starting

| Secret              | Effect of rotation                                                                 |
|----------------------|-------------------------------------------------------------------------------------|
| `POSTGRES_PASSWORD` | Brief backend/Celery downtime during the coordinated update (seconds, if done in order below). No user-visible data loss. |
| `JWT_SECRET_KEY`    | **Every currently signed-in user is logged out immediately**, no warning, the moment the new key is live — all existing access/refresh tokens fail signature verification. Users simply need to log in again; no data is lost. Pick a low-traffic window. |
| `SMTP_PASSWORD`     | No user-facing impact if rotated correctly before the old credential is revoked at the provider. Verification/reset emails could fail to send during the gap if done out of order. |

## Prerequisites

- Root/SSH access to the production server (same access used earlier this session for the
  Traefik fix).
- Access to whatever SMTP provider is configured (`SMTP_HOST` in the server's `.env` tells you
  which one).
- A password manager or other secure location to stage the new values — **never** paste secrets
  into chat, email, or a ticket.

## Step 0 — generate new values locally

```bash
cd backend
./scripts/rotate_secrets.sh --out /tmp/new_secrets.env   # local machine, not the server
```

This prints new random values for `POSTGRES_PASSWORD` and `JWT_SECRET_KEY` and reminds you that
`SMTP_PASSWORD` must come from your SMTP provider's dashboard instead (a locally-invented string
won't authenticate against their servers). Move `/tmp/new_secrets.env` into your password manager
and delete the file once staged — don't leave secrets sitting in `/tmp`.

## Step 1 — rotate `POSTGRES_PASSWORD`

On the server:

```bash
docker exec -it smaartspend-postgres psql -U smartbudget -d smartbudget \
  -c "ALTER USER smartbudget WITH PASSWORD '<NEW_POSTGRES_PASSWORD>';"
```

Then, in the server's `.env` (wherever the `smartbudget` stack's compose file reads it from —
this is a Portainer-managed stack per this session's earlier investigation, so check whether the
env is set via Portainer's stack environment-variables UI or a file):

```
POSTGRES_PASSWORD=<NEW_POSTGRES_PASSWORD>
DATABASE_URL=postgresql+psycopg://smartbudget:<NEW_POSTGRES_PASSWORD>@postgres:5432/smartbudget
```

Restart the backend, celery-worker, and celery-beat containers (not postgres itself — it already
has the new password from the `ALTER USER` above):

```bash
docker restart smaartspend-backend smaartspend-celery-worker smaartspend-celery-beat
```

**Verify before continuing:** `docker logs smaartspend-backend --tail 50` shows a clean startup
with no DB connection errors; `curl https://api.smaartspend.com/health/ready` returns healthy.

## Step 2 — rotate `SMTP_PASSWORD`

1. Log into the SMTP provider's dashboard (check `SMTP_HOST`/`SMTP_USERNAME` in the server's
   `.env` to identify which provider and account).
2. Generate a new app password / API key. Do not revoke the old one yet.
3. Update `SMTP_PASSWORD` in the server's `.env` to the new value.
4. Restart `smaartspend-backend` and `smaartspend-celery-worker` (email sending happens via
   Celery).
5. Trigger a real test email (e.g. request a password reset for a test account) and confirm it
   arrives.
6. Only after confirming delivery works, revoke the old credential at the provider.

## Step 3 — rotate `JWT_SECRET_KEY` (do this last, and expect the user-visible effect)

This is the step that logs everyone out. Do it deliberately, not as an afterthought to steps 1-2.

1. Update `JWT_SECRET_KEY` in the server's `.env` to the value generated in Step 0.
2. Restart `smaartspend-backend`:
   ```bash
   docker restart smaartspend-backend
   ```
3. Immediately after restart, every existing access/refresh token stops verifying. This is
   expected — there is no way to rotate the signing key without this effect, and it's the entire
   point of rotating it if the old key may have leaked.
4. Verify: log in with a real test account after the restart and confirm a fresh token pair
   works normally, and that the finance/auth endpoints respond correctly with the new token.

## Rollback

- **Postgres password**: if something goes wrong before Step 1's containers are confirmed
  healthy, `ALTER USER smartbudget WITH PASSWORD '<OLD_PASSWORD>';` reverts cleanly — keep the
  old value handy until Step 1 is verified.
- **SMTP password**: the old credential is still active until you explicitly revoke it in Step 2,
  so reverting `.env` to the old value is a safe fallback until then.
- **JWT key**: there is no meaningful rollback — once rotated, old sessions are gone either way.
  Reverting to the old key does not restore them and would reintroduce the leaked-key risk, so
  don't revert it; if something breaks after rotation, debug forward (check `.env` was saved
  correctly, container actually restarted with the new value) rather than rolling back.

## After all three are done

- Purge the leaked blobs from git history (`git filter-repo` or BFG) so they're not trivially
  re-discoverable by a future clone — note this is cleanup, not the actual fix; rotation is what
  neutralizes the risk, since the old values are useless to an attacker once rotated regardless
  of whether they're still visible in history.
- Add a pre-commit secret scanner (gitleaks or trufflehog) so a real secret can't be committed to
  `.env.example` (or anywhere) again without being caught before it reaches `git push`.
- Update this runbook with the actual rotation date once done, for the next person's context.
