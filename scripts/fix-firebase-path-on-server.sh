#!/bin/bash
# =============================================================================
# رفع خطای "path not found" برای فایل Firebase
# Deno در Edge Runtime فقط به مسیر functions دسترسی دارد.
# این اسکریپت فایل را کپی می‌کند و docker-compose را آپدیت می‌کند.
# اجرا روی سرور: bash fix-firebase-path-on-server.sh
# =============================================================================

set -e
cd ~/supabase/docker || exit 1

echo "[1/3] Creating .secrets in functions folder..."
mkdir -p ./volumes/functions/.secrets

echo "[2/3] Copying Firebase credentials..."
cp ./secrets/firebase-service-account.json ./volumes/functions/.secrets/

echo "[3/3] Updating GOOGLE_APPLICATION_CREDENTIALS in docker-compose..."
# Change path from /secrets/... to path inside functions (Deno can read)
sed -i 's|GOOGLE_APPLICATION_CREDENTIALS: /secrets/firebase-service-account.json|GOOGLE_APPLICATION_CREDENTIALS: /home/deno/functions/.secrets/firebase-service-account.json|g' docker-compose.yml

echo ""
echo "Done. Restart functions: docker-compose restart functions"
echo "Then test: bash test-send-notification-curl.sh"
