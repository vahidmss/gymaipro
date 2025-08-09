-- Simple fix for missing start_date column in trainer_clients table
-- این فایل را در Supabase SQL Editor اجرا کنید

-- 1. ابتدا بررسی کنید که آیا جداول وجود دارند
SELECT table_name 
FROM information_schema.tables 
WHERE table_name IN ('trainer_requests', 'trainer_clients');

-- 2. اگر جدول trainer_clients وجود ندارد، آن را ایجاد کنید
CREATE TABLE IF NOT EXISTS trainer_clients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trainer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'blocked')),
    start_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    end_date TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE(trainer_id, client_id)
);

-- 3. اگر جدول trainer_requests وجود ندارد، آن را ایجاد کنید
CREATE TABLE IF NOT EXISTS trainer_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trainer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    client_username TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'blocked')),
    request_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    response_date TIMESTAMP WITH TIME ZONE,
    message TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- 4. اگر فیلد start_date در جدول trainer_clients وجود ندارد، آن را اضافه کنید
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'trainer_clients' 
        AND column_name = 'start_date'
    ) THEN
        ALTER TABLE trainer_clients ADD COLUMN start_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW();
        RAISE NOTICE 'Added start_date column to trainer_clients table';
    ELSE
        RAISE NOTICE 'start_date column already exists in trainer_clients table';
    END IF;
END $$;

-- 5. اگر فیلد end_date در جدول trainer_clients وجود ندارد، آن را اضافه کنید
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'trainer_clients' 
        AND column_name = 'end_date'
    ) THEN
        ALTER TABLE trainer_clients ADD COLUMN end_date TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE 'Added end_date column to trainer_clients table';
    ELSE
        RAISE NOTICE 'end_date column already exists in trainer_clients table';
    END IF;
END $$;

-- 6. اگر فیلد notes در جدول trainer_clients وجود ندارد، آن را اضافه کنید
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'trainer_clients' 
        AND column_name = 'notes'
    ) THEN
        ALTER TABLE trainer_clients ADD COLUMN notes TEXT;
        RAISE NOTICE 'Added notes column to trainer_clients table';
    ELSE
        RAISE NOTICE 'notes column already exists in trainer_clients table';
    END IF;
END $$;

-- 7. اگر فیلد updated_at در جدول trainer_clients وجود ندارد، آن را اضافه کنید
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'trainer_clients' 
        AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE trainer_clients ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW();
        RAISE NOTICE 'Added updated_at column to trainer_clients table';
    ELSE
        RAISE NOTICE 'updated_at column already exists in trainer_clients table';
    END IF;
END $$;

-- 8. بررسی ساختار نهایی جداول
SELECT 
    'trainer_clients' as table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'trainer_clients'
ORDER BY ordinal_position;

SELECT 
    'trainer_requests' as table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'trainer_requests'
ORDER BY ordinal_position;

-- 9. تست ساده - ایجاد یک درخواست تست
-- این کوئری را فقط برای تست اجرا کنید
/*
INSERT INTO trainer_requests (trainer_id, client_username, message)
VALUES (
    (SELECT id FROM auth.users LIMIT 1), 
    'test_user', 
    'این یک درخواست تست است'
);
*/ 