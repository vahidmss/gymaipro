-- ایجاد bucket برای فایل‌های موزیک
CREATE BUCKET IF NOT EXISTS music_files;

-- تنظیمات bucket
UPDATE storage.buckets
SET public = true,
    file_size_limit = 52428800, -- 50MB
    allowed_mime_types = ARRAY['audio/mpeg', 'audio/mp3', 'audio/wav', 'audio/ogg', 'audio/m4a', 'audio/aac']
WHERE id = 'music_files';

-- ایجاد bucket برای تصاویر کاور موزیک
CREATE BUCKET IF NOT EXISTS music_covers;

-- تنظیمات bucket
UPDATE storage.buckets
SET public = true,
    file_size_limit = 5242880, -- 5MB
    allowed_mime_types = ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
WHERE id = 'music_covers';

-- RLS Policies برای music_files
CREATE POLICY "Users can upload music files"
  ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'music_files' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Public can view music files"
  ON storage.objects
  FOR SELECT
  USING (bucket_id = 'music_files');

-- RLS Policies برای music_covers
CREATE POLICY "Users can upload music covers"
  ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'music_covers' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Public can view music covers"
  ON storage.objects
  FOR SELECT
  USING (bucket_id = 'music_covers');

