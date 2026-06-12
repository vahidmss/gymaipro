-- فقط برای دیتابیس‌هایی که جدول custom_exercises از قبل دارند.
-- اگر create_custom_exercises_table.sql را دوباره اجرا کردید و خطای policy گرفتید،
-- همین فایل را اجرا کنید (نه کل اسکریپت create).

ALTER TABLE public.custom_exercises
    ADD COLUMN IF NOT EXISTS muscle_targets_json JSONB NOT NULL DEFAULT '{}'::jsonb;
