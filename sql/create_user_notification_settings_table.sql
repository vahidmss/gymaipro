-- جدول تنظیمات اعلان‌های کاربران
CREATE TABLE IF NOT EXISTS public.user_notification_settings (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  chat_notifications boolean NOT NULL DEFAULT true,
  workout_notifications boolean NOT NULL DEFAULT true,
  friend_request_notifications boolean NOT NULL DEFAULT true,
  trainer_request_notifications boolean NOT NULL DEFAULT true,
  trainer_message_notifications boolean NOT NULL DEFAULT true,
  general_notifications boolean NOT NULL DEFAULT true,
  sound_enabled boolean NOT NULL DEFAULT true,
  vibration_enabled boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT user_notification_settings_pkey PRIMARY KEY (id),
  CONSTRAINT user_notification_settings_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users (id) ON DELETE CASCADE,
  CONSTRAINT user_notification_settings_user_id_unique UNIQUE (user_id)
) TABLESPACE pg_default;

-- ایندکس برای جستجوی سریع
CREATE INDEX IF NOT EXISTS idx_user_notification_settings_user_id 
ON public.user_notification_settings USING btree (user_id) TABLESPACE pg_default;

-- تریگر برای به‌روزرسانی updated_at
CREATE OR REPLACE FUNCTION update_user_notification_settings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_user_notification_settings_updated_at
  BEFORE UPDATE ON public.user_notification_settings
  FOR EACH ROW
  EXECUTE FUNCTION update_user_notification_settings_updated_at();

-- دسترسی‌ها
GRANT ALL ON public.user_notification_settings TO authenticated;
GRANT ALL ON public.user_notification_settings TO service_role;

-- RLS (Row Level Security)
ALTER TABLE public.user_notification_settings ENABLE ROW LEVEL SECURITY;

-- پالیسی برای کاربران: فقط تنظیمات خودشان را ببینند
CREATE POLICY "Users can view their own notification settings"
  ON public.user_notification_settings
  FOR SELECT
  USING (auth.uid() = user_id);

-- پالیسی برای کاربران: فقط تنظیمات خودشان را به‌روزرسانی کنند
CREATE POLICY "Users can update their own notification settings"
  ON public.user_notification_settings
  FOR UPDATE
  USING (auth.uid() = user_id);

-- پالیسی برای کاربران: تنظیمات خودشان را ایجاد کنند
CREATE POLICY "Users can insert their own notification settings"
  ON public.user_notification_settings
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- تابع برای ایجاد تنظیمات پیش‌فرض برای کاربر جدید
CREATE OR REPLACE FUNCTION create_default_notification_settings()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_notification_settings (user_id)
  VALUES (NEW.id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- تریگر برای ایجاد تنظیمات پیش‌فرض هنگام ثبت‌نام کاربر
CREATE TRIGGER trigger_create_default_notification_settings
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION create_default_notification_settings();
