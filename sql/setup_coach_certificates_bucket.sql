-- تنظیمات Storage Bucket برای مدارک مربیان
-- این فایل را در Supabase SQL Editor اجرا کنید

-- 1. ایجاد Bucket (در Supabase Dashboard > Storage انجام دهید)
-- نام bucket: coach_certificates
-- عمومی: بله

-- 2. تنظیمات RLS Policy برای storage.objects

-- Policy برای آپلود (فقط مربیان)
CREATE POLICY "Trainers can upload certificates" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'coach_certificates' AND
  auth.uid() IS NOT NULL AND
  (storage.foldername(name))[1] = auth.uid()::text AND
  EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() AND role = 'trainer'
  )
);

-- Policy برای مشاهده (همه کاربران - برای نمایش تصاویر)
CREATE POLICY "Public can view certificates" ON storage.objects
FOR SELECT USING (bucket_id = 'coach_certificates');

-- Policy برای حذف (فقط صاحب فایل یا ادمین)
CREATE POLICY "Trainers can delete their certificates" ON storage.objects
FOR DELETE USING (
  bucket_id = 'coach_certificates' AND
  (
    auth.uid()::text = (storage.foldername(name))[1] OR
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  )
);

-- Policy برای به‌روزرسانی (فقط صاحب فایل)
CREATE POLICY "Trainers can update their certificates" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'coach_certificates' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- 3. تابع برای پاک‌سازی فایل‌های حذف شده
CREATE OR REPLACE FUNCTION cleanup_deleted_certificate_files()
RETURNS TRIGGER AS $$
BEGIN
  -- اگر مدرک حذف شد، فایل مربوطه را هم حذف کن
  IF OLD.certificate_url IS NOT NULL THEN
    -- استخراج نام فایل از URL
    DECLARE
      file_name TEXT;
    BEGIN
      file_name := split_part(OLD.certificate_url, '/', array_length(string_to_array(OLD.certificate_url, '/'), 1));
      
      -- حذف فایل از storage
      DELETE FROM storage.objects 
      WHERE bucket_id = 'coach_certificates' 
      AND name = file_name;
    END;
  END IF;
  
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- تریگر برای پاک‌سازی خودکار فایل‌ها
CREATE TRIGGER trigger_cleanup_certificate_files
  AFTER DELETE ON public.certificates
  FOR EACH ROW
  EXECUTE FUNCTION cleanup_deleted_certificate_files();

-- 4. تابع برای دریافت آمار storage
CREATE OR REPLACE FUNCTION get_certificate_storage_stats()
RETURNS TABLE (
  total_files BIGINT,
  total_size BIGINT,
  files_by_trainer JSONB
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*) as total_files,
    COALESCE(SUM((metadata->>'size')::bigint), 0) as total_size,
    jsonb_object_agg(
      (storage.foldername(name))[1],
      file_count
    ) as files_by_trainer
  FROM (
    SELECT 
      name,
      metadata,
      COUNT(*) as file_count
    FROM storage.objects 
    WHERE bucket_id = 'coach_certificates'
    GROUP BY name, metadata
  ) stats;
END;
$$ LANGUAGE plpgsql;

-- 5. تابع برای حذف فایل‌های قدیمی (اختیاری)
CREATE OR REPLACE FUNCTION cleanup_old_certificate_files(days_old INTEGER DEFAULT 30)
RETURNS INTEGER AS $$
DECLARE
  deleted_count INTEGER := 0;
BEGIN
  -- حذف فایل‌هایی که مربوط به مدارک حذف شده هستند
  DELETE FROM storage.objects 
  WHERE bucket_id = 'coach_certificates'
  AND created_at < NOW() - INTERVAL '1 day' * days_old
  AND name NOT IN (
    SELECT certificate_url 
    FROM public.certificates 
    WHERE certificate_url IS NOT NULL
  );
  
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- 6. View برای نمایش اطلاعات کامل مدارک
CREATE OR REPLACE VIEW certificates_with_storage_info AS
SELECT 
  c.*,
  p.username as trainer_username,
  COALESCE(p.first_name || ' ' || p.last_name, p.username) as trainer_full_name,
  p.avatar_url as trainer_avatar,
  approver.username as approver_username,
  CASE 
    WHEN c.certificate_url IS NOT NULL THEN
      (SELECT metadata->>'size' FROM storage.objects 
       WHERE bucket_id = 'coach_certificates' 
       AND name = split_part(c.certificate_url, '/', array_length(string_to_array(c.certificate_url, '/'), 1)))
    ELSE NULL
  END as file_size,
  CASE 
    WHEN c.certificate_url IS NOT NULL THEN
      (SELECT created_at FROM storage.objects 
       WHERE bucket_id = 'coach_certificates' 
       AND name = split_part(c.certificate_url, '/', array_length(string_to_array(c.certificate_url, '/'), 1)))
    ELSE NULL
  END as file_uploaded_at
FROM public.certificates c
JOIN public.profiles p ON c.trainer_id = p.id
LEFT JOIN public.profiles approver ON c.approved_by = approver.id;

-- 7. ایندکس برای بهبود عملکرد
CREATE INDEX IF NOT EXISTS idx_storage_objects_bucket_name 
ON storage.objects(bucket_id, name);

CREATE INDEX IF NOT EXISTS idx_storage_objects_created_at 
ON storage.objects(created_at DESC);

-- 8. تابع برای بررسی سلامت فایل‌ها
CREATE OR REPLACE FUNCTION check_certificate_file_health()
RETURNS TABLE (
  certificate_id UUID,
  trainer_id UUID,
  file_exists BOOLEAN,
  file_size BIGINT,
  status TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    c.id as certificate_id,
    c.trainer_id,
    CASE 
      WHEN s.name IS NOT NULL THEN true 
      ELSE false 
    END as file_exists,
    COALESCE((s.metadata->>'size')::bigint, 0) as file_size,
    CASE 
      WHEN s.name IS NULL THEN 'FILE_MISSING'
      WHEN (s.metadata->>'size')::bigint = 0 THEN 'FILE_EMPTY'
      ELSE 'FILE_OK'
    END as status
  FROM public.certificates c
  LEFT JOIN storage.objects s ON (
    s.bucket_id = 'coach_certificates' AND
    s.name = split_part(c.certificate_url, '/', array_length(string_to_array(c.certificate_url, '/'), 1))
  )
  WHERE c.certificate_url IS NOT NULL;
END;
$$ LANGUAGE plpgsql;
