-- =====================================================
-- پاکسازی سیستم چت - GymAI Pro
-- =====================================================

-- مرحله 1: حذف جداول موجود
DROP TABLE IF EXISTS chat_messages CASCADE;
DROP TABLE IF EXISTS chat_conversations CASCADE;
DROP TABLE IF EXISTS chat_rooms CASCADE;
DROP TABLE IF EXISTS chat_room_members CASCADE;

-- مرحله 2: حذف توابع موجود
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;
DROP FUNCTION IF EXISTS mark_conversation_as_read(UUID) CASCADE;
DROP FUNCTION IF EXISTS get_unread_message_count() CASCADE;
DROP FUNCTION IF EXISTS update_chat_conversation() CASCADE;

-- مرحله 3: حذف ایندکس‌های موجود
DROP INDEX IF EXISTS idx_chat_messages_sender_receiver;
DROP INDEX IF EXISTS idx_chat_messages_created_at;
DROP INDEX IF EXISTS idx_chat_messages_is_deleted;
DROP INDEX IF EXISTS idx_chat_conversations_user_id;
DROP INDEX IF EXISTS idx_chat_conversations_last_message_at;

-- مرحله 4: حذف تریگرها
DROP TRIGGER IF EXISTS update_chat_messages_updated_at ON chat_messages;
DROP TRIGGER IF EXISTS update_chat_conversations_updated_at ON chat_conversations;
DROP TRIGGER IF EXISTS update_chat_rooms_updated_at ON chat_rooms;
DROP TRIGGER IF EXISTS update_conversation_on_message ON chat_messages;

-- مرحله 5: حذف سیاست‌های RLS
DROP POLICY IF EXISTS "Users can view messages they sent or received" ON chat_messages;
DROP POLICY IF EXISTS "Users can insert their own messages" ON chat_messages;
DROP POLICY IF EXISTS "Users can update their own messages" ON chat_messages;
DROP POLICY IF EXISTS "Users can delete their own messages" ON chat_messages;

DROP POLICY IF EXISTS "Users can view their own conversations" ON chat_conversations;
DROP POLICY IF EXISTS "System can insert conversations" ON chat_conversations;
DROP POLICY IF EXISTS "System can update conversations" ON chat_conversations;

DROP POLICY IF EXISTS "Users can view rooms they are members of" ON chat_rooms;
DROP POLICY IF EXISTS "Users can create rooms" ON chat_rooms;
DROP POLICY IF EXISTS "Room creators can update rooms" ON chat_rooms;

DROP POLICY IF EXISTS "Users can view room members" ON chat_room_members;
DROP POLICY IF EXISTS "Room admins can manage members" ON chat_room_members;

-- =====================================================
-- پیام تأیید
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE 'تمامی جداول، توابع، تریگرها و سیاست‌های چت حذف شدند.';
    RAISE NOTICE 'حالا می‌توانید فایل chat_basic_setup.sql را اجرا کنید.';
END $$;

-- =====================================================
-- نکات:
-- 1. این فایل تمام داده‌های چت را حذف می‌کند
-- 2. قبل از اجرا از داده‌های مهم backup بگیرید
-- 3. بعد از اجرای این فایل، فایل setup را اجرا کنید
-- ===================================================== 