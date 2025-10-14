-- جدول حضور کاربران در چت
CREATE TABLE IF NOT EXISTS public.chat_presence (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  conversation_id UUID NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- هر کاربر فقط یک رکورد فعال در هر مکالمه
  UNIQUE(user_id, conversation_id)
);

-- ایندکس برای بهبود عملکرد
CREATE INDEX IF NOT EXISTS idx_chat_presence_user_id ON public.chat_presence(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_presence_conversation_id ON public.chat_presence(conversation_id);
CREATE INDEX IF NOT EXISTS idx_chat_presence_active ON public.chat_presence(is_active) WHERE is_active = true;

-- تابع برای به‌روزرسانی last_seen
CREATE OR REPLACE FUNCTION update_chat_presence_last_seen()
RETURNS TRIGGER AS $$
BEGIN
  NEW.last_seen = NOW();
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- تریگر برای به‌روزرسانی last_seen
CREATE TRIGGER trg_chat_presence_last_seen
  BEFORE UPDATE ON public.chat_presence
  FOR EACH ROW
  EXECUTE FUNCTION update_chat_presence_last_seen();

-- فعال‌سازی Realtime برای جدول حضور
ALTER TABLE public.chat_presence REPLICA IDENTITY FULL;

-- RLS policies
ALTER TABLE public.chat_presence ENABLE ROW LEVEL SECURITY;

-- کاربران فقط حضور خودشان را ببینند
CREATE POLICY "Users can view their own presence" ON public.chat_presence
  FOR SELECT USING (auth.uid() = user_id);

-- کاربران فقط حضور خودشان را تغییر دهند
CREATE POLICY "Users can manage their own presence" ON public.chat_presence
  FOR ALL USING (auth.uid() = user_id);

-- کاربران حضور سایر کاربران در مکالمات خودشان را ببینند
CREATE POLICY "Users can view presence in their conversations" ON public.chat_presence
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.chat_conversations cc 
      WHERE cc.id = conversation_id 
      AND (cc.user1_id = auth.uid() OR cc.user2_id = auth.uid())
    )
  );
