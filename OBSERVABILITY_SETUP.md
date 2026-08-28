# Observability and Crash Alerts

## What is already wired

- Flutter catches framework and uncaught async errors in `AppErrorHandler`.
- `CrashReportService` sanitizes payloads, queues reports offline, and uploads
  them to `client_crash_reports` after Supabase is ready.
- The admin dashboard includes the crash report screen.
- After a successful report upload, Flutter calls the `alert-client-crash` Edge
  Function with only the SHA-256 fingerprint.

## Supabase deployment order

1. Apply `supabase/migrations/20260828130000_harden_client_crash_reports.sql`.
2. Apply `supabase/migrations/20260828140000_create_client_crash_alerts.sql`.
3. Deploy `supabase/functions/alert-client-crash`.

Example deployment commands:

```powershell
supabase db push
supabase functions deploy alert-client-crash
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=... SMS_API_USERNAME=... SMS_API_PASSWORD=... OPS_ALERT_PHONE=... SMS_BODY_ID_CRASH_ALERT=...
```

Run these commands from the repository linked to the correct Supabase project.
Do not place the values shown as `...` in source control or in a client build.

For the repository's self-hosted Supabase layout, upload/reload all functions
with:

```powershell
.\scripts\deploy-edge-functions.ps1
```

This script now includes `alert-client-crash`. It requires the SSH key or
password configured for the server's SSH account.

The alert function uses the service role only on the server. Never put these
values in Flutter, `.env` shipped to users, or `--dart-define` for release:

- `SUPABASE_SERVICE_ROLE_KEY`
- `SMS_API_USERNAME`
- `SMS_API_PASSWORD`
- `OPS_ALERT_PHONE`
- `SMS_BODY_ID_CRASH_ALERT`

Optional server settings:

- `CRASH_ALERT_THRESHOLD` (default `3` reports)
- `CRASH_ALERT_WINDOW_MINUTES` (default `10`)
- `CRASH_ALERT_COOLDOWN_MINUTES` (default `30`)
- `SMS_API_BASE_URL`

## SMS template

Create a provider pattern template for `SMS_BODY_ID_CRASH_ALERT` with three
parameters:

1. fingerprint prefix
2. occurrence count
3. app version

The destination number is configured only as the server secret
`OPS_ALERT_PHONE`. The application does not contain a phone number.

## Safe SMS smoke test

Use a real access token from an authenticated user session. Never use or paste
the service-role key into the client or chat. First obtain a 64-character
fingerprint from an existing row in the admin crash report screen, then run:

```powershell
$env:GYMAI_SUPABASE_ANON_KEY = '<public-anon-key>'
.\scripts\test-crash-alert.ps1 -AccessToken $env:GYMAI_TEST_ACCESS_TOKEN -Fingerprint '<64-char-fingerprint>'
```

For a test on an empty database, set `CRASH_ALERT_THRESHOLD=1` temporarily on
the Edge Function, insert one sanitized test row through the server-side SQL
admin path, run the smoke test, and restore the normal threshold (`3`). Do not
add a public test endpoint and do not bypass authentication.

## Operational safety

- Alerts are thresholded per fingerprint and suppressed during the cooldown.
- Client reports remain usable if the alert function or SMS provider is down.
- The alert table has no client RLS policies; only the Edge Function service
  role can read or write alert state.
- Configure retention and access review for crash data before public launch.