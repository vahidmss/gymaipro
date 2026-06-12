-- فعال‌سازی چت GPT به‌صورت پیش‌فرض (قبلاً default false بود)
alter table public.app_runtime_controls
  alter column ai_chat_enabled set default true;

update public.app_runtime_controls
set ai_chat_enabled = true
where ai_chat_enabled = false;
