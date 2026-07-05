# Deploy send-chat-notification edge function to self-hosted Supabase
# Usage (PowerShell, from repo root):
#   .\scripts\deploy-send-chat-notification.ps1

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

$Server = "root@87.248.156.175"
$Port = "9011"
$RemoteBase = "/root/supabase/docker/volumes/functions"
$FunctionName = "send-chat-notification"
$LocalFile = Join-Path $Root "supabase\functions\$FunctionName\index.ts"

if (-not (Test-Path $LocalFile)) {
  Write-Error "Missing: $LocalFile"
}

Write-Host "=== Deploy $FunctionName ==="
Write-Host "Server: $Server (port $Port)"
Write-Host "Local:  $LocalFile"
Write-Host ""

Write-Host "[1/3] Create remote folder..."
& ssh -p $Port $Server "mkdir -p $RemoteBase/$FunctionName"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "[2/3] Upload index.ts..."
& scp -P $Port $LocalFile "${Server}:${RemoteBase}/${FunctionName}/index.ts"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "[3/3] Restart edge-functions container..."
& ssh -p $Port $Server "cd /root/supabase/docker && docker compose up -d --force-recreate functions"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "Done. send-chat-notification deployed with message_id dedup."
