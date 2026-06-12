# Relay رایگان OpenAI با Cloudflare Workers

وقتی سرور Supabase در ایران به `api.openai.com` مستقیم وصل نمی‌شود، این Worker واسطه می‌شود.

## پیش‌نیاز

- اکانت رایگان [Cloudflare](https://dash.cloudflare.com)
- [Node.js](https://nodejs.org) + `npm i -g wrangler`

## قدم‌ها

### ۱) تست از سرور ایران

```bash
# باید FAIL (timeout)
curl -sS --max-time 15 -o /dev/null -w "openai: %{http_code}\n" https://api.openai.com/v1/models

# باید 200 یا 301 (برای relay لازم است)
curl -sS --max-time 15 -o /dev/null -w "cloudflare: %{http_code}\n" https://cloudflare.com
```

### ۲) Deploy Worker

```bash
cd cloudflare/openai-relay
wrangler login
wrangler secret put OPENAI_API_KEY
wrangler secret put RELAY_SECRET
wrangler deploy
```

آدرس نهایی شبیه: `https://gymai-openai-relay.xxxx.workers.dev`

### ۳) تنظیم سرور Supabase

در `/root/supabase/docker/.env`:

```env
OPENAI_RELAY_URL=https://gymai-openai-relay.xxxx.workers.dev
OPENAI_RELAY_SECRET=همان_RELAY_SECRET
```

در `docker-compose.yml` زیر سرویس `functions` اضافه کن:

```yaml
OPENAI_RELAY_URL: ${OPENAI_RELAY_URL}
OPENAI_RELAY_SECRET: ${OPENAI_RELAY_SECRET}
```

سپس:

```bash
cd /root/supabase/docker
# فایل openai-chat را از پروژه کپی کن (deploy-openai-chat.ps1 یا scp)
docker compose restart functions
```

### ۴) تست relay از سرور

```bash
RELAY_URL="https://gymai-openai-relay.xxxx.workers.dev"
SECRET="همان_RELAY_SECRET"

curl -sS --max-time 40 -X POST "$RELAY_URL/v1/chat/completions" \
  -H "X-Relay-Secret: $SECRET" \
  -H "Content-Type: application/json" \
  -d '{"model":"gpt-4o-mini","messages":[{"role":"user","content":"سلام"}],"max_tokens":10}'
```

اگر JSON با `choices` دیدی، چت اپ هم باید کار کند.

## گزینه ج — بدون هزینه و بدون Cloudflare

در `.env` اپ:

```env
AI_ENGINE_MODE=rule_based
```

چت GPT واقعی غیرفعال می‌ماند؛ برنامه تمرین با موتور محلی ساخته می‌شود.
