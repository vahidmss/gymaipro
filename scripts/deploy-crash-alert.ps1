param(
  [string]$Server = 'root@87.248.156.175',
  [int]$Port = 9011,
  [string]$RemoteBase = '/root/supabase/docker'
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$MigrationOne = Join-Path $Root 'supabase\migrations\20260828130000_harden_client_crash_reports.sql'
$MigrationTwo = Join-Path $Root 'supabase\migrations\20260828140000_create_client_crash_alerts.sql'
$FunctionFile = Join-Path $Root 'supabase\functions\alert-client-crash\index.ts'
$EnsureFile = Join-Path $Root 'scripts\ensure-functions-sms-env.sh'

foreach ($path in @($MigrationOne, $MigrationTwo, $FunctionFile, $EnsureFile)) {
  if (-not (Test-Path $path)) {
    throw "Missing local file: $path"
  }
}

$remoteFunction = "$RemoteBase/volumes/functions/alert-client-crash/index.ts"

Write-Host '[1/5] Checking SSH access...'
& ssh -o StrictHostKeyChecking=accept-new -p $Port $Server 'echo ssh-ok'
if ($LASTEXITCODE -ne 0) {
  throw 'SSH authentication failed. Configure the correct key/password for this server first.'
}

Write-Host '[2/5] Uploading migrations, function, and env wiring script...'
& scp -P $Port $MigrationOne "${Server}:/tmp/20260828130000_harden_client_crash_reports.sql"
if ($LASTEXITCODE -ne 0) { throw 'Upload of migration one failed.' }
& scp -P $Port $MigrationTwo "${Server}:/tmp/20260828140000_create_client_crash_alerts.sql"
if ($LASTEXITCODE -ne 0) { throw 'Upload of migration two failed.' }
& scp -P $Port $FunctionFile "${Server}:/tmp/alert-client-crash-index.ts"
if ($LASTEXITCODE -ne 0) { throw 'Upload of Edge Function failed.' }
& scp -P $Port $EnsureFile "${Server}:/tmp/ensure-functions-sms-env.sh"
if ($LASTEXITCODE -ne 0) { throw 'Upload of env wiring script failed.' }

Write-Host '[3/5] Installing function and applying migrations...'
$remoteInstall = @"
set -e
mkdir -p '$RemoteBase/volumes/functions/alert-client-crash'
cp /tmp/alert-client-crash-index.ts '$remoteFunction'
cd '$RemoteBase'
docker compose exec -T db psql -U postgres -d postgres < /tmp/20260828130000_harden_client_crash_reports.sql
docker compose exec -T db psql -U postgres -d postgres < /tmp/20260828140000_create_client_crash_alerts.sql
"@
& ssh -p $Port $Server $remoteInstall
if ($LASTEXITCODE -ne 0) { throw 'Remote install or migration failed.' }

Write-Host '[4/5] Wiring secrets and recreating functions container...'
& ssh -p $Port $Server 'bash /tmp/ensure-functions-sms-env.sh'
if ($LASTEXITCODE -ne 0) { throw 'Functions container recreation failed.' }

Write-Host '[5/5] Checking function container...'
& ssh -p $Port $Server "cd '$RemoteBase'; docker compose ps functions; docker exec supabase-edge-functions env | grep -E '^(OPS_ALERT_PHONE|SMS_BODY_ID_CRASH_ALERT|SMS_API_USERNAME|SMS_API_PASSWORD|SUPABASE_SERVICE_ROLE_KEY)=' | sed 's/=.*/=<set>/'"
if ($LASTEXITCODE -ne 0) { throw 'Function container verification failed.' }

Write-Host 'Crash alert deployment completed.'
Write-Host 'Next: run scripts/test-crash-alert.ps1 with a real user access token and a 64-character crash fingerprint.'
