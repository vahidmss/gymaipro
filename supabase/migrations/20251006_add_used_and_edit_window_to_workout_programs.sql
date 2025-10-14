-- Add usage tracking fields
alter table if exists public.workout_programs
  add column if not exists is_used boolean not null default false,
  add column if not exists first_used_at timestamp with time zone null;

create index if not exists idx_workout_programs_first_used_at
  on public.workout_programs using btree (first_used_at);

-- Optional: helper generated column for edit deadline (commented out if not desired)
-- alter table if exists public.workout_programs
--   add column if not exists edit_deadline timestamp with time zone
--   generated always as (created_at + interval '3 days') stored;

-- Recommended: RLS policy to restrict updates after 3 days for trainers
-- Note: Uncomment and adapt to your auth schema if you use RLS; otherwise keep client-side checks only.
--
-- create policy if not exists workout_programs_trainer_update_within_3_days
--   on public.workout_programs
--   for update using (
--     -- allow owner user to update their own program anytime
--     auth.uid() = user_id
--     or (
--       -- trainer can update only within 3 days of creation
--       auth.uid() = trainer_id
--       and now() <= created_at + interval '3 days'
--     )
--   );

-- Enable RLS and define policies (Postgres doesn't support IF NOT EXISTS for policies)
alter table public.workout_programs enable row level security;

-- Drop existing policies if present to avoid duplicate name errors
drop policy if exists workout_programs_select on public.workout_programs;
drop policy if exists workout_programs_insert on public.workout_programs;
drop policy if exists workout_programs_update_limit_trainer_3d on public.workout_programs;
drop policy if exists workout_programs_delete_limit_trainer_3d on public.workout_programs;

-- SELECT: user (owner) or trainer can read
create policy workout_programs_select
on public.workout_programs
for select
using (
  auth.uid() = user_id
  or auth.uid() = trainer_id
);

-- INSERT: user or trainer can insert
create policy workout_programs_insert
on public.workout_programs
for insert
with check (
  auth.uid() = user_id
  or auth.uid() = trainer_id
);

-- UPDATE: user anytime; trainer only within 3 days of creation
create policy workout_programs_update_limit_trainer_3d
on public.workout_programs
for update
using (
  auth.uid() = user_id
  or (auth.uid() = trainer_id and now() <= created_at + interval '3 days')
);

-- DELETE (optional): mirror update rule
create policy workout_programs_delete_limit_trainer_3d
on public.workout_programs
for delete
using (
  auth.uid() = user_id
  or (auth.uid() = trainer_id and now() <= created_at + interval '3 days')
);
