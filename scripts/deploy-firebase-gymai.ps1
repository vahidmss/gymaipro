# =============================================================================
# آپلود Firebase Service Account (gymai-9db69) به سرور و آپدیت
# اجرا: powershell -ExecutionPolicy Bypass -File scripts\deploy-firebase-gymai.ps1
# =============================================================================

$Server = "root@87.248.156.175"
$Port = "9011"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$CredFile = Join-Path $ProjectRoot "secrets\firebase-service-account.json"

if (-not (Test-Path $CredFile)) {
  Write-Host "ERROR: File not found: $CredFile" -ForegroundColor Red
  exit 1
}

Write-Host "Uploading Firebase credentials (gymai-9db69)..." -ForegroundColor Cyan
scp -P $Port $CredFile "${Server}:/root/supabase/docker/secrets/firebase-service-account.json"

Write-Host "Running update on server..." -ForegroundColor Cyan
ssh -p $Port $Server 'cd ~/supabase/docker && B64=$(base64 -w 0 secrets/firebase-service-account.json 2>/dev/null || base64 secrets/firebase-service-account.json | tr -d "\n") && sed -i "/^FIREBASE_SERVICE_ACCOUNT_B64=/d" .env && echo "FIREBASE_SERVICE_ACCOUNT_B64=$B64" >> .env && docker compose restart functions && echo "Done. Test with curl."'

Write-Host ""
Write-Host "Done. SSH to server and test:" -ForegroundColor Green
Write-Host "  cd ~/supabase/docker"
Write-Host '  TOKEN=$(docker exec supabase-db psql -U postgres -d postgres -t -c "SELECT token FROM public.device_tokens WHERE is_push_enabled = true LIMIT 1;" 2>/dev/null | tr -d " ")'
Write-Host '  KEY=$(grep "^SERVICE_ROLE_KEY=" .env | cut -d= -f2-)'
Write-Host '  curl -sS -X POST http://127.0.0.1:8000/functions/v1/send-notifications -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" -d "{\"mode\":\"direct\",\"target_type\":\"device_tokens\",\"tokens\":[\"$TOKEN\"],\"title\":\"test\",\"body\":\"OK\"}"'
