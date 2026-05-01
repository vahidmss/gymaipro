#!/bin/bash
# =============================================================================
# قرار دادن Firebase credentials در .env به صورت Base64 (بی‌خطر برای کاراکترهای خاص)
# روی سرور اجرا کن: bash set-firebase-in-env.sh
# =============================================================================

set -e
cd ~/supabase/docker || exit 1

CRED_FILE="./secrets/firebase-service-account.json"
if [ ! -f "$CRED_FILE" ]; then
  echo "❌ File not found: $CRED_FILE"
  exit 1
fi

# Encode to base64 (safe for .env)
B64=$(base64 -w 0 "$CRED_FILE" 2>/dev/null || base64 -b 0 "$CRED_FILE")

# Remove existing lines
sed -i '/^FIREBASE_SERVICE_ACCOUNT_KEY=/d' .env
sed -i '/^FIREBASE_SERVICE_ACCOUNT_B64=/d' .env

# Add base64 (no special chars)
echo "FIREBASE_SERVICE_ACCOUNT_B64=$B64" >> .env

echo "✅ FIREBASE_SERVICE_ACCOUNT_B64 added to .env"

# Add to docker-compose functions environment if not present
if ! grep -q 'FIREBASE_SERVICE_ACCOUNT_B64:' docker-compose.yml 2>/dev/null; then
  # Add after FIREBASE_SERVICE_ACCOUNT_KEY or GOOGLE_APPLICATION_CREDENTIALS
  if grep -q 'FIREBASE_SERVICE_ACCOUNT_KEY:' docker-compose.yml; then
    sed -i '/FIREBASE_SERVICE_ACCOUNT_KEY:/a\      FIREBASE_SERVICE_ACCOUNT_B64: ${FIREBASE_SERVICE_ACCOUNT_B64}' docker-compose.yml
  else
    sed -i '/GOOGLE_APPLICATION_CREDENTIALS:/a\      FIREBASE_SERVICE_ACCOUNT_B64: ${FIREBASE_SERVICE_ACCOUNT_B64}' docker-compose.yml
  fi
  echo "✅ FIREBASE_SERVICE_ACCOUNT_B64 added to docker-compose.yml"
fi

echo ""
echo "Recreate functions (to load new env): docker-compose stop functions && docker-compose rm -f functions && docker-compose up -d functions"
