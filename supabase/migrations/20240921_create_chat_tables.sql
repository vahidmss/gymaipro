-- Create chat messages table
CREATE TABLE IF NOT EXISTS chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  receiver_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  is_read BOOLEAN NOT NULL DEFAULT false,
  attachment_url TEXT,
  attachment_type TEXT,
  
  CONSTRAINT sender_not_receiver CHECK (sender_id != receiver_id)
);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_chat_messages_sender_id ON chat_messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_receiver_id ON chat_messages(receiver_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at ON chat_messages(created_at);
CREATE INDEX IF NOT EXISTS idx_chat_messages_participants ON chat_messages(sender_id, receiver_id);

-- Create a view for recent conversations
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
    created_at,
    is_read
  FROM 
    chat_messages
  ORDER BY 
    LEAST(sender_id, receiver_id), 
    GREATEST(sender_id, receiver_id), 
    created_at DESC
)
SELECT 
  lm.id,
  p1.id as user_id,
  p2.id as other_user_id,
  p2.full_name as other_user_name,
  p2.avatar_url as other_user_avatar,
  lm.created_at as last_message_at,
  lm.message as last_message_text,
  NOT lm.is_read AND lm.receiver_id = p1.id as has_unread
FROM 
  last_messages lm
JOIN 
  profiles p1 ON (lm.sender_id = p1.id OR lm.receiver_id = p1.id)
JOIN 
  profiles p2 ON (
    (lm.sender_id = p2.id OR lm.receiver_id = p2.id) AND 
    p1.id != p2.id
  )
ORDER BY 
  lm.created_at DESC;

-- Add RLS policies for chat_messages
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- Users can only see messages they've sent or received
CREATE POLICY "Users can see their own messages" ON chat_messages
  FOR SELECT USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

-- Users can only insert messages they're sending
CREATE POLICY "Users can insert their own messages" ON chat_messages
  FOR INSERT WITH CHECK (auth.uid() = sender_id);

-- Users can only update messages they've received (for marking as read)
CREATE POLICY "Users can update messages they've received" ON chat_messages
  FOR UPDATE USING (auth.uid() = receiver_id)
  WITH CHECK (
    -- Only allow updating the is_read field
    is_read = true AND
    OLD.sender_id = sender_id AND
    OLD.receiver_id = receiver_id AND
    OLD.message = message AND
    OLD.created_at = created_at AND
    (OLD.attachment_url IS NULL AND attachment_url IS NULL OR
     OLD.attachment_url = attachment_url) AND
    (OLD.attachment_type IS NULL AND attachment_type IS NULL OR
     OLD.attachment_type = attachment_type)
  );

-- Users can only delete messages they've sent
CREATE POLICY "Users can delete their own messages" ON chat_messages
  FOR DELETE USING (auth.uid() = sender_id);

-- Enable realtime for chat messages
ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;

-- Create a function to mark messages as read
CREATE OR REPLACE FUNCTION mark_messages_as_read(p_sender_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE chat_messages
  SET is_read = true
  WHERE receiver_id = auth.uid() AND sender_id = p_sender_id AND is_read = false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER; 