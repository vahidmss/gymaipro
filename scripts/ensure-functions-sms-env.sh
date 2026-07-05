#!/bin/bash
# Ensure SMS/AI env reaches supabase-edge-functions container
# Run ON SERVER: bash /tmp/ensure-functions-sms-env.sh
set -euo pipefail

cd /root/supabase/docker || exit 1

COMPOSE="docker-compose.yml"
if [ ! -f "$COMPOSE" ]; then
  echo "ERROR: $COMPOSE not found"
  exit 1
fi

cp "$COMPOSE" "${COMPOSE}.bak.$(date +%Y%m%d_%H%M%S)"

add_var() {
  local var="$1"
  if grep -q "${var}:" "$COMPOSE"; then
    echo "  OK: $var in compose"
    return
  fi
  if grep -q 'OPENAI_API_KEY:' "$COMPOSE"; then
    sed -i "/OPENAI_API_KEY: \${OPENAI_API_KEY}/a\\      ${var}: \${${var}}" "$COMPOSE"
    echo "  ADDED: $var"
  elif grep -q 'GYM_TOPUP_SECRET:' "$COMPOSE"; then
    sed -i "/GYM_TOPUP_SECRET: \${GYM_TOPUP_SECRET}/a\\      ${var}: \${${var}}" "$COMPOSE"
    echo "  ADDED: $var"
  else
    echo "  MANUAL: add under functions -> environment:"
    echo "      ${var}: \${${var}}"
  fi
}

echo "=== Patch docker-compose.yml ==="
for v in \
  SMS_API_USERNAME \
  SMS_API_PASSWORD \
  SMS_API_BODY_ID \
  SMS_API_BASE_URL \
  SMS_BODY_ID_TRAINER_PROGRAM_REQUEST \
  SMS_BODY_ID_USER_PROGRAM_PURCHASE \
  OPENAI_API_KEY \
  AI_API_BASE_URL \
  OPENAI_BASE_URL \
  SUPABASE_SERVICE_ROLE_KEY \
  SUPABASE_ANON_KEY \
  SUPABASE_URL; do
  add_var "$v"
done

echo ""
echo "=== .env SMS keys (masked) ==="
grep -E '^SMS_' .env | sed 's/=.*/=***/' || echo "WARN: no SMS_ in .env"

echo ""
echo "=== Recreate functions container (reload env) ==="
docker compose up -d --force-recreate functions

echo ""
echo "=== Verify inside container ==="
sleep 2
docker exec supabase-edge-functions env | grep -E '^(SMS_|OPENAI|AI_API|SUPABASE_)' | sed 's/=.*/=***/' || {
  echo "ERROR: still missing — check functions: environment: in $COMPOSE"
  exit 1
}

echo ""
echo "Done. Test: curl send-otp"
