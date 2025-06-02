-- پاکسازی جدول‌های قبلی (با احتیاط در محیط تولید استفاده شود)
DROP TABLE IF EXISTS workout_program_logs CASCADE;
DROP TABLE IF EXISTS workout_logs CASCADE;
DROP TABLE IF EXISTS workout_exercises CASCADE;
DROP TABLE IF EXISTS workout_sets CASCADE;
DROP TABLE IF EXISTS workout_programs CASCADE;

-- ایجاد جدول workout_program_logs با ساختار JSONB
CREATE TABLE IF NOT EXISTS workout_program_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  program_name TEXT NOT NULL,
  -- استفاده از JSONB برای ذخیره کل ساختار برنامه تمرینی در یک ستون
  sessions JSONB NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- فعال‌سازی سیستم امنیتی RLS
ALTER TABLE workout_program_logs ENABLE ROW LEVEL SECURITY;

-- ایجاد سیاست‌های امنیتی برای کاربران
-- سیاست برای مشاهده فقط برنامه‌های تمرینی خود کاربر
CREATE POLICY select_own_logs ON workout_program_logs
  FOR SELECT USING (auth.uid() = user_id);

-- سیاست برای اضافه کردن برنامه‌های تمرینی توسط خود کاربر
CREATE POLICY insert_own_logs ON workout_program_logs
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- سیاست برای به‌روزرسانی برنامه‌های تمرینی توسط خود کاربر
CREATE POLICY update_own_logs ON workout_program_logs
  FOR UPDATE USING (auth.uid() = user_id);

-- سیاست برای حذف برنامه‌های تمرینی توسط خود کاربر
CREATE POLICY delete_own_logs ON workout_program_logs
  FOR DELETE USING (auth.uid() = user_id);

-- ایجاد شاخص برای جستجوی سریع‌تر بر اساس شناسه کاربر
CREATE INDEX idx_workout_program_logs_user_id ON workout_program_logs(user_id);

-- ایجاد شاخص برای جستجوی سریع‌تر بر اساس نام برنامه
CREATE INDEX idx_workout_program_logs_program_name ON workout_program_logs(program_name);

-- ایجاد ایندکس برای جستجو در داده‌های JSONB
CREATE INDEX idx_workout_program_logs_sessions ON workout_program_logs USING GIN (sessions);

-- ایجاد تریگر برای به‌روزرسانی خودکار ستون updated_at
CREATE OR REPLACE FUNCTION update_workout_program_logs_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_workout_program_logs_updated_at
BEFORE UPDATE ON workout_program_logs
FOR EACH ROW
EXECUTE FUNCTION update_workout_program_logs_updated_at();

-- ایجاد فانکشن برای گرفتن برنامه‌های تمرینی کاربر
CREATE OR REPLACE FUNCTION get_user_workout_program_logs(user_uuid UUID)
RETURNS SETOF workout_program_logs AS $$
BEGIN
  RETURN QUERY
  SELECT *
  FROM workout_program_logs
  WHERE user_id = user_uuid
  ORDER BY updated_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- اضافه کردن یک تابع برای استخراج اطلاعات از ساختار JSONB (مفید برای گزارش‌گیری)
CREATE OR REPLACE FUNCTION get_program_sessions(program JSONB)
RETURNS TABLE (day TEXT, exercise_count INT) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    s->>'day' as day,
    jsonb_array_length(s->'exercises') as exercise_count
  FROM jsonb_array_elements(program) s;
END;
$$ LANGUAGE plpgsql; 