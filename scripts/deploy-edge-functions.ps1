# Deploy edge function index.ts files + restart (PowerShell)
#   .\scripts\deploy-edge-functions.ps1

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

$Server = "root@87.248.156.175"
$Port = "9011"
$RemoteBase = "/root/supabase/docker/volumes/functions"
$Functions = @(
  "openai-chat",
  "send-otp",
  "verify-otp",
  "send-program-sms",
  "send-notifications",
  "send-chat-notification",
  "music-proxy",
  "wallet-topup-confirm"
)

$Utf8NoBom = New-Object System.Text.UTF8Encoding $false
$EnsureScript = Join-Path $Root "scripts\ensure-functions-sms-env.sh"
$TempEnsure = Join-Path $env:TEMP "ensure-functions-sms-env-unix.sh"
$ensureText = [System.IO.File]::ReadAllText($EnsureScript) -replace "`r`n", "`n" -replace "`r", "`n"
[System.IO.File]::WriteAllText($TempEnsure, $ensureText, $Utf8NoBom)

foreach ($name in $Functions) {
  $local = Join-Path $Root "supabase\functions\$name\index.ts"
  if (-not (Test-Path $local)) {
    Write-Error "Missing: $local"
  }
  Write-Host "Upload $name ..."
  & ssh -p $Port $Server "mkdir -p $RemoteBase/$name"
  & scp -P $Port $local "${Server}:${RemoteBase}/${name}/index.ts"
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

Write-Host "Upload ensure-functions-sms-env.sh ..."
& scp -P $Port $TempEnsure "${Server}:/tmp/ensure-functions-sms-env.sh"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Recreate functions container (reload SMS env)..."
& ssh -p $Port $Server "bash /tmp/ensure-functions-sms-env.sh"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Remove-Item -Path $TempEnsure -Force -ErrorAction SilentlyContinue

Write-Host "Done."
