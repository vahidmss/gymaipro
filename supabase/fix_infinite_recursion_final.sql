-- رفع قطعی مشکل infinite recursion در RLS policies
-- Run this in Supabase Dashboard SQL Editor

-- 1. کاملاً غیرفعال کردن RLS موقتاً
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;

-- 2. حذف تمام policies موجود
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
DROP POLICY IF EXISTS "Allow registration validation" ON public.profiles;
DROP POLICY IF EXISTS "Allow profile creation" ON public.profiles;
DROP POLICY IF EXISTS "Trainers can view athlete profiles" ON public.profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Allow profile creation during registration" ON public.profiles;
DROP POLICY IF EXISTS "Allow registration checks" ON public.profiles;
DROP POLICY IF EXISTS "Allow all operations" ON public.profiles;
DROP POLICY IF EXISTS "Allow all operations temporarily" ON public.profiles;
DROP POLICY IF EXISTS "Allow validation checks" ON public.profiles;
DROP POLICY IF EXISTS "Allow username validation" ON public.profiles;
DROP POLICY IF EXISTS "Allow phone validation" ON public.profiles;
DROP POLICY IF EXISTS "Allow service role profile creation" ON public.profiles;
DROP POLICY IF EXISTS "Allow public profile checks" ON public.profiles;

-- 3. اطمینان از وجود ستون role
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS role text DEFAULT 'athlete';
UPDATE public.profiles SET role = 'athlete' WHERE role IS NULL;

-- 4. Grant permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON public.profiles TO anon, authenticated;
GRANT ALL ON public.otp_codes TO anon, authenticated;
GRANT USAGE ON SEQUENCE public.otp_codes_id_seq TO anon, authenticated;

-- 5. فعال کردن مجدد RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 6. ایجاد policies ساده و بدون recursion
-- کاربران می‌توانند پروفایل خود را ببینند
CREATE POLICY "Users can view own profile" ON public.profiles
  FOR SELECT USING (auth.uid() = id);

-- کاربران می‌توانند پروفایل خود را به‌روزرسانی کنند
CREATE POLICY "Users can update own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

-- کاربران می‌توانند پروفایل خود را ایجاد کنند (برای ثبت نام)
CREATE POLICY "Users can insert own profile" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- دسترسی عمومی برای بررسی username/phone در زمان ثبت نام
CREATE POLICY "Allow registration validation" ON public.profiles
  FOR SELECT USING (true);

-- 7. ایجاد جداول trainer_requests و trainer_clients
CREATE TABLE IF NOT EXISTS public.trainer_requests (
    id uuid not null default gen_random_uuid(),
    trainer_id uuid not null,
    client_username text not null,
    status text not null default 'pending' check (status in ('pending', 'accepted', 'rejected', 'blocked')),
    request_date timestamp with time zone not null default now(),
    response_date timestamp with time zone null,
    message text null,
    created_at timestamp with time zone not null default now(),
    updated_at timestamp with time zone not null default now(),
    constraint trainer_requests_pkey primary key (id)
);

CREATE TABLE IF NOT EXISTS public.trainer_clients (
    id uuid not null default gen_random_uuid(),
    trainer_id uuid not null,
    client_id uuid not null,
    status text not null default 'active' check (status in ('active', 'inactive', 'blocked')),
    start_date timestamp with time zone not null default now(),
    end_date timestamp with time zone null,
    notes text null,
    created_at timestamp with time zone not null default now(),
    updated_at timestamp with time zone not null default now(),
    constraint trainer_clients_pkey primary key (id),
    constraint trainer_clients_trainer_id_fkey foreign key (trainer_id) references profiles (id) on delete cascade,
    constraint trainer_clients_client_id_fkey foreign key (client_id) references profiles (id) on delete cascade,
    constraint trainer_clients_unique unique (trainer_id, client_id)
);

-- 8. تنظیم foreign key برای trainer_requests
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'trainer_requests_trainer_id_fkey'
    ) THEN
        ALTER TABLE trainer_requests DROP CONSTRAINT trainer_requests_trainer_id_fkey;
    END IF;
END $$;

ALTER TABLE trainer_requests
ADD CONSTRAINT trainer_requests_trainer_id_fkey
FOREIGN KEY (trainer_id) REFERENCES profiles (id) ON DELETE CASCADE;

-- 9. Grant permissions برای جداول جدید
GRANT ALL ON public.trainer_requests TO anon, authenticated;
GRANT ALL ON public.trainer_clients TO anon, authenticated;

-- 10. Enable RLS برای جداول جدید
ALTER TABLE public.trainer_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trainer_clients ENABLE ROW LEVEL SECURITY;

-- 11. ایجاد RLS policies برای جداول جدید
DROP POLICY IF EXISTS "Users can manage own trainer requests" ON public.trainer_requests;
DROP POLICY IF EXISTS "Users can manage own trainer clients" ON public.trainer_clients;

CREATE POLICY "Users can manage own trainer requests" ON public.trainer_requests
    FOR ALL USING (
        auth.uid() = trainer_id OR 
        auth.uid() IN (
            SELECT id FROM public.profiles 
            WHERE username = client_username
        )
    );

CREATE POLICY "Users can manage own trainer clients" ON public.trainer_clients
    FOR ALL USING (
        auth.uid() = trainer_id OR 
        auth.uid() = client_id
    );

-- 12. ایجاد indexes
CREATE INDEX IF NOT EXISTS idx_trainer_requests_trainer_id ON public.trainer_requests(trainer_id);
CREATE INDEX IF NOT EXISTS idx_trainer_requests_client_username ON public.trainer_requests(client_username);
CREATE INDEX IF NOT EXISTS idx_trainer_requests_status ON public.trainer_requests(status);

CREATE INDEX IF NOT EXISTS idx_trainer_clients_trainer_id ON public.trainer_clients(trainer_id);
CREATE INDEX IF NOT EXISTS idx_trainer_clients_client_id ON public.trainer_clients(client_id);
CREATE INDEX IF NOT EXISTS idx_trainer_clients_status ON public.trainer_clients(status);

-- 13. بررسی نهایی
SELECT 'Infinite recursion fixed successfully - All tables and policies created' as status; 