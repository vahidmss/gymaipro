-- Debug / payment: allow users to UPDATE their own rows in subscriptions.
-- Needed for cancel, renew, plan upgrade, and debug premium grant/revoke.
-- Run in Supabase SQL Editor.

ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can update their subscriptions" ON public.subscriptions;
CREATE POLICY "Users can update their subscriptions"
  ON public.subscriptions
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Optional: confirm policies
SELECT policyname, cmd, qual
FROM pg_policies
WHERE tablename = 'subscriptions'
ORDER BY policyname;
