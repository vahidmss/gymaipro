-- هیت‌مپ عضلانی برای تمرین‌های اختصاصی مربی
alter table public.custom_exercises
  add column if not exists muscle_targets_json jsonb not null default '{}'::jsonb;
