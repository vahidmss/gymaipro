# Run Flutter on Android/iOS with .env (required after .env removed from assets)
# Usage: .\scripts\run-android-debug.ps1
#        .\scripts\run-android-debug.ps1 -Device "SM A528B"

param(
  [string]$Device = ""
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

$EnvFile = Join-Path $Root ".env"
if (-not (Test-Path $EnvFile)) {
  Write-Host ""
  Write-Host "ERROR: .env not found" -ForegroundColor Red
  Write-Host "  copy .env.example .env"
  Write-Host "  Then set SUPABASE_ANON_KEY and OPENAI_API_KEY"
  Write-Host ""
  exit 1
}

Write-Host ""
Write-Host "=== GymAI Pro - Android/iOS debug ===" -ForegroundColor Cyan
Write-Host "Using: --dart-define-from-file=.env"
Write-Host ""

if ($Device) {
  flutter run -d $Device --dart-define-from-file=.env
} else {
  flutter run --dart-define-from-file=.env
}
