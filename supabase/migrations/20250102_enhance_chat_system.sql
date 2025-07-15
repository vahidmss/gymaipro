-- Enhanced Chat System Migration
-- This migration improves the existing chat system with better structure and features

-- First, let's clean up any existing chat tables to avoid conflicts
DROP TABLE IF EXISTS chat_messages CASCADE;
DROP VIEW IF EXISTS chat_conversations CASCADE;
DROP FUNCTION IF EXISTS mark_messages_as_read CASCADE;

-- Create enhanced chat_messages table
CREATE TABLE IF NOT EXISTS chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  receiver_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  message_type TEXT NOT NULL DEFAULT 'text', -- text, image, file, voice
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  is_read BOOLEAN NOT NULL DEFAULT false,
  is_deleted BOOLEAN NOT NULL DEFAULT false,
  attachment_url TEXT,
  attachment_type TEXT,
  attachment_name TEXT,
  attachment_size INTEGER,
  
  CONSTRAINT sender_not_receiver CHECK (sender_id != receiver_id),
  CONSTRAINT valid_message_type CHECK (message_type IN ('text', 'image', 'file', 'voice'))
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_chat_messages_sender_id ON chat_messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_receiver_id ON chat_messages(receiver_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at ON chat_messages(created_at);
CREATE INDEX IF NOT EXISTS idx_chat_messages_participants ON chat_messages(sender_id, receiver_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_conversation ON chat_messages(LEAST(sender_id, receiver_id), GREATEST(sender_id, receiver_id));

-- Create enhanced chat_conversations view
CREATE OR REPLACE VIEW chat_conversations AS
WITH last_messages AS (
  SELECT 
    DISTINCT ON (
      LEAST(sender_id, receiver_id), 
      GREATEST(sender_id, receiver_id)
    ) 
    id,
    sender_id,
    receiver_id,
    message,
    message_type,
    created_at,
    is_read,
    is_deleted
  FROM 
    chat_messages
  WHERE 
    is_deleted = false
  ORDER BY 
    LEAST(sender_id, receiver_id), 
    GREATEST(sender_id, receiver_id), 
    created_at DESC
),
unread_counts AS (
  SELECT 
    LEAST(sender_id, receiver_id) as user1,
    GREATEST(sender_id, receiver_id) as user2,
    COUNT(*) as unread_count
  FROM 
    chat_messages
  WHERE 
    is_read = false 
    AND is_deleted = false
    AND receiver_id = auth.uid()
  GROUP BY 
    LEAST(sender_id, receiver_id), 
    GREATEST(sender_id, receiver_id)
)
SELECT 
  lm.id,
  p1.id as user_id,
  p2.id as other_user_id,
  COALESCE(
    NULLIF(CONCAT_WS(' ', p2.first_name, p2.last_name), ' '), 
    p2.username, 
    'کاربر'
  ) as other_user_name,
  p2.avatar_url as other_user_avatar,
  p2.role as other_user_role,
  lm.created_at as last_message_at,
  lm.message as last_message_text,
  lm.message_type as last_message_type,
  COALESCE(uc.unread_count, 0) as unread_count,
  lm.sender_id = p1.id as is_sent_by_me
FROM 
  last_messages lm
JOIN 
  profiles p1 ON (lm.sender_id = p1.id OR lm.receiver_id = p1.id)
JOIN 
  profiles p2 ON (
    (lm.sender_id = p2.id OR lm.receiver_id = p2.id) AND 
    p1.id != p2.id
  )
LEFT JOIN 
  unread_counts uc ON (
    (uc.user1 = p1.id AND uc.user2 = p2.id) OR 
    (uc.user1 = p2.id AND uc.user2 = p1.id)
  )
WHERE 
  p1.id = auth.uid()
ORDER BY 
  lm.created_at DESC;

-- Create chat_rooms table for group chats (future feature)
CREATE TABLE IF NOT EXISTS chat_rooms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  room_type TEXT NOT NULL DEFAULT 'direct', -- direct, group
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  is_active BOOLEAN NOT NULL DEFAULT true,
  
  CONSTRAINT valid_room_type CHECK (room_type IN ('direct', 'group'))
);

-- Create chat_room_participants table
CREATE TABLE IF NOT EXISTS chat_room_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id UUID NOT NULL REFERENCES chat_rooms(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  is_admin BOOLEAN NOT NULL DEFAULT false,
  is_muted BOOLEAN NOT NULL DEFAULT false,
  
  UNIQUE(room_id, user_id)
);

-- Add RLS policies for chat_messages
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- Users can only see messages they've sent or received
CREATE POLICY "Users can see their own messages" ON chat_messages
  FOR SELECT USING (
    auth.uid() = sender_id OR auth.uid() = receiver_id
  );

-- Users can only insert messages they're sending
CREATE POLICY "Users can insert their own messages" ON chat_messages
  FOR INSERT WITH CHECK (auth.uid() = sender_id);

-- Users can only update messages they've sent (for editing) or received (for marking as read)
CREATE POLICY "Users can update their own messages" ON chat_messages
  FOR UPDATE USING (
    auth.uid() = sender_id OR auth.uid() = receiver_id
  );

-- Users can only delete messages they've sent
CREATE POLICY "Users can delete their own messages" ON chat_messages
  FOR DELETE USING (auth.uid() = sender_id);

-- Add RLS policies for chat_rooms
ALTER TABLE chat_rooms ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view rooms they participate in" ON chat_rooms
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM chat_room_participants 
      WHERE room_id = chat_rooms.id AND user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create rooms" ON chat_rooms
  FOR INSERT WITH CHECK (auth.uid() = created_by);

-- Add RLS policies for chat_room_participants
ALTER TABLE chat_room_participants ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view room participants" ON chat_room_participants
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM chat_room_participants crp2
      WHERE crp2.room_id = chat_room_participants.room_id 
      AND crp2.user_id = auth.uid()
    )
  );

CREATE POLICY "Room creators can manage participants" ON chat_room_participants
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM chat_rooms 
      WHERE id = chat_room_participants.room_id 
      AND created_by = auth.uid()
    )
  );

-- Enable realtime for chat tables
ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE chat_rooms;
ALTER PUBLICATION supabase_realtime ADD TABLE chat_room_participants;

-- Create enhanced function to mark messages as read
CREATE OR REPLACE FUNCTION mark_messages_as_read(p_sender_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE chat_messages
  SET is_read = true, updated_at = now()
  WHERE receiver_id = auth.uid() 
    AND sender_id = p_sender_id 
    AND is_read = false
    AND is_deleted = false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to get unread message count
CREATE OR REPLACE FUNCTION get_unread_message_count()
RETURNS INTEGER AS $$
BEGIN
  RETURN (
    SELECT COUNT(*)
    FROM chat_messages
    WHERE receiver_id = auth.uid() 
      AND is_read = false 
      AND is_deleted = false
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to mark conversation as read
CREATE OR REPLACE FUNCTION mark_conversation_as_read(p_other_user_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE chat_messages
  SET is_read = true, updated_at = now()
  WHERE receiver_id = auth.uid() 
    AND sender_id = p_other_user_id 
    AND is_read = false
    AND is_deleted = false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for updated_at on chat_messages
CREATE OR REPLACE FUNCTION update_chat_messages_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_chat_messages_updated_at
  BEFORE UPDATE ON chat_messages
  FOR EACH ROW
  EXECUTE FUNCTION update_chat_messages_updated_at();

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON chat_messages TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON chat_rooms TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON chat_room_participants TO authenticated;
GRANT SELECT ON chat_conversations TO authenticated;

-- Insert some sample data for testing (optional)
-- This will be removed in production
INSERT INTO chat_messages (sender_id, receiver_id, message, message_type)
SELECT 
  p1.id as sender_id,
  p2.id as receiver_id,
  'سلام! چطور هستید؟' as message,
  'text' as message_type
FROM profiles p1, profiles p2 
WHERE p1.role = 'trainer' 
  AND p2.role = 'athlete' 
  AND p1.id != p2.id
LIMIT 5; 