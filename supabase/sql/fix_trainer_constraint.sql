-- اصلاح constraint جدول trainer_clients برای اضافه کردن 'pending'
-- این فایل constraint قدیمی را حذف و constraint جدید با 'pending' اضافه می‌کند

-- 1. حذف constraint قدیمی
ALTER TABLE trainer_clients DROP CONSTRAINT IF EXISTS trainer_clients_status_check;

-- 2. اضافه کردن constraint جدید با 'pending'
ALTER TABLE trainer_clients 
ADD CONSTRAINT trainer_clients_status_check 
CHECK (status IN ('active', 'inactive', 'blocked', 'pending'));

-- 3. تغییر default value به 'pending'
ALTER TABLE trainer_clients ALTER COLUMN status SET DEFAULT 'pending';

-- 4. نمایش نتیجه
SELECT 
    constraint_name,
    check_clause
FROM information_schema.check_constraints 
WHERE constraint_name = 'trainer_clients_status_check'; 