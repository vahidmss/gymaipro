-- Create exercise bookmarks table
CREATE TABLE IF NOT EXISTS public.exercise_bookmarks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  exercise_id INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,

  -- Uniqueness constraint to prevent duplicates
  UNIQUE (user_id, exercise_id)
);

-- Add RLS policies for exercise_bookmarks
ALTER TABLE public.exercise_bookmarks ENABLE ROW LEVEL SECURITY;





-- Create exercise likes table
CREATE TABLE IF NOT EXISTS public.exercise_likes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  exercise_id INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,

  -- Uniqueness constraint to prevent duplicates
  UNIQUE (user_id, exercise_id)
);

-- Add RLS policies for exercise_likes
ALTER TABLE public.exercise_likes ENABLE ROW LEVEL SECURITY;


-- Allow users to insert their own likes
CREATE POLICY "Users can create their own likes" 
  ON public.exercise_likes 
  FOR INSERT 
  WITH CHECK (auth.uid() = user_id);



-- Create exercise comments table
CREATE TABLE IF NOT EXISTS public.exercise_comments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  exercise_id INTEGER NOT NULL,
  comment TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Add RLS policies for exercise_comments
ALTER TABLE public.exercise_comments ENABLE ROW LEVEL SECURITY;

-- Allow users to select all comments
CREATE POLICY "Users can view all comments" 
  ON public.exercise_comments 
  FOR SELECT 
  USING (true);

-- Allow users to insert their own comments
CREATE POLICY "Users can create their own comments" 
  ON public.exercise_comments 
  FOR INSERT 
  WITH CHECK (auth.uid() = user_id);





-- Create a function to count likes for an exercise
CREATE OR REPLACE FUNCTION get_exercise_likes_count(exercise_id_param INTEGER)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN (
    SELECT COUNT(*)
    FROM public.exercise_likes
    WHERE exercise_id = exercise_id_param
  );
END;
$$; 