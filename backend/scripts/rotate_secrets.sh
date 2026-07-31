#!/usr/bin/env bash
# Generates NEW random values for the secrets flagged as leaked in git history
# (commit 279c570 — see backend/ROTATION_RUNBOOK.md for the full incident and
# the exact steps to apply these on the server).
#
# SAFE BY DESIGN: this script never touches any live system. It only
# generates values locally and prints them, plus the exact manual commands
# to apply each one. It does not SSH anywhere, does not call docker/psql,
# and does not modify any file outside of the --out path you choose.
#
# Usage:
#   ./rotate_secrets.sh                # print new values + apply instructions
#   ./rotate_secrets.sh --out FILE     # also write them to FILE in .env format
#
# SMTP_PASSWORD is intentionally NOT generated here — it's issued by your SMTP
# provider (see SMTP_HOST in .env), not something you can invent locally and
# expect to authenticate. Rotate it in the provider's dashboard/API instead;
# this script only reminds you to.

set -euo pipefail

OUT_FILE=""
if [[ "${1:-}" == "--out" ]]; then
  OUT_FILE="${2:?--out requires a file path}"
fi

require_python() {
  command -v python3 >/dev/null 2>&1 || {
    echo "python3 is required to generate secrets" >&2
    exit 1
  }
}
require_python

gen_urlsafe() {
  # $1 = number of random bytes (before base64 encoding, so output is longer)
  python3 -c "import secrets; print(secrets.token_urlsafe(${1}))"
}

NEW_POSTGRES_PASSWORD="$(gen_urlsafe 32)"
NEW_JWT_SECRET_KEY="$(gen_urlsafe 48)"

echo "# Generated $(date -u +%Y-%m-%dT%H:%M:%SZ) — apply via backend/ROTATION_RUNBOOK.md"
echo "# Do NOT commit this output. Do NOT paste these into chat/Slack/email."
echo
echo "POSTGRES_PASSWORD=${NEW_POSTGRES_PASSWORD}"
echo "JWT_SECRET_KEY=${NEW_JWT_SECRET_KEY}"
echo
echo "# SMTP_PASSWORD: NOT generated here. Rotate it in your SMTP provider's"
echo "# dashboard/API (check SMTP_HOST in the server's .env for which provider),"
echo "# then paste the new value into the runbook step manually."
echo
echo "# DATABASE_URL (rebuild this line with the new Postgres password once"
echo "# you know POSTGRES_USER/POSTGRES_DB from the server's current .env):"
echo "# DATABASE_URL=postgresql+psycopg://<POSTGRES_USER>:${NEW_POSTGRES_PASSWORD}@postgres:5432/<POSTGRES_DB>"
echo
echo "Next: follow backend/ROTATION_RUNBOOK.md — do not apply these until you"
echo "have read it. Rotating JWT_SECRET_KEY logs out every currently signed-in"
echo "user immediately, with no warning."

if [[ -n "$OUT_FILE" ]]; then
  {
    echo "# Generated $(date -u +%Y-%m-%dT%H:%M:%SZ) — see backend/ROTATION_RUNBOOK.md before applying"
    echo "POSTGRES_PASSWORD=${NEW_POSTGRES_PASSWORD}"
    echo "JWT_SECRET_KEY=${NEW_JWT_SECRET_KEY}"
  } > "$OUT_FILE"
  chmod 600 "$OUT_FILE"
  echo
  echo "Also wrote the two generated values to: ${OUT_FILE} (chmod 600)"
fi
