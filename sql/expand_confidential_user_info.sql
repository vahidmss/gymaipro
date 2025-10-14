-- Expand confidential_user_info to cover new app features
-- Run this after your current table creation

-- 1) Lifestyle / Preferences section
alter table if exists public.confidential_user_info
  add column if not exists lifestyle_preferences jsonb;

create index if not exists confidential_user_info_lifestyle_idx
  on public.confidential_user_info using gin (lifestyle_preferences);

comment on column public.confidential_user_info.lifestyle_preferences is
  'User lifestyle/preferences: shift work, sleep pattern, smoking/alcohol, diet likes/dislikes, extra notes';

-- 2) Global photo album settings
alter table if exists public.confidential_user_info
  add column if not exists photos_visible_to_trainer boolean not null default false,
  add column if not exists last_photo_at timestamptz null,
  add column if not exists days_between_photos int not null default 20,
  add column if not exists max_photos_per_month int not null default 4;

comment on column public.confidential_user_info.photos_visible_to_trainer is
  'If true, photo album is visible to trainer (per-photo flags still may apply within photo_album JSON).';
comment on column public.confidential_user_info.last_photo_at is
  'Timestamp of the last uploaded body photo (for enforcing cadence rules).';
comment on column public.confidential_user_info.days_between_photos is
  'Minimum days required between body photo uploads.';
comment on column public.confidential_user_info.max_photos_per_month is
  'Upper bound on number of photos user may upload per month.';

-- 3) Photo album JSON docs
-- Store array of objects with shape:
-- { url, type: "front|back|side|progress", taken_at, notes, is_visible_to_trainer, blur_level }
-- Already stored in photo_album column; no DDL required beyond comments
comment on column public.confidential_user_info.photo_album is
  'Array of photo objects: {url,type(front|back|side|progress),taken_at,notes,is_visible_to_trainer,blur_level}';

-- 4) Ensure RLS stays enabled (no-op if already enabled)
alter table public.confidential_user_info enable row level security;


