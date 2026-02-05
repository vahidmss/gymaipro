-- ایجاد جدول تمرین‌های اختصاصی مربیان
CREATE TABLE IF NOT EXISTS public.custom_exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    
    -- اطلاعات اصلی تمرین
    title VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    detailed_description TEXT,
    
    -- عضلات
    main_muscle VARCHAR(100),
    secondary_muscles TEXT, -- CSV یا JSON array
    
    -- مشخصات تمرین
    difficulty VARCHAR(50) DEFAULT 'متوسط',
    equipment VARCHAR(100) DEFAULT 'بدون تجهیزات',
    exercise_type VARCHAR(50) DEFAULT 'قدرتی',
    target_area VARCHAR(100),
    
    -- محتوا
    video_url TEXT,
    image_url TEXT,
    tips TEXT[], -- Array of tips
    
    -- تنظیمات دسترسی
    visibility VARCHAR(20) DEFAULT 'private' CHECK (visibility IN ('private', 'public')),
    shared_with_clients BOOLEAN DEFAULT true,
    approved BOOLEAN DEFAULT false, -- برای تمرین‌های public
    
    -- متادیتا
    tags TEXT[],
    other_names TEXT[],
    estimated_duration INTEGER DEFAULT 0, -- ثانیه
    
    -- آمار
    views_count INTEGER DEFAULT 0,
    likes_count INTEGER DEFAULT 0,
    
    -- تاریخ‌ها
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT valid_difficulty CHECK (difficulty IN ('آسان', 'متوسط', 'سخت', 'حرفه‌ای')),
    CONSTRAINT valid_exercise_type CHECK (exercise_type IN ('قدرتی', 'کاردیو', 'کششی', 'تعادلی', 'انعطاف‌پذیری'))
);

-- ایندکس‌ها
CREATE INDEX IF NOT EXISTS idx_custom_exercises_created_by ON public.custom_exercises(created_by);
CREATE INDEX IF NOT EXISTS idx_custom_exercises_visibility ON public.custom_exercises(visibility);
CREATE INDEX IF NOT EXISTS idx_custom_exercises_approved ON public.custom_exercises(approved) WHERE visibility = 'public';
CREATE INDEX IF NOT EXISTS idx_custom_exercises_created_at ON public.custom_exercises(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_custom_exercises_main_muscle ON public.custom_exercises(main_muscle);
CREATE INDEX IF NOT EXISTS idx_custom_exercises_difficulty ON public.custom_exercises(difficulty);

-- تریگر برای به‌روزرسانی updated_at
CREATE OR REPLACE FUNCTION update_custom_exercises_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_custom_exercises_updated_at ON public.custom_exercises;
CREATE TRIGGER trigger_update_custom_exercises_updated_at
    BEFORE UPDATE ON public.custom_exercises
    FOR EACH ROW
    EXECUTE FUNCTION update_custom_exercises_updated_at();

-- فعال‌سازی Row Level Security
ALTER TABLE public.custom_exercises ENABLE ROW LEVEL SECURITY;

-- Policy: کاربران می‌توانند تمرین‌های خود را ببینند
CREATE POLICY "Users can view their own custom exercises"
    ON public.custom_exercises
    FOR SELECT
    USING (auth.uid() = created_by);

-- Policy: مربیان می‌توانند تمرین‌های public را ببینند
CREATE POLICY "Users can view public custom exercises"
    ON public.custom_exercises
    FOR SELECT
    USING (visibility = 'public' AND approved = true);

-- Policy: مربیان می‌توانند تمرین‌های مربی خود را ببینند (اگر شاگرد باشند)
CREATE POLICY "Clients can view trainer's shared exercises"
    ON public.custom_exercises
    FOR SELECT
    USING (
        visibility = 'private' 
        AND shared_with_clients = true
        AND EXISTS (
            SELECT 1 FROM public.trainer_clients
            WHERE trainer_id = created_by
            AND client_id = auth.uid()
            AND status = 'active'
        )
    );

-- Policy: فقط سازنده می‌تواند تمرین بسازد
CREATE POLICY "Users can create their own custom exercises"
    ON public.custom_exercises
    FOR INSERT
    WITH CHECK (auth.uid() = created_by);

-- Policy: فقط سازنده می‌تواند تمرین خود را ویرایش کند
CREATE POLICY "Users can update their own custom exercises"
    ON public.custom_exercises
    FOR UPDATE
    USING (auth.uid() = created_by)
    WITH CHECK (auth.uid() = created_by);

-- Policy: فقط سازنده می‌تواند تمرین خود را حذف کند
CREATE POLICY "Users can delete their own custom exercises"
    ON public.custom_exercises
    FOR DELETE
    USING (auth.uid() = created_by);

-- Policy: ادمین‌ها می‌توانند همه تمرین‌ها را ببینند و تایید کنند
CREATE POLICY "Admins can manage all custom exercises"
    ON public.custom_exercises
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid()
            AND role = 'admin'
        )
    );

