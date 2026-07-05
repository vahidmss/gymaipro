#!/bin/bash
# Fix corrupted .env (BOM / keys glued on one line) and re-apply sync snippet
set -euo pipefail

DOCKER_DIR="${1:-/root/supabase/docker}"
SYNC_FILE="${2:-/tmp/gymaipro-sync.env}"

cd "$DOCKER_DIR" || exit 1

echo "=== Fix server .env in $DOCKER_DIR ==="

restored=0
for bak in $(ls -t .env.bak.* 2>/dev/null || true); do
  if grep -q 'BaseServiceNumberSMS_API_USERNAME' "$bak" 2>/dev/null; then
    echo "Skip corrupt backup: $bak"
    continue
  fi
  echo "Restore from backup: $bak"
  cp "$bak" .env
  restored=1
  break
done

if [ "$restored" -eq 0 ] && [ -f .env ]; then
  echo "No clean backup — strip bad lines from current .env"
  grep -v 'BaseServiceNumberSMS_API_USERNAME' .env > .env.clean || true
  mv .env.clean .env
fi

sed -i '1s/^\xEF\xBB\xBF//' .env 2>/dev/null || true

if [ -f "$SYNC_FILE" ]; then
  sed -i '1s/^\xEF\xBB\xBF//' "$SYNC_FILE" 2>/dev/null || true
  sed -i 's/\r$//' "$SYNC_FILE" 2>/dev/null || true
  echo "Sync file lines:"
  wc -l "$SYNC_FILE"
  if [ -f /tmp/merge-server-env.sh ]; then
    bash /tmp/merge-server-env.sh "$SYNC_FILE"
  else
    echo "ERROR: /tmp/merge-server-env.sh missing"
    exit 1
  fi
else
  echo "WARN: no sync file — restored backup only"
fi

echo ""
echo "=== Keys (masked) ==="
grep -E '^(SMS_|OPENAI|AI_API|SUPABASE_)' .env | sed 's/=.*/=***/' || true
