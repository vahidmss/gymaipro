-- حذف دوطرفه دوستی: trigger با SECURITY DEFINER + RPC اختیاری

CREATE OR REPLACE FUNCTION public.remove_mutual_friendship()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  DELETE FROM public.user_friends
  WHERE (user_id = OLD.user_id AND friend_id = OLD.friend_id)
     OR (user_id = OLD.friend_id AND friend_id = OLD.user_id);
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS remove_mutual_friendship_trigger ON public.user_friends;

CREATE TRIGGER remove_mutual_friendship_trigger
  AFTER DELETE ON public.user_friends
  FOR EACH ROW
  EXECUTE FUNCTION public.remove_mutual_friendship();

-- RPC برای حذف از اپ (اگر trigger به هر دلیل اجرا نشد)
CREATE OR REPLACE FUNCTION public.remove_friend_bidirectional(p_friend_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user uuid := auth.uid();
BEGIN
  IF v_user IS NULL THEN
    RAISE EXCEPTION 'not authenticated';
  END IF;

  DELETE FROM public.user_friends
  WHERE (user_id = v_user AND friend_id = p_friend_id)
     OR (user_id = p_friend_id AND friend_id = v_user);
END;
$$;

GRANT EXECUTE ON FUNCTION public.remove_friend_bidirectional(uuid) TO authenticated;
