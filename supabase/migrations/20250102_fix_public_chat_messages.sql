-- حذف جدول قبلی اگر وجود دارد
DROP TABLE IF EXISTS public_chat_messages CASCADE;

-- ایجاد جدول public_chat_messages جدید
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

-- RLS برای public_chat_messages
ALTER TABLE public_chat_messages ENABLE ROW LEVEL SECURITY;

-- Policy برای مشاهده پیام‌ها
CREATE POLICY "Anyone can view public messages" ON public_chat_messages
  FOR SELECT USING (is_deleted = FALSE);

-- Policy برای ارسال پیام
CREATE POLICY "Authenticated users can send public messages" ON public_chat_messages
  FOR INSERT WITH CHECK (auth.uid() = sender_id);

-- Policy برای ویرایش پیام‌های خود
CREATE POLICY "Users can update their own messages" ON public_chat_messages
  FOR UPDATE USING (auth.uid() = sender_id);

-- Policy برای حذف پیام‌های خود
CREATE POLICY "Users can delete their own messages" ON public_chat_messages
  FOR DELETE USING (auth.uid() = sender_id);

-- Function برای پر کردن خودکار اطلاعات کاربر
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

-- Trigger برای پر کردن خودکار اطلاعات کاربر
DROP TRIGGER IF EXISTS trigger_populate_user_info_public_chat ON public_chat_messages;
CREATE TRIGGER trigger_populate_user_info_public_chat
  BEFORE INSERT ON public_chat_messages
  FOR EACH ROW
  EXECUTE FUNCTION populate_user_info_in_public_chat();

-- ایجاد index برای بهبود performance
CREATE INDEX idx_public_chat_messages_created_at ON public_chat_messages(created_at DESC);
CREATE INDEX idx_public_chat_messages_sender_id ON public_chat_messages(sender_id);
CREATE INDEX idx_public_chat_messages_is_deleted ON public_chat_messages(is_deleted);

-- Function برای به‌روزرسانی updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger برای به‌روزرسانی خودکار updated_at
DROP TRIGGER IF EXISTS trigger_update_public_chat_messages_updated_at ON public_chat_messages;
CREATE TRIGGER trigger_update_public_chat_messages_updated_at
  BEFORE UPDATE ON public_chat_messages
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column(); 