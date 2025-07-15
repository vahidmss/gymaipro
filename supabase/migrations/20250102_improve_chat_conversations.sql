-- Improve chat_conversations table to show proper user names
-- Create a function to update conversation names when profile is updated
CREATE OR REPLACE FUNCTION update_conversation_names()
RETURNS TRIGGER AS $$
BEGIN
  -- Update conversations where this user is the other user
  UPDATE chat_conversations 
  SET other_user_name = CASE 
    WHEN NEW.first_name IS NOT NULL AND NEW.last_name IS NOT NULL 
      THEN NEW.first_name || ' ' || NEW.last_name
    WHEN NEW.first_name IS NOT NULL 
      THEN NEW.first_name
    WHEN NEW.last_name IS NOT NULL 
      THEN NEW.last_name
    ELSE 
      'کاربر ناشناس'
  END,
  other_user_avatar = NEW.avatar_url,
  other_user_role = NEW.role
  WHERE other_user_id = NEW.id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to update conversation names when profile is updated
DROP TRIGGER IF EXISTS trigger_update_conversation_names ON profiles;
CREATE TRIGGER trigger_update_conversation_names
  AFTER UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_conversation_names();

-- Update existing conversations with proper user names
UPDATE chat_conversations 
SET 
  other_user_name = CASE 
    WHEN p.first_name IS NOT NULL AND p.last_name IS NOT NULL 
      THEN p.first_name || ' ' || p.last_name
    WHEN p.first_name IS NOT NULL 
      THEN p.first_name
    WHEN p.last_name IS NOT NULL 
      THEN p.last_name
    ELSE 
      'کاربر ناشناس'
  END,
  other_user_avatar = p.avatar_url,
  other_user_role = p.role
FROM profiles p
WHERE chat_conversations.other_user_id = p.id;

-- Create function to automatically create conversation with proper names
CREATE OR REPLACE FUNCTION create_conversation_with_names(
  p_user_id UUID,
  p_other_user_id UUID
)
RETURNS UUID AS $$
DECLARE
  v_conversation_id UUID;
  v_other_user_name TEXT;
  v_other_user_avatar TEXT;
  v_other_user_role TEXT;
BEGIN
  -- Get other user info
  SELECT 
    CASE 
      WHEN first_name IS NOT NULL AND last_name IS NOT NULL 
        THEN first_name || ' ' || last_name
      WHEN first_name IS NOT NULL 
        THEN first_name
      WHEN last_name IS NOT NULL 
        THEN last_name
      ELSE 
        'کاربر ناشناس'
    END,
    avatar_url,
    role
  INTO v_other_user_name, v_other_user_avatar, v_other_user_role
  FROM profiles 
  WHERE id = p_other_user_id;
  
  -- Create conversation
  INSERT INTO chat_conversations (
    user_id, 
    other_user_id, 
    other_user_name, 
    other_user_avatar, 
    other_user_role,
    last_message_at
  ) VALUES (
    p_user_id, 
    p_other_user_id, 
    v_other_user_name, 
    v_other_user_avatar, 
    v_other_user_role,
    NOW()
  ) RETURNING id INTO v_conversation_id;
  
  RETURN v_conversation_id;
END;
$$ LANGUAGE plpgsql; 