create table if not exists public.app_runtime_controls (
  id text primary key default 'global',
  maintenance_mode boolean not null default false,
  maintenance_message text not null default 'اپلیکیشن موقتاً در حال بروزرسانی است.',
  force_update boolean not null default false,
  min_supported_version text not null default '',
  latest_version text not null default '',
  update_url text not null default '',
  maintenance_scope text not null default 'all_non_admin' check (
    maintenance_scope in ('all_non_admin', 'athlete_only', 'trainer_only')
  ),
  ai_hub_enabled boolean not null default true,
  academy_enabled boolean not null default true,
  my_club_enabled boolean not null default true,
  social_enabled boolean not null default true,
  private_chat_enabled boolean not null default true,
  public_chat_enabled boolean not null default true,
  updated_by uuid,
  updated_at timestamptz not null default now()
);

insert into public.app_runtime_controls (id)
values ('global')
on conflict (id) do nothing;

create table if not exists public.app_runtime_controls_audit (
  id bigserial primary key,
  changed_by uuid,
  changed_at timestamptz not null default now(),
  change_summary text not null,
  new_config jsonb
);

create index if not exists idx_app_runtime_controls_audit_changed_at
  on public.app_runtime_controls_audit (changed_at desc);

alter table public.app_runtime_controls enable row level security;
alter table public.app_runtime_controls_audit enable row level security;

drop policy if exists "app_runtime_controls_read_authenticated" on public.app_runtime_controls;
create policy "app_runtime_controls_read_authenticated"
  on public.app_runtime_controls
  for select
  to authenticated
  using (true);

drop policy if exists "app_runtime_controls_admin_update" on public.app_runtime_controls;
create policy "app_runtime_controls_admin_update"
  on public.app_runtime_controls
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

drop policy if exists "app_runtime_controls_audit_admin_read" on public.app_runtime_controls_audit;
create policy "app_runtime_controls_audit_admin_read"
  on public.app_runtime_controls_audit
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

drop policy if exists "app_runtime_controls_audit_admin_insert" on public.app_runtime_controls_audit;
create policy "app_runtime_controls_audit_admin_insert"
  on public.app_runtime_controls_audit
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.profiles p
      where p.id = auth.uid()
        and p.role = 'admin'
    )
  );
