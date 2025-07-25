-- جدول لاگ تمرینات برنامه با ساختار JSONB
create table if not exists workout_program_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  program_name text not null,
  log_date date not null, -- تاریخ روز لاگ (هر روز فقط یک لاگ برای هر برنامه)
  sessions jsonb not null, -- آرایه‌ای از جلسات، هر جلسه شامل exercises و هر exercise شامل sets
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, program_name, log_date)
);

-- ایندکس برای جستجوی سریع‌تر
create index if not exists idx_workout_program_logs_user_date on workout_program_logs(user_id, log_date desc); 