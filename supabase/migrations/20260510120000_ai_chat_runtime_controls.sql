-- پیام و وضعیت چت GPT از پنل ادمین
alter table public.app_runtime_controls
  add column if not exists ai_chat_enabled boolean not null default false;

alter table public.app_runtime_controls
  add column if not exists ai_chat_unavailable_message text not null default 'فعلاً چت با هوش مصنوعی در دسترس نیست!';
