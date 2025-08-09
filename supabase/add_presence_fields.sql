-- =====================================================
-- اضافه کردن فیلدهای حضور کاربران - GymAI Pro
-- =====================================================

-- اضافه کردن فیلدهای حضور به جدول profiles
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS last_seen_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS is_online BOOLEAN DEFAULT FALSE;

-- ایجاد ایندکس برای جستجوی سریع کاربران آنلاین
CREATE INDEX IF NOT EXISTS idx_profiles_last_seen_at ON profiles(last_seen_at DESC);
CREATE INDEX IF NOT EXISTS idx_profiles_is_online ON profiles(is_online);

-- تابع برای به‌روزرسانی خودکار last_seen_at
CREATE OR REPLACE FUNCTION update_last_seen()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_seen_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- تریگر برای به‌روزرسانی خودکار last_seen_at
DROP TRIGGER IF EXISTS update_profiles_last_seen ON profiles;
CREATE TRIGGER update_profiles_last_seen
    BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_last_seen();

-- تابع برای دریافت کاربران آنلاین
CREATE OR REPLACE FUNCTION get_online_users()
RETURNS TABLE (
    id UUID,
    first_name TEXT,
    last_name TEXT,
    username TEXT,
    avatar_url TEXT,
    role TEXT,
    last_seen_at TIMESTAMP WITH TIME ZONE,
    is_online BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.first_name,
        p.last_name,
        p.username,
        p.avatar_url,
        p.role,
        p.last_seen_at,
        p.is_online
    FROM profiles p
    WHERE p.is_online = TRUE
    ORDER BY p.last_seen_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- پیام تأیید
DO $$
BEGIN
    RAISE NOTICE 'فیلدهای حضور کاربران اضافه شدند!';
    RAISE NOTICE 'فیلدهای جدید: last_seen_at, is_online';
    RAISE NOTICE 'ایندکس‌ها: idx_profiles_last_seen_at, idx_profiles_is_online';
    RAISE NOTICE 'تابع: get_online_users()';
    RAISE NOTICE 'حالا سیستم حضور کاربران آماده است!';
END $$; 