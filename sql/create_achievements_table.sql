-- Create achievements table for storing user achievement progress
-- This table stores the current progress and unlock status for each achievement per user

DROP TABLE IF EXISTS public.achievements CASCADE;

CREATE TABLE IF NOT EXISTS public.achievements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  achievement_id VARCHAR(100) NOT NULL,
  current_value INTEGER NOT NULL DEFAULT 0,
  unlocked_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  
  -- Ensure one record per user per achievement
  CONSTRAINT achievements_user_achievement_unique UNIQUE (user_id, achievement_id)
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS achievements_user_id_idx ON public.achievements(user_id);
CREATE INDEX IF NOT EXISTS achievements_achievement_id_idx ON public.achievements(achievement_id);
CREATE INDEX IF NOT EXISTS achievements_unlocked_at_idx ON public.achievements(unlocked_at) WHERE unlocked_at IS NOT NULL;

-- Enable Row Level Security
ALTER TABLE public.achievements ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
-- Users can view their own achievements
CREATE POLICY "Users can view their own achievements" ON public.achievements
  FOR SELECT USING (auth.uid() = user_id);

-- Users can insert their own achievements
CREATE POLICY "Users can insert their own achievements" ON public.achievements
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own achievements
CREATE POLICY "Users can update their own achievements" ON public.achievements
  FOR UPDATE USING (auth.uid() = user_id);

-- Users can delete their own achievements (optional, for reset functionality)
CREATE POLICY "Users can delete their own achievements" ON public.achievements
  FOR DELETE USING (auth.uid() = user_id);

-- Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_achievements_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = timezone('utc'::text, now());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_achievements_updated_at_trigger
  BEFORE UPDATE ON public.achievements
  FOR EACH ROW
  EXECUTE FUNCTION update_achievements_updated_at();

-- Create function to get user's achievement statistics
CREATE OR REPLACE FUNCTION get_user_achievement_stats(p_user_id UUID)
RETURNS TABLE (
  total_achievements INTEGER,
  unlocked_count INTEGER,
  total_points BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*)::INTEGER as total_achievements,
    COUNT(*) FILTER (WHERE unlocked_at IS NOT NULL)::INTEGER as unlocked_count,
    COALESCE(SUM(
      CASE 
        WHEN a.unlocked_at IS NOT NULL THEN
          CASE a.achievement_id
            WHEN 'first_workout' THEN 10
            WHEN 'workout_beginner' THEN 50
            WHEN 'workout_intermediate' THEN 200
            WHEN 'workout_master' THEN 500
            WHEN 'workout_legend' THEN 2000
            WHEN 'streak_3' THEN 30
            WHEN 'streak_7' THEN 100
            WHEN 'streak_30' THEN 500
            WHEN 'early_bird' THEN 150
            WHEN 'first_meal_log' THEN 10
            WHEN 'meal_plan_week' THEN 100
            WHEN 'healthy_eater' THEN 300
            WHEN 'water_champion' THEN 400
            WHEN 'weight_loss_5kg' THEN 400
            WHEN 'weight_loss_10kg' THEN 800
            WHEN 'goal_achieved' THEN 1000
            WHEN 'body_transform' THEN 600
            WHEN 'invite_1' THEN 20
            WHEN 'invite_5' THEN 100
            WHEN 'invite_10' THEN 300
            WHEN 'trainer_chat' THEN 50
            WHEN 'profile_complete' THEN 50
            WHEN 'first_login' THEN 5
            WHEN 'active_user_30' THEN 200
            WHEN 'active_user_365' THEN 1000
            ELSE 0
          END
        ELSE 0
      END
    ), 0)::BIGINT as total_points
  FROM public.achievements a
  WHERE a.user_id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on function to authenticated users
GRANT EXECUTE ON FUNCTION get_user_achievement_stats(UUID) TO authenticated;

-- Add comment to table
COMMENT ON TABLE public.achievements IS 'Stores user achievement progress and unlock status';
COMMENT ON COLUMN public.achievements.achievement_id IS 'Unique identifier for the achievement (e.g., first_workout, workout_beginner)';
COMMENT ON COLUMN public.achievements.current_value IS 'Current progress value towards the achievement target';
COMMENT ON COLUMN public.achievements.unlocked_at IS 'Timestamp when the achievement was unlocked (NULL if not unlocked yet)';

