-- جداول مورد نیاز برای پوش نوتیفیکیشن (در پروژهٔ جدید اگر نبودند ساخته می‌شوند)

-- 1) ذخیره توکن‌های FCM هر دستگاه
CREATE TABLE IF NOT EXISTS public.device_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  token text NOT NULL,
  platform text,
  is_push_enabled boolean DEFAULT true,
  last_seen timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now(),
  UNIQUE(token)
);

CREATE INDEX IF NOT EXISTS idx_device_tokens_user_id ON public.device_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_device_tokens_push_enabled ON public.device_tokens(is_push_enabled) WHERE is_push_enabled = true;

ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own device_tokens"
  ON public.device_tokens FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- سرویس رول (Edge Function) باید بتواند همه را بخواند؛ با SERVICE_ROLE_KEY از RLS عبور می‌شود

-- 2) صف/تاریخچه درخواست‌های ارسال همگانی
CREATE TABLE IF NOT EXISTS public.notification_broadcast_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  target_type text NOT NULL CHECK (target_type IN ('topic', 'inactive_7d')),
  topic text,
  title text NOT NULL,
  body text NOT NULL,
  data jsonb,
  status text NOT NULL DEFAULT 'queued' CHECK (status IN ('queued', 'sent', 'failed')),
  processed_at timestamptz,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_broadcast_requests_status ON public.notification_broadcast_requests(status);
CREATE INDEX IF NOT EXISTS idx_broadcast_requests_created ON public.notification_broadcast_requests(created_at);

ALTER TABLE public.notification_broadcast_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins/trainers can manage broadcast_requests"
  ON public.notification_broadcast_requests FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role IN ('admin', 'trainer')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role IN ('admin', 'trainer')
    )
  );

-- 3) ویو کاربران غیرفعال ۷ روز (برای ارسال به inactive_7d)
-- نیاز به ستون last_active_at در profiles
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'last_active_at') THEN
    ALTER TABLE public.profiles ADD COLUMN last_active_at timestamptz;
  END IF;
END $$;

-- حذف ویو قبلی (در صورت وجود) و ساخت مجدد — REPLACE با ستون‌های متفاوت در پستگرس خطا می‌دهد
DROP VIEW IF EXISTS public.inactive_users_7d;

CREATE VIEW public.inactive_users_7d AS
SELECT id AS user_id
FROM public.profiles
WHERE last_active_at IS NULL
   OR last_active_at < (now() - interval '7 days');