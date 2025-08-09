-- Test queries for trainer system
-- این فایل برای تست سیستم مربی-شاگرد استفاده می‌شود

-- 1. مشاهده تمام درخواست‌های مربی
SELECT 
    tr.id,
    tr.trainer_id,
    tr.client_username,
    tr.status,
    tr.request_date,
    tr.response_date,
    tr.message,
    p1.username as trainer_username,
    p2.username as client_username_actual
FROM trainer_requests tr
LEFT JOIN profiles p1 ON tr.trainer_id = p1.user_id
LEFT JOIN profiles p2 ON p2.username = tr.client_username
ORDER BY tr.created_at DESC;

-- 2. مشاهده تمام روابط مربی-شاگرد
SELECT 
    tc.id,
    tc.trainer_id,
    tc.client_id,
    tc.status,
    tc.start_date,
    tc.end_date,
    tc.notes,
    p1.username as trainer_username,
    p2.username as client_username
FROM trainer_clients tc
LEFT JOIN profiles p1 ON tc.trainer_id = p1.user_id
LEFT JOIN profiles p2 ON tc.client_id = p2.user_id
ORDER BY tc.created_at DESC;

-- 3. آمار درخواست‌ها برای یک مربی خاص
SELECT 
    status,
    COUNT(*) as count
FROM trainer_requests 
WHERE trainer_id = 'YOUR_TRAINER_ID_HERE'
GROUP BY status;

-- 4. مشاهده درخواست‌های ارسالی به یک کاربر خاص
SELECT 
    tr.*,
    p.username as trainer_username
FROM trainer_requests tr
LEFT JOIN profiles p ON tr.trainer_id = p.user_id
WHERE tr.client_username = 'TARGET_USERNAME_HERE'
ORDER BY tr.created_at DESC;

-- 5. مشاهده شاگردان فعال یک مربی
SELECT 
    tc.*,
    p.username as client_username,
    p.full_name as client_full_name
FROM trainer_clients tc
LEFT JOIN profiles p ON tc.client_id = p.user_id
WHERE tc.trainer_id = 'YOUR_TRAINER_ID_HERE' 
AND tc.status = 'active'
ORDER BY tc.start_date DESC;

-- 6. مشاهده مربیان یک شاگرد
SELECT 
    tc.*,
    p.username as trainer_username,
    p.full_name as trainer_full_name
FROM trainer_clients tc
LEFT JOIN profiles p ON tc.trainer_id = p.user_id
WHERE tc.client_id = 'YOUR_CLIENT_ID_HERE' 
AND tc.status = 'active'
ORDER BY tc.start_date DESC;

-- 7. آمار کلی سیستم
SELECT 
    'Total Requests' as metric,
    COUNT(*) as value
FROM trainer_requests
UNION ALL
SELECT 
    'Pending Requests' as metric,
    COUNT(*) as value
FROM trainer_requests
WHERE status = 'pending'
UNION ALL
SELECT 
    'Accepted Requests' as metric,
    COUNT(*) as value
FROM trainer_requests
WHERE status = 'accepted'
UNION ALL
SELECT 
    'Active Relationships' as metric,
    COUNT(*) as value
FROM trainer_clients
WHERE status = 'active';

-- 8. پاک کردن داده‌های تست (در صورت نیاز)
-- DELETE FROM trainer_clients;
-- DELETE FROM trainer_requests;

-- 9. بررسی عملکرد trigger
-- این کوئری نشان می‌دهد که آیا trigger درست کار می‌کند یا نه
SELECT 
    tr.id as request_id,
    tr.status as request_status,
    tc.id as relationship_id,
    tc.status as relationship_status
FROM trainer_requests tr
LEFT JOIN trainer_clients tc ON tr.trainer_id = tc.trainer_id 
    AND tc.client_id = (SELECT user_id FROM profiles WHERE username = tr.client_username)
WHERE tr.status = 'accepted'
ORDER BY tr.updated_at DESC; 