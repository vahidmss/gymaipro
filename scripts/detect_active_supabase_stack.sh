#!/usr/bin/env bash
# Run ON THE SERVER (SSH as root). Finds which folder actually runs Kong/Supabase
# and prints safe next steps (paths only; you grep secrets yourself).
set -euo pipefail

echo "=============================================="
echo "GymAI — تشخیص استک فعال Supabase روی این سرور"
echo "=============================================="

echo ""
echo "== 1) docker compose projects =="
docker compose ls -a 2>/dev/null || true

echo ""
echo "== 2) Kong / supabase containers (names) =="
docker ps --format '{{.Names}}\t{{.Status}}\t{{.Ports}}' | grep -Ei 'kong|supabase-' || true

ACTIVE_DIR=""
for d in /root/supabase/docker /root/supabase-project "$HOME/supabase/docker" "$HOME/supabase-project"; do
  if [[ -f "$d/docker-compose.yml" && -f "$d/.env" ]]; then
    if docker compose -f "$d/docker-compose.yml" ps 2>/dev/null | grep -q supabase-kong; then
      ACTIVE_DIR="$d"
      break
    fi
  fi
done

echo ""
if [[ -n "$ACTIVE_DIR" ]]; then
  echo "== نتیجه: استک فعال این مسیر است =="
  echo "$ACTIVE_DIR"
  echo ""
  echo "برای دیدن ANON_KEY (کپی در .env اپ):"
  echo "  grep '^ANON_KEY=' \"$ACTIVE_DIR/.env\""
  echo ""
  echo "برای ورود Studio (Basic Auth Kong):"
  echo "  grep '^DASHBOARD_USERNAME=' \"$ACTIVE_DIR/.env\""
  echo "  grep '^DASHBOARD_PASSWORD=' \"$ACTIVE_DIR/.env\""
  echo ""
  echo "وضعیت سرویس‌ها:"
  docker compose -f "$ACTIVE_DIR/docker-compose.yml" ps
else
  echo "== هشدار: پوشهٔ فعال با supabase-kong پیدا نشد =="
  echo "دستی بزن: docker compose ls"
  echo "بعد cd همان مسیری که CONFIG FILES نشان می‌دهد."
fi

echo ""
echo "== 3) دیسک ریشه =="
df -h / | tail -1

echo ""
echo "=============================================="
echo "پایان."
echo "=============================================="
