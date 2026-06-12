-- نوع پست audio (پادکست/فایل صوتی) + اصلاح RLS برای حذف/ویرایش وقتی profiles.id ≠ auth.uid()

-- 1) نوع محتوای audio
alter table public.trainer_channel_posts
  drop constraint if exists trainer_channel_posts_content_type_check;

alter table public.trainer_channel_posts
  add constraint trainer_channel_posts_content_type_check
  check (content_type in ('text', 'image', 'video', 'voice', 'audio'));

-- 2) تابع کمکی مالک کانال (profile.id یا auth_user_id)
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

-- 3) به‌روزرسانی سیاست‌های کانال
drop policy if exists "trainer_channels_read_enabled" on public.trainer_channels;
create policy "trainer_channels_read_enabled"
  on public.trainer_channels for select to authenticated
  using (
    is_enabled = true
    or trainer_id in (select public.trainer_channel_profile_ids_for_auth())
  );

drop policy if exists "trainer_channels_owner_write" on public.trainer_channels;
create policy "trainer_channels_owner_write"
  on public.trainer_channels for all to authenticated
  using (trainer_id in (select public.trainer_channel_profile_ids_for_auth()))
  with check (trainer_id in (select public.trainer_channel_profile_ids_for_auth()));

drop policy if exists "trainer_channel_posts_read" on public.trainer_channel_posts;
create policy "trainer_channel_posts_read"
  on public.trainer_channel_posts for select to authenticated
  using (
    is_deleted = false
    and exists (
      select 1 from public.trainer_channels c
      where c.id = channel_id
        and (
          c.is_enabled = true
          or c.trainer_id in (select public.trainer_channel_profile_ids_for_auth())
        )
    )
  );

drop policy if exists "trainer_channel_posts_owner_write" on public.trainer_channel_posts;
create policy "trainer_channel_posts_owner_write"
  on public.trainer_channel_posts for insert to authenticated
  with check (trainer_id in (select public.trainer_channel_profile_ids_for_auth()));

drop policy if exists "trainer_channel_posts_owner_update" on public.trainer_channel_posts;
create policy "trainer_channel_posts_owner_update"
  on public.trainer_channel_posts for update to authenticated
  using (trainer_id in (select public.trainer_channel_profile_ids_for_auth()))
  with check (trainer_id in (select public.trainer_channel_profile_ids_for_auth()));
