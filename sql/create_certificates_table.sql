-- ایجاد جدول certificates برای مدارک مربیان
CREATE TABLE IF NOT EXISTS public.certificates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trainer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    type VARCHAR(50) NOT NULL CHECK (type IN ('coaching', 'championship', 'education', 'specialization', 'achievement', 'other')),
    issuing_organization VARCHAR(255),
    issue_date DATE,
    expiry_date DATE,
    certificate_url TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    category VARCHAR(100),
    rejection_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    approved_at TIMESTAMP WITH TIME ZONE,
    approved_by UUID REFERENCES auth.users(id)
);

-- ایندکس‌ها برای بهبود عملکرد
CREATE INDEX IF NOT EXISTS idx_certificates_trainer_id ON public.certificates(trainer_id);
CREATE INDEX IF NOT EXISTS idx_certificates_status ON public.certificates(status);
CREATE INDEX IF NOT EXISTS idx_certificates_type ON public.certificates(type);
CREATE INDEX IF NOT EXISTS idx_certificates_created_at ON public.certificates(created_at DESC);

-- ایندکس ترکیبی برای جستجوی مدارک مربی
CREATE INDEX IF NOT EXISTS idx_certificates_trainer_status ON public.certificates(trainer_id, status);

-- RLS (Row Level Security) policies
ALTER TABLE public.certificates ENABLE ROW LEVEL SECURITY;

-- مربیان می‌توانند مدارک خود را ببینند
CREATE POLICY "Trainers can view their own certificates" ON public.certificates
    FOR SELECT USING (auth.uid() = trainer_id);

-- مربیان می‌توانند مدارک جدید اضافه کنند
CREATE POLICY "Trainers can insert their own certificates" ON public.certificates
    FOR INSERT WITH CHECK (auth.uid() = trainer_id);

-- مربیان می‌توانند مدارک خود را به‌روزرسانی کنند (فقط اگر در انتظار تایید باشد)
CREATE POLICY "Trainers can update pending certificates" ON public.certificates
    FOR UPDATE USING (auth.uid() = trainer_id AND status = 'pending');

-- ادمین‌ها می‌توانند همه مدارک را ببینند
CREATE POLICY "Admins can view all certificates" ON public.certificates
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- ادمین‌ها می‌توانند وضعیت مدارک را تغییر دهند
CREATE POLICY "Admins can update certificate status" ON public.certificates
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- کاربران عمومی می‌توانند مدارک تایید شده را ببینند
CREATE POLICY "Public can view approved certificates" ON public.certificates
    FOR SELECT USING (status = 'approved');

-- تابع برای به‌روزرسانی زمان تایید
CREATE OR REPLACE FUNCTION update_certificate_approval()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'approved' AND OLD.status != 'approved' THEN
        NEW.approved_at = NOW();
        NEW.approved_by = auth.uid();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- تریگر برای به‌روزرسانی زمان تایید
CREATE TRIGGER trigger_update_certificate_approval
    BEFORE UPDATE ON public.certificates
    FOR EACH ROW
    EXECUTE FUNCTION update_certificate_approval();

-- تابع برای بررسی انقضای مدارک
CREATE OR REPLACE FUNCTION check_certificate_expiry()
RETURNS TRIGGER AS $$
BEGIN
    -- اگر تاریخ انقضا مشخص شده و گذشته است، هشدار ایجاد کنید
    IF NEW.expiry_date IS NOT NULL AND NEW.expiry_date < CURRENT_DATE THEN
        -- می‌توانید اینجا اعلان یا هشدار ایجاد کنید
        RAISE NOTICE 'Certificate % has expired', NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- تریگر برای بررسی انقضای مدارک
CREATE TRIGGER trigger_check_certificate_expiry
    BEFORE INSERT OR UPDATE ON public.certificates
    FOR EACH ROW
    EXECUTE FUNCTION check_certificate_expiry();
