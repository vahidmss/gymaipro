# GymaiPro - automated UI / performance health check (no manual tapping needed)
# Usage:  .\scripts\check_ui_health.ps1
#         .\scripts\check_ui_health.ps1 -Gate     # CI: fail on HIGH perf issues
#         .\scripts\check_ui_health.ps1 -Strict

param(
    [switch]$Strict,
    [switch]$Advisory,
    [switch]$Gate
)

$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)

Write-Host "`n== flutter analyze (errors/warnings) ==" -ForegroundColor Cyan
$analyzeOutput = cmd /c "flutter analyze 2>&1"
$blocking = $analyzeOutput | Select-String -Pattern "error -|warning -"
if ($blocking) {
    $blocking | ForEach-Object { Write-Host $_ }
    throw "Analyzer errors/warnings found."
}
Write-Host "  OK - 0 errors, 0 warnings" -ForegroundColor DarkGray

Write-Host "`n== static UI health audit ==" -ForegroundColor Cyan
$auditArgs = @("run", "test/run_ui_health_audit.dart")
if ($Strict) { $auditArgs += "--strict" }
elseif ($Gate) { $auditArgs += "--gate" }
if ($Advisory) { $auditArgs += "--advisory" }
dart @auditArgs
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "`n== widget smoke tests ==" -ForegroundColor Cyan
flutter test test/ui_health_smoke_test.dart
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "`n[OK] UI health check complete." -ForegroundColor Green
