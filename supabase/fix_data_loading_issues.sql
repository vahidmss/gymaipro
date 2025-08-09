-- رفع مشکلات فراخوانی اطلاعات
-- Run this in Supabase Dashboard SQL Editor

-- 1. اطمینان از وجود ستون role در profiles
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS role text DEFAULT 'athlete';

-- 2. به‌روزرسانی profiles موجود
UPDATE public.profiles SET role = 'athlete' WHERE role IS NULL;

-- 3. ایجاد جدول trainer_requests اگر وجود ندارد
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

-- 4. ایجاد جدول trainer_clients اگر وجود ندارد
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

-- 5. حذف foreign key قدیمی اگر وجود دارد
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'trainer_requests_trainer_id_fkey'
    ) THEN
        ALTER TABLE trainer_requests DROP CONSTRAINT trainer_requests_trainer_id_fkey;
    END IF;
END $$;

-- 6. اضافه کردن foreign key جدید
ALTER TABLE trainer_requests
ADD CONSTRAINT trainer_requests_trainer_id_fkey
FOREIGN KEY (trainer_id) REFERENCES profiles (id) ON DELETE CASCADE;

-- 7. Grant permissions
GRANT ALL ON public.trainer_requests TO anon, authenticated;
GRANT ALL ON public.trainer_clients TO anon, authenticated;

-- 8. Enable RLS
ALTER TABLE public.trainer_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trainer_clients ENABLE ROW LEVEL SECURITY;

-- 9. Drop existing policies
DROP POLICY IF EXISTS "Users can manage own trainer requests" ON public.trainer_requests;
DROP POLICY IF EXISTS "Users can manage own trainer clients" ON public.trainer_clients;

-- 10. Create RLS policies for trainer_requests
CREATE POLICY "Users can manage own trainer requests" ON public.trainer_requests
    FOR ALL USING (
        auth.uid() = trainer_id OR 
        auth.uid() IN (
            SELECT id FROM public.profiles 
            WHERE username = client_username
        )
    );

-- 11. Create RLS policies for trainer_clients
CREATE POLICY "Users can manage own trainer clients" ON public.trainer_clients
    FOR ALL USING (
        auth.uid() = trainer_id OR 
        auth.uid() = client_id
    );

-- 12. ایجاد indexes برای بهبود عملکرد
CREATE INDEX IF NOT EXISTS idx_trainer_requests_trainer_id ON public.trainer_requests(trainer_id);
CREATE INDEX IF NOT EXISTS idx_trainer_requests_client_username ON public.trainer_requests(client_username);
CREATE INDEX IF NOT EXISTS idx_trainer_requests_status ON public.trainer_requests(status);

CREATE INDEX IF NOT EXISTS idx_trainer_clients_trainer_id ON public.trainer_clients(trainer_id);
CREATE INDEX IF NOT EXISTS idx_trainer_clients_client_id ON public.trainer_clients(client_id);
CREATE INDEX IF NOT EXISTS idx_trainer_clients_status ON public.trainer_clients(status);

-- 13. بررسی نهایی
SELECT 'Database setup completed successfully' as status; 