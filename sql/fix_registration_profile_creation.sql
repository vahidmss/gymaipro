-- تابع برای ایجاد پروفایل کاربر با دسترسی مناسب
CREATE OR REPLACE FUNCTION public.create_user_profile(
    user_id UUID,
    p_username TEXT,
    p_phone_number TEXT,
    p_email TEXT DEFAULT NULL
)
RETURNS JSON
SECURITY DEFINER -- این تابع با دسترسی‌های صاحب آن (postgres) اجرا می‌شود
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

-- اعطای دسترسی به کاربران احراز هویت شده
GRANT EXECUTE ON FUNCTION public.create_user_profile(UUID, TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_user_profile(UUID, TEXT, TEXT, TEXT) TO anon;

-- تابع کمکی برای بررسی وجود کاربر بر اساس شماره موبایل
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

-- تابع سازگار با کد موجود (check_user_exists)
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
