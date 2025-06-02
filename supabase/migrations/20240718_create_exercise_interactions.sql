-- Exercise Likes table to store user likes on exercises
CREATE TABLE IF NOT EXISTS public.exercise_likes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    exercise_id INTEGER NOT NULL, -- WordPress API exercise ID
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    UNIQUE (user_id, exercise_id)
);

-- Exercise Comments table to store user comments on exercises
CREATE TABLE IF NOT EXISTS public.exercise_comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    exercise_id INTEGER NOT NULL, -- WordPress API exercise ID
    comment TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Exercise Bookmarks table to store user saved/bookmarked exercises
CREATE TABLE IF NOT EXISTS public.exercise_bookmarks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    exercise_id INTEGER NOT NULL, -- WordPress API exercise ID
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    UNIQUE (user_id, exercise_id)
);

-- Enable Row Level Security
ALTER TABLE public.exercise_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercise_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercise_bookmarks ENABLE ROW LEVEL SECURITY;

-- Exercise Likes Policies
CREATE POLICY "Users can view all exercise likes" 
ON public.exercise_likes FOR SELECT 
USING (true);

CREATE POLICY "Users can insert their own likes" 
ON public.exercise_likes FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own likes" 
ON public.exercise_likes FOR DELETE 
USING (auth.uid() = user_id);

-- Exercise Comments Policies
CREATE POLICY "Users can view all exercise comments" 
ON public.exercise_comments FOR SELECT 
USING (true);

CREATE POLICY "Users can insert their own comments" 
ON public.exercise_comments FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own comments" 
ON public.exercise_comments FOR UPDATE 
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own comments" 
ON public.exercise_comments FOR DELETE 
USING (auth.uid() = user_id);

-- Exercise Bookmarks Policies
CREATE POLICY "Users can view their own bookmarks" 
ON public.exercise_bookmarks FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own bookmarks" 
ON public.exercise_bookmarks FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own bookmarks" 
ON public.exercise_bookmarks FOR DELETE 
USING (auth.uid() = user_id);

-- Create trigger for updated_at on comments
CREATE OR REPLACE FUNCTION update_exercise_comments_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_exercise_comments_updated_at
BEFORE UPDATE ON public.exercise_comments
FOR EACH ROW
EXECUTE FUNCTION update_exercise_comments_updated_at();

-- Create function to count likes for an exercise
CREATE OR REPLACE FUNCTION get_exercise_likes_count(exercise_id_param INTEGER)
RETURNS INTEGER AS $$
DECLARE
    likes_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO likes_count
    FROM public.exercise_likes
    WHERE exercise_id = exercise_id_param;
    
    RETURN likes_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to check if a user has liked an exercise
CREATE OR REPLACE FUNCTION has_user_liked_exercise(user_id_param UUID, exercise_id_param INTEGER)
RETURNS BOOLEAN AS $$
DECLARE
    has_liked BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1
        FROM public.exercise_likes
        WHERE user_id = user_id_param AND exercise_id = exercise_id_param
    ) INTO has_liked;
    
    RETURN has_liked;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grants
GRANT ALL ON TABLE public.exercise_likes TO postgres, service_role;
GRANT ALL ON TABLE public.exercise_comments TO postgres, service_role;
GRANT ALL ON TABLE public.exercise_bookmarks TO postgres, service_role;

GRANT SELECT ON TABLE public.exercise_likes TO anon, authenticated;
GRANT INSERT, DELETE ON TABLE public.exercise_likes TO authenticated;

GRANT SELECT ON TABLE public.exercise_comments TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON TABLE public.exercise_comments TO authenticated;

GRANT SELECT, INSERT, DELETE ON TABLE public.exercise_bookmarks TO authenticated; 