-- In-app announcements system
create table if not exists public.in_app_announcements (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null,
  media_type text not null default 'image' check (media_type in ('image', 'video')),
  media_url text,
  cta_type text not null default 'none' check (cta_type in ('none', 'deep_link', 'external_url')),
  cta_text text,
  cta_value text,
  dismiss_mode text not null default 'daily' check (dismiss_mode in ('always', 'daily', 'once')),
  priority integer not null default 0,
  is_active boolean not null default true,
  start_at timestamptz,
  end_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz
);

create index if not exists idx_in_app_announcements_active
  on public.in_app_announcements (is_active, priority desc, created_at desc);

create table if not exists public.in_app_announcement_events (
  id bigserial primary key,
  announcement_id uuid not null references public.in_app_announcements(id) on delete cascade,
  user_id uuid,
  event_type text not null check (event_type in ('shown', 'clicked', 'dismissed')),
  created_at timestamptz not null default now()
);

create index if not exists idx_in_app_announcement_events_announcement
  on public.in_app_announcement_events (announcement_id, created_at desc);

-- RLS
alter table public.in_app_announcements enable row level security;
alter table public.in_app_announcement_events enable row level security;

-- Everyone can read active announcements.
drop policy if exists "in_app_announcements_read_active" on public.in_app_announcements;
create policy "in_app_announcements_read_active"
  on public.in_app_announcements
  for select
  to authenticated
  using (is_active = true);

-- Admins can do all operations.
drop policy if exists "in_app_announcements_admin_all" on public.in_app_announcements;
create policy "in_app_announcements_admin_all"
  on public.in_app_announcements
  for all
  to authenticated
  using (
    exists (
      select 1
      from public.profiles p
      where p.id = auth.uid()
        and p.role = 'admin'
    )
  )
  with check (
    exists (
      select 1
      from public.profiles p
      where p.id = auth.uid()
        and p.role = 'admin'
    )
  );

-- Any authenticated user can insert their own event rows.
drop policy if exists "in_app_announcement_events_insert_auth" on public.in_app_announcement_events;
create policy "in_app_announcement_events_insert_auth"
  on public.in_app_announcement_events
  for insert
  to authenticated
  with check (user_id is null or user_id = auth.uid());

-- Admins can view events for analytics.
drop policy if exists "in_app_announcement_events_admin_read" on public.in_app_announcement_events;
create policy "in_app_announcement_events_admin_read"
  on public.in_app_announcement_events
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.profiles p
      where p.id = auth.uid()
        and p.role = 'admin'
    )
  );
