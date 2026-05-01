#!/bin/bash
# =============================================================================
# تست اتصال سرور به Firebase/Google APIs
# روی سرور اجرا کن: bash test-firebase-connectivity.sh
# داخل کانتینر Edge Functions اجرا می‌شود تا ببینی به FCM دسترسی داره یا نه
# =============================================================================

set -e

SUPABASE_DOCKER="${SUPABASE_DOCKER:-$HOME/supabase/docker}"
cd "$SUPABASE_DOCKER" || { echo "Directory not found: $SUPABASE_DOCKER"; exit 1; }

CONTAINER="supabase-edge-functions"

echo "=========================================="
echo "Firebase/Google APIs Connectivity Test"
echo "=========================================="
echo ""

# 1) آیا کانتینر functions در حال اجراست؟
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
  echo "❌ کانتینر $CONTAINER در حال اجرا نیست. اول اجرا کن: docker-compose up -d"
  exit 1
fi
echo "✅ کانتینر $CONTAINER در حال اجرا است."
echo ""

# 2) تست اتصال به oauth2.googleapis.com (endpoint مورد استفاده برای token)
echo "[1/4] تست اتصال به oauth2.googleapis.com ..."
OUT=$(docker exec "$CONTAINER" wget -q -O - --timeout=10 https://oauth2.googleapis.com/token 2>&1 || true)
if echo "$OUT" | grep -qE "405|400|Connection refused|timed out|Name or service not known"; then
  if echo "$OUT" | grep -q "timed out\|Name or service not known"; then
    echo "❌ oauth2.googleapis.com قابل دسترسی نیست (timeout یا DNS). ممکنه از ایران مسدود باشه."
  else
    echo "✅ oauth2.googleapis.com در دسترس است (پاسخ دریافت شد)"
  fi
else
  echo "✅ oauth2.googleapis.com در دسترس است"
fi
echo ""

# 3) تست اتصال به fcm.googleapis.com
echo "[2/4] تست اتصال به fcm.googleapis.com ..."
OUT2=$(docker exec "$CONTAINER" wget -q -O - --timeout=10 https://fcm.googleapis.com 2>&1 || true)
if echo "$OUT2" | grep -q "timed out\|Name or service not known"; then
  echo "❌ fcm.googleapis.com قابل دسترسی نیست (محدودیت شبکه)"
elif echo "$OUT2" | grep -qE "40[0-9]|Connection"; then
  echo "✅ fcm.googleapis.com در دسترس است"
else
  echo "✅ fcm.googleapis.com در دسترس است"
fi
echo ""

# 4) آیا فایل firebase-service-account وجود دارد؟
echo "[3/4] بررسی فایل Firebase service account ..."
CRED_FILE="/secrets/firebase-service-account.json"
if docker exec "$CONTAINER" test -r "$CRED_FILE" 2>/dev/null; then
  echo "✅ فایل $CRED_FILE وجود دارد و قابل خواندن است"
  PROJECT=$(docker exec "$CONTAINER" sh -c "cat $CRED_FILE 2>/dev/null | grep -o '\"project_id\":\"[^\"]*\"' | head -1" 2>/dev/null || true)
  if [ -n "$PROJECT" ]; then
    echo "   project_id: $PROJECT"
  fi
else
  echo "❌ فایل $CRED_FILE وجود ندارد یا خواندنی نیست"
  echo "   مسیر روی سرور: $SUPABASE_DOCKER/secrets/firebase-service-account.json"
fi
echo ""

# 5) چک envهای لازم
echo "[4/4] بررسی env و credentials ..."
docker exec "$CONTAINER" env 2>/dev/null | grep -E "^(SUPABASE_URL|SUPABASE_SERVICE_ROLE_KEY|FIREBASE_PROJECT_ID|GOOGLE_APPLICATION_CREDENTIALS)=" | sed 's/=.*/=***/' || true

if docker exec "$CONTAINER" test -r "$CRED_FILE" 2>/dev/null; then
  echo "✅ Firebase: از فایل $CRED_FILE استفاده می‌شود"
else
  HAS_KEY=$(docker exec "$CONTAINER" env 2>/dev/null | grep "^FIREBASE_SERVICE_ACCOUNT_KEY=" | wc -c)
  if [ "$HAS_KEY" -gt 30 ]; then
    echo "✅ Firebase: FIREBASE_SERVICE_ACCOUNT_KEY از env ست شده"
  else
    echo "⚠️ هیچکدام ست نشده: فایل credentials یا FIREBASE_SERVICE_ACCOUNT_KEY"
  fi
fi

echo ""
echo "=========================================="
echo "پایان تست"
echo "=========================================="
echo ""
echo "اگر فایربیس در دسترس نبود: ممکن است سرور در ایران محدودیت خروجی به Google داشته باشد."
echo "راه‌حل: استفاده از VPN/پروکسی روی سرور یا سرور در دیتاسنتر خارج."
echo ""
echo "برای دیدن لاگ Edge Function:"
echo "  docker logs supabase-edge-functions -f --tail 50"
echo ""
