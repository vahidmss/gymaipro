-- ایجاد جدول trainer_clients برای مدیریت روابط مربی-شاگرد
CREATE TABLE IF NOT EXISTS public.trainer_clients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trainer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'rejected', 'ended')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- اطمینان از اینکه هر مربی-شاگرد فقط یک رابطه داشته باشد
    UNIQUE(trainer_id, client_id)
);

-- ایندکس‌ها برای بهبود عملکرد
CREATE INDEX IF NOT EXISTS idx_trainer_clients_trainer_id ON public.trainer_clients(trainer_id);
CREATE INDEX IF NOT EXISTS idx_trainer_clients_client_id ON public.trainer_clients(client_id);
CREATE INDEX IF NOT EXISTS idx_trainer_clients_status ON public.trainer_clients(status);
CREATE INDEX IF NOT EXISTS idx_trainer_clients_created_at ON public.trainer_clients(created_at DESC);

-- تریگر برای به‌روزرسانی updated_at
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_trainer_clients_updated_at ON public.trainer_clients;
CREATE TRIGGER set_trainer_clients_updated_at
    BEFORE UPDATE ON public.trainer_clients
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

-- فعال‌سازی Row Level Security
ALTER TABLE public.trainer_clients ENABLE ROW LEVEL SECURITY;

-- پالیسی‌های امنیتی
-- کاربران می‌توانند روابط خود را ببینند
CREATE POLICY "Users can view their own trainer relationships" ON public.trainer_clients
    FOR SELECT USING (
        auth.uid() = trainer_id OR 
        auth.uid() = client_id
    );

-- مربیان می‌توانند روابط خود را ایجاد کنند
CREATE POLICY "Trainers can create relationships" ON public.trainer_clients
    FOR INSERT WITH CHECK (
        auth.uid() = trainer_id
    );

-- مربیان و شاگردان می‌توانند روابط خود را به‌روزرسانی کنند
CREATE POLICY "Trainers and clients can update their relationships" ON public.trainer_clients
    FOR UPDATE USING (
        auth.uid() = trainer_id OR 
        auth.uid() = client_id
    );

-- مربیان و شاگردان می‌توانند روابط خود را حذف کنند
CREATE POLICY "Trainers and clients can delete their relationships" ON public.trainer_clients
    FOR DELETE USING (
        auth.uid() = trainer_id OR 
        auth.uid() = client_id
    );

-- اعطای دسترسی‌ها
GRANT SELECT, INSERT, UPDATE, DELETE ON public.trainer_clients TO authenticated;
GRANT USAGE ON SCHEMA public TO authenticated;
