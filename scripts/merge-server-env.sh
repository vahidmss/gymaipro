#!/bin/bash
# Merge key/value lines from /tmp/gymaipro-sync.env into Supabase docker .env
# Run on server after sync-server-env-from-local.ps1
set -euo pipefail

SUPABASE_DOCKER="${SUPABASE_DOCKER:-/root/supabase/docker}"
SYNC_FILE="${1:-/tmp/gymaipro-sync.env}"

cd "$SUPABASE_DOCKER" || { echo "Not found: $SUPABASE_DOCKER"; exit 1; }

if [ ! -f "$SYNC_FILE" ]; then
  echo "Missing sync file: $SYNC_FILE"
  exit 1
fi

# Strip UTF-8 BOM if present (Windows upload)
if command -v sed >/dev/null 2>&1; then
  sed -i '1s/^\xEF\xBB\xBF//' "$SYNC_FILE" 2>/dev/null || true
fi

cp .env ".env.bak.$(date +%Y%m%d_%H%M%S)"
echo "Backup .env created."

upsert_key() {
  local key="$1"
  local value="$2"
  local tmp
  tmp="$(mktemp)"
  grep -v "^${key}=" .env > "$tmp" || true
  printf '%s=%s\n' "$key" "$value" >> "$tmp"
  mv "$tmp" .env
}

while IFS= read -r line || [ -n "$line" ]; do
  line="${line//$'\r'/}"
  [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
  key="${line%%=*}"
  value="${line#*=}"
  key="$(echo "$key" | xargs)"
  [[ -z "$key" ]] && continue
  upsert_key "$key" "$value"
  echo "  set $key"
done < "$SYNC_FILE"

# Aliases for Edge Functions (reference existing docker keys)
upsert_key "SUPABASE_URL" "https://api.gymaipro.ir"

if grep -q '^ANON_KEY=' .env; then
  anon="$(grep '^ANON_KEY=' .env | cut -d= -f2-)"
  upsert_key "SUPABASE_ANON_KEY" "$anon"
fi

if grep -q '^SERVICE_ROLE_KEY=' .env; then
  role="$(grep '^SERVICE_ROLE_KEY=' .env | cut -d= -f2-)"
  upsert_key "SUPABASE_SERVICE_ROLE_KEY" "$role"
fi

echo ""
echo "Patching docker-compose.yml for functions env..."

COMPOSE="docker-compose.yml"
if [ ! -f "$COMPOSE" ]; then
  echo "WARNING: $COMPOSE not found - skip compose patch."
else
  cp "$COMPOSE" "${COMPOSE}.bak.$(date +%Y%m%d_%H%M%S)"

  add_compose_var() {
    local var="$1"
    if grep -q "${var}:" "$COMPOSE" 2>/dev/null; then
      echo "  compose: $var already present"
      return
    fi
    if grep -q 'GYM_TOPUP_SECRET:' "$COMPOSE"; then
      sed -i "/GYM_TOPUP_SECRET: \${GYM_TOPUP_SECRET}/a\\      ${var}: \${${var}}" "$COMPOSE"
      echo "  compose: added $var"
    elif grep -q 'OPENAI_API_KEY:' "$COMPOSE"; then
      sed -i "/OPENAI_API_KEY: \${OPENAI_API_KEY}/a\\      ${var}: \${${var}}" "$COMPOSE"
      echo "  compose: added $var"
    else
      echo "  compose: WARNING could not find anchor for $var - add manually under functions:"
      echo "      ${var}: \${${var}}"
    fi
  }

  for v in \
    OPENAI_API_KEY \
    AI_API_BASE_URL \
    OPENAI_BASE_URL \
    SMS_API_USERNAME \
    SMS_API_PASSWORD \
    SMS_API_BODY_ID \
    SMS_API_BASE_URL \
    SUPABASE_SERVICE_ROLE_KEY \
    SUPABASE_ANON_KEY \
    SUPABASE_URL; do
    add_compose_var "$v"
  done
fi

echo ""
echo "Recreating edge functions (reload env from .env)..."
docker compose up -d --force-recreate functions 2>/dev/null || docker-compose up -d --force-recreate functions

echo ""
echo "=== Server .env keys (masked) ==="
grep -E '^(SMS_|AI_API|OPENAI_BASE|OPENAI_API_KEY|SUPABASE_SERVICE|SUPABASE_ANON_KEY|SUPABASE_URL=)' .env 2>/dev/null | sed 's/=.*/=***/' || echo "WARNING: grep found nothing"

echo ""
echo "Done. Verify inside container:"
echo "  docker exec supabase-edge-functions env | grep -E 'SMS_|OPENAI|AI_API|SUPABASE_' | sed 's/=.*/=***/'"
