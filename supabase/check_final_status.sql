-- Check Final Status of Tables and Policies
-- Run these queries in Supabase SQL Editor to verify everything is set up correctly

-- 1. Check profiles table structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'profiles' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Check otp_codes table structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'otp_codes' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 3. Check RLS status on profiles table
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'profiles' 
AND schemaname = 'public';

-- 4. Check all RLS policies on profiles table
SELECT 
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'profiles' 
AND schemaname = 'public'
ORDER BY policyname;

-- 5. Check RLS status on otp_codes table
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'otp_codes' 
AND schemaname = 'public';

-- 6. Check all RLS policies on otp_codes table
SELECT 
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'otp_codes' 
AND schemaname = 'public'
ORDER BY policyname;

-- 7. Check user_role enum
SELECT 
    t.typname AS enum_name,
    e.enumlabel AS enum_value
FROM pg_type t 
JOIN pg_enum e ON t.oid = e.enumtypid  
WHERE t.typname = 'user_role'
ORDER BY e.enumsortorder;

-- 8. Check functions
SELECT 
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN (
    'cleanup_expired_otp_codes',
    'manual_cleanup_otp_codes',
    'is_authenticated',
    'is_admin',
    'is_trainer',
    'handle_updated_at'
)
ORDER BY routine_name;

-- 9. Check triggers
SELECT 
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers 
WHERE trigger_schema = 'public' 
AND event_object_table = 'profiles'
ORDER BY trigger_name;

-- 10. Check indexes on profiles table
SELECT 
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'profiles' 
AND schemaname = 'public'
ORDER BY indexname;

-- 11. Check indexes on otp_codes table
SELECT 
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'otp_codes' 
AND schemaname = 'public'
ORDER BY indexname;

-- 12. Check permissions
SELECT 
    grantee,
    table_name,
    privilege_type
FROM information_schema.role_table_grants 
WHERE table_schema = 'public' 
AND table_name IN ('profiles', 'otp_codes')
ORDER BY table_name, grantee, privilege_type;

-- 13. Check sequence permissions
SELECT 
    grantee,
    object_name as sequence_name,
    privilege_type
FROM information_schema.role_usage_grants 
WHERE object_schema = 'public' 
AND object_name = 'otp_codes_id_seq'
ORDER BY grantee, privilege_type;

-- 14. Check function permissions
SELECT 
    grantee,
    routine_name,
    privilege_type
FROM information_schema.role_routine_grants 
WHERE routine_schema = 'public' 
AND routine_name IN (
    'cleanup_expired_otp_codes',
    'manual_cleanup_otp_codes',
    'is_authenticated',
    'is_admin',
    'is_trainer'
)
ORDER BY routine_name, grantee, privilege_type; 