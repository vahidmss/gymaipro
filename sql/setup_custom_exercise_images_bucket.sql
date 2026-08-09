-- اجرای دستی در Supabase SQL Editor اگر migration هنوز روی پروژه اعمال نشده
-- باکت تصاویر تمرین اختصاصی

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'exercise_images',
  'exercise_images',
  true,
  10485760,
  array['image/jpeg', 'image/jpg', 'image/png', 'image/webp', 'image/gif', 'image/heic']
)
on conflict (id) do update
set public = true;

drop policy if exists "Trainers can upload exercise images" on storage.objects;
drop policy if exists "Public can view exercise images" on storage.objects;
drop policy if exists "Trainers can delete their exercise images" on storage.objects;
drop policy if exists "Trainers can update their exercise images" on storage.objects;
drop policy if exists "exercise_images_insert" on storage.objects;
drop policy if exists "exercise_images_select" on storage.objects;
drop policy if exists "exercise_images_update" on storage.objects;
drop policy if exists "exercise_images_delete" on storage.objects;

create policy "exercise_images_insert"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'exercise_images'
  and auth.uid() is not null
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "exercise_images_select"
on storage.objects for select to public
using (bucket_id = 'exercise_images');

create policy "exercise_images_update"
on storage.objects for update to authenticated
using (
  bucket_id = 'exercise_images'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'exercise_images'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "exercise_images_delete"
on storage.objects for delete to authenticated
using (
  bucket_id = 'exercise_images'
  and (
    (storage.foldername(name))[1] = auth.uid()::text
    or exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'admin'
    )
  )
);
