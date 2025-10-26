-- بررسی ساده bucket coach_certificates
-- این فایل را در Supabase SQL Editor اجرا کنید

-- 1. بررسی وجود bucket
SELECT name, public, created_at 
FROM storage.buckets 
WHERE name = 'coach_certificates';

-- 2. اگر bucket وجود ندارد، آن را ایجاد کنید
INSERT INTO storage.buckets (id, name, public, created_at, updated_at)
VALUES (
  'coach_certificates',
  'coach_certificates', 
  true,
  NOW(),
  NOW()
)
ON CONFLICT (id) DO NOTHING;

-- 3. بررسی مجدد
SELECT name, public, created_at 
FROM storage.buckets 
WHERE name = 'coach_certificates';
