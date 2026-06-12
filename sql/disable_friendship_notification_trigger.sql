-- فقط یک منبع اعلان: کلاینت (برای INSERT جدید) / resend از کلاینت
-- این trigger را غیرفعال کنید تا اعلان تکراری در داشبورد نیاید.

DROP TRIGGER IF EXISTS friendship_request_notify_trigger ON public.friendship_requests;

-- اختیاری: تابع را نگه دارید ولی trigger را حذف کردیم.
-- CREATE TRIGGER ... را دوباره فعال نکنید مگر dedup کامل داشته باشید.
