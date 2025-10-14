-- Create workout_daily_logs table
CREATE TABLE IF NOT EXISTS workout_daily_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    log_date DATE NOT NULL,
    sessions JSONB NOT NULL DEFAULT '[]',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, log_date)
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_workout_daily_logs_user_date ON workout_daily_logs(user_id, log_date);

-- Enable RLS
ALTER TABLE workout_daily_logs ENABLE ROW LEVEL SECURITY;

-- Create policy for users to access only their own logs
CREATE POLICY "Users can view their own workout daily logs" ON workout_daily_logs
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own workout daily logs" ON workout_daily_logs
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own workout daily logs" ON workout_daily_logs
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own workout daily logs" ON workout_daily_logs
    FOR DELETE USING (auth.uid() = user_id);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_workout_daily_logs_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_workout_daily_logs_updated_at
    BEFORE UPDATE ON workout_daily_logs
    FOR EACH ROW
    EXECUTE FUNCTION update_workout_daily_logs_updated_at(); 