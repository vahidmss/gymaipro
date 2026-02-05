-- تنظیم RLS Policy برای جدول ai_exercises
-- این فایل RLS را برای جدول ai_exercises تنظیم می‌کند تا همه کاربران بتوانند تمرین‌ها را بخوانند

-- بررسی وجود جدول
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'ai_exercises'
    ) THEN
        RAISE EXCEPTION 'جدول ai_exercises وجود ندارد. لطفاً ابتدا جدول را ایجاد کنید.';
    END IF;
END $$;

-- حذف RLS policies قدیمی (اگر وجود دارند)
DROP POLICY IF EXISTS "Public can view ai_exercises" ON public.ai_exercises;
DROP POLICY IF EXISTS "Anyone can view ai_exercises" ON public.ai_exercises;
DROP POLICY IF EXISTS "Authenticated users can view ai_exercises" ON public.ai_exercises;

-- فعال کردن RLS
ALTER TABLE public.ai_exercises ENABLE ROW LEVEL SECURITY;

-- ایجاد Policy برای خواندن: همه کاربران (authenticated و anonymous) می‌توانند تمرین‌ها را ببینند
CREATE POLICY "Public can view ai_exercises"
    ON public.ai_exercises
    FOR SELECT
    USING (true); -- همه می‌توانند بخوانند

-- Policy برای insert: فقط authenticated users (برای sync)
CREATE POLICY "Authenticated users can insert ai_exercises"
    ON public.ai_exercises
    FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL);

-- Policy برای update: فقط authenticated users (برای sync)
CREATE POLICY "Authenticated users can update ai_exercises"
    ON public.ai_exercises
    FOR UPDATE
    USING (auth.uid() IS NOT NULL)
    WITH CHECK (auth.uid() IS NOT NULL);

-- Policy برای delete: فقط authenticated users (برای sync)
CREATE POLICY "Authenticated users can delete ai_exercises"
    ON public.ai_exercises
    FOR DELETE
    USING (auth.uid() IS NOT NULL);

-- بررسی وضعیت RLS
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public' 
AND tablename = 'ai_exercises';

-- نمایش policies
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE schemaname = 'public' 
AND tablename = 'ai_exercises';

