-- RPC برای درج اعلان درون‌برنامه‌ای برای هر کاربر (بدون وابستگی به RLS کلاینت)
CREATE OR REPLACE FUNCTION public.create_user_notification(
  p_user_id UUID,
  p_title TEXT,
  p_message TEXT,
  p_type TEXT DEFAULT 'system',
  p_priority INT DEFAULT 2,
  p_data JSONB DEFAULT '{}'::jsonb,
  p_action_url TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  new_id UUID;
BEGIN
  INSERT INTO public.notifications (
    user_id,
    title,
    message,
    type,
    priority,
    data,
    action_url
  )
  VALUES (
    p_user_id,
    p_title,
    p_message,
    p_type,
    p_priority,
    COALESCE(p_data, '{}'::jsonb),
    p_action_url
  )
  RETURNING id INTO new_id;

  RETURN new_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_user_notification TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_user_notification TO service_role;
