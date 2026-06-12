#!/bin/bash
# =============================================================================
# راه‌اندازی openai-chat روی Supabase self-hosted (روی سرور لینوکس اجرا شود)
# استفاده:
#   cd ~/supabase/docker   # یا /root/supabase/docker
#   bash ~/setup-openai-chat-on-server.sh
# =============================================================================

set -e

SUPABASE_DOCKER="${SUPABASE_DOCKER:-$HOME/supabase/docker}"
if [ -d "/root/supabase/docker" ]; then
  SUPABASE_DOCKER="/root/supabase/docker"
fi

cd "$SUPABASE_DOCKER" || { echo "پوشه پیدا نشد: $SUPABASE_DOCKER"; exit 1; }
echo "Working in: $(pwd)"

FUNC_DIR="./volumes/functions/openai-chat"
mkdir -p "$FUNC_DIR"
if [ ! -f "$FUNC_DIR/index.ts" ]; then
  echo "❌ $FUNC_DIR/index.ts وجود ندارد."
  echo "   اول از ویندوز deploy-openai-chat.ps1 را اجرا کن یا فایل را دستی کپی کن."
  exit 1
fi
echo "✅ فایل تابع: $FUNC_DIR/index.ts"

# --- 1) OPENAI_API_KEY در .env ---
if grep -q '^OPENAI_API_KEY=' .env 2>/dev/null; then
  echo ".env: OPENAI_API_KEY از قبل وجود دارد (در صورت نیاز دستی ویرایش کن)."
else
  echo ""
  echo "کلید OpenAI را وارد کن (با sk-proj- شروع می‌شود؛ در ترمینال دیده می‌شود):"
  read -r -s OPENAI_KEY
  echo ""
  if [ -z "$OPENAI_KEY" ]; then
    echo "❌ کلید خالی بود."
    exit 1
  fi
  echo "OPENAI_API_KEY=${OPENAI_KEY}" >> .env
  echo "✅ OPENAI_API_KEY به .env اضافه شد."
fi

# --- 2) docker-compose.yml ---
if grep -q 'OPENAI_API_KEY:' docker-compose.yml 2>/dev/null; then
  echo "docker-compose.yml: OPENAI_API_KEY از قبل هست."
else
  if ! grep -q 'GYM_TOPUP_SECRET:' docker-compose.yml 2>/dev/null; then
    echo "⚠️ خط مرجع GYM_TOPUP_SECRET پیدا نشد؛ دستی زیر سرویس functions اضافه کن:"
    echo "      OPENAI_API_KEY: \${OPENAI_API_KEY}"
  else
    sed -i '/GYM_TOPUP_SECRET: ${GYM_TOPUP_SECRET}/a\      OPENAI_API_KEY: ${OPENAI_API_KEY}' docker-compose.yml
    echo "✅ OPENAI_API_KEY به docker-compose.yml اضافه شد."
  fi
fi

# --- 3) ANON_KEY برای تابع (اگر نبود) ---
if ! grep -q 'SUPABASE_ANON_KEY:' docker-compose.yml 2>/dev/null; then
  if grep -q 'ANON_KEY:' docker-compose.yml 2>/dev/null; then
    sed -i '/ANON_KEY: ${ANON_KEY}/a\      SUPABASE_ANON_KEY: ${ANON_KEY}' docker-compose.yml 2>/dev/null || true
    echo "✅ SUPABASE_ANON_KEY به docker-compose.yml اضافه شد."
  fi
fi

echo ""
echo "ریستارت کانتینر functions ..."
docker compose restart functions 2>/dev/null || docker-compose restart functions

echo ""
echo "=========================================="
echo "تمام. تست:"
echo "  bash scripts/test-openai-connectivity.sh"
echo "=========================================="
