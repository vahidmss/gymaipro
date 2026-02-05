-- RLS Policies for meal_plans table
-- این فایل باید بعد از ایجاد جدول meal_plans اجرا شود

-- فعال‌سازی Row Level Security
ALTER TABLE public.meal_plans ENABLE ROW LEVEL SECURITY;

-- حذف policies قبلی (اگر وجود داشته باشند)
DROP POLICY IF EXISTS "Users can view their own meal plans" ON public.meal_plans;
DROP POLICY IF EXISTS "Users can insert their own meal plans" ON public.meal_plans;
DROP POLICY IF EXISTS "Users can update their own meal plans" ON public.meal_plans;
DROP POLICY IF EXISTS "Users can delete their own meal plans" ON public.meal_plans;
DROP POLICY IF EXISTS "Trainers can view their clients meal plans" ON public.meal_plans;
DROP POLICY IF EXISTS "Trainers can insert meal plans for their clients" ON public.meal_plans;
DROP POLICY IF EXISTS "Trainers can update meal plans for their clients" ON public.meal_plans;
DROP POLICY IF EXISTS "Trainers can delete meal plans for their clients" ON public.meal_plans;

-- SELECT: کاربران می‌توانند برنامه‌های خود را ببینند
CREATE POLICY "Users can view their own meal plans" ON public.meal_plans
    FOR SELECT USING (auth.uid() = user_id);

-- SELECT: مربیان می‌توانند برنامه‌های شاگردان خود را ببینند (اگر رابطه active دارند)
CREATE POLICY "Trainers can view their clients meal plans" ON public.meal_plans
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.trainer_clients
            WHERE trainer_clients.trainer_id = auth.uid()
            AND trainer_clients.client_id = meal_plans.user_id
            AND trainer_clients.status = 'active'
        )
    );

-- INSERT: کاربران می‌توانند برنامه‌های خود را ایجاد کنند
CREATE POLICY "Users can insert their own meal plans" ON public.meal_plans
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- INSERT: مربیان می‌توانند برای شاگردان خود برنامه ایجاد کنند (اگر رابطه active دارند)
CREATE POLICY "Trainers can insert meal plans for their clients" ON public.meal_plans
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.trainer_clients
            WHERE trainer_clients.trainer_id = auth.uid()
            AND trainer_clients.client_id = meal_plans.user_id
            AND trainer_clients.status = 'active'
        )
    );

-- UPDATE: کاربران می‌توانند برنامه‌های خود را به‌روزرسانی کنند
CREATE POLICY "Users can update their own meal plans" ON public.meal_plans
    FOR UPDATE USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- UPDATE: مربیان می‌توانند برنامه‌های شاگردان خود را به‌روزرسانی کنند (اگر رابطه active دارند)
CREATE POLICY "Trainers can update meal plans for their clients" ON public.meal_plans
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.trainer_clients
            WHERE trainer_clients.trainer_id = auth.uid()
            AND trainer_clients.client_id = meal_plans.user_id
            AND trainer_clients.status = 'active'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.trainer_clients
            WHERE trainer_clients.trainer_id = auth.uid()
            AND trainer_clients.client_id = meal_plans.user_id
            AND trainer_clients.status = 'active'
        )
    );

-- DELETE: کاربران می‌توانند برنامه‌های خود را حذف کنند
CREATE POLICY "Users can delete their own meal plans" ON public.meal_plans
    FOR DELETE USING (auth.uid() = user_id);

-- DELETE: مربیان می‌توانند برنامه‌های شاگردان خود را حذف کنند (اگر رابطه active دارند)
CREATE POLICY "Trainers can delete meal plans for their clients" ON public.meal_plans
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM public.trainer_clients
            WHERE trainer_clients.trainer_id = auth.uid()
            AND trainer_clients.client_id = meal_plans.user_id
            AND trainer_clients.status = 'active'
        )
    );

