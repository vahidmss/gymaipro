alter table public.app_runtime_controls
add column if not exists update_url text not null default '';
