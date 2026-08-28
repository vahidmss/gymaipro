param(
  [Parameter(Mandatory = $true)]
  [ValidatePattern('^(09\d{9}|98\d{10}|\+98\d{10})$')]
  [string]$PhoneNumber,

  [string]$SupabaseUrl = 'https://api.gymaipro.ir',
  [string]$AnonKey
)

$ErrorActionPreference = 'Stop'
$envPath = Join-Path (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)) '.env'
if ([string]::IsNullOrWhiteSpace($AnonKey)) {
  if (-not (Test-Path $envPath)) {
    throw "Missing .env at $envPath. Pass -AnonKey explicitly."
  }
  $AnonKey = ((Get-Content $envPath |
    Where-Object { $_ -match '^SUPABASE_ANON_KEY=' }) -replace '^SUPABASE_ANON_KEY=', '').Trim()
}
if ([string]::IsNullOrWhiteSpace($AnonKey)) {
  throw 'SUPABASE_ANON_KEY is missing.'
}

$normalized = $PhoneNumber -replace '^\+98', '0' -replace '^98', '0'
if ($normalized.Length -eq 10 -and $normalized -notmatch '^0') {
  $normalized = "0$normalized"
}

$endpoint = "$($SupabaseUrl.TrimEnd('/'))/functions/v1/send-otp"
$headers = @{
  apikey = $AnonKey
  'Content-Type' = 'application/json'
}

Write-Host "Requesting one login OTP for $($normalized.Substring(0, 4))******$($normalized.Substring($normalized.Length - 2))..."
$response = Invoke-RestMethod `
  -Method Post `
  -Uri $endpoint `
  -Headers $headers `
  -Body (@{ phone_number = $normalized } | ConvertTo-Json)

if ($response.sms_sent -eq $true) {
  Write-Host 'SMS provider accepted the OTP request.' -ForegroundColor Green
} else {
  Write-Warning 'OTP was processed but SMS provider did not confirm delivery.'
}
$response | Select-Object ok, sms_sent, message | ConvertTo-Json
