-- Single-currency gamification: achievement unlocks grant league امتیاز via bonus_points.
-- Safe to re-run (IF NOT EXISTS / CREATE OR REPLACE).

ALTER TABLE public.achievements
  ADD COLUMN IF NOT EXISTS bonus_points INTEGER NOT NULL DEFAULT 0;

COMMENT ON COLUMN public.achievements.bonus_points IS
  'League points awarded once at unlock time (locked value; catalog changes do not rewrite past awards)';

-- Backfill unlocked rows that never received a bonus (idempotent: only where bonus_points = 0).
UPDATE public.achievements
SET bonus_points = CASE achievement_id
  WHEN 'profile_complete' THEN 50
  WHEN 'first_login' THEN 20
  WHEN 'membership_10_days' THEN 40
  WHEN 'membership_30_days' THEN 100
  WHEN 'membership_90_days' THEN 200
  WHEN 'membership_1_year' THEN 500
  WHEN 'streak_3_days' THEN 30
  WHEN 'streak_10_days' THEN 80
  WHEN 'streak_30_days' THEN 250
  WHEN 'confidential_info' THEN 40
  WHEN 'invite_1' THEN 30
  WHEN 'invite_3' THEN 80
  WHEN 'invite_10' THEN 200
  WHEN 'invite_30' THEN 500
  WHEN 'log_exercise' THEN 25
  WHEN 'log_diet' THEN 25
  WHEN 'log_calorie' THEN 20
  WHEN 'get_exercise_program' THEN 40
  WHEN 'get_diet_program' THEN 40
  ELSE 25
END
WHERE unlocked_at IS NOT NULL
  AND bonus_points = 0;

CREATE OR REPLACE FUNCTION get_user_achievement_stats(p_user_id UUID)
RETURNS TABLE (
  total_achievements INTEGER,
  unlocked_count INTEGER,
  total_points BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COUNT(*)::INTEGER AS total_achievements,
    COUNT(*) FILTER (WHERE a.unlocked_at IS NOT NULL)::INTEGER AS unlocked_count,
    COALESCE(SUM(a.bonus_points) FILTER (WHERE a.unlocked_at IS NOT NULL), 0)::BIGINT AS total_points
  FROM public.achievements a
  WHERE a.user_id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_user_achievement_stats(UUID) TO authenticated;

-- NOTE: public.point_history is unused by the Flutter app (display rows are synthesized
-- from RankingScoreBreakdown). Do not DROP in production from this migration.
