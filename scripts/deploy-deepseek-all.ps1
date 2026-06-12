# آپلود openai-chat + اسکریپت‌های سرور + راهنمای relay
# از PowerShell در ریشه پروژه:
#   powershell -ExecutionPolicy Bypass -File .\scripts\deploy-deepseek-all.ps1

$Server = "root@87.248.156.175"
$Port = "9011"
$RemoteDocker = "/root/supabase/docker"
$LocalIndex = "supabase/functions/openai-chat/index.ts"

if (-not (Test-Path $LocalIndex)) {
  Write-Error "فایل پیدا نشد: $LocalIndex"
  exit 1
}

Write-Host "آپلود index.ts ..."
ssh -p $Port $Server "mkdir -p $RemoteDocker/volumes/functions/openai-chat"
scp -P $Port $LocalIndex "${Server}:${RemoteDocker}/volumes/functions/openai-chat/index.ts"

Write-Host "آپلود اسکریپت‌های تست/راه‌اندازی ..."
scp -P $Port scripts/test-openai-connectivity.sh "${Server}:~/test-openai-connectivity.sh"
scp -P $Port scripts/setup-deepseek-on-server.sh "${Server}:~/setup-deepseek-on-server.sh"
ssh -p $Port $Server "chmod +x ~/test-openai-connectivity.sh ~/setup-deepseek-on-server.sh"

Write-Host ""
Write-Host "=========================================="
Write-Host "مرحله ۱ — Cloudflare Worker (ویندوز):"
Write-Host "  cd cloudflare\openai-relay"
Write-Host "  wrangler login"
Write-Host "  wrangler secret put OPENAI_API_KEY    # کلید DeepSeek"
Write-Host "  wrangler secret put RELAY_SECRET      # یک رمز دلخواه قوی"
Write-Host "  wrangler deploy"
Write-Host ""
Write-Host "مرحله ۲ — سرور:"
Write-Host "  ssh -p $Port $Server"
Write-Host "  bash ~/setup-deepseek-on-server.sh"
Write-Host "  bash ~/test-openai-connectivity.sh"
Write-Host "=========================================="
