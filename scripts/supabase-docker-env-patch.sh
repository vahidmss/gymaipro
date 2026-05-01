#!/bin/bash
# =============================================================================
# Supabase Docker – اضافه کردن envهای لازم برای Edge Functions
# روی سرور اجرا کن: bash supabase-docker-env-patch.sh
# یا: chmod +x supabase-docker-env-patch.sh && ./supabase-docker-env-patch.sh
# =============================================================================

set -e

SUPABASE_DOCKER="${SUPABASE_DOCKER:-$HOME/supabase/docker}"
cd "$SUPABASE_DOCKER" || { echo "Directory not found: $SUPABASE_DOCKER"; exit 1; }

echo "Working in: $(pwd)"

# 1) بکاپ docker-compose.yml
if [ ! -f docker-compose.yml.bak.before-env-patch ]; then
  cp docker-compose.yml docker-compose.yml.bak.before-env-patch
  echo "Backup created: docker-compose.yml.bak.before-env-patch"
fi

# 2) اضافه کردن envهای Edge Functions به سرویس functions (فقط اگر قبلاً اضافه نشده)
if grep -q 'FIREBASE_PROJECT_ID:' docker-compose.yml 2>/dev/null && grep -q 'GYM_TOPUP_SECRET:' docker-compose.yml 2>/dev/null; then
  echo "docker-compose.yml: Edge Function env vars already present, skipping."
else
  # در لینوکس: بعد از خط GOOGLE_APPLICATION_CREDENTIALS این سه خط را اضافه می‌کنیم
  sed -i '/GOOGLE_APPLICATION_CREDENTIALS: \/secrets\/firebase-service-account.json/a\
      FIREBASE_PROJECT_ID: ${FIREBASE_PROJECT_ID}\
      GYM_TOPUP_SECRET: ${GYM_TOPUP_SECRET}\
      FIREBASE_SERVICE_ACCOUNT_KEY: ${FIREBASE_SERVICE_ACCOUNT_KEY}' docker-compose.yml
  echo "docker-compose.yml: Added FIREBASE_PROJECT_ID, GYM_TOPUP_SECRET, FIREBASE_SERVICE_ACCOUNT_KEY to functions service."
fi

# 3) اضافه کردن کلیدهای جدید به .env اگر قبلاً نیستند
append_env_if_missing() {
  local key="$1"
  if grep -q "^${key}=" .env 2>/dev/null; then
    echo ".env: ${key} already set."
  else
    echo "${key}=" >> .env
    echo ".env: Appended ${key}= (fill value from Supabase Dashboard Secrets)."
  fi
}

append_env_if_missing "FIREBASE_PROJECT_ID"
append_env_if_missing "GYM_TOPUP_SECRET"
append_env_if_missing "FIREBASE_SERVICE_ACCOUNT_KEY"

echo ""
echo "Done. Next steps:"
echo "1. Edit .env and set: FIREBASE_PROJECT_ID, GYM_TOPUP_SECRET, FIREBASE_SERVICE_ACCOUNT_KEY (from Supabase Cloud Secrets)."
echo "2. Restart functions: docker-compose restart functions"
echo "3. For FIREBASE_SERVICE_ACCOUNT_KEY: if your Edge Function expects JSON string, paste the whole JSON in one line in .env."
