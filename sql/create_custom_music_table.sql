-- جدول موزیک‌های اختصاصی مربی
CREATE TABLE IF NOT EXISTS custom_music (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  artist TEXT NOT NULL,
  audio_url TEXT NOT NULL,
  cover_image_url TEXT NOT NULL,
  duration INTEGER NOT NULL DEFAULT 0, -- مدت زمان به ثانیه
  category TEXT, -- دسته‌بندی
  description TEXT,
  visibility TEXT NOT NULL DEFAULT 'private', -- 'private' or 'public'
  views_count INTEGER NOT NULL DEFAULT 0,
  likes_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  CONSTRAINT valid_visibility CHECK (visibility IN ('private', 'public'))
);

-- ایندکس برای جستجوی سریع‌تر
CREATE INDEX IF NOT EXISTS idx_custom_music_created_by ON custom_music(created_by);
CREATE INDEX IF NOT EXISTS idx_custom_music_visibility ON custom_music(visibility);
CREATE INDEX IF NOT EXISTS idx_custom_music_category ON custom_music(category);

-- تابع برای به‌روزرسانی خودکار updated_at
CREATE OR REPLACE FUNCTION update_custom_music_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- تریگر برای به‌روزرسانی خودکار updated_at
CREATE TRIGGER trigger_update_custom_music_updated_at
  BEFORE UPDATE ON custom_music
  FOR EACH ROW
  EXECUTE FUNCTION update_custom_music_updated_at();

-- RLS (Row Level Security) Policies
ALTER TABLE custom_music ENABLE ROW LEVEL SECURITY;

-- Policy: کاربران می‌توانند موزیک‌های خود را ببینند
CREATE POLICY "Users can view their own music"
  ON custom_music
  FOR SELECT
  USING (auth.uid() = created_by);

-- Policy: کاربران می‌توانند موزیک‌های public را ببینند
CREATE POLICY "Users can view public music"
  ON custom_music
  FOR SELECT
  USING (visibility = 'public');

-- Policy: کاربران می‌توانند موزیک‌های خود را اضافه کنند
CREATE POLICY "Users can insert their own music"
  ON custom_music
  FOR INSERT
  WITH CHECK (auth.uid() = created_by);

-- Policy: کاربران می‌توانند موزیک‌های خود را به‌روزرسانی کنند
CREATE POLICY "Users can update their own music"
  ON custom_music
  FOR UPDATE
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);

-- Policy: کاربران می‌توانند موزیک‌های خود را حذف کنند
CREATE POLICY "Users can delete their own music"
  ON custom_music
  FOR DELETE
  USING (auth.uid() = created_by);

