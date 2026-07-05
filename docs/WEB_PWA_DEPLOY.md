# Web / PWA Deployment

## 1. Client env (public only)

Copy `env.web.example.json` to `env.web.json` and set:

- `SUPABASE_ANON_KEY` — from your Supabase server (`ANON_KEY` in docker `.env`)

Never add `OPENAI_API_KEY`, `SMS_API_*`, or payment secrets to this file.

## 2. Server secrets (docker `.env` on api.gymaipro.ir)

```env
OPENAI_API_KEY=sk-...
SMS_API_USERNAME=...
SMS_API_PASSWORD=...
SMS_API_BODY_ID=...
SMS_API_BASE_URL=https://rest.payamak-panel.com/api/SendSMS/BaseServiceNumber
SUPABASE_SERVICE_ROLE_KEY=...
# Optional Iran relay:
OPENAI_RELAY_URL=https://your-worker.workers.dev
OPENAI_RELAY_SECRET=...
```

## 3. Database migration

Run on Supabase Postgres:

`supabase/migrations/20260621120000_otp_server_security.sql`

## 4. Deploy Edge Functions

```powershell
.\scripts\deploy-edge-functions.ps1
```

Then on server: `docker compose restart functions`

## 5. Build web

```powershell
.\scripts\build-web.ps1
```

Upload `build/web` to HTTPS (e.g. `app.gymaipro.ir`).

## 6. Local web dev

```powershell
flutter run -d chrome --dart-define-from-file=env.web.json
```

## Security model

| Feature | Route |
|---------|--------|
| AI chat | `openai-chat` Edge Function + user JWT |
| OTP | `send-otp` / `verify-otp` + service role |
| Payments | WordPress proxy (existing) |
| Supabase data | RLS + anon key |

Mobile legacy (direct SMS / direct AI): set in `.env`:

```env
OTP_USE_SERVER=false
OPENAI_USE_PROXY=false
OPENAI_API_KEY=...
```
