-- =============================================
-- Fix Friendship Trigger RLS Issue
-- =============================================
-- مشکل: تابع create_mutual_friendship از SECURITY DEFINER استفاده نمی‌کند
-- این باعث می‌شود که RLS policies مانع insert در user_friends شوند
-- راه حل: اضافه کردن SECURITY DEFINER به تابع

-- حذف تابع قبلی
DROP FUNCTION IF EXISTS create_mutual_friendship() CASCADE;

-- ایجاد تابع جدید با SECURITY DEFINER
CREATE OR REPLACE FUNCTION create_mutual_friendship()
RETURNS TRIGGER 
SECURITY DEFINER -- اجرا با دسترسی‌های صاحب تابع (postgres) برای bypass کردن RLS
SET search_path = public
AS $$
BEGIN
    -- اگر درخواست تایید شد، دوستی متقابل ایجاد کن
    IF NEW.status = 'accepted' AND OLD.status != 'accepted' THEN
        -- اضافه کردن دوستی از requester به requested
        INSERT INTO user_friends (user_id, friend_id)
        VALUES (NEW.requester_id, NEW.requested_id)
        ON CONFLICT (user_id, friend_id) DO NOTHING;
        
        -- اضافه کردن دوستی از requested به requester
        INSERT INTO user_friends (user_id, friend_id)
        VALUES (NEW.requested_id, NEW.requester_id)
        ON CONFLICT (user_id, friend_id) DO NOTHING;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ایجاد مجدد trigger
DROP TRIGGER IF EXISTS create_mutual_friendship_trigger ON friendship_requests;

CREATE TRIGGER create_mutual_friendship_trigger
    AFTER UPDATE ON friendship_requests
    FOR EACH ROW
    EXECUTE FUNCTION create_mutual_friendship();

-- =============================================
-- بررسی و تست
-- =============================================
-- برای تست، می‌توانید یک درخواست دوستی را تایید کنید و بررسی کنید که
-- دو رکورد در user_friends ایجاد شده است (یکی برای هر کاربر)
