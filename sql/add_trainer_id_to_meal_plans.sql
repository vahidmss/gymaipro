-- افزودن ستون trainer_id به جدول meal_plans
-- این فایل باید در Supabase SQL Editor اجرا شود

-- افزودن ستون trainer_id به جدول meal_plans
ALTER TABLE public.meal_plans
ADD COLUMN IF NOT EXISTS trainer_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL;

-- ایجاد ایندکس برای بهبود عملکرد جستجو
CREATE INDEX IF NOT EXISTS idx_meal_plans_trainer_id ON public.meal_plans(trainer_id);

-- ایجاد foreign key constraint (اگر قبلاً وجود نداشته باشد)
-- Supabase به صورت خودکار foreign key را ایجاد می‌کند، اما می‌توانیم به صورت صریح اضافه کنیم
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM pg_constraint 
        WHERE conname = 'meal_plans_trainer_id_fkey'
    ) THEN
        ALTER TABLE public.meal_plans
        ADD CONSTRAINT meal_plans_trainer_id_fkey 
        FOREIGN KEY (trainer_id) 
        REFERENCES public.profiles(id) 
        ON DELETE SET NULL;
    END IF;
END $$;

-- به‌روزرسانی RLS policies برای در نظر گیری trainer_id
-- این policies قبلاً در create_meal_plans_rls_policies.sql تعریف شده‌اند
-- اما اگر نیاز به به‌روزرسانی باشد، می‌توانیم اینجا اضافه کنیم

