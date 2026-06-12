# آپلود Edge Function openai-chat به سرور self-hosted Supabase
# از PowerShell در ریشه پروژه gymaipro اجرا کن:
#   .\scripts\deploy-openai-chat.ps1
#
# قبل از اجرا متغیرها را با اطلاعات سرور خودت تنظیم کن.

$Server = "root@87.248.156.175"   # کاربر@IP
$Port = "9011"                    # پورت SSH
$RemoteFunctionsDir = "/root/supabase/docker/volumes/functions/openai-chat"
$LocalFile = "supabase/functions/openai-chat/index.ts"

if (-not (Test-Path $LocalFile)) {
  Write-Error "فایل پیدا نشد: $LocalFile — از ریشه پروژه اجرا کن."
  exit 1
}

Write-Host "ساخت پوشه روی سرور..."
ssh -p $Port $Server "mkdir -p $RemoteFunctionsDir"

Write-Host "کپی index.ts ..."
scp -P $Port $LocalFile "${Server}:${RemoteFunctionsDir}/index.ts"

Write-Host ""
Write-Host "فایل آپلود شد. حالا روی سرور این مراحل را انجام بده:"
Write-Host "  1) OPENAI_API_KEY را در .env سرور بگذار"
Write-Host "  2) docker-compose.yml را برای OPENAI_API_KEY آپدیت کن (راهنما: scripts/setup-openai-chat-on-server.sh)"
Write-Host "  3) docker compose restart functions"
Write-Host "  4) bash scripts/test-openai-connectivity.sh"
