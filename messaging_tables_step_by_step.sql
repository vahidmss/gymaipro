-- ظ…ط±ط­ظ„ظ‡ 1: ط§غŒط¬ط§ط¯ ط¬ط¯ظˆظ„ message_groups
CREATE TABLE IF NOT EXISTS message_groups (
  id UUID PRIMARY KEY,
  name TEXT NOT NULL,
  owner_id UUID NOT NULL,
  member_ids UUID[] NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ظ…ط±ط­ظ„ظ‡ 2: ط§غŒط¬ط§ط¯ ط¬ط¯ظˆظ„ messages
CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY,
  sender_id UUID NOT NULL,
  receiver_id UUID,
  group_id UUID,
  content TEXT NOT NULL,
  "timestamp" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  sender_role TEXT NOT NULL,
  attachment TEXT,
  
  -- ط¨ط§غŒط¯ غŒط§ receiver_id غŒط§ group_id ظ¾ط± ط´ظˆط¯طŒ ط§ظ…ط§ ظ†ظ‡ ظ‡ط± ط¯ظˆ
  CONSTRAINT either_receiver_or_group CHECK (
    (receiver_id IS NULL AND group_id IS NOT NULL) OR
    (receiver_id IS NOT NULL AND group_id IS NULL)
  )
);

-- ظ…ط±ط­ظ„ظ‡ 3: ط§غŒط¬ط§ط¯ ط¬ط¯ظˆظ„ trainer_clients
CREATE TABLE IF NOT EXISTS trainer_clients (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  trainer_id UUID NOT NULL,
  athlete_id UUID NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- ظ‡ط± ظ…ط±ط¨غŒ ظˆ ط´ط§ع¯ط±ط¯ ظپظ‚ط· غŒع© ط¨ط§ط± ظ…غŒâ€Œطھظˆط§ظ†ظ†ط¯ ط¨ط§ ظ‡ظ… ظ…ط±طھط¨ط· ط´ظˆظ†ط¯
  CONSTRAINT unique_trainer_athlete UNIQUE (trainer_id, athlete_id)
);

-- ظ…ط±ط­ظ„ظ‡ 4: ط§ط¶ط§ظپظ‡ ع©ط±ط¯ظ† foreign key ظ‡ط§
ALTER TABLE message_groups 
  ADD CONSTRAINT fk_message_groups_owner
  FOREIGN KEY (owner_id) 
  REFERENCES profiles(id) 
  ON DELETE CASCADE;

ALTER TABLE messages 
  ADD CONSTRAINT fk_messages_sender
  FOREIGN KEY (sender_id) 
  REFERENCES profiles(id) 
  ON DELETE CASCADE;

ALTER TABLE messages 
  ADD CONSTRAINT fk_messages_receiver
  FOREIGN KEY (receiver_id) 
  REFERENCES profiles(id) 
  ON DELETE CASCADE;

ALTER TABLE messages 
  ADD CONSTRAINT fk_messages_group
  FOREIGN KEY (group_id) 
  REFERENCES message_groups(id) 
  ON DELETE CASCADE;

ALTER TABLE trainer_clients 
  ADD CONSTRAINT fk_trainer_clients_trainer
  FOREIGN KEY (trainer_id) 
  REFERENCES profiles(id) 
  ON DELETE CASCADE;

ALTER TABLE trainer_clients 
  ADD CONSTRAINT fk_trainer_clients_athlete
  FOREIGN KEY (athlete_id) 
  REFERENCES profiles(id) 
  ON DELETE CASCADE;

-- ظ…ط±ط­ظ„ظ‡ 5: ط§غŒط¬ط§ط¯ ط§غŒظ†ط¯ع©ط³â€Œظ‡ط§
CREATE INDEX IF NOT EXISTS idx_message_groups_owner ON message_groups(owner_id);

CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver ON messages(receiver_id);
CREATE INDEX IF NOT EXISTS idx_messages_group ON messages(group_id);
CREATE INDEX IF NOT EXISTS idx_messages_timestamp ON messages("timestamp");

CREATE INDEX IF NOT EXISTS idx_trainer_clients_trainer ON trainer_clients(trainer_id);
CREATE INDEX IF NOT EXISTS idx_trainer_clients_athlete ON trainer_clients(athlete_id);

-- ظ…ط±ط­ظ„ظ‡ 6: طھظ†ط¸غŒظ… ط¯ط³طھط±ط³غŒ RLS
ALTER TABLE message_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE trainer_clients ENABLE ROW LEVEL SECURITY;

-- ظ…ط±ط­ظ„ظ‡ 7: ط§غŒط¬ط§ط¯ ط³غŒط§ط³طھâ€Œظ‡ط§غŒ RLS
-- ط³غŒط§ط³طھ RLS ط¨ط±ط§غŒ ع¯ط±ظˆظ‡â€Œظ‡ط§غŒ ظ¾غŒط§ظ…
CREATE POLICY message_groups_select_policy ON message_groups 
  FOR SELECT USING (
    auth.uid() = owner_id OR 
    auth.uid() = ANY(member_ids)
  );

CREATE POLICY message_groups_insert_policy ON message_groups 
  FOR INSERT WITH CHECK (auth.uid() = owner_id);

CREATE POLICY message_groups_update_policy ON message_groups 
  FOR UPDATE USING (auth.uid() = owner_id);

-- ط³غŒط§ط³طھ RLS ط¨ط±ط§غŒ ظ¾غŒط§ظ…â€Œظ‡ط§
CREATE POLICY messages_select_policy ON messages 
  FOR SELECT USING (
    auth.uid() = sender_id OR 
    auth.uid() = receiver_id OR 
    auth.uid() IN (
      SELECT unnest(member_ids) FROM message_groups WHERE id = group_id
    )
  );

CREATE POLICY messages_insert_policy ON messages 
  FOR INSERT WITH CHECK (auth.uid() = sender_id);

CREATE POLICY messages_update_policy ON messages 
  FOR UPDATE USING (auth.uid() = receiver_id)
  WITH CHECK (
    auth.uid() = receiver_id AND
    (OLD.is_read, is_read) = (FALSE, TRUE) AND
    OLD.content = content AND
    OLD.sender_id = sender_id AND
    OLD.receiver_id = receiver_id AND
    OLD.group_id = group_id AND
    OLD."timestamp" = "timestamp" AND
    OLD.sender_role = sender_role AND
    OLD.attachment = attachment
  );

-- ط³غŒط§ط³طھ RLS ط¨ط±ط§غŒ ط§ط±طھط¨ط§ط· ظ…ط±ط¨غŒ ظˆ ط´ط§ع¯ط±ط¯
CREATE POLICY trainer_clients_select_policy ON trainer_clients 
  FOR SELECT USING (
    auth.uid() = trainer_id OR 
    auth.uid() = athlete_id
  );

CREATE POLICY trainer_clients_insert_policy ON trainer_clients 
  FOR INSERT WITH CHECK (
    auth.uid() = trainer_id OR 
    auth.uid() = athlete_id
  );

-- ظ…ط±ط­ظ„ظ‡ 8: ط§غŒط¬ط§ط¯ طھط§ط¨ط¹ ط¨ط±ط§غŒ ع¯ط±ظپطھظ† ط¢ط®ط±غŒظ† ظ¾غŒط§ظ… ط§ط² ظ‡ط± ظ…ع©ط§ظ„ظ…ظ‡
CREATE OR REPLACE FUNCTION get_last_messages(user_id UUID)
RETURNS TABLE (
  id UUID,
  sender_id UUID,
  receiver_id UUID,
  group_id UUID,
  content TEXT,
  "timestamp" TIMESTAMPTZ,
  is_read BOOLEAN,
  sender_role TEXT,
  attachment TEXT
) AS $$
BEGIN
  RETURN QUERY
    WITH user_conversations AS (
      -- ظ¾غŒط§ظ…â€Œظ‡ط§غŒ ظ…ط³طھظ‚غŒظ… ع©ظ‡ ع©ط§ط±ط¨ط± ظپط±ط³طھط§ط¯ظ‡ غŒط§ ط¯ط±غŒط§ظپطھ ع©ط±ط¯ظ‡
      SELECT DISTINCT
        CASE
          WHEN sender_id = user_id THEN receiver_id
          ELSE sender_id
        END AS contact_id,
        NULL::UUID AS group_id
      FROM messages
      WHERE (sender_id = user_id OR receiver_id = user_id)
        AND group_id IS NULL
      
      UNION
      
      -- ع¯ط±ظˆظ‡â€Œظ‡ط§غŒغŒ ع©ظ‡ ع©ط§ط±ط¨ط± ط¹ط¶ظˆ ط¢ظ†ظ‡ط§ط³طھ
      SELECT NULL::UUID AS contact_id,
        id AS group_id
      FROM message_groups
      WHERE owner_id = user_id OR user_id = ANY(member_ids)
    ),
    latest_messages AS (
      -- ط¢ط®ط±غŒظ† ظ¾غŒط§ظ… ط§ط² ظ‡ط± ظ…ع©ط§ظ„ظ…ظ‡ ظ…ط³طھظ‚غŒظ…
      SELECT DISTINCT ON (contact_id) m.*
      FROM user_conversations uc
      JOIN messages m ON 
        (m.sender_id = user_id AND m.receiver_id = uc.contact_id) OR
        (m.sender_id = uc.contact_id AND m.receiver_id = user_id)
      WHERE uc.group_id IS NULL
      ORDER BY contact_id, m."timestamp" DESC
      
      UNION
      
      -- ط¢ط®ط±غŒظ† ظ¾غŒط§ظ… ط§ط² ظ‡ط± ع¯ط±ظˆظ‡
      SELECT DISTINCT ON (group_id) m.*
      FROM user_conversations uc
      JOIN messages m ON m.group_id = uc.group_id
      WHERE uc.contact_id IS NULL
      ORDER BY group_id, m."timestamp" DESC
    )
    SELECT * FROM latest_messages
    ORDER BY "timestamp" DESC;
END;
$$ LANGUAGE plpgsql; 
