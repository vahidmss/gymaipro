-- Food Likes table to store user likes on foods
CREATE TABLE IF NOT EXISTS public.food_likes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    food_id INTEGER NOT NULL, -- WordPress API food ID
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    UNIQUE (user_id, food_id)
);

-- Food Comments table to store user comments on foods
CREATE TABLE IF NOT EXISTS public.food_comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    food_id INTEGER NOT NULL, -- WordPress API food ID
    comment TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Food Bookmarks table to store user saved/bookmarked foods
CREATE TABLE IF NOT EXISTS public.food_bookmarks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    food_id INTEGER NOT NULL, -- WordPress API food ID
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    UNIQUE (user_id, food_id)
);

-- Enable Row Level Security
ALTER TABLE public.food_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.food_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.food_bookmarks ENABLE ROW LEVEL SECURITY;

-- Food Likes Policies
CREATE POLICY "Users can view all food likes" 
ON public.food_likes FOR SELECT 
USING (true);

CREATE POLICY "Users can insert their own likes" 
ON public.food_likes FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own likes" 
ON public.food_likes FOR DELETE 
USING (auth.uid() = user_id);

-- Food Comments Policies
CREATE POLICY "Users can view all food comments" 
ON public.food_comments FOR SELECT 
USING (true);

CREATE POLICY "Users can insert their own comments" 
ON public.food_comments FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own comments" 
ON public.food_comments FOR UPDATE 
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own comments" 
ON public.food_comments FOR DELETE 
USING (auth.uid() = user_id);

-- Food Bookmarks Policies
CREATE POLICY "Users can view their own bookmarks" 
ON public.food_bookmarks FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own bookmarks" 
ON public.food_bookmarks FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own bookmarks" 
ON public.food_bookmarks FOR DELETE 
USING (auth.uid() = user_id);

-- Create trigger for updated_at on comments
CREATE OR REPLACE FUNCTION update_food_comments_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_food_comments_updated_at
BEFORE UPDATE ON public.food_comments
FOR EACH ROW
EXECUTE FUNCTION update_food_comments_updated_at();

-- Create function to count likes for a food
CREATE OR REPLACE FUNCTION get_food_likes_count(food_id_param INTEGER)
RETURNS INTEGER AS $$
DECLARE
    likes_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO likes_count
    FROM public.food_likes
    WHERE food_id = food_id_param;
    
    RETURN likes_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to check if a user has liked a food
CREATE OR REPLACE FUNCTION has_user_liked_food(user_id_param UUID, food_id_param INTEGER)
RETURNS BOOLEAN AS $$
DECLARE
    has_liked BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1
        FROM public.food_likes
        WHERE user_id = user_id_param AND food_id = food_id_param
    ) INTO has_liked;
    
    RETURN has_liked;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grants
GRANT ALL ON TABLE public.food_likes TO postgres, service_role;
GRANT ALL ON TABLE public.food_comments TO postgres, service_role;
GRANT ALL ON TABLE public.food_bookmarks TO postgres, service_role;

GRANT SELECT ON TABLE public.food_likes TO anon, authenticated;
GRANT INSERT, DELETE ON TABLE public.food_likes TO authenticated;

GRANT SELECT ON TABLE public.food_comments TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON TABLE public.food_comments TO authenticated;

GRANT SELECT, INSERT, DELETE ON TABLE public.food_bookmarks TO authenticated; 