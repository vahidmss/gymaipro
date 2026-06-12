#!/bin/bash
# تست DeepSeek + relay + تابع openai-chat
# روی سرور: cd /root/supabase/docker && bash ~/test-openai-connectivity.sh

set -e

SUPABASE_DOCKER="${SUPABASE_DOCKER:-$HOME/supabase/docker}"
if [ -d "/root/supabase/docker" ]; then
  SUPABASE_DOCKER="/root/supabase/docker"
fi

cd "$SUPABASE_DOCKER" || { echo "Directory not found: $SUPABASE_DOCKER"; exit 1; }

CONTAINER="supabase-edge-functions"
API_KEY=$(grep '^OPENAI_API_KEY=' .env 2>/dev/null | cut -d= -f2- | tr -d '\r')
API_BASE=$(grep '^AI_API_BASE_URL=' .env 2>/dev/null | cut -d= -f2- | tr -d '\r')
API_BASE="${API_BASE:-https://api.deepseek.com}"
MODEL=$(grep '^AI_DEFAULT_MODEL=' .env 2>/dev/null | cut -d= -f2- | tr -d '\r')
MODEL="${MODEL:-deepseek-v4-flash}"

echo "=========================================="
echo "DeepSeek Connectivity Test"
echo "=========================================="

if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
  echo "❌ کانتینر $CONTAINER در حال اجرا نیست."
  exit 1
fi
echo "✅ کانتینر $CONTAINER در حال اجراست."
echo ""

echo "[1/5] فایل تابع openai-chat ..."
if docker exec "$CONTAINER" test -f /home/deno/functions/openai-chat/index.ts 2>/dev/null; then
  echo "✅ openai-chat/index.ts در کانتینر وجود دارد"
else
  echo "❌ openai-chat/index.ts پیدا نشد — deploy-openai-chat.ps1 را اجرا کن"
fi
echo ""

echo "[2/5] env کانتینر ..."
for v in OPENAI_API_KEY OPENAI_RELAY_URL OPENAI_RELAY_SECRET AI_API_BASE_URL; do
  if docker exec "$CONTAINER" env 2>/dev/null | grep -q "^${v}="; then
    echo "✅ $v در کانتینر هست"
  else
    echo "⚠️ $v در کانتینر نیست — setup-deepseek-on-server.sh + force-recreate"
  fi
done
echo ""

echo "[3/5] اتصال مستقیم به ${API_BASE} ..."
if [ -z "$API_KEY" ]; then
  echo "❌ OPENAI_API_KEY در .env نیست"
else
  OUT=$(curl -sS --max-time 20 \
    -H "Authorization: Bearer ${API_KEY}" \
    -H "Content-Type: application/json" \
    -d "{\"model\":\"${MODEL}\",\"messages\":[{\"role\":\"user\",\"content\":\"ping\"}],\"max_tokens\":5}" \
    "${API_BASE}/chat/completions" 2>&1 || true)
  if echo "$OUT" | grep -q "timed out\|Could not resolve\|Connection refused\|Failed to connect"; then
    echo "❌ ${API_BASE} از سرور مستقیم در دسترس نیست (ایران) — relay لازم است"
  elif echo "$OUT" | grep -q '"choices"'; then
    echo "✅ ${API_BASE} مستقیم کار می‌کند"
  elif echo "$OUT" | grep -qi "invalid\|unauthorized\|authentication"; then
    echo "⚠️ به API وصل شد ولی کلید نامعتبر است"
  else
    echo "⚠️ پاسخ API:"
    echo "$OUT" | head -c 400
    echo ""
  fi
fi
echo ""

echo "[4/5] Cloudflare (برای relay) ..."
CF_CODE=$(curl -sS --max-time 15 -o /dev/null -w "%{http_code}" https://cloudflare.com 2>/dev/null || echo "000")
if [ "$CF_CODE" = "200" ] || [ "$CF_CODE" = "301" ] || [ "$CF_CODE" = "302" ]; then
  echo "✅ cloudflare.com در دسترس است — relay امکان‌پذیر است"
else
  echo "❌ cloudflare.com در دسترس نیست (HTTP $CF_CODE)"
fi
echo ""

echo "[5/5] تست OPENAI_RELAY_URL ..."
if ! grep -q '^OPENAI_RELAY_URL=' .env 2>/dev/null; then
  echo "❌ OPENAI_RELAY_URL در .env نیست — Worker Cloudflare را deploy کن"
else
  RELAY=$(grep '^OPENAI_RELAY_URL=' .env | cut -d= -f2- | tr -d '\r')
  RSEC=$(grep '^OPENAI_RELAY_SECRET=' .env | cut -d= -f2- | tr -d '\r')
  ROUT=$(curl -sS --max-time 40 -X POST "$RELAY/v1/chat/completions" \
    -H "X-Relay-Secret: $RSEC" \
    -H "Content-Type: application/json" \
    -d "{\"model\":\"${MODEL}\",\"messages\":[{\"role\":\"user\",\"content\":\"ping\"}],\"max_tokens\":5}" 2>&1 || true)
  if echo "$ROUT" | grep -q '"choices"'; then
    echo "✅ Relay کار می‌کند — چت اپ باید OK باشد"
  else
    echo "❌ Relay جواب نداد:"
    echo "$ROUT" | head -c 400
    echo ""
  fi
fi

echo ""
echo "لاگ تابع:"
echo "  docker logs $CONTAINER -f --tail 50"
