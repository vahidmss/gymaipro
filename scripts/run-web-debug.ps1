# Run Flutter web in debug — UI on phone/emulator/browser, logs in this terminal (Cursor can read them).
#
# Usage (repo root):
#   .\scripts\run-web-debug.ps1              # LAN: phone + emulator browser
#   .\scripts\run-web-debug.ps1 -Chrome      # opens Chrome on PC (simplest)
#   .\scripts\run-web-debug.ps1 -Port 8888
#
# Phone (same Wi‑Fi):  http://<PC-IP>:8080
# Android emulator:    http://10.0.2.2:8080

param(
  [switch]$Chrome,
  [int]$Port = 8080,
  [string]$HostName = "0.0.0.0"
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

$EnvFile = Join-Path $Root "env.web.json"
if (-not (Test-Path $EnvFile)) {
  Write-Host "env.web.json not found - generating from .env ..."
  & (Join-Path $Root "scripts\generate-env-web.ps1")
}

function Get-LanIPv4 {
  Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Where-Object {
      $_.IPAddress -notlike "127.*" -and
      $_.PrefixOrigin -ne "WellKnown"
    } |
    Sort-Object InterfaceMetric |
    Select-Object -ExpandProperty IPAddress -First 1
}

$lanIp = Get-LanIPv4
if (-not $lanIp) { $lanIp = "<your-PC-IP>" }

Write-Host ""
Write-Host "=== GymAI Pro - Web debug ===" -ForegroundColor Cyan
Write-Host "Logs: this terminal (share with Cursor for debugging)"
Write-Host ""

if ($Chrome) {
  Write-Host "Device: Chrome on this PC"
  Write-Host "Command: flutter run -d chrome --dart-define-from-file=env.web.json"
  Write-Host ""
  flutter run -d chrome --dart-define-from-file=env.web.json
  exit $LASTEXITCODE
}

Write-Host "Device: browser on phone / Android emulator"
Write-Host "  Phone (Wi-Fi):     http://${lanIp}:$Port"
Write-Host "  Android emulator:  http://10.0.2.2:$Port"
Write-Host ""
Write-Host "Hot reload: r | Hot restart: R | Quit: q"
Write-Host ""

flutter run -d web-server `
  --web-hostname=$HostName `
  --web-port=$Port `
  --dart-define-from-file=env.web.json
