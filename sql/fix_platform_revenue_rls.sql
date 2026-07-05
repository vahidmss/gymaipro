-- رفع خطای RLS هنگام insert در platform_revenue از اپ موبایل
-- اجرا در Supabase Dashboard > SQL Editor

CREATE OR REPLACE FUNCTION public.current_user_profile_id()
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT id FROM public.profiles WHERE auth_user_id = auth.uid() LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.record_platform_revenue(
  p_transaction_id text,
  p_subscription_id text,
  p_trainer_id uuid,
  p_amount integer,
  p_commission_percentage real
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_profile_id uuid;
BEGIN
  v_profile_id := public.current_user_profile_id();

  IF NOT EXISTS (
    SELECT 1
    FROM public.trainer_subscriptions ts
    WHERE ts.id = p_subscription_id
      AND ts.payment_transaction_id = p_transaction_id
      AND ts.trainer_id = p_trainer_id
      AND (ts.user_id = auth.uid() OR ts.user_id = v_profile_id)
  ) THEN
    RAISE EXCEPTION 'forbidden' USING ERRCODE = '42501';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.platform_revenue pr
    WHERE pr.subscription_id = p_subscription_id
  ) THEN
    RETURN;
  END IF;

  INSERT INTO public.platform_revenue (
    transaction_id,
    subscription_id,
    trainer_id,
    amount,
    commission_percentage
  ) VALUES (
    p_transaction_id,
    p_subscription_id,
    p_trainer_id,
    GREATEST(p_amount, 0),
    p_commission_percentage
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.record_platform_revenue(
  text, text, uuid, integer, real
) TO authenticated;
