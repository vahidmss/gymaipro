-- جدول تمرینات
CREATE TABLE public.workouts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    duration INTEGER NOT NULL, -- به دقیقه
    calories INTEGER,
    workout_type TEXT NOT NULL, -- نوع تمرین (قدرتی، هوازی، و...)
    workout_date DATE NOT NULL DEFAULT CURRENT_DATE,
    completed BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- جدول حرکات تمرینی
CREATE TABLE public.exercises (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    muscle_group TEXT NOT NULL, -- گروه عضلانی (سینه، پا، پشت، و...)
    difficulty_level TEXT NOT NULL, -- سطح سختی (مبتدی، متوسط، پیشرفته)
    instructions TEXT,
    image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- جدول جزئیات تمرینات
CREATE TABLE public.workout_exercises (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workout_id UUID NOT NULL REFERENCES public.workouts(id) ON DELETE CASCADE,
    exercise_id UUID NOT NULL REFERENCES public.exercises(id),
    sets INTEGER,
    reps INTEGER,
    weight FLOAT,
    duration INTEGER, -- به ثانیه (برای تمرینات هوازی یا پلانک و...)
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    UNIQUE (workout_id, exercise_id)
);

-- تنظیم RLS
ALTER TABLE public.workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_exercises ENABLE ROW LEVEL SECURITY;

-- سیاست‌های workouts
CREATE POLICY "Users can view their own workouts" 
ON public.workouts FOR SELECT 
USING (auth.uid() = profile_id);

CREATE POLICY "Users can insert their own workouts" 
ON public.workouts FOR INSERT 
WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "Users can update their own workouts" 
ON public.workouts FOR UPDATE 
USING (auth.uid() = profile_id);

CREATE POLICY "Users can delete their own workouts" 
ON public.workouts FOR DELETE 
USING (auth.uid() = profile_id);

-- سیاست‌های exercises
CREATE POLICY "Anyone can view exercises" 
ON public.exercises FOR SELECT 
USING (true);

-- سیاست‌های workout_exercises
CREATE POLICY "Users can view their own workout_exercises" 
ON public.workout_exercises FOR SELECT 
USING (EXISTS (
    SELECT 1 FROM public.workouts w 
    WHERE w.id = workout_id AND w.profile_id = auth.uid()
));

CREATE POLICY "Users can insert their own workout_exercises" 
ON public.workout_exercises FOR INSERT 
WITH CHECK (EXISTS (
    SELECT 1 FROM public.workouts w 
    WHERE w.id = workout_id AND w.profile_id = auth.uid()
));

CREATE POLICY "Users can update their own workout_exercises" 
ON public.workout_exercises FOR UPDATE 
USING (EXISTS (
    SELECT 1 FROM public.workouts w 
    WHERE w.id = workout_id AND w.profile_id = auth.uid()
));

CREATE POLICY "Users can delete their own workout_exercises" 
ON public.workout_exercises FOR DELETE 
USING (EXISTS (
    SELECT 1 FROM public.workouts w 
    WHERE w.id = workout_id AND w.profile_id = auth.uid()
));

-- ایجاد تریگر برای بروزرسانی updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_workouts_updated_at
BEFORE UPDATE ON public.workouts
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- ایجاد تابع برای محاسبه تعداد تمرینات کاربر
CREATE OR REPLACE FUNCTION get_workout_stats(user_id UUID)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'workout_count', COUNT(*),
        'total_duration', COALESCE(SUM(duration), 0),
        'total_calories', COALESCE(SUM(calories), 0),
        'consecutive_days', (
            WITH dates AS (
                SELECT DISTINCT workout_date
                FROM public.workouts
                WHERE profile_id = user_id
                ORDER BY workout_date DESC
            ),
            consecutive AS (
                SELECT workout_date,
                       workout_date - CAST(ROW_NUMBER() OVER (ORDER BY workout_date DESC) AS INTEGER) AS grp
                FROM dates
            )
            SELECT COUNT(*) FROM (
                SELECT grp, COUNT(*) AS streak
                FROM consecutive
                GROUP BY grp
                ORDER BY MIN(workout_date) DESC
                LIMIT 1
            ) s
        )
    ) INTO result
    FROM public.workouts
    WHERE profile_id = user_id;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- اضافه کردن چند حرکت پیش‌فرض
INSERT INTO public.exercises (name, description, muscle_group, difficulty_level, instructions) VALUES
('پرس سینه', 'حرکت پایه برای عضلات سینه', 'سینه', 'متوسط', 'روی نیمکت بخوابید و وزنه را بالای سینه خود نگه دارید...'),
('اسکات', 'حرکت پایه برای عضلات پا', 'پا', 'متوسط', 'پاها به اندازه عرض شانه باز، پشت صاف، زانوها را خم کنید...'),
('زیربغل سیم‌کش', 'حرکت کششی برای عضلات پشت', 'پشت', 'مبتدی', 'رو به دستگاه بایستید، پاها به اندازه عرض شانه باز...'),
('جلو بازو هالتر', 'حرکت پایه برای عضلات جلو بازو', 'بازو', 'مبتدی', 'هالتر را با دست‌ها در حالتی که کف دست رو به بالاست بگیرید...'),
('پلانک', 'حرکت ایزومتریک برای تقویت مرکز بدن', 'شکم', 'مبتدی', 'در حالت شنا قرار بگیرید اما به جای دست‌ها روی ساعد تکیه کنید...'); 