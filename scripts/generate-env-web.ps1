# Generate env.web.json from local .env (public + OpenAI direct key for web)
#   .\scripts\generate-env-web.ps1
#
# OPENAI_API_KEY goes into the web bundle (direct client route). Restrict it in
# OpenAI dashboard: usage limits + model allowlist.

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$LocalEnv = Join-Path $Root ".env"
$Out = Join-Path $Root "env.web.json"

if (-not (Test-Path $LocalEnv)) { Write-Error ".env missing" }

$vars = @{}
Get-Content $LocalEnv -Encoding UTF8 | ForEach-Object {
  if ($_ -match '^\s*#' -or $_ -match '^\s*$') { return }
  $eq = $_.IndexOf('=')
  if ($eq -lt 1) { return }
  $vars[$_.Substring(0, $eq).Trim()] = $_.Substring($eq + 1).Trim()
}

$web = [ordered]@{
  SUPABASE_URL = if ($vars["SUPABASE_URL"]) { $vars["SUPABASE_URL"] } else { "https://api.gymaipro.ir" }
  SUPABASE_ANON_KEY = $vars["SUPABASE_ANON_KEY"]
  OPENAI_USE_PROXY = "false"
  OPENAI_API_KEY = $vars["OPENAI_API_KEY"]
  SUPABASE_EDGE_FUNCTIONS_ENABLED = "true"
  OTP_USE_SERVER = "true"
  AI_ENGINE_MODE = "openai"
  ONLINE_PAYMENT_ENABLED = "true"
  WORDPRESS_API_BASE_URL = "https://gymaipro.ir"
}

if (-not $web.SUPABASE_ANON_KEY) { Write-Error "SUPABASE_ANON_KEY missing in .env" }
if (-not $web.OPENAI_API_KEY) {
  Write-Warning "OPENAI_API_KEY missing in .env — AI chat will not work on web until set"
}

$web | ConvertTo-Json | Set-Content -Path $Out -Encoding UTF8
Write-Host "Created $Out (direct OpenAI route; no SMS/payment secrets)"
Write-Host "Run: .\scripts\build-web.ps1"
