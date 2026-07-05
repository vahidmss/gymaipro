# Check SMS/AI keys on SERVER .env (masked)
#   .\scripts\verify-server-env.ps1

$Server = "root@87.248.156.175"
$Port = "9011"

Write-Host "Checking SERVER /root/supabase/docker/.env ..."
& ssh -p $Port $Server "grep -E 'SMS_|AI_API|OPENAI|SUPABASE_' /root/supabase/docker/.env | sed 's/=.*/=***/'"
