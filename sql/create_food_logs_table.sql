-- Create food_logs table
drop table if exists public.food_logs cascade;

create table if not exists public.food_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  log_date date not null,
  meals jsonb not null default '[]',
  created_at timestamp with time zone default timezone('utc'::text, now()),
  updated_at timestamp with time zone default timezone('utc'::text, now())
);

-- Create unique index for one log per user per day
create unique index if not exists food_logs_user_id_log_date_idx on public.food_logs (user_id, log_date);

-- Create index for date queries
create index if not exists food_logs_log_date_idx on public.food_logs (log_date);

-- Enable RLS
alter table public.food_logs enable row level security;

-- Create policies
create policy "Users can view their own food logs" on public.food_logs
  for select using (auth.uid() = user_id);

create policy "Users can insert their own food logs" on public.food_logs
  for insert with check (auth.uid() = user_id);

create policy "Users can update their own food logs" on public.food_logs
  for update using (auth.uid() = user_id);

create policy "Users can delete their own food logs" on public.food_logs
  for delete using (auth.uid() = user_id); 