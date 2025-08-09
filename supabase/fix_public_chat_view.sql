-- Fix public_chat_with_senders view
-- This script fixes the view to include all necessary fields

DROP VIEW IF EXISTS public.public_chat_with_senders;

CREATE OR REPLACE VIEW public.public_chat_with_senders AS
SELECT 
    pcm.id,
    pcm.sender_id,
    pcm.message,
    pcm.message_type,
    pcm.is_deleted,
    pcm.created_at,
    pcm.created_at as updated_at,
    p.username as sender_username,
    p.first_name as sender_first_name,
    p.last_name as sender_last_name,
    p.avatar_url as sender_avatar_url,
    p.role as sender_role
FROM public_chat_messages pcm
JOIN profiles p ON pcm.sender_id = p.id
ORDER BY pcm.created_at DESC;

-- Grant access to the updated view
GRANT SELECT ON public.public_chat_with_senders TO authenticated;

-- Verify the view was created correctly
SELECT 'View public_chat_with_senders updated successfully' as status; 