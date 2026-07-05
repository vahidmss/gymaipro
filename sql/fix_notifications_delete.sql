-- Fix: users could not delete notifications (missing DELETE RLS + RPC helpers)

-- RLS: allow users to delete their own rows
DROP POLICY IF EXISTS "Users can delete their own notifications" ON notifications;
CREATE POLICY "Users can delete their own notifications" ON notifications
    FOR DELETE USING (auth.uid() = user_id);

-- Single notification delete (matches mark_notification_as_read pattern)
CREATE OR REPLACE FUNCTION delete_notification(notification_uuid UUID, user_uuid UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    DELETE FROM notifications
    WHERE id = notification_uuid AND user_id = user_uuid;

    RETURN FOUND;
END;
$$;

GRANT EXECUTE ON FUNCTION delete_notification(UUID, UUID) TO authenticated;

-- Bulk delete read notifications (ensure function exists / is up to date)
CREATE OR REPLACE FUNCTION delete_read_notifications(user_uuid UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM notifications
    WHERE user_id = user_uuid AND is_read = true;

    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$;

GRANT EXECUTE ON FUNCTION delete_read_notifications(UUID) TO authenticated;
