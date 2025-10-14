-- Create confidential user info table linked to public.profiles
-- Run in Supabase SQL editor or add as a migration.

create table if not exists public.confidential_user_info (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  has_consented boolean not null default false,
  consented_at timestamptz null,
  notes text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- one row per profile (adjust later if you want multi-versions)
create unique index if not exists confidential_user_info_profile_uidx
  on public.confidential_user_info(profile_id);

-- trigger to keep updated_at fresh
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end; $$ language plpgsql;

drop trigger if exists set_confidential_user_info_updated_at on public.confidential_user_info;
create trigger set_confidential_user_info_updated_at
before update on public.confidential_user_info
for each row execute function public.set_updated_at();

-- Enable Row Level Security
alter table public.confidential_user_info enable row level security;

-- Policies: only the owner (auth.uid() == profile_id) can read/write his row
drop policy if exists "select own confidential info" on public.confidential_user_info;
create policy "select own confidential info" on public.confidential_user_info
for select
to authenticated
using (profile_id = auth.uid());

drop policy if exists "insert own confidential info" on public.confidential_user_info;
create policy "insert own confidential info" on public.confidential_user_info
for insert
to authenticated
with check (profile_id = auth.uid());

drop policy if exists "update own confidential info" on public.confidential_user_info;
create policy "update own confidential info" on public.confidential_user_info
for update
to authenticated
using (profile_id = auth.uid())
with check (profile_id = auth.uid());

drop policy if exists "delete own confidential info" on public.confidential_user_info;
create policy "delete own confidential info" on public.confidential_user_info
for delete
to authenticated
using (profile_id = auth.uid());

-- Optional: allow service_role full access (by default it can bypass RLS)
-- grants (optional; Supabase handles by roles)
grant select, insert, update, delete on public.confidential_user_info to authenticated;


