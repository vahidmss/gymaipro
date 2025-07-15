-- Add user info fields to public_chat_messages table
ALTER TABLE public_chat_messages 
ADD COLUMN IF NOT EXISTS sender_name TEXT,
ADD COLUMN IF NOT EXISTS sender_avatar TEXT,
ADD COLUMN IF NOT EXISTS sender_role TEXT;

-- Create function to automatically populate user info when sending message
CREATE OR REPLACE FUNCTION populate_user_info_in_public_chat()
RETURNS TRIGGER AS $$
BEGIN
  -- Get user info from profiles table
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
  INTO NEW.sender_name, NEW.sender_avatar, NEW.sender_role
  FROM profiles 
  WHERE id = NEW.sender_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically populate user info
DROP TRIGGER IF EXISTS trigger_populate_user_info_public_chat ON public_chat_messages;
CREATE TRIGGER trigger_populate_user_info_public_chat
  BEFORE INSERT ON public_chat_messages
  FOR EACH ROW
  EXECUTE FUNCTION populate_user_info_in_public_chat();

-- Update existing messages with user info
UPDATE public_chat_messages 
SET 
  sender_name = CASE 
    WHEN p.first_name IS NOT NULL AND p.last_name IS NOT NULL 
      THEN p.first_name || ' ' || p.last_name
    WHEN p.first_name IS NOT NULL 
      THEN p.first_name
    WHEN p.last_name IS NOT NULL 
      THEN p.last_name
    ELSE 
      'کاربر ناشناس'
  END,
  sender_avatar = p.avatar_url,
  sender_role = p.role
FROM profiles p
WHERE public_chat_messages.sender_id = p.id
  AND public_chat_messages.sender_name IS NULL; 