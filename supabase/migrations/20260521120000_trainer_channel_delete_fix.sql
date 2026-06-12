-- رفع حذف پست کانال: soft-delete + RLS (select بعد از is_deleted=true ردیف را برنمی‌گرداند)

-- تابع مالک (اگر migration قبلی اعمال نشده باشد)
create or replace function public.trainer_channel_profile_ids_for_auth()
returns setof uuid
language sql
stable
security definer
set search_path = public
as $$
  select p.id
  from public.profiles p
  where p.id = auth.uid()
     or p.auth_user_id = auth.uid();
$$;

grant execute on function public.trainer_channel_profile_ids_for_auth() to authenticated;

-- مالک بتواند پست‌های خود را ببیند (حتی soft-deleted) — برای تأیید حذف
drop policy if exists "trainer_channel_posts_owner_select" on public.trainer_channel_posts;
create policy "trainer_channel_posts_owner_select"
  on public.trainer_channel_posts for select to authenticated
  using (trainer_id in (select public.trainer_channel_profile_ids_for_auth()));

-- RPC حذف نرم — مستقل از RLS خواندن پس از حذف
create or replace function public.trainer_channel_soft_delete_post(p_post_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count int;
begin
  update public.trainer_channel_posts
  set
    is_deleted = true,
    updated_at = now()
  where id = p_post_id
    and is_deleted = false
    and trainer_id in (select public.trainer_channel_profile_ids_for_auth());

  get diagnostics v_count = row_count;
  return v_count > 0;
end;
$$;

grant execute on function public.trainer_channel_soft_delete_post(uuid) to authenticated;

-- custom_music: حذف وقتی created_by = profiles.id ولی auth.uid() = auth_user_id
create or replace function public.custom_music_owner_ids_for_auth()
returns setof uuid
language sql
stable
security definer
set search_path = public
as $$
  select p.id
  from public.profiles p
  where p.id = auth.uid()
     or p.auth_user_id = auth.uid();
$$;

grant execute on function public.custom_music_owner_ids_for_auth() to authenticated;

drop policy if exists "Users can delete their own music" on public.custom_music;
create policy "Users can delete their own music"
  on public.custom_music for delete to authenticated
  using (created_by in (select public.custom_music_owner_ids_for_auth()));

drop policy if exists "Users can update their own music" on public.custom_music;
create policy "Users can update their own music"
  on public.custom_music for update to authenticated
  using (created_by in (select public.custom_music_owner_ids_for_auth()))
  with check (created_by in (select public.custom_music_owner_ids_for_auth()));

drop policy if exists "Users can view their own music" on public.custom_music;
create policy "Users can view their own music"
  on public.custom_music for select to authenticated
  using (created_by in (select public.custom_music_owner_ids_for_auth()));

drop policy if exists "Users can insert their own music" on public.custom_music;
create policy "Users can insert their own music"
  on public.custom_music for insert to authenticated
  with check (created_by in (select public.custom_music_owner_ids_for_auth()));
