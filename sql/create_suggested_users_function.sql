-- =============================================
-- Function برای دریافت کاربران پیشنهادی
-- =============================================

CREATE OR REPLACE FUNCTION get_suggested_users(
    current_user_id UUID,
    limit_count INTEGER DEFAULT 10
)
RETURNS TABLE (
    id UUID,
    username TEXT,
    full_name TEXT,
    avatar_url TEXT,
    is_online BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.username,
        CONCAT(COALESCE(p.first_name, ''), ' ', COALESCE(p.last_name, '')) as full_name,
        p.avatar_url,
        p.is_online
    FROM profiles p
    WHERE p.id != current_user_id
    AND p.id NOT IN (
        -- کاربرانی که قبلاً دوست هستند
        SELECT uf.friend_id 
        FROM user_friends uf 
        WHERE uf.user_id = current_user_id
        UNION
        -- کاربرانی که درخواست دوستی ارسال کرده‌اند
        SELECT fr.requested_id 
        FROM friendship_requests fr 
        WHERE fr.requester_id = current_user_id
        UNION
        -- کاربرانی که درخواست دوستی دریافت کرده‌اند
        SELECT fr.requester_id 
        FROM friendship_requests fr 
        WHERE fr.requested_id = current_user_id
        UNION
        -- کاربرانی که بلاک شده‌اند
        SELECT ub.blocked_id 
        FROM user_blocks ub 
        WHERE ub.blocker_id = current_user_id
    )
    ORDER BY p.is_online DESC, p.created_at DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- Grant permissions
-- =============================================

GRANT EXECUTE ON FUNCTION get_suggested_users(UUID, INTEGER) TO authenticated;
