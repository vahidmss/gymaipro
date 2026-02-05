-- تنظیمات Storage Bucket برای تصاویر تمرین‌های اختصاصی
-- این فایل را در Supabase SQL Editor اجرا کنید

-- 1. ایجاد Bucket (در Supabase Dashboard > Storage انجام دهید)
-- نام bucket: exercise_images
-- عمومی: بله

-- 2. تنظیمات RLS Policy برای storage.objects

-- Policy برای آپلود (فقط مربیان و ادمین‌ها)
CREATE POLICY "Trainers can upload exercise images" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'exercise_images' AND
  auth.uid() IS NOT NULL AND
  (storage.foldername(name))[1] = auth.uid()::text AND
  EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() AND role IN ('trainer', 'admin')
  )
);

-- Policy برای مشاهده (همه کاربران - برای نمایش تصاویر)
CREATE POLICY "Public can view exercise images" ON storage.objects
FOR SELECT USING (bucket_id = 'exercise_images');

-- Policy برای حذف (فقط صاحب فایل یا ادمین)
CREATE POLICY "Trainers can delete their exercise images" ON storage.objects
FOR DELETE USING (
  bucket_id = 'exercise_images' AND
  (
    auth.uid()::text = (storage.foldername(name))[1] OR
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  )
);

-- Policy برای به‌روزرسانی (فقط صاحب فایل)
CREATE POLICY "Trainers can update their exercise images" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'exercise_images' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

