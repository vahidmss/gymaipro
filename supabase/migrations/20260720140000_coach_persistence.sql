-- Coach v2 persistence: memories, chat, summaries, multi-step state.

CREATE TABLE IF NOT EXISTS coach_memories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    memory_key TEXT NOT NULL,
    value TEXT NOT NULL,
    category TEXT NOT NULL DEFAULT 'other',
    confidence REAL NOT NULL DEFAULT 0.5,
    importance TEXT NOT NULL DEFAULT 'medium',
    source TEXT NOT NULL DEFAULT 'system',
    expires_at TIMESTAMPTZ,
    editable BOOLEAN NOT NULL DEFAULT TRUE,
    user_editable BOOLEAN NOT NULL DEFAULT TRUE,
    ai_generated BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, memory_key)
);

CREATE INDEX IF NOT EXISTS idx_coach_memories_user_updated
    ON coach_memories (user_id, updated_at DESC);

CREATE TABLE IF NOT EXISTS coach_chat_messages (
    id TEXT NOT NULL,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL,
    message_type TEXT NOT NULL DEFAULT 'normal',
    content TEXT NOT NULL,
    cards JSONB NOT NULL DEFAULT '[]'::jsonb,
    tokens_used INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, id)
);

CREATE INDEX IF NOT EXISTS idx_coach_chat_messages_user_created
    ON coach_chat_messages (user_id, created_at DESC);

CREATE TABLE IF NOT EXISTS coach_conversation_summaries (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    summary TEXT,
    message_count INTEGER NOT NULL DEFAULT 0,
    topics TEXT[] NOT NULL DEFAULT '{}',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS coach_conversation_states (
    state_id TEXT NOT NULL,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    state JSONB NOT NULL,
    expires_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, state_id)
);

CREATE INDEX IF NOT EXISTS idx_coach_conversation_states_user_updated
    ON coach_conversation_states (user_id, updated_at DESC);

ALTER TABLE coach_memories ENABLE ROW LEVEL SECURITY;
ALTER TABLE coach_chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE coach_conversation_summaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE coach_conversation_states ENABLE ROW LEVEL SECURITY;

CREATE POLICY coach_memories_select_own ON coach_memories
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY coach_memories_insert_own ON coach_memories
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY coach_memories_update_own ON coach_memories
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY coach_memories_delete_own ON coach_memories
    FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY coach_chat_messages_select_own ON coach_chat_messages
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY coach_chat_messages_insert_own ON coach_chat_messages
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY coach_chat_messages_update_own ON coach_chat_messages
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY coach_chat_messages_delete_own ON coach_chat_messages
    FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY coach_conversation_summaries_select_own ON coach_conversation_summaries
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY coach_conversation_summaries_insert_own ON coach_conversation_summaries
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY coach_conversation_summaries_update_own ON coach_conversation_summaries
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY coach_conversation_summaries_delete_own ON coach_conversation_summaries
    FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY coach_conversation_states_select_own ON coach_conversation_states
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY coach_conversation_states_insert_own ON coach_conversation_states
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY coach_conversation_states_update_own ON coach_conversation_states
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY coach_conversation_states_delete_own ON coach_conversation_states
    FOR DELETE USING (auth.uid() = user_id);
