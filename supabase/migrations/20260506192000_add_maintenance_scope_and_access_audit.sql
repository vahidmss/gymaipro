alter table public.app_runtime_controls
add column if not exists maintenance_scope text not null default 'all_non_admin';

alter table public.app_runtime_controls
drop constraint if exists app_runtime_controls_maintenance_scope_check;

alter table public.app_runtime_controls
add constraint app_runtime_controls_maintenance_scope_check
check (maintenance_scope in ('all_non_admin', 'athlete_only', 'trainer_only'));

create table if not exists public.app_runtime_controls_audit (
  id bigserial primary key,
  changed_by uuid,
  changed_at timestamptz not null default now(),
  change_summary text not null,
  new_config jsonb
);

create index if not exists idx_app_runtime_controls_audit_changed_at
  on public.app_runtime_controls_audit (changed_at desc);

alter table public.app_runtime_controls_audit enable row level security;

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
