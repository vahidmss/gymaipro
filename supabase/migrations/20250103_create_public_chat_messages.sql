-- Migration 20250103: Create Public Chat Messages Table

-- Create table for global public chat messages
CREATE TABLE IF NOT EXISTS public_chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  is_deleted BOOLEAN NOT NULL DEFAULT false
);

-- Trigger to update updated_at on update
CREATE OR REPLACE FUNCTION update_public_chat_messages_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_public_chat_messages_updated_at
  BEFORE UPDATE ON public_chat_messages
  FOR EACH ROW
  EXECUTE FUNCTION update_public_chat_messages_updated_at();

-- Enable Row Level Security
ALTER TABLE public_chat_messages ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Allow all authenticated users to select messages
CREATE POLICY "Allow select public chat" ON public_chat_messages
  FOR SELECT USING (true);

-- RLS Policy: Allow authenticated users to insert their own messages
CREATE POLICY "Allow insert public chat" ON public_chat_messages
  FOR INSERT WITH CHECK (auth.uid() = sender_id);

-- RLS Policy: Prevent deletes by clients
CREATE POLICY "Prevent delete public chat" ON public_chat_messages
  FOR DELETE USING (false);

-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public_chat_messages; 