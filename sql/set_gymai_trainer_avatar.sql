-- =============================================================================
-- آواتار مربی GymAI — یک‌بار اجرا + آپلود عکس
-- =============================================================================
-- ۱) در Supabase Dashboard → Storage → bucket «profile_images»
--    فایل images/GymAI.jpg را با نام زیر آپلود کنید:
--       public/gymai-trainer-avatar.jpg
-- ۲) اگر دامنه API شما غیر از api.gymaipro.ir است، v_avatar_url را عوض کنید.
-- =============================================================================

UPDATE public.profiles
SET
  avatar_url = 'https://api.gymaipro.ir/storage/v1/object/public/profile_images/public/gymai-trainer-avatar.jpg',
  updated_at = now()
WHERE username = 'gymai_trainer'
   OR id = 'ddb977b5-0d39-4d9f-9a11-8dabbf301c02';
