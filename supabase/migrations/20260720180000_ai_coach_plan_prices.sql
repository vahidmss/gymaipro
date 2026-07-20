-- قیمت فروش پلن‌های مربی هوشمند (قابل تنظیم از پنل ادمین)

CREATE TABLE IF NOT EXISTS public.ai_coach_plan_prices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id text NOT NULL,
  title text NOT NULL,
  description text NOT NULL DEFAULT '',
  price_rial integer NOT NULL CHECK (price_rial >= 0),
  validity_days integer NOT NULL DEFAULT 31 CHECK (validity_days > 0),
  features text[] NOT NULL DEFAULT '{}',
  is_active boolean NOT NULL DEFAULT true,
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ai_coach_plan_prices_plan_active
  ON public.ai_coach_plan_prices (plan_id, is_active, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_ai_coach_plan_prices_active
  ON public.ai_coach_plan_prices (is_active)
  WHERE is_active = true;

ALTER TABLE public.ai_coach_plan_prices ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS ai_coach_plan_prices_read_authenticated
  ON public.ai_coach_plan_prices;
CREATE POLICY ai_coach_plan_prices_read_authenticated
  ON public.ai_coach_plan_prices
  FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS ai_coach_plan_prices_admin_write
  ON public.ai_coach_plan_prices;
CREATE POLICY ai_coach_plan_prices_admin_write
  ON public.ai_coach_plan_prices
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role = 'admin'
    )
  );

INSERT INTO public.ai_coach_plan_prices (
  plan_id,
  title,
  description,
  price_rial,
  validity_days,
  features,
  is_active
)
SELECT
  v.plan_id,
  v.title,
  v.description,
  v.price_rial,
  v.validity_days,
  v.features,
  true
FROM (
  VALUES
    (
      'coach_pro',
      'Coach Pro',
      'دسترسی پیشرفته مربی هوشمند برای تمرین و بازبینی برنامه',
      990000,
      31,
      ARRAY[
        'ساخت برنامه تمرینی با هوش مصنوعی',
        'ویرایش برنامه',
        'تحلیل ریکاوری',
        'بازبینی تمرین و برنامه',
        'پیام‌های نامحدود مربی'
      ]::text[]
    ),
    (
      'ultimate_ai',
      'Ultimate AI',
      'دسترسی کامل به تمام قابلیت‌های مربی هوشمند',
      1990000,
      31,
      ARRAY[
        'تمام امکانات Coach Pro',
        'تحلیل پیشرفت',
        'برنامه تغذیه',
        'مشاوره مکمل',
        'استدلال پیشرفته AI'
      ]::text[]
    )
) AS v(plan_id, title, description, price_rial, validity_days, features)
WHERE NOT EXISTS (
  SELECT 1
  FROM public.ai_coach_plan_prices p
  WHERE p.plan_id = v.plan_id
    AND p.is_active = true
);

COMMENT ON TABLE public.ai_coach_plan_prices IS
  'Sellable AI coach plan prices managed by admin (not OpenAI token costs).';
