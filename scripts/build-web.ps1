# Build GymAI Pro for Web / PWA (public secrets only)
# Usage (from repo root):
#   1) Copy env.web.example.json -> env.web.json and fill SUPABASE_ANON_KEY
#   2) .\scripts\build-web.ps1
#      .\scripts\build-web.ps1 -BaseHref "/"          # subdomain root (app.gymaipro.ir)
#      .\scripts\build-web.ps1 -BaseHref "/app/"       # subfolder (gymaipro.ir/app/) — default

param(
  [string]$BaseHref = "/app/"
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

if (-not $BaseHref.EndsWith("/")) {
  $BaseHref = "$BaseHref/"
}
if (-not $BaseHref.StartsWith("/")) {
  $BaseHref = "/$BaseHref"
}

$EnvFile = Join-Path $Root "env.web.json"
if (-not (Test-Path $EnvFile)) {
  Write-Error @"
env.web.json not found.
Copy env.web.example.json to env.web.json and set SUPABASE_ANON_KEY.
Do NOT put OPENAI_API_KEY, SMS passwords, or payment secrets in this file.
"@
}

Write-Host "Building Flutter web (release) base-href=$BaseHref ..."
flutter build web `
  --release `
  --base-href $BaseHref `
  --dart-define-from-file=env.web.json `
  --no-wasm-dry-run

Write-Host ""
Write-Host "Done. Output: build\web"

if ($BaseHref -eq "/") {
  Copy-Item -Force (Join-Path $Root "web\.htaccess.root") (Join-Path $Root "build\web\.htaccess") -ErrorAction SilentlyContinue
  if (-not (Test-Path (Join-Path $Root "build\web\.htaccess"))) {
    @"
<IfModule mod_rewrite.c>
  RewriteEngine On
  RewriteBase /
  RewriteCond %{REQUEST_FILENAME} !-f
  RewriteCond %{REQUEST_FILENAME} !-d
  RewriteRule ^ index.html [L]
</IfModule>
"@ | Set-Content -Path (Join-Path $Root "build\web\.htaccess") -Encoding UTF8
  }
} else {
  Copy-Item -Force (Join-Path $Root "web\.htaccess") (Join-Path $Root "build\web\.htaccess")
}

Write-Host "Copied .htaccess for base-href $BaseHref"
Write-Host "Deploy build\web to: https://gymaipro.ir$BaseHref"
Write-Host "Ensure Edge Functions are deployed: .\scripts\deploy-edge-functions.ps1"

Write-Host ""
Write-Host "Creating Linux-friendly zip (forward slashes) ..."
python (Join-Path $Root "scripts\zip-web-release.py")
if ($LASTEXITCODE -ne 0) {
  Write-Error "zip-web-release.py failed"
}
