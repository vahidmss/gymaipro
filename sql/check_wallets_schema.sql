-- بررسی ساختار جدول wallets
SELECT 
  column_name, 
  data_type, 
  is_nullable, 
  column_default
FROM information_schema.columns 
WHERE table_name = 'wallets' 
ORDER BY ordinal_position;

-- نمایش تمام جداول
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name LIKE '%wallet%';

-- بررسی وجود جدول wallets
SELECT EXISTS (
  SELECT 1 
  FROM information_schema.tables 
  WHERE table_name = 'wallets' 
  AND table_schema = 'public'
) as wallets_exists;
