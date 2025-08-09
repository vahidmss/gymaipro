-- Trainer System Final Setup
-- این فایل را در Supabase SQL Editor اجرا کنید

-- 1. جدول trainer_details (در حال حاضر موجود است)
-- بررسی و اطمینان از وجود
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'trainer_details') THEN
        CREATE TABLE public.trainer_details (
            id uuid not null,
            specialties text[] null,
            experience_years integer null,
            certifications text[] null,
            education text null,
            hourly_rate numeric null,
            availability json null,
            bio_extended text null,
            created_at timestamp with time zone not null default now(),
            updated_at timestamp with time zone not null default now(),
            constraint trainer_details_pkey primary key (id),
            constraint trainer_details_id_fkey foreign KEY (id) references profiles (id) on delete CASCADE
        );
        RAISE NOTICE 'Created trainer_details table';
    ELSE
        RAISE NOTICE 'trainer_details table already exists';
    END IF;
END $$;

-- 2. ایجاد جدول trainer_requests (اگر وجود ندارد)
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

-- 3. اصلاح foreign key برای trainer_requests
DO $$ 
BEGIN
    -- حذف constraint قدیمی اگر وجود دارد
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'trainer_requests_trainer_id_fkey'
    ) THEN
        ALTER TABLE trainer_requests DROP CONSTRAINT trainer_requests_trainer_id_fkey;
        RAISE NOTICE 'Dropped old foreign key constraint';
    END IF;
    
    -- اضافه کردن constraint جدید
    ALTER TABLE trainer_requests 
    ADD CONSTRAINT trainer_requests_trainer_id_fkey 
    FOREIGN KEY (trainer_id) REFERENCES profiles (id) ON DELETE CASCADE;
    
    RAISE NOTICE 'Added new foreign key constraint to profiles table';
END $$;

-- 4. ایجاد جدول trainer_clients (ضروری!)
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

-- 5. ایجاد جدول trainer_reviews (اختیاری - برای آینده)
CREATE TABLE IF NOT EXISTS public.trainer_reviews (
    id uuid not null default gen_random_uuid(),
    trainer_id uuid not null,
    client_id uuid not null,
    rating integer not null check (rating >= 1 and rating <= 5),
    review text null,
    created_at timestamp with time zone not null default now(),
    updated_at timestamp with time zone not null default now(),
    constraint trainer_reviews_pkey primary key (id),
    constraint trainer_reviews_trainer_id_fkey foreign key (trainer_id) references profiles (id) on delete cascade,
    constraint trainer_reviews_client_id_fkey foreign key (client_id) references profiles (id) on delete cascade,
    constraint trainer_reviews_unique unique (trainer_id, client_id)
);

-- 6. ایجاد Index ها برای عملکرد بهتر
CREATE INDEX IF NOT EXISTS idx_trainer_requests_trainer_id ON trainer_requests(trainer_id);
CREATE INDEX IF NOT EXISTS idx_trainer_requests_client_username ON trainer_requests(client_username);
CREATE INDEX IF NOT EXISTS idx_trainer_requests_status ON trainer_requests(status);

CREATE INDEX IF NOT EXISTS idx_trainer_clients_trainer_id ON trainer_clients(trainer_id);
CREATE INDEX IF NOT EXISTS idx_trainer_clients_client_id ON trainer_clients(client_id);
CREATE INDEX IF NOT EXISTS idx_trainer_clients_status ON trainer_clients(status);

CREATE INDEX IF NOT EXISTS idx_trainer_reviews_trainer_id ON trainer_reviews(trainer_id);
CREATE INDEX IF NOT EXISTS idx_trainer_reviews_client_id ON trainer_reviews(client_id);

-- 7. فعال‌سازی Row Level Security
ALTER TABLE trainer_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE trainer_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE trainer_clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE trainer_reviews ENABLE ROW LEVEL SECURITY;

-- 8. ایجاد Policies برای trainer_details
DROP POLICY IF EXISTS trainer_details_select_policy ON trainer_details;
CREATE POLICY trainer_details_select_policy ON trainer_details
    FOR SELECT USING (true);

DROP POLICY IF EXISTS trainer_details_insert_policy ON trainer_details;
CREATE POLICY trainer_details_insert_policy ON trainer_details
    FOR INSERT WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS trainer_details_update_policy ON trainer_details;
CREATE POLICY trainer_details_update_policy ON trainer_details
    FOR UPDATE USING (auth.uid() = id);

-- 9. ایجاد Policies برای trainer_requests
DROP POLICY IF EXISTS trainer_requests_select_policy ON trainer_requests;
CREATE POLICY trainer_requests_select_policy ON trainer_requests
    FOR SELECT USING (
        auth.uid() = trainer_id OR 
        client_username = (SELECT username FROM profiles WHERE id = auth.uid())
    );

DROP POLICY IF EXISTS trainer_requests_insert_policy ON trainer_requests;
CREATE POLICY trainer_requests_insert_policy ON trainer_requests
    FOR INSERT WITH CHECK (auth.uid() = trainer_id);

DROP POLICY IF EXISTS trainer_requests_update_policy ON trainer_requests;
CREATE POLICY trainer_requests_update_policy ON trainer_requests
    FOR UPDATE USING (
        auth.uid() = trainer_id OR 
        client_username = (SELECT username FROM profiles WHERE id = auth.uid())
    );

-- 10. ایجاد Policies برای trainer_clients
DROP POLICY IF EXISTS trainer_clients_select_policy ON trainer_clients;
CREATE POLICY trainer_clients_select_policy ON trainer_clients
    FOR SELECT USING (auth.uid() = trainer_id OR auth.uid() = client_id);

DROP POLICY IF EXISTS trainer_clients_insert_policy ON trainer_clients;
CREATE POLICY trainer_clients_insert_policy ON trainer_clients
    FOR INSERT WITH CHECK (auth.uid() = trainer_id OR auth.uid() = client_id);

DROP POLICY IF EXISTS trainer_clients_update_policy ON trainer_clients;
CREATE POLICY trainer_clients_update_policy ON trainer_clients
    FOR UPDATE USING (auth.uid() = trainer_id OR auth.uid() = client_id);

-- 11. ایجاد Policies برای trainer_reviews
DROP POLICY IF EXISTS trainer_reviews_select_policy ON trainer_reviews;
CREATE POLICY trainer_reviews_select_policy ON trainer_reviews
    FOR SELECT USING (true);

DROP POLICY IF EXISTS trainer_reviews_insert_policy ON trainer_reviews;
CREATE POLICY trainer_reviews_insert_policy ON trainer_reviews
    FOR INSERT WITH CHECK (auth.uid() = client_id);

DROP POLICY IF EXISTS trainer_reviews_update_policy ON trainer_reviews;
CREATE POLICY trainer_reviews_update_policy ON trainer_reviews
    FOR UPDATE USING (auth.uid() = client_id);

-- 12. بررسی نهایی ساختار جداول
SELECT 
    'trainer_details' as table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'trainer_details'
ORDER BY ordinal_position;

SELECT 
    'trainer_requests' as table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'trainer_requests'
ORDER BY ordinal_position;

SELECT 
    'trainer_clients' as table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'trainer_clients'
ORDER BY ordinal_position;

SELECT 
    'trainer_reviews' as table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'trainer_reviews'
ORDER BY ordinal_position;

-- 13. پیام موفقیت
DO $$
BEGIN
    RAISE NOTICE 'Trainer system setup completed successfully!';
    RAISE NOTICE 'All tables, indexes, and policies have been created.';
END $$; 