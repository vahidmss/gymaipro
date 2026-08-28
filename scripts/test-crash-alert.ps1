param(
  [Parameter(Mandatory = $true)]
  [string]$AccessToken,

  [Parameter(Mandatory = $true)]
  [ValidatePattern('^[a-fA-F0-9]{64}$')]
  [string]$Fingerprint,

  [string]$AnonKey = $env:GYMAI_SUPABASE_ANON_KEY,

  [string]$SupabaseUrl = 'https://api.gymaipro.ir'
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($AnonKey)) {
  throw 'Provide the public Supabase anon key with -AnonKey or GYMAI_SUPABASE_ANON_KEY.'
}

$endpoint = "$($SupabaseUrl.TrimEnd('/'))/functions/v1/alert-client-crash"
$headers = @{
  Authorization = "Bearer $AccessToken"
  apikey = $AnonKey
  'Content-Type' = 'application/json'
}

Write-Host "Calling crash alert function for fingerprint $($Fingerprint.Substring(0, 12))..."
$response = Invoke-RestMethod `
  -Method Post `
  -Uri $endpoint `
  -Headers $headers `
  -Body (@{ fingerprint = $Fingerprint } | ConvertTo-Json)

$response | ConvertTo-Json -Depth 5
Write-Host 'A successful response only means the alert decision completed; verify SMS delivery separately.'