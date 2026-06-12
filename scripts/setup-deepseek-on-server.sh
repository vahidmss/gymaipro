#!/bin/bash
# DeepSeek روی Supabase self-hosted — relay + env کانتینر functions
# روی سرور: bash ~/setup-deepseek-on-server.sh

set -e

SUPABASE_DOCKER="${SUPABASE_DOCKER:-/root/supabase/docker}"
cd "$SUPABASE_DOCKER" || { echo "پوشه پیدا نشد: $SUPABASE_DOCKER"; exit 1; }

echo "Working in: $(pwd)"

if [ ! -f "./volumes/functions/openai-chat/index.ts" ]; then
  echo "❌ volumes/functions/openai-chat/index.ts نیست — اول از ویندوز deploy کن."
  exit 1
fi

ensure_env() {
  local key="$1"
  local val="$2"
  if grep -q "^${key}=" .env 2>/dev/null; then
    sed -i "/^${key}=/d" .env
  fi
  echo "${key}=${val}" >> .env
  echo "✅ .env: ${key}"
}

ensure_compose_var() {
  local var="$1"
  if grep -q "${var}:" docker-compose.yml 2>/dev/null; then
    echo "docker-compose.yml: ${var} از قبل هست"
    return
  fi
  if grep -q 'OPENAI_API_KEY:' docker-compose.yml 2>/dev/null; then
    sed -i "/OPENAI_API_KEY: \${OPENAI_API_KEY}/a\\      ${var}: \${${var}}" docker-compose.yml
    echo "✅ docker-compose.yml: ${var} اضافه شد"
  elif grep -q 'GYM_TOPUP_SECRET:' docker-compose.yml 2>/dev/null; then
    sed -i '/GYM_TOPUP_SECRET: ${GYM_TOPUP_SECRET}/a\      OPENAI_API_KEY: ${OPENAI_API_KEY}' docker-compose.yml
    sed -i "/OPENAI_API_KEY: \${OPENAI_API_KEY}/a\\      ${var}: \${${var}}" docker-compose.yml
    echo "✅ docker-compose.yml: OPENAI_API_KEY + ${var} اضافه شد"
  else
    echo "⚠️ دستی زیر سرویس functions اضافه کن: ${var}: \${${var}}"
  fi
}

# --- کلید DeepSeek (اگر از قبل نباشد) ---
if ! grep -q '^OPENAI_API_KEY=' .env 2>/dev/null; then
  echo ""
  read -r -s -p "کلید DeepSeek (sk-...): " DS_KEY
  echo ""
  [ -n "$DS_KEY" ] || { echo "❌ کلید خالی"; exit 1; }
  ensure_env OPENAI_API_KEY "$DS_KEY"
else
  echo "✅ OPENAI_API_KEY در .env هست"
fi

ensure_env AI_API_BASE_URL "https://api.deepseek.com"
ensure_env AI_DEFAULT_MODEL "deepseek-v4-flash"

# --- Relay (الزامی برای سرور ایران) ---
if ! grep -q '^OPENAI_RELAY_URL=' .env 2>/dev/null; then
  echo ""
  echo "⚠️ OPENAI_RELAY_URL در .env نیست."
  echo "   اول از ویندوز Cloudflare Worker را deploy کن (OPENAI_RELAY_CLOUDFLARE_FA.md)"
  read -r -p "آدرس Worker (مثلاً https://gymai-openai-relay.xxx.workers.dev): " RELAY_URL
  read -r -s -p "RELAY_SECRET (همان secret در Cloudflare): " RELAY_SEC
  echo ""
  [ -n "$RELAY_URL" ] && [ -n "$RELAY_SEC" ] || { echo "❌ relay خالی"; exit 1; }
  ensure_env OPENAI_RELAY_URL "$RELAY_URL"
  ensure_env OPENAI_RELAY_SECRET "$RELAY_SEC"
else
  echo "✅ OPENAI_RELAY_URL در .env هست"
fi

for v in OPENAI_API_KEY OPENAI_RELAY_URL OPENAI_RELAY_SECRET AI_API_BASE_URL AI_DEFAULT_MODEL; do
  ensure_compose_var "$v"
done

if ! grep -q 'SUPABASE_ANON_KEY:' docker-compose.yml 2>/dev/null; then
  if grep -q 'ANON_KEY:' docker-compose.yml 2>/dev/null; then
    sed -i '/ANON_KEY: ${ANON_KEY}/a\      SUPABASE_ANON_KEY: ${ANON_KEY}' docker-compose.yml 2>/dev/null || true
    echo "✅ SUPABASE_ANON_KEY به docker-compose.yml اضافه شد"
  fi
fi

echo ""
echo "بازسازی کانتینر functions (برای خواندن env جدید)..."
docker compose up -d --force-recreate functions 2>/dev/null || docker-compose up -d --force-recreate functions

echo ""
echo "=========================================="
echo "تمام. تست:"
echo "  bash ~/test-openai-connectivity.sh"
echo "=========================================="
