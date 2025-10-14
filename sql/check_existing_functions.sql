-- بررسی وجود توابع مورد نیاز
SELECT 
    routine_name,
    routine_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_schema = 'public' 
    AND routine_name IN ('create_user_profile', 'check_user_exists', 'check_user_exists_by_phone')
ORDER BY routine_name;
