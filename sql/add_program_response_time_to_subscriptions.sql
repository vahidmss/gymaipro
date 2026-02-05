-- افزودن ستون program_response_time به جدول trainer_subscriptions
-- این فایل باید در Supabase SQL Editor اجرا شود

-- افزودن ستون program_response_time (زمان انتظار تا ارسال برنامه - به ثانیه)
-- این زمان از created_at (زمان خرید) تا sent_at (زمان ارسال برنامه) محاسبه می‌شود
ALTER TABLE public.trainer_subscriptions
ADD COLUMN IF NOT EXISTS program_response_time INTEGER;

-- ایجاد ایندکس برای بهبود عملکرد جستجو و رتبه‌بندی
CREATE INDEX IF NOT EXISTS idx_trainer_subscriptions_program_response_time 
ON public.trainer_subscriptions(program_response_time);

-- توضیح: 
-- - program_response_time: مدت زمان انتظار تا ارسال برنامه (به ثانیه)
-- - این فیلد برای رتبه‌بندی مربی‌ها بر اساس سرعت پاسخ استفاده می‌شود
-- - هرچه این عدد کمتر باشد، مربی سریع‌تر پاسخ داده است

