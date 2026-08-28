param(
  [string]$Server = 'root@87.248.156.175',
  [int]$Port = 9011,
  [string]$RemoteBase = '/root/supabase/docker'
)

$ErrorActionPreference = 'Stop'

$remoteScript = @'
set -e
cd /root/supabase/docker

sed -i '/^CRASH_ALERT_THRESHOLD=/d' .env
echo 'CRASH_ALERT_THRESHOLD=3' >> .env
sed -i '/^CRASH_ALERT_WINDOW_MINUTES=/d' .env
echo 'CRASH_ALERT_WINDOW_MINUTES=10' >> .env
sed -i '/^CRASH_ALERT_COOLDOWN_MINUTES=/d' .env
echo 'CRASH_ALERT_COOLDOWN_MINUTES=30' >> .env

docker compose exec -T db psql -v ON_ERROR_STOP=1 -U supabase_admin -d postgres -c "DELETE FROM public.client_crash_reports WHERE fingerprint = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';"
docker compose exec -T db psql -v ON_ERROR_STOP=1 -U supabase_admin -d postgres -c "DELETE FROM public.client_crash_alerts WHERE fingerprint = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';"

docker compose up -d --force-recreate functions

echo '=== Production alert settings (masked) ==='
grep -E '^(SMS_BODY_ID_CRASH_ALERT|OPS_ALERT_PHONE|CRASH_ALERT_THRESHOLD|CRASH_ALERT_WINDOW_MINUTES|CRASH_ALERT_COOLDOWN_MINUTES)=' .env | sed 's/=.*/=<set>/'
echo '=== Function container settings (masked) ==='
docker exec supabase-edge-functions env | grep -E '^(SMS_BODY_ID_CRASH_ALERT|OPS_ALERT_PHONE|CRASH_ALERT_THRESHOLD|CRASH_ALERT_WINDOW_MINUTES|CRASH_ALERT_COOLDOWN_MINUTES)=' | sed 's/=.*/=<set>/'
'@ -replace "`r`n", "`n" -replace "`r", "`n"

Write-Host 'Restoring production alert settings and removing the test fingerprint...'
& ssh -p $Port $Server $remoteScript
if ($LASTEXITCODE -ne 0) {
  throw 'Production restore failed.'
}
Write-Host 'Production alert settings restored. Keep the new alert Body ID unset until the template is ready.'
