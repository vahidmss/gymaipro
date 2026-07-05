#!/usr/bin/env bash
# Fix Supabase Realtime for GymAI (self-hosted)
# Run ON THE SERVER as root:
#   cd ~/supabase/docker && bash /root/fix-supabase-realtime-server.sh
#
# Or from Windows:
#   scp -P 9011 scripts/fix-supabase-realtime-server.sh root@87.248.156.175:/root/
#   ssh -p 9011 root@87.248.156.175 "bash /root/fix-supabase-realtime-server.sh"

set -euo pipefail

PUBLIC_URL="${PUBLIC_URL:-https://api.gymaipro.ir}"
SUPABASE_DIR="${SUPABASE_DIR:-/root/supabase/docker}"
NGINX_SITE="${NGINX_SITE:-/etc/nginx/sites-available/api.gymaipro.ir}"

echo "=== GymAI Supabase Realtime Fix ==="
echo "PUBLIC_URL=$PUBLIC_URL"
echo "SUPABASE_DIR=$SUPABASE_DIR"

if [[ ! -d "$SUPABASE_DIR" ]]; then
  echo "ERROR: $SUPABASE_DIR not found"
  exit 1
fi

cd "$SUPABASE_DIR"

# --- 1) Fix public URLs in .env (app uses https://api.gymaipro.ir) ---
echo ""
echo "[1/6] Updating SITE_URL / API_EXTERNAL_URL / SUPABASE_PUBLIC_URL ..."
for key in SITE_URL API_EXTERNAL_URL SUPABASE_PUBLIC_URL; do
  if grep -q "^${key}=" .env; then
    sed -i "s|^${key}=.*|${key}=${PUBLIC_URL}|" .env
  else
    echo "${key}=${PUBLIC_URL}" >> .env
  fi
done
grep -E '^SITE_URL=|^API_EXTERNAL_URL=|^SUPABASE_PUBLIC_URL=' .env

# --- 2) DB: ensure chat_conversations in realtime publication + REPLICA IDENTITY ---
echo ""
echo "[2/6] SQL: realtime publication + REPLICA IDENTITY ..."
DB_CONTAINER=$(docker ps --format '{{.Names}}' | grep -E 'supabase-db|\.db$' | head -1)
if [[ -z "$DB_CONTAINER" ]]; then
  echo "WARN: postgres container not found, skipping SQL"
else
  docker exec -i "$DB_CONTAINER" psql -U postgres -d postgres <<'SQL'
ALTER TABLE public.chat_conversations REPLICA IDENTITY FULL;
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'chat_conversations'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_conversations;
  END IF;
END $$;
SQL
  echo "SQL applied."
fi

# --- 3) Nginx: WebSocket for /realtime/ ---
echo ""
echo "[3/6] Nginx WebSocket block for api.gymaipro.ir ..."
if [[ ! -f "$NGINX_SITE" ]]; then
  echo "WARN: $NGINX_SITE not found — configure nginx manually"
else
  cp -a "$NGINX_SITE" "${NGINX_SITE}.bak.$(date +%Y%m%d%H%M%S)"
  if grep -q 'location /realtime/' "$NGINX_SITE"; then
    echo "location /realtime/ already exists — edit manually if needed"
  else
    # Insert before last closing brace of the 443 server block (simple append before final })
    awk '
      /listen 443/ { in_ssl=1 }
      in_ssl && /^}$/ && !done {
        print "    location /realtime/ {"
        print "        proxy_pass http://127.0.0.1:8000;"
        print "        proxy_http_version 1.1;"
        print "        proxy_set_header Upgrade $http_upgrade;"
        print "        proxy_set_header Connection \"upgrade\";"
        print "        proxy_set_header Host $host;"
        print "        proxy_set_header X-Real-IP $remote_addr;"
        print "        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;"
        print "        proxy_set_header X-Forwarded-Proto $scheme;"
        print "        proxy_read_timeout 86400;"
        print "    }"
        print ""
        done=1
      }
      { print }
    ' "$NGINX_SITE" > "${NGINX_SITE}.new"
    mv "${NGINX_SITE}.new" "$NGINX_SITE"
    echo "Inserted location /realtime/ into $NGINX_SITE"
  fi
  nginx -t && systemctl reload nginx
  echo "Nginx reloaded."
fi

# --- 4) Restart stack (realtime then kong) ---
echo ""
echo "[4/6] Restarting realtime + kong ..."
docker compose restart realtime
sleep 20
docker compose restart kong
sleep 8

# --- 5) Health checks ---
echo ""
echo "[5/6] Health checks ..."
ANON=$(grep '^ANON_KEY=' .env | cut -d= -f2-)
RT_CONTAINER=$(docker ps --format '{{.Names}}' | grep -i realtime | head -1)
echo "Realtime container: $RT_CONTAINER"

docker exec "$RT_CONTAINER" curl -sS \
  -H "Authorization: Bearer ${ANON}" \
  "http://127.0.0.1:4000/api/tenants/realtime-dev/health" || true
echo ""

echo "WebSocket via Kong (expect 101):"
curl -sS -o /dev/null -w "HTTP %{http_code}\n" \
  -H "Connection: Upgrade" \
  -H "Upgrade: websocket" \
  -H "Sec-WebSocket-Version: 13" \
  -H "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" \
  "http://127.0.0.1:8000/realtime/v1/websocket?apikey=${ANON}&vsn=1.0.0" \
  --max-time 8 || true

# --- 6) Disk warning ---
echo ""
echo "[6/6] Disk usage:"
df -h / | tail -1
echo ""
echo "=== Done ==="
echo "In health JSON look for: db_connected:true replication_connected:true"
echo "Then restart the Flutter app (full restart, not hot reload)."
