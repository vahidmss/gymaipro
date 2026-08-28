# Build GymAI Pro Android release APK (and optional AAB) with dart-defines.
# Usage (from repo root):
#   .\scripts\build-android-release.ps1
#   .\scripts\build-android-release.ps1 -Aab
#   .\scripts\build-android-release.ps1 -EnvFile ".env"
#
# Requires:
#   - .env (or -EnvFile) with SUPABASE_ANON_KEY and other defines
#   - Recommended: android/key.properties + upload-keystore.jks
#     (.\scripts\setup-android-keystore.ps1)

param(
  [string]$EnvFile = ".env",
  [switch]$Aab,
  [switch]$SplitPerAbi
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

$EnvPath = Join-Path $Root $EnvFile
if (-not (Test-Path $EnvPath)) {
  Write-Error @"
Env file not found: $EnvFile
Release builds do NOT load .env from assets — you must pass --dart-define-from-file.
"@
}

$KeyProps = Join-Path $Root "android\key.properties"
$Keystore = Join-Path $Root "android\upload-keystore.jks"
if (-not (Test-Path $KeyProps) -or -not (Test-Path $Keystore)) {
  Write-Error @"
Release signing files are missing.
Need both:
  android\key.properties
  android\upload-keystore.jks
Without them, Android will not install an update over a previous APK.
If this PC never had a keystore, run: .\scripts\setup-android-keystore.ps1
If you already shipped an APK, copy the ORIGINAL jks + key.properties from backup. Do not generate a new key.
"@
}
Write-Host "Using release signing from android\key.properties"

$extra = @("--target-platform", "android-arm64")
if ($SplitPerAbi) {
  # Prefer split APKs only when explicitly requested (overrides single-ABI).
  $extra = @("--split-per-abi")
}

Write-Host "Building Android release with --dart-define-from-file=$EnvFile ..."

if ($Aab) {
  flutter build appbundle --release --dart-define-from-file=$EnvFile @extra
  Write-Host "AAB: build\app\outputs\bundle\release\app-release.aab"
} else {
  flutter build apk --release --dart-define-from-file=$EnvFile @extra
  Write-Host "APK: build\app\outputs\flutter-apk\app-release.apk"
}

Write-Host "Done. Sideload only on arm64 phones (target-platform=android-arm64)."
