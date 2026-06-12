-- چند تصویر و چند ویدیو برای تمرین‌های اختصاصی (custom_exercises)
alter table public.custom_exercises
  add column if not exists image_urls jsonb not null default '[]'::jsonb,
  add column if not exists video_urls jsonb not null default '[]'::jsonb;

-- پر کردن آرایه‌ها از فیلدهای تک‌مقداری قبلی (فقط وقتی آرایه خالی است)
update public.custom_exercises
set image_urls = jsonb_build_array(image_url)
where coalesce(jsonb_array_length(image_urls), 0) = 0
  and image_url is not null
  and trim(image_url) <> '';

update public.custom_exercises
set video_urls = jsonb_build_array(video_url)
where coalesce(jsonb_array_length(video_urls), 0) = 0
  and video_url is not null
  and trim(video_url) <> '';
