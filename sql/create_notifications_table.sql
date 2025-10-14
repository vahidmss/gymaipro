-- Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('welcome', 'workout', 'reminder', 'achievement', 'message', 'payment', 'system')),
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    data JSONB DEFAULT '{}'::jsonb, -- Additional data for specific notification types
    expires_at TIMESTAMP WITH TIME ZONE, -- Optional expiration date
    action_url TEXT, -- Optional URL to navigate when notification is clicked
    priority INTEGER DEFAULT 1 CHECK (priority >= 1 AND priority <= 5) -- 1=low, 5=high
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON notifications(user_id, is_read) WHERE is_read = FALSE;

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_notifications_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_notifications_updated_at
    BEFORE UPDATE ON notifications
    FOR EACH ROW
    EXECUTE FUNCTION update_notifications_updated_at();

-- Enable RLS (Row Level Security)
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view their own notifications" ON notifications
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications" ON notifications
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "System can insert notifications" ON notifications
    FOR INSERT WITH CHECK (true);

-- Create function to get unread notification count
CREATE OR REPLACE FUNCTION get_unread_notification_count(user_uuid UUID)
RETURNS INTEGER AS $$
BEGIN
    RETURN (
        SELECT COUNT(*)
        FROM notifications
        WHERE user_id = user_uuid AND is_read = FALSE
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to mark notifications as read
CREATE OR REPLACE FUNCTION mark_notification_as_read(notification_uuid UUID, user_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE notifications
    SET is_read = TRUE, updated_at = NOW()
    WHERE id = notification_uuid AND user_id = user_uuid;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to mark all notifications as read for a user
CREATE OR REPLACE FUNCTION mark_all_notifications_as_read(user_uuid UUID)
RETURNS INTEGER AS $$
DECLARE
    updated_count INTEGER;
BEGIN
    UPDATE notifications
    SET is_read = TRUE, updated_at = NOW()
    WHERE user_id = user_uuid AND is_read = FALSE;
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RETURN updated_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Insert some sample notifications for testing
INSERT INTO notifications (user_id, title, message, type, priority) VALUES
    ((SELECT id FROM auth.users LIMIT 1), 'خوش آمدید به جیم‌آی پرو!', 'حالا می‌توانید از تمام امکانات اپلیکیشن استفاده کنید.', 'welcome', 3),
    ((SELECT id FROM auth.users LIMIT 1), 'برنامه تمرینی جدید', 'برنامه تمرینی هفته جدید شما آماده است.', 'workout', 2),
    ((SELECT id FROM auth.users LIMIT 1), 'یادآوری تمرین', 'زمان تمرین شما فرا رسیده است.', 'reminder', 4),
    ((SELECT id FROM auth.users LIMIT 1), 'دستاورد جدید!', 'تبریک! شما 10 روز متوالی تمرین کرده‌اید.', 'achievement', 5),
    ((SELECT id FROM auth.users LIMIT 1), 'پیام جدید', 'شما یک پیام جدید دریافت کرده‌اید.', 'message', 2);
