-- جلوگیری از اعلان تکراری درخواست دوستی (کلاینت + trigger)
-- و حذف action_url که ناوبری را به تب اشتباه می‌برد.

CREATE OR REPLACE FUNCTION public.notify_on_friendship_request_insert()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  requester_name TEXT;
BEGIN
  IF NEW.status IS DISTINCT FROM 'pending' THEN
    RETURN NEW;
  END IF;

  -- اگر کلاینت یا trigger قبلی همین درخواست را ثبت کرده، تکرار نساز.
  IF EXISTS (
    SELECT 1
    FROM public.notifications n
    WHERE n.user_id = NEW.requested_id
      AND n.created_at > (NOW() - INTERVAL '15 minutes')
      AND COALESCE(n.data->>'type', '') = 'friend_request'
      AND COALESCE(n.data->>'request_id', '') = NEW.id::text
  ) THEN
    RETURN NEW;
  END IF;

  SELECT COALESCE(
    NULLIF(TRIM(CONCAT(COALESCE(first_name, ''), ' ', COALESCE(last_name, ''))), ''),
    NULLIF(TRIM(username), ''),
    'کاربر'
  )
  INTO requester_name
  FROM public.profiles
  WHERE id = NEW.requester_id OR auth_user_id = NEW.requester_id
  LIMIT 1;

  INSERT INTO public.notifications (
    user_id,
    title,
    message,
    type,
    priority,
    data,
    action_url
  )
  SELECT
    NEW.requested_id,
    'درخواست دوستی جدید',
    requester_name || ' می‌خواهد با شما دوست شود',
    'system',
    2,
    jsonb_build_object(
      'type', 'friend_request',
      'route', '/my-club',
      'initialTab', 2,
      'request_id', NEW.id::text,
      'requester_id', NEW.requester_id::text
    ),
    NULL
  WHERE EXISTS (
    SELECT 1 FROM public.user_notification_settings uns
    WHERE uns.user_id = NEW.requested_id
      AND uns.friend_request_notifications = true
  )
  OR NOT EXISTS (
    SELECT 1 FROM public.user_notification_settings uns
    WHERE uns.user_id = NEW.requested_id
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
