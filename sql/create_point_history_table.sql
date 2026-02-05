-- Create point_history table for storing user point earning history
-- This table stores the complete history of points earned by users from various sources

DROP TABLE IF EXISTS public.point_history CASCADE;

CREATE TABLE IF NOT EXISTS public.point_history (
  id VARCHAR(255) PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  points INTEGER NOT NULL DEFAULT 0,
  source VARCHAR(50) NOT NULL, -- achievement, dailyCheckIn, workout, nutrition, social, other
  source_id VARCHAR(255), -- ID of the source (e.g., achievement_id)
  source_title VARCHAR(255) NOT NULL, -- Title of the source
  source_icon VARCHAR(10) NOT NULL DEFAULT '⭐', -- Icon/emoji for the source
  earned_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now()),
  description TEXT, -- Optional description
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS point_history_user_id_idx ON public.point_history(user_id);
CREATE INDEX IF NOT EXISTS point_history_source_idx ON public.point_history(source);
CREATE INDEX IF NOT EXISTS point_history_source_id_idx ON public.point_history(source_id);
CREATE INDEX IF NOT EXISTS point_history_earned_at_idx ON public.point_history(earned_at DESC);

-- Enable Row Level Security
ALTER TABLE public.point_history ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
-- Users can view their own point history
CREATE POLICY "Users can view their own point history" ON public.point_history
  FOR SELECT USING (auth.uid() = user_id);

-- Users can insert their own point history
CREATE POLICY "Users can insert their own point history" ON public.point_history
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own point history (for corrections)
CREATE POLICY "Users can update their own point history" ON public.point_history
  FOR UPDATE USING (auth.uid() = user_id);

-- Users can delete their own point history (optional, for reset functionality)
CREATE POLICY "Users can delete their own point history" ON public.point_history
  FOR DELETE USING (auth.uid() = user_id);

-- Add comments
COMMENT ON TABLE public.point_history IS 'Stores complete history of points earned by users from various sources';
COMMENT ON COLUMN public.point_history.source IS 'Source of points: achievement, dailyCheckIn, workout, nutrition, social, other';
COMMENT ON COLUMN public.point_history.source_id IS 'ID of the source (e.g., achievement_id for achievements)';
COMMENT ON COLUMN public.point_history.source_title IS 'Human-readable title of the source';
COMMENT ON COLUMN public.point_history.source_icon IS 'Icon/emoji representing the source';
COMMENT ON COLUMN public.point_history.earned_at IS 'Timestamp when points were earned';

