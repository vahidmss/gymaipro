-- Migration برای رفع کامل مشکلات چت همگانی
-- تاریخ: 2025-01-04

-- 1. حذف کامل جدول قبلی و همه وابستگی‌ها
DROP TABLE IF EXISTS public_chat_messages CASCADE;
DROP FUNCTION IF EXISTS populate_user_info_in_public_chat() CASCADE;
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;

-- 2. ایجاد مجدد جدول public_chat_messages
CREATE TABLE public_chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  sender_name TEXT,
  sender_avatar TEXT,
  sender_role TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  is_deleted BOOLEAN DEFAULT FALSE
);

-- 3. فعال‌سازی RLS
ALTER TABLE public_chat_messages ENABLE ROW LEVEL SECURITY;

-- 4. حذف policies قبلی (اگر وجود دارند)
DROP POLICY IF EXISTS "Anyone can view public messages" ON public_chat_messages;
DROP POLICY IF EXISTS "Authenticated users can send public messages" ON public_chat_messages;
DROP POLICY IF EXISTS "Users can update their own messages" ON public_chat_messages;
DROP POLICY IF EXISTS "Users can delete their own messages" ON public_chat_messages;

-- 5. ایجاد policies جدید
-- همه کاربران (حتی anonymous) می‌توانند پیام‌ها را ببینند
CREATE POLICY "Anyone can view public messages" ON public_chat_messages
  FOR SELECT USING (is_deleted = FALSE);

-- فقط کاربران authenticated می‌توانند پیام ارسال کنند
CREATE POLICY "Authenticated users can send public messages" ON public_chat_messages
  FOR INSERT WITH CHECK (auth.uid() = sender_id);

-- کاربران فقط می‌توانند پیام‌های خود را ویرایش کنند
CREATE POLICY "Users can update their own messages" ON public_chat_messages
  FOR UPDATE USING (auth.uid() = sender_id);

-- کاربران فقط می‌توانند پیام‌های خود را حذف کنند
CREATE POLICY "Users can delete their own messages" ON public_chat_messages
  FOR DELETE USING (auth.uid() = sender_id);

-- 6. Function برای پر کردن خودکار اطلاعات کاربر
CREATE OR REPLACE FUNCTION populate_user_info_in_public_chat()
RETURNS TRIGGER AS $$
BEGIN
  -- دریافت اطلاعات کاربر از جدول profiles
  SELECT 
    CASE 
      WHEN first_name IS NOT NULL AND last_name IS NOT NULL 
        THEN first_name || ' ' || last_name
      WHEN first_name IS NOT NULL 
        THEN first_name
      WHEN last_name IS NOT NULL 
        THEN last_name
      ELSE 
        'کاربر ناشناس'
    END,
    avatar_url,
    role
  INTO NEW.sender_name, NEW.sender_avatar, NEW.sender_role
  FROM profiles 
  WHERE id = NEW.sender_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 7. Function برای به‌روزرسانی updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 8. Trigger برای پر کردن خودکار اطلاعات کاربر
DROP TRIGGER IF EXISTS trigger_populate_user_info_public_chat ON public_chat_messages;
CREATE TRIGGER trigger_populate_user_info_public_chat
  BEFORE INSERT ON public_chat_messages
  FOR EACH ROW
  EXECUTE FUNCTION populate_user_info_in_public_chat();

-- 9. Trigger برای به‌روزرسانی خودکار updated_at
DROP TRIGGER IF EXISTS trigger_update_public_chat_messages_updated_at ON public_chat_messages;
CREATE TRIGGER trigger_update_public_chat_messages_updated_at
  BEFORE UPDATE ON public_chat_messages
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- 10. ایجاد indexes برای بهبود performance
CREATE INDEX idx_public_chat_messages_created_at ON public_chat_messages(created_at DESC);
CREATE INDEX idx_public_chat_messages_sender_id ON public_chat_messages(sender_id);
CREATE INDEX idx_public_chat_messages_is_deleted ON public_chat_messages(is_deleted);

-- 11. فعال‌سازی realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public_chat_messages;

-- 12. Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON public_chat_messages TO authenticated;
GRANT SELECT ON public_chat_messages TO anon;

-- 13. اضافه کردن چند پیام تست (اختیاری)
INSERT INTO public_chat_messages (sender_id, message, sender_name, sender_role)
SELECT 
  p.id,
  'سلام! به چت همگانی خوش آمدید! 👋' as message,
  CASE 
    WHEN p.first_name IS NOT NULL AND p.last_name IS NOT NULL 
      THEN p.first_name || ' ' || p.last_name
    WHEN p.first_name IS NOT NULL 
      THEN p.first_name
    WHEN p.last_name IS NOT NULL 
      THEN p.last_name
    ELSE 'کاربر ناشناس'
  END as sender_name,
  p.role as sender_role
FROM profiles p
WHERE p.role IN ('trainer', 'athlete')
LIMIT 3; 