-- کانال مربی: یک کانال عمومی اختیاری per مربی (برندینگ و جذب شاگرد)
-- جدا از چت خصوصی؛ بدون عضویت/درخواست join

create table if not exists public.trainer_channels (
  id uuid primary key default gen_random_uuid(),
  trainer_id uuid not null unique references public.profiles(id) on delete cascade,
  is_enabled boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_trainer_channels_trainer
  on public.trainer_channels (trainer_id);

create index if not exists idx_trainer_channels_enabled
  on public.trainer_channels (is_enabled) where is_enabled = true;

create table if not exists public.trainer_channel_posts (
  id uuid primary key default gen_random_uuid(),
  channel_id uuid not null references public.trainer_channels(id) on delete cascade,
  trainer_id uuid not null references public.profiles(id) on delete cascade,
  content_type text not null check (content_type in ('text', 'image', 'video', 'voice')),
  text_content text,
  media_url text,
  media_duration_seconds integer,
  is_deleted boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz,
  constraint trainer_channel_posts_text_or_media check (
    content_type = 'text'
      or (media_url is not null and length(trim(media_url)) > 0)
  )
);

create index if not exists idx_trainer_channel_posts_channel_created
  on public.trainer_channel_posts (channel_id, created_at desc)
  where is_deleted = false;

create index if not exists idx_trainer_channel_posts_trainer
  on public.trainer_channel_posts (trainer_id, created_at desc)
  where is_deleted = false;

-- به‌روزرسانی updated_at کانال هنگام پست جدید
create or replace function public.trainer_channel_touch_updated_at()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.trainer_channels
  set updated_at = now()
  where id = new.channel_id;
  return new;
end;
$$;

drop trigger if exists trainer_channel_posts_touch_channel on public.trainer_channel_posts;
create trigger trainer_channel_posts_touch_channel
  after insert or update on public.trainer_channel_posts
  for each row execute function public.trainer_channel_touch_updated_at();

-- RLS
alter table public.trainer_channels enable row level security;
alter table public.trainer_channel_posts enable row level security;

-- خواندن کانال فعال برای همه کاربران احراز هویت‌شده
drop policy if exists "trainer_channels_read_enabled" on public.trainer_channels;
create policy "trainer_channels_read_enabled"
  on public.trainer_channels for select to authenticated
  using (is_enabled = true or trainer_id = auth.uid());

-- مربی/ادمین مالک کانال خودش
drop policy if exists "trainer_channels_owner_write" on public.trainer_channels;
create policy "trainer_channels_owner_write"
  on public.trainer_channels for all to authenticated
  using (trainer_id = auth.uid())
  with check (trainer_id = auth.uid());

-- ادمین همه کانال‌ها
drop policy if exists "trainer_channels_admin_all" on public.trainer_channels;
create policy "trainer_channels_admin_all"
  on public.trainer_channels for all to authenticated
  using (
    exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')
  )
  with check (
    exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')
  );

-- پست‌های کانال فعال (غیرحذف‌شده)
drop policy if exists "trainer_channel_posts_read" on public.trainer_channel_posts;
create policy "trainer_channel_posts_read"
  on public.trainer_channel_posts for select to authenticated
  using (
    is_deleted = false
    and exists (
      select 1 from public.trainer_channels c
      where c.id = channel_id
        and (c.is_enabled = true or c.trainer_id = auth.uid())
    )
  );

drop policy if exists "trainer_channel_posts_owner_write" on public.trainer_channel_posts;
create policy "trainer_channel_posts_owner_write"
  on public.trainer_channel_posts for insert to authenticated
  with check (trainer_id = auth.uid());

drop policy if exists "trainer_channel_posts_owner_update" on public.trainer_channel_posts;
create policy "trainer_channel_posts_owner_update"
  on public.trainer_channel_posts for update to authenticated
  using (trainer_id = auth.uid())
  with check (trainer_id = auth.uid());

drop policy if exists "trainer_channel_posts_admin_all" on public.trainer_channel_posts;
create policy "trainer_channel_posts_admin_all"
  on public.trainer_channel_posts for all to authenticated
  using (
    exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')
  )
  with check (
    exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')
  );
