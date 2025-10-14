-- Function to delete all read notifications for a user
CREATE OR REPLACE FUNCTION delete_read_notifications(user_uuid UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    -- Delete all read notifications for the user
    DELETE FROM public.notifications 
    WHERE user_id = user_uuid 
    AND is_read = true;
    
    -- Get the count of deleted rows
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    RETURN deleted_count;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION delete_read_notifications(UUID) TO authenticated;
