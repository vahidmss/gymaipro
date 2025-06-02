-- Create Workout Programs Table
-- این اسکریپت را در SQL Editor پنل Supabase اجرا کنید

-- بررسی وجود تابع uuid_generate_v4 (در صورت نیاز)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ایجاد جدول workout_programs
CREATE TABLE IF NOT EXISTS public.workout_programs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    program_name VARCHAR(255) NOT NULL,
    data JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_deleted BOOLEAN DEFAULT FALSE
);

-- توضیحات جدول
COMMENT ON TABLE public.workout_programs IS 'برنامه‌های تمرینی کاربران با ساختار جیسون';

-- ایجاد ایندکس‌ها
CREATE INDEX workout_programs_profile_id_idx ON public.workout_programs(profile_id);
CREATE INDEX workout_programs_created_at_idx ON public.workout_programs(created_at);
CREATE INDEX workout_programs_program_name_idx ON public.workout_programs(program_name);

-- فعال‌سازی امنیت سطر (RLS)
ALTER TABLE public.workout_programs ENABLE ROW LEVEL SECURITY;

-- سیاست‌های امنیتی
CREATE POLICY "Users can create their own workout programs"
ON public.workout_programs FOR INSERT
TO authenticated
WITH CHECK (profile_id = auth.uid());

CREATE POLICY "Users can view their own workout programs"
ON public.workout_programs FOR SELECT
TO authenticated
USING (profile_id = auth.uid());

CREATE POLICY "Users can update their own workout programs"
ON public.workout_programs FOR UPDATE
TO authenticated
USING (profile_id = auth.uid());

CREATE POLICY "Users can delete their own workout programs"
ON public.workout_programs FOR DELETE
TO authenticated
USING (profile_id = auth.uid());

-- تابع به‌روزرسانی خودکار تاریخ
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- اعمال تریگر به جدول
DROP TRIGGER IF EXISTS set_updated_at ON public.workout_programs;
CREATE TRIGGER set_updated_at
BEFORE UPDATE ON public.workout_programs
FOR EACH ROW
EXECUTE FUNCTION public.handle_updated_at(); 