-- =============================================
-- سیستم دوستی - Friendship System Tables
-- =============================================

-- جدول درخواست‌های دوستی
CREATE TABLE IF NOT EXISTS friendship_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    requester_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    requested_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'cancelled')),
    message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(requester_id, requested_id)
);

-- جدول دوستان (برای دوستی‌های تایید شده)
CREATE TABLE IF NOT EXISTS user_friends (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    friend_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, friend_id),
    CHECK (user_id != friend_id)
);

-- جدول بلاک کردن کاربران
CREATE TABLE IF NOT EXISTS user_blocks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    blocker_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    blocked_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(blocker_id, blocked_id),
    CHECK (blocker_id != blocked_id)
);

-- =============================================
-- Indexes برای بهبود عملکرد
-- =============================================

-- Indexes برای friendship_requests
CREATE INDEX IF NOT EXISTS idx_friendship_requests_requester ON friendship_requests(requester_id);
CREATE INDEX IF NOT EXISTS idx_friendship_requests_requested ON friendship_requests(requested_id);
CREATE INDEX IF NOT EXISTS idx_friendship_requests_status ON friendship_requests(status);
CREATE INDEX IF NOT EXISTS idx_friendship_requests_created_at ON friendship_requests(created_at);

-- Indexes برای user_friends
CREATE INDEX IF NOT EXISTS idx_user_friends_user_id ON user_friends(user_id);
CREATE INDEX IF NOT EXISTS idx_user_friends_friend_id ON user_friends(friend_id);
CREATE INDEX IF NOT EXISTS idx_user_friends_created_at ON user_friends(created_at);

-- Indexes برای user_blocks
CREATE INDEX IF NOT EXISTS idx_user_blocks_blocker ON user_blocks(blocker_id);
CREATE INDEX IF NOT EXISTS idx_user_blocks_blocked ON user_blocks(blocked_id);

-- =============================================
-- Row Level Security (RLS) Policies
-- =============================================

-- فعال کردن RLS
ALTER TABLE friendship_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_friends ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_blocks ENABLE ROW LEVEL SECURITY;

-- Policies برای friendship_requests
CREATE POLICY "Users can view their own friendship requests" ON friendship_requests
    FOR SELECT USING (auth.uid() = requester_id OR auth.uid() = requested_id);

CREATE POLICY "Users can insert their own friendship requests" ON friendship_requests
    FOR INSERT WITH CHECK (auth.uid() = requester_id);

CREATE POLICY "Users can update their own friendship requests" ON friendship_requests
    FOR UPDATE USING (auth.uid() = requester_id OR auth.uid() = requested_id);

CREATE POLICY "Users can delete their own friendship requests" ON friendship_requests
    FOR DELETE USING (auth.uid() = requester_id OR auth.uid() = requested_id);

-- Policies برای user_friends
CREATE POLICY "Users can view their own friendships" ON user_friends
    FOR SELECT USING (auth.uid() = user_id OR auth.uid() = friend_id);

CREATE POLICY "Users can insert friendships for themselves" ON user_friends
    FOR INSERT WITH CHECK (auth.uid() = user_id OR auth.uid() = friend_id);

CREATE POLICY "Users can delete their own friendships" ON user_friends
    FOR DELETE USING (auth.uid() = user_id OR auth.uid() = friend_id);

-- Policies برای user_blocks
CREATE POLICY "Users can view their own blocks" ON user_blocks
    FOR SELECT USING (auth.uid() = blocker_id);

CREATE POLICY "Users can insert blocks for themselves" ON user_blocks
    FOR INSERT WITH CHECK (auth.uid() = blocker_id);

CREATE POLICY "Users can delete their own blocks" ON user_blocks
    FOR DELETE USING (auth.uid() = blocker_id);

-- =============================================
-- Functions و Triggers
-- =============================================

-- Function برای به‌روزرسانی updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger برای friendship_requests
CREATE TRIGGER update_friendship_requests_updated_at
    BEFORE UPDATE ON friendship_requests
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Function برای ایجاد دوستی متقابل
CREATE OR REPLACE FUNCTION create_mutual_friendship()
RETURNS TRIGGER AS $$
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
$$ language 'plpgsql';

-- Trigger برای ایجاد دوستی متقابل
CREATE TRIGGER create_mutual_friendship_trigger
    AFTER UPDATE ON friendship_requests
    FOR EACH ROW
    EXECUTE FUNCTION create_mutual_friendship();

-- Function برای حذف دوستی متقابل
CREATE OR REPLACE FUNCTION remove_mutual_friendship()
RETURNS TRIGGER AS $$
BEGIN
    -- حذف دوستی متقابل
    DELETE FROM user_friends 
    WHERE (user_id = OLD.user_id AND friend_id = OLD.friend_id)
       OR (user_id = OLD.friend_id AND friend_id = OLD.user_id);
    
    RETURN OLD;
END;
$$ language 'plpgsql';

-- Trigger برای حذف دوستی متقابل
CREATE TRIGGER remove_mutual_friendship_trigger
    AFTER DELETE ON user_friends
    FOR EACH ROW
    EXECUTE FUNCTION remove_mutual_friendship();

-- =============================================
-- Views برای نمایش بهتر داده‌ها
-- =============================================

-- View برای نمایش درخواست‌های دوستی با اطلاعات کاربر
CREATE OR REPLACE VIEW friendship_requests_with_users AS
SELECT 
    fr.*,
    requester.username as requester_username,
    CONCAT(COALESCE(requester.first_name, ''), ' ', COALESCE(requester.last_name, '')) as requester_full_name,
    requester.avatar_url as requester_avatar,
    requested.username as requested_username,
    CONCAT(COALESCE(requested.first_name, ''), ' ', COALESCE(requested.last_name, '')) as requested_full_name,
    requested.avatar_url as requested_avatar
FROM friendship_requests fr
LEFT JOIN profiles requester ON fr.requester_id = requester.id
LEFT JOIN profiles requested ON fr.requested_id = requested.id;

-- View برای نمایش دوستان با اطلاعات کاربر
CREATE OR REPLACE VIEW user_friends_with_info AS
SELECT 
    uf.*,
    friend.username as friend_username,
    CONCAT(COALESCE(friend.first_name, ''), ' ', COALESCE(friend.last_name, '')) as friend_full_name,
    friend.avatar_url as friend_avatar,
    friend.is_online as friend_is_online
FROM user_friends uf
LEFT JOIN profiles friend ON uf.friend_id = friend.id;

-- =============================================
-- Sample Data (اختیاری - برای تست)
-- =============================================

-- درج داده‌های نمونه (فقط برای تست)
-- INSERT INTO friendship_requests (requester_id, requested_id, message) 
-- VALUES 
--     ('user1-uuid', 'user2-uuid', 'سلام! دوست می‌شویم؟'),
--     ('user2-uuid', 'user3-uuid', 'بیا دوست بشیم');

-- =============================================
-- Comments
-- =============================================

COMMENT ON TABLE friendship_requests IS 'جدول درخواست‌های دوستی بین کاربران';
COMMENT ON TABLE user_friends IS 'جدول دوستی‌های تایید شده بین کاربران';
COMMENT ON TABLE user_blocks IS 'جدول بلاک کردن کاربران';

COMMENT ON COLUMN friendship_requests.status IS 'وضعیت درخواست: pending, accepted, rejected, cancelled';
COMMENT ON COLUMN friendship_requests.message IS 'پیام همراه درخواست دوستی';
COMMENT ON COLUMN user_friends.user_id IS 'شناسه کاربر';
COMMENT ON COLUMN user_friends.friend_id IS 'شناسه دوست';
COMMENT ON COLUMN user_blocks.blocker_id IS 'شناسه کاربر بلاک کننده';
COMMENT ON COLUMN user_blocks.blocked_id IS 'شناسه کاربر بلاک شده';
