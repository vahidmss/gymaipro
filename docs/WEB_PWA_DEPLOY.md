# Web / PWA Deployment

## 1. Client env (`env.web.json`)

Copy `env.web.example.json` to `env.web.json` and set:

| Key | Required | Notes |
|-----|----------|-------|
| `SUPABASE_ANON_KEY` | Yes | Public — protected by RLS |
| `OPENAI_API_KEY` | Yes (direct AI) | **In web bundle** — restrict in OpenAI dashboard |
| `OPENAI_USE_PROXY` | No | Default `false` (server filtered → client direct) |

Or generate from `.env`:

```powershell
.\scripts\generate-env-web.ps1
```

**Never add** to `env.web.json`:

- `OPENAI` only if using proxy (`OPENAI_USE_PROXY=true` on server with Edge Function)
- `SMS_API_*`, `ZIBAL_*`, `ZARINPAL_*`, `SUPABASE_SERVICE_ROLE_KEY`

## 2. Server secrets (docker `.env` on api.gymaipro.ir)

```env
SMS_API_USERNAME=...
SMS_API_PASSWORD=...
SMS_API_BODY_ID=...
SUPABASE_SERVICE_ROLE_KEY=...
# Optional if OPENAI_USE_PROXY=true later:
OPENAI_API_KEY=sk-...
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
# or
.\scripts\run-web-debug.ps1 -Chrome
```

## Security model

| Feature | Route |
|---------|--------|
| AI chat | **Client direct** → OpenAI (`OPENAI_USE_PROXY=false`) + rate limit |
| AI chat (optional) | `openai-chat` Edge Function when `OPENAI_USE_PROXY=true` |
| OTP | `send-otp` / `verify-otp` (never client SMS on web) |
| Program SMS | `send-program-sms` Edge Function |
| Zibal payment | WordPress proxy (`/gymaipro/v1/zibal/*`) |
| Zarinpal | Native only (blocked on web — no client merchant API) |
| Supabase data | RLS + anon key |

## OpenAI key on web (accepted trade-off)

Because the server cannot reach OpenAI, the key is compiled into the web bundle.
Mitigations in app:

- Client rate limit (20 req/min, 2s spacing)
- Require login for proxy route; direct route uses your restricted key

**In OpenAI dashboard:** set monthly budget cap, restrict models to `gpt-4o-mini` / `gpt-4o`.

## Mobile dev (native)

```powershell
flutter run --dart-define-from-file=.env
```

Legacy direct SMS/AI on mobile: only when `OTP_USE_SERVER=false` / keys in `.env` — not for web.
