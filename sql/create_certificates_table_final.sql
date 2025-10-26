-- جدول نهایی مدارک مربیان
-- هر مدرک یک سطر جداگانه - بهترین مدل برای مدیریت

CREATE TABLE IF NOT EXISTS public.certificates (
    -- شناسه‌های اصلی
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trainer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- اطلاعات مدرک
    title VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL CHECK (type IN ('coaching', 'championship', 'education', 'specialization', 'achievement', 'other')),
    certificate_url TEXT NOT NULL, -- لینک تصویر مدرک
    
    -- وضعیت تایید
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    rejection_reason TEXT, -- دلیل رد (اگر رد شده باشد)
    
    -- اطلاعات تایید
    approved_by UUID REFERENCES auth.users(id), -- ادمین تاییدکننده
    approved_at TIMESTAMP WITH TIME ZONE, -- زمان تایید
    
    -- زمان‌بندی
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ایندکس‌ها برای بهبود عملکرد
CREATE INDEX IF NOT EXISTS idx_certificates_trainer_id ON public.certificates(trainer_id);
CREATE INDEX IF NOT EXISTS idx_certificates_status ON public.certificates(status);
CREATE INDEX IF NOT EXISTS idx_certificates_type ON public.certificates(type);
CREATE INDEX IF NOT EXISTS idx_certificates_created_at ON public.certificates(created_at DESC);

-- ایندکس ترکیبی برای جستجوی سریع
CREATE INDEX IF NOT EXISTS idx_certificates_trainer_status ON public.certificates(trainer_id, status);
CREATE INDEX IF NOT EXISTS idx_certificates_type_status ON public.certificates(type, status);

-- RLS (Row Level Security) policies
ALTER TABLE public.certificates ENABLE ROW LEVEL SECURITY;

-- مربیان می‌توانند مدارک خود را ببینند
CREATE POLICY "Trainers can view their own certificates" ON public.certificates
    FOR SELECT USING (auth.uid() = trainer_id);

-- مربیان می‌توانند مدارک جدید اضافه کنند
CREATE POLICY "Trainers can insert their own certificates" ON public.certificates
    FOR INSERT WITH CHECK (auth.uid() = trainer_id);

-- مربیان می‌توانند مدارک در انتظار خود را حذف کنند
CREATE POLICY "Trainers can delete pending certificates" ON public.certificates
    FOR DELETE USING (auth.uid() = trainer_id AND status = 'pending');

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
    -- اگر وضعیت به تایید تغییر کرد
    IF NEW.status = 'approved' AND OLD.status != 'approved' THEN
        NEW.approved_at = NOW();
        NEW.approved_by = auth.uid();
    END IF;
    
    -- اگر وضعیت تغییر کرد، زمان به‌روزرسانی را تغییر بده
    IF NEW.status != OLD.status THEN
        NEW.updated_at = NOW();
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- تریگر برای به‌روزرسانی زمان تایید
CREATE TRIGGER trigger_update_certificate_approval
    BEFORE UPDATE ON public.certificates
    FOR EACH ROW
    EXECUTE FUNCTION update_certificate_approval();

-- تابع برای آمار مدارک مربی
CREATE OR REPLACE FUNCTION get_trainer_certificate_stats(trainer_uuid UUID)
RETURNS TABLE (
    total_certificates BIGINT,
    approved_certificates BIGINT,
    pending_certificates BIGINT,
    rejected_certificates BIGINT,
    coaching_count BIGINT,
    championship_count BIGINT,
    education_count BIGINT,
    specialization_count BIGINT,
    achievement_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*) as total_certificates,
        COUNT(*) FILTER (WHERE status = 'approved') as approved_certificates,
        COUNT(*) FILTER (WHERE status = 'pending') as pending_certificates,
        COUNT(*) FILTER (WHERE status = 'rejected') as rejected_certificates,
        COUNT(*) FILTER (WHERE type = 'coaching') as coaching_count,
        COUNT(*) FILTER (WHERE type = 'championship') as championship_count,
        COUNT(*) FILTER (WHERE type = 'education') as education_count,
        COUNT(*) FILTER (WHERE type = 'specialization') as specialization_count,
        COUNT(*) FILTER (WHERE type = 'achievement') as achievement_count
    FROM public.certificates 
    WHERE trainer_id = trainer_uuid;
END;
$$ LANGUAGE plpgsql;

-- تابع برای دریافت مدارک تایید شده مربی
CREATE OR REPLACE FUNCTION get_approved_trainer_certificates(trainer_uuid UUID)
RETURNS TABLE (
    id UUID,
    title VARCHAR,
    type VARCHAR,
    certificate_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.title,
        c.type,
        c.certificate_url,
        c.created_at
    FROM public.certificates c
    WHERE c.trainer_id = trainer_uuid 
    AND c.status = 'approved'
    ORDER BY c.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- تابع برای دریافت مدارک در انتظار تایید (فقط برای ادمین‌ها)
CREATE OR REPLACE FUNCTION get_pending_certificates()
RETURNS TABLE (
    id UUID,
    trainer_id UUID,
    trainer_username VARCHAR,
    trainer_full_name VARCHAR,
    title VARCHAR,
    type VARCHAR,
    certificate_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.trainer_id,
        p.username as trainer_username,
        COALESCE(p.first_name || ' ' || p.last_name, p.username) as trainer_full_name,
        c.title,
        c.type,
        c.certificate_url,
        c.created_at
    FROM public.certificates c
    JOIN public.profiles p ON c.trainer_id = p.id
    WHERE c.status = 'pending'
    ORDER BY c.created_at ASC;
END;
$$ LANGUAGE plpgsql;

-- تابع برای تایید/رد مدرک (فقط برای ادمین‌ها)
CREATE OR REPLACE FUNCTION approve_certificate(
    cert_id UUID,
    new_status VARCHAR,
    rejection_reason TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    current_user_role VARCHAR;
BEGIN
    -- بررسی نقش کاربر
    SELECT role INTO current_user_role 
    FROM public.profiles 
    WHERE id = auth.uid();
    
    -- فقط ادمین‌ها می‌توانند تایید/رد کنند
    IF current_user_role != 'admin' THEN
        RAISE EXCEPTION 'فقط ادمین‌ها می‌توانند مدارک را تایید یا رد کنند';
    END IF;
    
    -- به‌روزرسانی وضعیت مدرک
    UPDATE public.certificates 
    SET 
        status = new_status,
        rejection_reason = CASE 
            WHEN new_status = 'rejected' THEN rejection_reason 
            ELSE NULL 
        END,
        approved_by = auth.uid(),
        approved_at = CASE 
            WHEN new_status = 'approved' THEN NOW() 
            ELSE NULL 
        END,
        updated_at = NOW()
    WHERE id = cert_id;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- تابع برای حذف مدرک (فقط مربی صاحب مدرک یا ادمین)
CREATE OR REPLACE FUNCTION delete_certificate(cert_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    cert_trainer_id UUID;
    current_user_role VARCHAR;
BEGIN
    -- دریافت صاحب مدرک
    SELECT trainer_id INTO cert_trainer_id 
    FROM public.certificates 
    WHERE id = cert_id;
    
    -- بررسی نقش کاربر
    SELECT role INTO current_user_role 
    FROM public.profiles 
    WHERE id = auth.uid();
    
    -- فقط صاحب مدرک یا ادمین می‌تواند حذف کند
    IF auth.uid() != cert_trainer_id AND current_user_role != 'admin' THEN
        RAISE EXCEPTION 'شما اجازه حذف این مدرک را ندارید';
    END IF;
    
    -- حذف مدرک
    DELETE FROM public.certificates WHERE id = cert_id;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- ایجاد view برای نمایش مدارک با اطلاعات مربی
CREATE OR REPLACE VIEW certificates_with_trainer_info AS
SELECT 
    c.*,
    p.username as trainer_username,
    COALESCE(p.first_name || ' ' || p.last_name, p.username) as trainer_full_name,
    p.avatar_url as trainer_avatar,
    approver.username as approver_username
FROM public.certificates c
JOIN public.profiles p ON c.trainer_id = p.id
LEFT JOIN public.profiles approver ON c.approved_by = approver.id;

-- ایجاد view برای آمار کلی مدارک
CREATE OR REPLACE VIEW certificate_statistics AS
SELECT 
    COUNT(*) as total_certificates,
    COUNT(*) FILTER (WHERE status = 'approved') as approved_count,
    COUNT(*) FILTER (WHERE status = 'pending') as pending_count,
    COUNT(*) FILTER (WHERE status = 'rejected') as rejected_count,
    COUNT(*) FILTER (WHERE type = 'coaching') as coaching_count,
    COUNT(*) FILTER (WHERE type = 'championship') as championship_count,
    COUNT(*) FILTER (WHERE type = 'education') as education_count,
    COUNT(*) FILTER (WHERE type = 'specialization') as specialization_count,
    COUNT(*) FILTER (WHERE type = 'achievement') as achievement_count,
    COUNT(DISTINCT trainer_id) as trainers_with_certificates
FROM public.certificates;
