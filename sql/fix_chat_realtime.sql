-- Improve private chat realtime delivery (JSONB messages column updates)
-- Run on Supabase DB if realtime messages feel delayed or missing.

-- Full row image for UPDATE events (needed for messages JSONB payload)
ALTER TABLE public.chat_conversations REPLICA IDENTITY FULL;

-- Ensure table is in realtime publication
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'chat_conversations'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_conversations;
  END IF;
END $$;

-- Peer presence realtime (instant read ticks when both users are in chat)
ALTER TABLE public.chat_presence REPLICA IDENTITY FULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'chat_presence'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_presence;
  END IF;
END $$;
