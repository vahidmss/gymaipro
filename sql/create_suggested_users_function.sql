-- Function برای دریافت کاربران پیشنهادی

DROP FUNCTION IF EXISTS get_suggested_users(UUID, INTEGER);

CREATE OR REPLACE FUNCTION get_suggested_users(
    current_user_id UUID,
    limit_count INTEGER DEFAULT 10
)
RETURNS TABLE (
    id UUID,
    username TEXT,
    full_name TEXT,
    avatar_url TEXT,
    is_online BOOLEAN,
    last_seen_at TIMESTAMPTZ,
    last_active_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.username,
        CONCAT(COALESCE(p.first_name, ''), ' ', COALESCE(p.last_name, '')) as full_name,
        p.avatar_url,
        (
          COALESCE(p.last_seen_at, p.last_active_at)
            > (NOW() - INTERVAL '5 minutes')
        ) as is_online,
        p.last_seen_at,
        p.last_active_at
    FROM profiles p
    WHERE p.id != current_user_id
    AND p.id NOT IN (
        SELECT uf.friend_id 
        FROM user_friends uf 
        WHERE uf.user_id = current_user_id
        UNION
        SELECT fr.requested_id 
        FROM friendship_requests fr 
        WHERE fr.requester_id = current_user_id
        UNION
        SELECT fr.requester_id 
        FROM friendship_requests fr 
        WHERE fr.requested_id = current_user_id
        UNION
        SELECT ub.blocked_id 
        FROM user_blocks ub 
        WHERE ub.blocker_id = current_user_id
    )
    ORDER BY
      (COALESCE(p.last_seen_at, p.last_active_at) > (NOW() - INTERVAL '5 minutes')) DESC,
      p.created_at DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_suggested_users(UUID, INTEGER) TO authenticated;
