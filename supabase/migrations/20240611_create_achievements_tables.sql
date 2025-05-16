-- ایجاد جدول انواع دستاوردها
CREATE TABLE public.achievements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    icon TEXT NOT NULL,
    color TEXT NOT NULL DEFAULT '#FDB436',
    criteria JSONB NOT NULL,
    points INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- ایجاد جدول دستاوردهای کاربران
CREATE TABLE public.user_achievements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    achievement_id UUID NOT NULL REFERENCES public.achievements(id) ON DELETE CASCADE,
    unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    progress FLOAT DEFAULT 0,
    UNIQUE (profile_id, achievement_id)
);

-- افزودن توضیحات به جداول
COMMENT ON TABLE public.achievements IS 'Types of achievements that users can unlock';
COMMENT ON TABLE public.user_achievements IS 'Achievements unlocked by users';

-- تنظیم سیاست‌های امنیتی (RLS)
ALTER TABLE public.achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;

-- سیاست‌های خواندن برای achievements
CREATE POLICY "Anyone can read achievements" 
ON public.achievements FOR SELECT 
USING (true);

-- سیاست‌های user_achievements
CREATE POLICY "Users can view their own achievements" 
ON public.user_achievements FOR SELECT 
USING (auth.uid() = profile_id);

CREATE POLICY "Service role can insert user achievements" 
ON public.user_achievements FOR INSERT 
WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "Service role can update user achievements" 
ON public.user_achievements FOR UPDATE 
USING (auth.uid() = profile_id);

-- افزودن تعدادی دستاورد اولیه
INSERT INTO public.achievements (name, description, icon, color, criteria, points) VALUES
('مبتدی', 'ثبت اولین تمرین', 'LucideIcons.dumbbell', '#4CAF50', '{"workout_count": 1}', 50),
('متوالی', 'ثبت تمرین برای ۷ روز متوالی', 'LucideIcons.flame', '#FF9800', '{"consecutive_workout_days": 7}', 100),
('قهرمان', 'تکمیل ۳۰ جلسه تمرین', 'LucideIcons.medal', '#FDB436', '{"workout_count": 30}', 200),
('کوهنورد', 'افزایش ۱۰ درصدی وزنه‌ها', 'LucideIcons.mountain', '#2196F3', '{"weight_increase_percentage": 10}', 150),
('متعادل', 'رسیدن به BMI سالم', 'LucideIcons.heartPulse', '#F44336', '{"bmi_healthy": true}', 300),
('حرفه‌ای', 'تکمیل ۱۰۰ جلسه تمرین', 'LucideIcons.crown', '#9C27B0', '{"workout_count": 100}', 500);

-- ایجاد function برای بررسی دستاوردها
CREATE OR REPLACE FUNCTION check_achievements()
RETURNS TRIGGER AS $$
BEGIN
    -- کدی برای بررسی اینکه آیا کاربر دستاورد جدیدی باز کرده است
    -- بر اساس تغییرات ایجاد شده در رکورد‌های مختلف
    -- به عنوان مثال: بررسی تعداد تمرینات، وزن، BMI و...
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER; 