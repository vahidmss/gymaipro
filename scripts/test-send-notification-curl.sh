#!/bin/bash
# =============================================================================
# تست دستی Edge Function send-notifications روی سرور
# استفاده: bash test-send-notification-curl.sh
# ابتدا ANON_KEY را از .env بخوان و به topic "all" پیام بفرست
# =============================================================================

cd ~/supabase/docker || exit 1
# Use SERVICE_ROLE_KEY for server-side test (bypasses user auth)
KEY=$(grep "^SERVICE_ROLE_KEY=" .env | cut -d= -f2-)
if [ -z "$KEY" ]; then
  echo "❌ SERVICE_ROLE_KEY not found in .env"
  exit 1
fi

echo "Testing send-notifications (topic: all)..."
curl -sS -X POST "http://127.0.0.1:8000/functions/v1/send-notifications" \
  -H "Authorization: Bearer $KEY" \
  -H "Content-Type: application/json" \
  -d '{"mode":"direct","target_type":"topic","topic":"all","title":"تست از سرور","body":"اگر این را دیدی، Edge Function کار می‌کند!"}'

echo ""
echo "Done. Check app for notification (must be subscribed to topic 'all')."
echo "Check logs: docker logs supabase-edge-functions --tail 20"
