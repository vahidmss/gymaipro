-- Chat media bucket for private messenger (voice / image / file)
-- Run in Supabase SQL Editor after reviewing.
-- App currently uploads via CDN (dl.gymaipro.ir) so messaging works TODAY;
-- this bucket is the production-grade private ACL target for a later switch.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'chat_media',
  'chat_media',
  false,
  20971520, -- 20 MB
  array[
    'audio/mp4',
    'audio/m4a',
    'audio/aac',
    'audio/mpeg',
    'audio/wav',
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/gif',
    'application/pdf',
    'application/zip',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
  ]
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- Path convention: {conversation_id}/{user_id}/{uuid}.ext
-- Participants of that conversation may read; only the uploader may write/delete.

drop policy if exists "chat_media_select_participants" on storage.objects;
create policy "chat_media_select_participants"
on storage.objects for select
to authenticated
using (
  bucket_id = 'chat_media'
  and exists (
    select 1
    from public.chat_conversations c
    where c.id::text = (storage.foldername(name))[1]
      and (c.user1_id = auth.uid() or c.user2_id = auth.uid())
  )
);

drop policy if exists "chat_media_insert_own" on storage.objects;
create policy "chat_media_insert_own"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'chat_media'
  and (storage.foldername(name))[2] = auth.uid()::text
  and exists (
    select 1
    from public.chat_conversations c
    where c.id::text = (storage.foldername(name))[1]
      and (c.user1_id = auth.uid() or c.user2_id = auth.uid())
  )
);

drop policy if exists "chat_media_update_own" on storage.objects;
create policy "chat_media_update_own"
on storage.objects for update
to authenticated
using (
  bucket_id = 'chat_media'
  and (storage.foldername(name))[2] = auth.uid()::text
)
with check (
  bucket_id = 'chat_media'
  and (storage.foldername(name))[2] = auth.uid()::text
);

drop policy if exists "chat_media_delete_own" on storage.objects;
create policy "chat_media_delete_own"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'chat_media'
  and (storage.foldername(name))[2] = auth.uid()::text
);

-- Optional helper column for inbox icons (safe if already exists)
alter table public.chat_conversations
  add column if not exists last_message_type text default 'text';
