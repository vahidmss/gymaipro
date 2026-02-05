-- جداول لایک موزیک (مثل exercise likes)

-- جدول لایک‌های کاربران برای موزیک
CREATE TABLE IF NOT EXISTS user_music_likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  music_id INTEGER NOT NULL, -- ID موزیک (hash از UUID)
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- جلوگیری از لایک تکراری
  UNIQUE(user_id, music_id)
);

-- ایندکس برای جستجوی سریع‌تر
CREATE INDEX IF NOT EXISTS idx_user_music_likes_user_id ON user_music_likes(user_id);
CREATE INDEX IF NOT EXISTS idx_user_music_likes_music_id ON user_music_likes(music_id);

-- جدول تعداد کل لایک‌های هر موزیک
CREATE TABLE IF NOT EXISTS global_music_likes (
  music_id INTEGER PRIMARY KEY,
  total_likes INTEGER NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ایندکس برای مرتب‌سازی سریع
CREATE INDEX IF NOT EXISTS idx_global_music_likes_total_likes ON global_music_likes(total_likes DESC);

-- RLS (Row Level Security) Policies
ALTER TABLE user_music_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE global_music_likes ENABLE ROW LEVEL SECURITY;

-- Policy: کاربران می‌توانند لایک‌های خود را ببینند
CREATE POLICY "Users can view their own music likes"
  ON user_music_likes
  FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: کاربران می‌توانند لایک اضافه کنند
CREATE POLICY "Users can insert their own music likes"
  ON user_music_likes
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: کاربران می‌توانند لایک خود را حذف کنند
CREATE POLICY "Users can delete their own music likes"
  ON user_music_likes
  FOR DELETE
  USING (auth.uid() = user_id);

-- Policy: همه می‌توانند تعداد کل لایک‌ها را ببینند
CREATE POLICY "Everyone can view global music likes"
  ON global_music_likes
  FOR SELECT
  USING (true);

-- تابع برای افزایش تعداد لایک‌ها
CREATE OR REPLACE FUNCTION increment_music_likes(music_id_param INTEGER)
RETURNS void AS $$
BEGIN
  INSERT INTO global_music_likes (music_id, total_likes, updated_at)
  VALUES (music_id_param, 1, NOW())
  ON CONFLICT (music_id) 
  DO UPDATE SET 
    total_likes = global_music_likes.total_likes + 1,
    updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- تابع برای کاهش تعداد لایک‌ها
CREATE OR REPLACE FUNCTION decrement_music_likes(music_id_param INTEGER)
RETURNS void AS $$
BEGIN
  UPDATE global_music_likes
  SET 
    total_likes = GREATEST(0, total_likes - 1),
    updated_at = NOW()
  WHERE music_id = music_id_param;
  
  -- حذف رکورد اگر لایک‌ها به صفر رسید (اختیاری)
  DELETE FROM global_music_likes 
  WHERE music_id = music_id_param AND total_likes = 0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

