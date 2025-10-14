-- Update confidential_user_info table with new fields for comprehensive data storage
-- Run this after the initial table creation

-- Add JSON columns for different sections of confidential information
alter table if exists public.confidential_user_info
  add column if not exists body_measurements jsonb,
  add column if not exists health_info jsonb,
  add column if not exists fitness_goals jsonb,
  add column if not exists photo_album jsonb,
  add column if not exists trainer_visibility jsonb;

-- Create indexes for better query performance
create index if not exists confidential_user_info_body_measurements_idx
  on public.confidential_user_info using gin (body_measurements);

create index if not exists confidential_user_info_health_info_idx
  on public.confidential_user_info using gin (health_info);

create index if not exists confidential_user_info_fitness_goals_idx
  on public.confidential_user_info using gin (fitness_goals);

create index if not exists confidential_user_info_photo_album_idx
  on public.confidential_user_info using gin (photo_album);

create index if not exists confidential_user_info_trainer_visibility_idx
  on public.confidential_user_info using gin (trainer_visibility);

-- Add comments for documentation
comment on column public.confidential_user_info.body_measurements is 'Body measurements data including height, weight, circumferences, etc.';
comment on column public.confidential_user_info.health_info is 'Health information including medical conditions, medications, allergies, etc.';
comment on column public.confidential_user_info.fitness_goals is 'Fitness goals and targets set by the user';
comment on column public.confidential_user_info.photo_album is 'Photo album with body photos, timestamps, and visibility settings';
comment on column public.confidential_user_info.trainer_visibility is 'Settings for what information is visible to trainers';

-- Optional: Create a function to update the updated_at timestamp
create or replace function public.update_confidential_user_info_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end; $$ language plpgsql;

-- Update the existing trigger to use the new function name
drop trigger if exists set_confidential_user_info_updated_at on public.confidential_user_info;
create trigger set_confidential_user_info_updated_at
before update on public.confidential_user_info
for each row execute function public.update_confidential_user_info_updated_at();
