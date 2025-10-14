-- ایجاد جدول profiles برای اطلاعات کاربران
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username VARCHAR(50) UNIQUE NOT NULL,
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    avatar_url TEXT,
    bio TEXT,
    birth_date DATE,
    height INTEGER, -- قد به سانتی‌متر
    weight DECIMAL(5,2), -- وزن به کیلوگرم
    gender VARCHAR(10) CHECK (gender IN ('male', 'female', 'other')),
    role VARCHAR(20) NOT NULL DEFAULT 'athlete' CHECK (role IN ('athlete', 'trainer', 'admin')),
    
    -- اطلاعات مربی
    experience_years INTEGER DEFAULT 0,
    specializations TEXT,
    rating DECIMAL(3,2) DEFAULT 0.0,
    review_count INTEGER DEFAULT 0,
    certifications JSONB DEFAULT '[]'::jsonb,
    
    -- اهداف ورزشی
    fitness_goals JSONB DEFAULT '[]'::jsonb,
    
    -- تاریخ‌ها
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_active_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- وضعیت آنلاین
    is_online BOOLEAN DEFAULT false
);

-- ایندکس‌ها برای بهبود عملکرد
CREATE INDEX IF NOT EXISTS idx_profiles_username ON public.profiles(username);
CREATE INDEX IF NOT EXISTS idx_profiles_phone_number ON public.profiles(phone_number);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_created_at ON public.profiles(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_profiles_last_active_at ON public.profiles(last_active_at DESC);

-- ایندکس‌های خاص برای مربیان
CREATE INDEX IF NOT EXISTS idx_profiles_trainers ON public.profiles(role, rating DESC) WHERE role = 'trainer';
CREATE INDEX IF NOT EXISTS idx_profiles_specializations ON public.profiles(specializations) WHERE role = 'trainer';

-- تریگر برای به‌روزرسانی updated_at
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_profiles_updated_at ON public.profiles;
CREATE TRIGGER set_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

-- فعال‌سازی Row Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- پالیسی‌های امنیتی
-- کاربران می‌توانند پروفایل خود را ببینند
CREATE POLICY "Users can view their own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

-- کاربران می‌توانند پروفایل خود را به‌روزرسانی کنند
CREATE POLICY "Users can update their own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

-- کاربران می‌توانند پروفایل خود را ایجاد کنند
CREATE POLICY "Users can create their own profile" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- همه کاربران احراز هویت شده می‌توانند پروفایل‌های عمومی را ببینند
CREATE POLICY "Authenticated users can view public profiles" ON public.profiles
    FOR SELECT USING (auth.role() = 'authenticated');

-- اعطای دسترسی‌ها
GRANT SELECT, INSERT, UPDATE, DELETE ON public.profiles TO authenticated;
GRANT USAGE ON SCHEMA public TO authenticated;
