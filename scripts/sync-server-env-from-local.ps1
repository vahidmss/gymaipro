# Sync SMS + AI secrets from local .env to Supabase server (Edge Functions)
# Run from repo root:
#   .\scripts\sync-server-env-from-local.ps1

$ErrorActionPreference = "Stop"

$Server = "root@87.248.156.175"
$Port = "9011"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$LocalEnv = Join-Path $Root ".env"
$MergeScript = Join-Path $Root "scripts\merge-server-env.sh"
$FixScript = Join-Path $Root "scripts\fix-server-env.sh"
$TempSync = Join-Path $env:TEMP "gymaipro-sync.env"
$TempMerge = Join-Path $env:TEMP "merge-server-env-unix.sh"
$TempFix = Join-Path $env:TEMP "fix-server-env-unix.sh"
$Utf8NoBom = New-Object System.Text.UTF8Encoding $false

if (-not (Test-Path $LocalEnv)) {
  Write-Error ".env not found at $LocalEnv"
}

if (-not (Test-Path $MergeScript)) {
  Write-Error "merge-server-env.sh not found at $MergeScript"
}
if (-not (Test-Path $FixScript)) {
  Write-Error "fix-server-env.sh not found at $FixScript"
}

function Read-DotEnv {
  param([string]$Path)
  $map = @{}
  Get-Content -LiteralPath $Path -Encoding UTF8 | ForEach-Object {
    $line = $_.TrimEnd("`r")
    if ($line -match '^\s*#' -or $line -match '^\s*$') { return }
    $eq = $line.IndexOf('=')
    if ($eq -lt 1) { return }
    $k = $line.Substring(0, $eq).Trim()
    $v = $line.Substring($eq + 1)
    if ($k) { $map[$k] = $v }
  }
  return $map
}

$vars = Read-DotEnv -Path $LocalEnv

$syncKeys = @(
  "SMS_API_BASE_URL",
  "SMS_API_USERNAME",
  "SMS_API_PASSWORD",
  "SMS_API_BODY_ID",
  "SMS_BODY_ID_TRAINER_PROGRAM_REQUEST",
  "SMS_BODY_ID_USER_PROGRAM_PURCHASE",
  "OPENAI_API_KEY",
  "SUPABASE_URL",
  "SUPABASE_ANON_KEY"
)

$outLines = @()
foreach ($key in $syncKeys) {
  if ($vars.ContainsKey($key) -and $vars[$key].Trim()) {
    $outLines += ($key + "=" + $vars[$key].Trim())
  }
}

if ($vars.ContainsKey("OPENAI_API_KEY") -and $vars["OPENAI_API_KEY"].Trim()) {
  $outLines += "AI_API_BASE_URL=https://api.openai.com"
  $outLines += "OPENAI_BASE_URL=https://api.openai.com"
}

if ($outLines.Count -eq 0) {
  Write-Error "No keys to sync. Check .env file."
}

# UTF-8 without BOM (Linux-safe)
[System.IO.File]::WriteAllText($TempSync, (($outLines -join "`n") + "`n"), $Utf8NoBom)

# Merge + fix scripts: LF only
$mergeText = [System.IO.File]::ReadAllText($MergeScript) -replace "`r`n", "`n" -replace "`r", "`n"
[System.IO.File]::WriteAllText($TempMerge, $mergeText, $Utf8NoBom)
$fixText = [System.IO.File]::ReadAllText($FixScript) -replace "`r`n", "`n" -replace "`r", "`n"
[System.IO.File]::WriteAllText($TempFix, $fixText, $Utf8NoBom)

Write-Host ("Syncing " + $outLines.Count + " keys to SERVER /root/supabase/docker/.env")
Write-Host "NOTE: Local d:\gymaipro\.env is NOT changed (one-way sync to server)."

Write-Host "Upload scripts..."
& scp -P $Port $TempMerge "${Server}:/tmp/merge-server-env.sh"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& scp -P $Port $TempFix "${Server}:/tmp/fix-server-env.sh"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Upload env snippet..."
& scp -P $Port $TempSync "${Server}:/tmp/gymaipro-sync.env"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Upload ensure-functions-sms-env.sh ..."
$EnsureScript = Join-Path $Root "scripts\ensure-functions-sms-env.sh"
$TempEnsure = Join-Path $env:TEMP "ensure-functions-sms-env-unix.sh"
$ensureText = [System.IO.File]::ReadAllText($EnsureScript) -replace "`r`n", "`n" -replace "`r", "`n"
[System.IO.File]::WriteAllText($TempEnsure, $ensureText, $Utf8NoBom)
& scp -P $Port $TempEnsure "${Server}:/tmp/ensure-functions-sms-env.sh"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Fix .env + merge + recreate functions container..."
& ssh -p $Port $Server "bash /tmp/fix-server-env.sh /root/supabase/docker /tmp/gymaipro-sync.env && bash /tmp/ensure-functions-sms-env.sh"
if ($LASTEXITCODE -ne 0) {
  Write-Host ""
  Write-Host "SSH merge failed. Try manual: ssh ... then bash /tmp/merge-server-env.sh /tmp/gymaipro-sync.env"
  exit $LASTEXITCODE
}

& ssh -p $Port $Server "rm -f /tmp/gymaipro-sync.env" 2>$null

Remove-Item -Path $TempSync -Force -ErrorAction SilentlyContinue
Remove-Item -Path $TempMerge -Force -ErrorAction SilentlyContinue
Remove-Item -Path $TempFix -Force -ErrorAction SilentlyContinue
Remove-Item -Path $TempEnsure -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "Done."
