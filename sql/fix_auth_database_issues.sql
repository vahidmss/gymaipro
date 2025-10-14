-- اصلاح احتمالی مشکلات database برای authentication
-- این فایل مشکلات رایج را بررسی و اصلاح می‌کند

-- 1. بررسی و اصلاح RLS policies
-- اگر RLS خیلی محدودکننده باشد، ممکن است باعث خطا شود
SELECT 'Checking RLS status' as step;
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'profiles' AND schemaname = 'public';

-- 2. بررسی دسترسی‌های کاربران
SELECT 'Checking user permissions' as step;
SELECT 
    grantee,
    privilege_type,
    is_grantable
FROM information_schema.table_privileges 
WHERE table_name = 'profiles' 
    AND table_schema = 'public'
ORDER BY grantee, privilege_type;

-- 3. اصلاح احتمالی RLS policies (اگر لازم باشد)
-- این policies ممکن است خیلی محدودکننده باشند
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;

-- ایجاد RLS policies جدید و کمتر محدودکننده
CREATE POLICY "Enable read access for authenticated users" ON public.profiles
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Enable insert for authenticated users" ON public.profiles
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Enable update for authenticated users" ON public.profiles
    FOR UPDATE USING (auth.role() = 'authenticated');

-- 4. بررسی و اصلاح توابع database
-- اگر توابع وجود ندارند، آنها را ایجاد می‌کنیم

-- بررسی وجود تابع create_user_profile
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.routines 
        WHERE routine_name = 'create_user_profile' 
        AND routine_schema = 'public'
    ) THEN
        RAISE NOTICE 'create_user_profile function does not exist, creating...';
        
        -- ایجاد تابع create_user_profile
        CREATE OR REPLACE FUNCTION public.create_user_profile(
            user_id UUID,
            p_username TEXT,
            p_phone_number TEXT,
            p_email TEXT DEFAULT NULL
        )
        RETURNS JSON
        SECURITY DEFINER
        SET search_path = public, auth
        LANGUAGE plpgsql
        AS $$
        DECLARE
            result JSON;
            profile_data JSON;
        BEGIN
            -- بررسی اینکه آیا کاربر در auth.users وجود دارد
            IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = user_id) THEN
                RETURN json_build_object(
                    'success', false,
                    'error', 'User not found in auth.users',
                    'error_code', 'USER_NOT_FOUND'
                );
            END IF;

            -- بررسی اینکه آیا پروفایل از قبل وجود دارد
            IF EXISTS (SELECT 1 FROM public.profiles WHERE id = user_id) THEN
                RETURN json_build_object(
                    'success', false,
                    'error', 'Profile already exists',
                    'error_code', 'PROFILE_EXISTS'
                );
            END IF;

            -- بررسی تکراری نبودن نام کاربری
            IF EXISTS (SELECT 1 FROM public.profiles WHERE username = p_username) THEN
                RETURN json_build_object(
                    'success', false,
                    'error', 'Username already exists',
                    'error_code', 'USERNAME_EXISTS'
                );
            END IF;

            -- بررسی تکراری نبودن شماره موبایل
            IF EXISTS (SELECT 1 FROM public.profiles WHERE phone_number = p_phone_number) THEN
                RETURN json_build_object(
                    'success', false,
                    'error', 'Phone number already exists',
                    'error_code', 'PHONE_EXISTS'
                );
            END IF;

            -- بررسی تکراری نبودن ایمیل (اگر ارائه شده)
            IF p_email IS NOT NULL AND EXISTS (SELECT 1 FROM public.profiles WHERE email = p_email) THEN
                RETURN json_build_object(
                    'success', false,
                    'error', 'Email already exists',
                    'error_code', 'EMAIL_EXISTS'
                );
            END IF;

            -- ایجاد پروفایل
            BEGIN
                INSERT INTO public.profiles (
                    id,
                    username,
                    phone_number,
                    email,
                    role,
                    created_at,
                    updated_at
                ) VALUES (
                    user_id,
                    p_username,
                    p_phone_number,
                    p_email,
                    'athlete',
                    NOW(),
                    NOW()
                );

                -- بازگرداندن داده‌های پروفایل ایجاد شده
                SELECT json_build_object(
                    'id', id,
                    'username', username,
                    'phone_number', phone_number,
                    'email', email,
                    'role', role,
                    'created_at', created_at,
                    'updated_at', updated_at
                ) INTO profile_data
                FROM public.profiles
                WHERE id = user_id;

                RETURN json_build_object(
                    'success', true,
                    'profile', profile_data
                );

            EXCEPTION
                WHEN unique_violation THEN
                    RETURN json_build_object(
                        'success', false,
                        'error', 'Unique constraint violation',
                        'error_code', 'CONSTRAINT_VIOLATION',
                        'detail', SQLERRM
                    );
                WHEN foreign_key_violation THEN
                    RETURN json_build_object(
                        'success', false,
                        'error', 'Foreign key constraint violation',
                        'error_code', 'FK_VIOLATION',
                        'detail', SQLERRM
                    );
                WHEN OTHERS THEN
                    RETURN json_build_object(
                        'success', false,
                        'error', 'Database error: ' || SQLERRM,
                        'error_code', 'DB_ERROR',
                        'sqlstate', SQLSTATE
                    );
            END;
        END;
        $$;
        
        -- اعطای دسترسی
        GRANT EXECUTE ON FUNCTION public.create_user_profile(UUID, TEXT, TEXT, TEXT) TO authenticated;
        GRANT EXECUTE ON FUNCTION public.create_user_profile(UUID, TEXT, TEXT, TEXT) TO anon;
        
        RAISE NOTICE 'create_user_profile function created successfully';
    ELSE
        RAISE NOTICE 'create_user_profile function already exists';
    END IF;
END $$;

-- 5. بررسی و اصلاح تابع check_user_exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.routines 
        WHERE routine_name = 'check_user_exists' 
        AND routine_schema = 'public'
    ) THEN
        RAISE NOTICE 'check_user_exists function does not exist, creating...';
        
        CREATE OR REPLACE FUNCTION public.check_user_exists(phone TEXT)
        RETURNS BOOLEAN
        SECURITY DEFINER
        SET search_path = public
        LANGUAGE plpgsql
        AS $$
        BEGIN
            RETURN EXISTS (SELECT 1 FROM public.profiles WHERE phone_number = phone);
        END;
        $$;
        
        -- اعطای دسترسی
        GRANT EXECUTE ON FUNCTION public.check_user_exists(TEXT) TO authenticated;
        GRANT EXECUTE ON FUNCTION public.check_user_exists(TEXT) TO anon;
        
        RAISE NOTICE 'check_user_exists function created successfully';
    ELSE
        RAISE NOTICE 'check_user_exists function already exists';
    END IF;
END $$;

-- 6. بررسی و اصلاح تابع check_user_exists_by_phone
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.routines 
        WHERE routine_name = 'check_user_exists_by_phone' 
        AND routine_schema = 'public'
    ) THEN
        RAISE NOTICE 'check_user_exists_by_phone function does not exist, creating...';
        
        CREATE OR REPLACE FUNCTION public.check_user_exists_by_phone(p_phone_number TEXT)
        RETURNS JSON
        SECURITY DEFINER
        SET search_path = public
        LANGUAGE plpgsql
        AS $$
        BEGIN
            IF EXISTS (SELECT 1 FROM public.profiles WHERE phone_number = p_phone_number) THEN
                RETURN json_build_object(
                    'exists', true,
                    'in_profiles', true
                );
            ELSE
                RETURN json_build_object(
                    'exists', false,
                    'in_profiles', false
                );
            END IF;
        END;
        $$;
        
        -- اعطای دسترسی
        GRANT EXECUTE ON FUNCTION public.check_user_exists_by_phone(TEXT) TO authenticated;
        GRANT EXECUTE ON FUNCTION public.check_user_exists_by_phone(TEXT) TO anon;
        
        RAISE NOTICE 'check_user_exists_by_phone function created successfully';
    ELSE
        RAISE NOTICE 'check_user_exists_by_phone function already exists';
    END IF;
END $$;

-- 7. بررسی نهایی
SELECT 'Final verification' as step;
SELECT 
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
    AND routine_name IN ('create_user_profile', 'check_user_exists', 'check_user_exists_by_phone')
ORDER BY routine_name;

SELECT 'Database functions fix completed' as result;
