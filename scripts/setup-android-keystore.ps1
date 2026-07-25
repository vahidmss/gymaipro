# Create a release keystore for multi-phone sideload / Play uploads.
# Usage (from repo root):
#   .\scripts\setup-android-keystore.ps1
#
# Creates:
#   android/upload-keystore.jks
#   android/key.properties  (gitignored)
#
# Keep the .jks and passwords safe — lost keystore = cannot update the same app install.

param(
  [string]$Alias = "gymaipro",
  [string]$StoreFileName = "upload-keystore.jks"
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$AndroidDir = Join-Path $Root "android"
$StorePath = Join-Path $AndroidDir $StoreFileName
$PropsPath = Join-Path $AndroidDir "key.properties"

if (Test-Path $StorePath) {
  Write-Host "Keystore already exists: $StorePath"
  Write-Host "Delete it only if you intentionally want a NEW signing identity."
  if (-not (Test-Path $PropsPath)) {
    Write-Error "Keystore exists but key.properties is missing. Create key.properties from key.properties.example."
  }
  exit 0
}

$keytool = Get-Command keytool -ErrorAction SilentlyContinue
if (-not $keytool) {
  Write-Error "keytool not found. Install a JDK and ensure keytool is on PATH."
}

$pass = Read-Host "Enter keystore password (min 6 chars)" -AsSecureString
$passPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
  [Runtime.InteropServices.Marshal]::SecureStringToBSTR($pass)
)
if ([string]::IsNullOrWhiteSpace($passPlain) -or $passPlain.Length -lt 6) {
  Write-Error "Password too short."
}

Write-Host "Generating $StorePath ..."
& keytool -genkey -v `
  -keystore $StorePath `
  -keyalg RSA `
  -keysize 2048 `
  -validity 10000 `
  -alias $Alias `
  -storepass $passPlain `
  -keypass $passPlain `
  -dname "CN=GYMAI Pro, OU=Mobile, O=GYMAI, L=Tehran, ST=Tehran, C=IR"

@"
storePassword=$passPlain
keyPassword=$passPlain
keyAlias=$Alias
storeFile=../$StoreFileName
"@ | Set-Content -Path $PropsPath -Encoding ASCII

Write-Host ""
Write-Host "Done."
Write-Host "  Keystore: $StorePath"
Write-Host "  Props:    $PropsPath"
Write-Host "Build with: .\scripts\build-android-release.ps1"
Write-Host "NEVER commit upload-keystore.jks or key.properties"
