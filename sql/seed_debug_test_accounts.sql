-- =============================================================================
-- Seed: سه اکانت تستی دیباگ (athlete / trainer / admin)
-- =============================================================================
-- اجرا در Supabase → SQL Editor (یک‌بار کافی است؛ idempotent).
--
-- | نقش     | شماره       | یوزرنیم         | ایمیل              | پسورد       |
-- |---------|-------------|-----------------|--------------------|-------------|
-- | athlete | 09129999001 | debug_athlete   | 9129999001@gym.ai  | 09129999001 |
-- | trainer | 09129999002 | debug_trainer   | 9129999002@gym.ai  | 09129999002 |
-- | admin   | 09129999003 | debug_admin     | 9129999003@gym.ai  | 09129999003 |
--
-- مارکر پاک‌سازی:
--   • username پیشوند debug_
--   • phone در 09129999001..003
--   • bio شامل [DEBUG_TEST_ACCOUNT]
--
-- بعد از تست: بخش CLEANUP پایین همین فایل را اجرا کنید.
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

DO $$
DECLARE
  v_instance_id UUID := '00000000-0000-0000-0000-000000000000';
  r RECORD;
  v_user_id UUID;
  v_email TEXT;
  v_password TEXT;
BEGIN
  FOR r IN
    SELECT * FROM (VALUES
      (
        'a0112999-9001-4000-8000-000000000001'::uuid,
        '09129999001',
        'debug_athlete',
        'athlete',
        'ورزشکار',
        'تست'
      ),
      (
        'a0112999-9002-4000-8000-000000000002'::uuid,
        '09129999002',
        'debug_trainer',
        'trainer',
        'مربی',
        'تست'
      ),
      (
        'a0112999-9003-4000-8000-000000000003'::uuid,
        '09129999003',
        'debug_admin',
        'admin',
        'ادمین',
        'تست'
      )
    ) AS t(fixed_id, phone, username, role, first_name, last_name)
  LOOP
    -- ایمیل مطابق قرارداد اپ (رقم‌های شماره بدون صفر اول + @gym.ai)
    v_email := regexp_replace(r.phone, '^0+', '') || '@gym.ai';
    v_password := r.phone;

    -- اگر از قبل با همین ایمیل / شماره / یوزرنیم وجود داشت، همان id را بگیر
    SELECT u.id INTO v_user_id
    FROM auth.users u
    WHERE lower(u.email) = lower(v_email)
    LIMIT 1;

    IF v_user_id IS NULL THEN
      SELECT p.id INTO v_user_id
      FROM public.profiles p
      WHERE p.phone_number = r.phone
         OR p.username = r.username
      LIMIT 1;
    END IF;

    IF v_user_id IS NULL THEN
      v_user_id := r.fixed_id;
    END IF;

    -- auth.users
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = v_user_id) THEN
      INSERT INTO auth.users (
        instance_id,
        id,
        aud,
        role,
        email,
        encrypted_password,
        email_confirmed_at,
        recovery_sent_at,
        last_sign_in_at,
        raw_app_meta_data,
        raw_user_meta_data,
        created_at,
        updated_at,
        confirmation_token,
        email_change,
        email_change_token_new,
        recovery_token
      ) VALUES (
        v_instance_id,
        v_user_id,
        'authenticated',
        'authenticated',
        v_email,
        crypt(v_password, gen_salt('bf')),
        NOW(),
        NOW(),
        NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        jsonb_build_object(
          'username', r.username,
          'phone', r.phone,
          'debug_test_account', true
        ),
        NOW(),
        NOW(),
        '',
        '',
        '',
        ''
      );
    ELSE
      UPDATE auth.users
      SET
        email = v_email,
        encrypted_password = crypt(v_password, gen_salt('bf')),
        email_confirmed_at = COALESCE(email_confirmed_at, NOW()),
        raw_app_meta_data = '{"provider":"email","providers":["email"]}'::jsonb,
        updated_at = NOW()
      WHERE id = v_user_id;
    END IF;

    -- auth.identities (لازم برای signInWithPassword)
    IF NOT EXISTS (
      SELECT 1
      FROM auth.identities
      WHERE user_id = v_user_id
        AND provider = 'email'
    ) THEN
      INSERT INTO auth.identities (
        id,
        user_id,
        identity_data,
        provider,
        provider_id,
        last_sign_in_at,
        created_at,
        updated_at
      ) VALUES (
        v_user_id,
        v_user_id,
        jsonb_build_object(
          'sub', v_user_id::text,
          'email', v_email,
          'email_verified', true
        ),
        'email',
        v_user_id::text,
        NOW(),
        NOW(),
        NOW()
      );
    ELSE
      UPDATE auth.identities
      SET
        identity_data = jsonb_build_object(
          'sub', v_user_id::text,
          'email', v_email,
          'email_verified', true
        ),
        provider_id = v_user_id::text,
        updated_at = NOW()
      WHERE user_id = v_user_id
        AND provider = 'email';
    END IF;

    -- profiles
    IF EXISTS (SELECT 1 FROM public.profiles WHERE id = v_user_id) THEN
      UPDATE public.profiles
      SET
        username = r.username,
        phone_number = r.phone,
        email = v_email,
        first_name = r.first_name,
        last_name = r.last_name,
        role = r.role::public.user_role,
        auth_user_id = v_user_id,
        bio = '[DEBUG_TEST_ACCOUNT] اکانت تستی دیباگ — قابل حذف با seed_debug_test_accounts.sql',
        updated_at = NOW()
      WHERE id = v_user_id;
    ELSIF EXISTS (
      SELECT 1 FROM public.profiles
      WHERE phone_number = r.phone OR username = r.username
    ) THEN
      UPDATE public.profiles
      SET
        username = r.username,
        phone_number = r.phone,
        email = v_email,
        first_name = r.first_name,
        last_name = r.last_name,
        role = r.role::public.user_role,
        auth_user_id = v_user_id,
        bio = '[DEBUG_TEST_ACCOUNT] اکانت تستی دیباگ — قابل حذف با seed_debug_test_accounts.sql',
        updated_at = NOW()
      WHERE phone_number = r.phone
         OR username = r.username;
    ELSE
      INSERT INTO public.profiles (
        id,
        username,
        phone_number,
        email,
        first_name,
        last_name,
        role,
        auth_user_id,
        bio,
        created_at,
        updated_at
      ) VALUES (
        v_user_id,
        r.username,
        r.phone,
        v_email,
        r.first_name,
        r.last_name,
        r.role::public.user_role,
        v_user_id,
        '[DEBUG_TEST_ACCOUNT] اکانت تستی دیباگ — قابل حذف با seed_debug_test_accounts.sql',
        NOW(),
        NOW()
      );
    END IF;

    RAISE NOTICE 'debug account ready: % (%) id=%', r.username, r.role, v_user_id;
  END LOOP;
END $$;

-- تأیید
SELECT
  p.id,
  p.username,
  p.phone_number,
  p.email,
  p.role,
  p.auth_user_id,
  p.bio
FROM public.profiles p
WHERE p.username LIKE 'debug_%'
   OR p.phone_number IN ('09129999001', '09129999002', '09129999003')
   OR p.bio LIKE '%[DEBUG_TEST_ACCOUNT]%'
ORDER BY p.phone_number;


-- =============================================================================
-- CLEANUP — فقط بعد از اتمام تست‌ها اجرا کنید
-- =============================================================================
-- این بلوک به‌صورت پیش‌فرض کامنت است. برای پاک کردن، کل بلوک زیر را
-- از حالت کامنت خارج کرده و اجرا کنید.
-- =============================================================================

/*
DO $$
DECLARE
  v_ids UUID[];
BEGIN
  SELECT ARRAY_AGG(DISTINCT id)
  INTO v_ids
  FROM (
    SELECT id FROM public.profiles
    WHERE username LIKE 'debug_%'
       OR phone_number IN ('09129999001', '09129999002', '09129999003')
       OR bio LIKE '%[DEBUG_TEST_ACCOUNT]%'
    UNION
    SELECT id FROM auth.users
    WHERE lower(email) IN (
      '9129999001@gym.ai',
      '9129999002@gym.ai',
      '9129999003@gym.ai'
    )
       OR id IN (
         'a0112999-9001-4000-8000-000000000001'::uuid,
         'a0112999-9002-4000-8000-000000000002'::uuid,
         'a0112999-9003-4000-8000-000000000003'::uuid
       )
  ) s;

  IF v_ids IS NULL OR array_length(v_ids, 1) IS NULL THEN
    RAISE NOTICE 'No debug test accounts found to delete.';
    RETURN;
  END IF;

  RAISE NOTICE 'Deleting debug test account ids: %', v_ids;

  -- پروفایل‌ها (اگر FK به auth نباشد یا cascade ناقص باشد)
  DELETE FROM public.profiles WHERE id = ANY (v_ids);
  DELETE FROM public.profiles WHERE auth_user_id = ANY (v_ids);

  -- identities سپس users (cascade اغلب profiles را هم می‌برد اگر FK درست باشد)
  DELETE FROM auth.identities WHERE user_id = ANY (v_ids);
  DELETE FROM auth.users WHERE id = ANY (v_ids);

  RAISE NOTICE 'Debug test accounts removed.';
END $$;

SELECT
  p.id,
  p.username,
  p.phone_number
FROM public.profiles p
WHERE p.username LIKE 'debug_%'
   OR p.phone_number IN ('09129999001', '09129999002', '09129999003')
   OR p.bio LIKE '%[DEBUG_TEST_ACCOUNT]%';
*/
