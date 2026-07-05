# Generate env.web.json from local .env (public keys only — safe for web build)
#   .\scripts\generate-env-web.ps1

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
  OPENAI_USE_PROXY = "true"
  SUPABASE_EDGE_FUNCTIONS_ENABLED = "true"
  OTP_USE_SERVER = "true"
  AI_ENGINE_MODE = "openai"
  ONLINE_PAYMENT_ENABLED = "true"
  WORDPRESS_API_BASE_URL = "https://gymaipro.ir"
}

if (-not $web.SUPABASE_ANON_KEY) { Write-Error "SUPABASE_ANON_KEY missing in .env" }

$web | ConvertTo-Json | Set-Content -Path $Out -Encoding UTF8
Write-Host "Created $Out (public keys only - run build-web.ps1 next)"
