-- Nutrition calorie goal fields on profiles (V1 smart static goal).
-- Separates maintenance TDEE from a user-set (or rate-derived) calorie goal.

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS nutrition_goal_mode TEXT NOT NULL DEFAULT 'none'
    CHECK (nutrition_goal_mode IN ('none', 'maintain', 'lose', 'gain', 'custom')),
  ADD COLUMN IF NOT EXISTS target_weight_kg NUMERIC,
  ADD COLUMN IF NOT EXISTS weekly_rate_kg NUMERIC,
  ADD COLUMN IF NOT EXISTS calorie_goal_kcal INTEGER,
  ADD COLUMN IF NOT EXISTS calorie_goal_source TEXT
    CHECK (calorie_goal_source IS NULL OR calorie_goal_source IN ('computed', 'manual')),
  ADD COLUMN IF NOT EXISTS calorie_goal_updated_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS goal_reached_at TIMESTAMPTZ;

COMMENT ON COLUMN public.profiles.nutrition_goal_mode IS
  'none=show maintenance reference only; maintain/lose/gain/custom=active calorie goal';
COMMENT ON COLUMN public.profiles.calorie_goal_kcal IS
  'Persisted daily calorie goal used by meal log / coach when mode != none';
COMMENT ON COLUMN public.profiles.target_weight_kg IS
  'Optional target body weight for lose/gain modes';
COMMENT ON COLUMN public.profiles.weekly_rate_kg IS
  'Absolute kg/week rate used to derive deficit/surplus';
