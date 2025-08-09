-- =====================================================
-- جدول‌های کامل سیستم برنامه تمرینی - GymAI Pro
-- =====================================================

-- 1. جدول برنامه‌های تمرینی اصلی
CREATE TABLE IF NOT EXISTS public.workout_programs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    program_name VARCHAR(255) NOT NULL,
    data JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_deleted BOOLEAN DEFAULT FALSE
);

-- 2. جدول لاگ‌های روزانه تمرین
CREATE TABLE IF NOT EXISTS workout_daily_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    log_date DATE NOT NULL,
    sessions JSONB NOT NULL DEFAULT '[]',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, log_date)
);

-- 3. جدول لاگ‌های برنامه تمرینی
CREATE TABLE IF NOT EXISTS workout_program_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id),
    program_id UUID REFERENCES workout_programs(id),
    session_index INTEGER,
    workout_data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. جدول لاگ‌های تمرین عمومی
CREATE TABLE IF NOT EXISTS workout_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id),
    exercise_id TEXT,
    exercise_name TEXT,
    exercise_tag TEXT,
    sets JSONB,
    duration_seconds INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    notes TEXT
);

-- 5. جدول بوکمارک‌های تمرین
CREATE TABLE IF NOT EXISTS public.exercise_bookmarks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    exercise_id INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    constraint exercise_bookmarks_unique unique (user_id, exercise_id)
);

-- 6. جدول لایک‌های تمرین
CREATE TABLE IF NOT EXISTS public.exercise_likes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    exercise_id INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    constraint exercise_likes_unique unique (user_id, exercise_id)
);

-- =====================================================
-- ایندکس‌ها برای بهبود عملکرد
-- =====================================================

-- ایندکس‌های workout_programs
CREATE INDEX IF NOT EXISTS workout_programs_profile_id_idx ON public.workout_programs(profile_id);
CREATE INDEX IF NOT EXISTS workout_programs_created_at_idx ON public.workout_programs(created_at);
CREATE INDEX IF NOT EXISTS workout_programs_program_name_idx ON public.workout_programs(program_name);

-- ایندکس‌های workout_daily_logs
CREATE INDEX IF NOT EXISTS idx_workout_daily_logs_user_date ON workout_daily_logs(user_id, log_date);

-- ایندکس‌های workout_program_logs
CREATE INDEX IF NOT EXISTS idx_workout_program_logs_user_id ON workout_program_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_program_logs_program_id ON workout_program_logs(program_id);
CREATE INDEX IF NOT EXISTS idx_workout_program_logs_created_at ON workout_program_logs(created_at);

-- ایندکس‌های workout_logs
CREATE INDEX IF NOT EXISTS idx_workout_logs_user_id ON workout_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_logs_created_at ON workout_logs(created_at);

-- ایندکس‌های exercise_bookmarks
CREATE INDEX IF NOT EXISTS idx_exercise_bookmarks_user_id ON public.exercise_bookmarks(user_id);
CREATE INDEX IF NOT EXISTS idx_exercise_bookmarks_exercise_id ON public.exercise_bookmarks(exercise_id);

-- ایندکس‌های exercise_likes
CREATE INDEX IF NOT EXISTS idx_exercise_likes_user_id ON public.exercise_likes(user_id);
CREATE INDEX IF NOT EXISTS idx_exercise_likes_exercise_id ON public.exercise_likes(exercise_id);

-- =====================================================
-- توابع مورد نیاز
-- =====================================================

-- تابع به‌روزرسانی خودکار تاریخ
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- تابع به‌روزرسانی workout_daily_logs
CREATE OR REPLACE FUNCTION update_workout_daily_logs_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- تابع شمارش لایک‌های تمرین
CREATE OR REPLACE FUNCTION public.get_exercise_likes_count(exercise_id_param INTEGER)
RETURNS INTEGER AS $$
DECLARE
    likes_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO likes_count
    FROM public.exercise_likes
    WHERE exercise_id = exercise_id_param;
    
    RETURN COALESCE(likes_count, 0);
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- تریگرها
-- =====================================================

-- تریگر workout_programs
DROP TRIGGER IF EXISTS set_updated_at ON public.workout_programs;
CREATE TRIGGER set_updated_at
BEFORE UPDATE ON public.workout_programs
FOR EACH ROW
EXECUTE FUNCTION public.handle_updated_at();

-- تریگر workout_daily_logs
DROP TRIGGER IF EXISTS update_workout_daily_logs_updated_at ON workout_daily_logs;
CREATE TRIGGER update_workout_daily_logs_updated_at
    BEFORE UPDATE ON workout_daily_logs
    FOR EACH ROW
    EXECUTE FUNCTION update_workout_daily_logs_updated_at();

-- =====================================================
-- فعال‌سازی امنیت سطر (RLS)
-- =====================================================

-- workout_programs
ALTER TABLE public.workout_programs ENABLE ROW LEVEL SECURITY;

-- workout_daily_logs
ALTER TABLE workout_daily_logs ENABLE ROW LEVEL SECURITY;

-- workout_program_logs
ALTER TABLE workout_program_logs ENABLE ROW LEVEL SECURITY;

-- workout_logs
ALTER TABLE workout_logs ENABLE ROW LEVEL SECURITY;

-- exercise_bookmarks
ALTER TABLE public.exercise_bookmarks ENABLE ROW LEVEL SECURITY;

-- exercise_likes
ALTER TABLE public.exercise_likes ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- سیاست‌های امنیتی (RLS Policies)
-- =====================================================

-- سیاست‌های workout_programs
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

-- سیاست‌های workout_daily_logs
CREATE POLICY "Users can view their own workout daily logs" ON workout_daily_logs
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own workout daily logs" ON workout_daily_logs
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own workout daily logs" ON workout_daily_logs
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own workout daily logs" ON workout_daily_logs
    FOR DELETE USING (auth.uid() = user_id);

-- سیاست‌های workout_program_logs
CREATE POLICY "Users can view their own workout program logs" ON workout_program_logs
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own workout program logs" ON workout_program_logs
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own workout program logs" ON workout_program_logs
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own workout program logs" ON workout_program_logs
    FOR DELETE USING (auth.uid() = user_id);

-- سیاست‌های workout_logs
CREATE POLICY "Users can view their own workout logs" ON workout_logs
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own workout logs" ON workout_logs
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own workout logs" ON workout_logs
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own workout logs" ON workout_logs
    FOR DELETE USING (auth.uid() = user_id);

-- سیاست‌های exercise_bookmarks
CREATE POLICY "Users can manage own exercise bookmarks" ON public.exercise_bookmarks
    FOR ALL USING (auth.uid() = user_id);

-- سیاست‌های exercise_likes
CREATE POLICY "Users can manage own exercise likes" ON public.exercise_likes
    FOR ALL USING (auth.uid() = user_id);

-- =====================================================
-- مجوزهای دسترسی
-- =====================================================

-- اعطای مجوز به کاربران
GRANT ALL ON public.workout_programs TO anon, authenticated;
GRANT ALL ON workout_daily_logs TO anon, authenticated;
GRANT ALL ON workout_program_logs TO anon, authenticated;
GRANT ALL ON workout_logs TO anon, authenticated;
GRANT ALL ON public.exercise_bookmarks TO anon, authenticated;
GRANT ALL ON public.exercise_likes TO anon, authenticated;

-- اعطای مجوز اجرای توابع
GRANT EXECUTE ON FUNCTION public.get_exercise_likes_count(INTEGER) TO anon, authenticated;

-- =====================================================
-- توضیحات جداول
-- =====================================================

COMMENT ON TABLE public.workout_programs IS 'برنامه‌های تمرینی کاربران با ساختار جیسون';
COMMENT ON TABLE workout_daily_logs IS 'لاگ‌های روزانه تمرین کاربران';
COMMENT ON TABLE workout_program_logs IS 'لاگ‌های برنامه تمرینی خاص';
COMMENT ON TABLE workout_logs IS 'لاگ‌های عمومی تمرین';
COMMENT ON TABLE public.exercise_bookmarks IS 'بوکمارک‌های تمرین کاربران';
COMMENT ON TABLE public.exercise_likes IS 'لایک‌های تمرین کاربران';

-- =====================================================
-- نمونه داده برای تست (اختیاری)
-- =====================================================

/*
-- نمونه برنامه تمرینی
INSERT INTO public.workout_programs (profile_id, program_name, data) VALUES (
    'USER_UUID_HERE',
    'برنامه تست',
    '{
        "sessions": [
            {
                "day": "روز 1",
                "exercises": [
                    {
                        "type": "normal",
                        "exercise_id": 1,
                        "tag": "سینه",
                        "style": "sets_reps",
                        "sets": [
                            {"reps": 10, "weight": 50},
                            {"reps": 8, "weight": 60}
                        ]
                    }
                ]
            }
        ]
    }'::jsonb
);

-- نمونه لاگ روزانه
INSERT INTO workout_daily_logs (user_id, log_date, sessions) VALUES (
    'USER_UUID_HERE',
    CURRENT_DATE,
    '[
        {
            "exercise_name": "پرس سینه",
            "sets": [
                {"reps": 10, "weight": 50, "completed": true},
                {"reps": 8, "weight": 60, "completed": true}
            ]
        }
    ]'::jsonb
);
*/
