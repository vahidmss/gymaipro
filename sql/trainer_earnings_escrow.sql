-- سیستم Escrow درآمد مربی
-- پول پس از پرداخت شاگرد فقط برای ادمین ثبت می‌شود.
-- مربی پس از ارسال برنامه + پایان فرصت ۳ روزه ادیت، مبلغ «در انتظار» را می‌بیند.
-- پس از hold_days (پیش‌فرض ۳ روز) مبلغ قابل برداشت می‌شود.

-- 1. ستون‌های escrow روی اشتراک مربی
ALTER TABLE trainer_subscriptions
ADD COLUMN IF NOT EXISTS trainer_share_amount INTEGER CHECK (trainer_share_amount >= 0),
ADD COLUMN IF NOT EXISTS platform_commission_amount INTEGER CHECK (platform_commission_amount >= 0),
ADD COLUMN IF NOT EXISTS program_edit_until TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS earnings_hold_start_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS earnings_withdrawable_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS earnings_escrow_status TEXT DEFAULT 'in_platform'
  CHECK (earnings_escrow_status IN (
    'in_platform', 'edit_window', 'hold', 'withdrawable', 'frozen', 'paid_out'
  )),
ADD COLUMN IF NOT EXISTS earnings_frozen BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS earnings_frozen_reason TEXT,
ADD COLUMN IF NOT EXISTS earnings_early_released BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS earnings_early_released_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS earnings_early_released_by UUID REFERENCES auth.users(id);

CREATE INDEX IF NOT EXISTS idx_trainer_subscriptions_escrow_status
  ON trainer_subscriptions(earnings_escrow_status);
CREATE INDEX IF NOT EXISTS idx_trainer_subscriptions_withdrawable_at
  ON trainer_subscriptions(earnings_withdrawable_at)
  WHERE earnings_withdrawable_at IS NOT NULL;

-- 2. فرصت ادیت برنامه در تنظیمات کمیسیون
ALTER TABLE commission_settings
ADD COLUMN IF NOT EXISTS edit_window_days INTEGER NOT NULL DEFAULT 3 CHECK (edit_window_days >= 0);

-- 3. مسدودسازی برداشت کل مربی (توسط ادمین)
ALTER TABLE wallets
ADD COLUMN IF NOT EXISTS payout_blocked BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS payout_blocked_reason TEXT;

CREATE INDEX IF NOT EXISTS idx_wallets_payout_blocked
  ON wallets(payout_blocked) WHERE payout_blocked = TRUE;

-- 4. لاگ اقدامات ادمین روی escrow
CREATE TABLE IF NOT EXISTS trainer_escrow_admin_actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subscription_id TEXT REFERENCES trainer_subscriptions(id) ON DELETE CASCADE,
    trainer_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    action TEXT NOT NULL CHECK (action IN (
      'freeze', 'unfreeze', 'early_release', 'extend_hold', 'block_payout', 'unblock_payout'
    )),
    reason TEXT,
    admin_id UUID NOT NULL REFERENCES auth.users(id),
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_escrow_admin_actions_subscription
  ON trainer_escrow_admin_actions(subscription_id);
CREATE INDEX IF NOT EXISTS idx_escrow_admin_actions_trainer
  ON trainer_escrow_admin_actions(trainer_id);

ALTER TABLE trainer_escrow_admin_actions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins manage escrow actions" ON trainer_escrow_admin_actions
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role = 'admin'
        )
    );

-- 5. backfill: مبالغ از platform_revenue برای اشتراک‌های قبلی
UPDATE trainer_subscriptions ts
SET
  platform_commission_amount = COALESCE(
    ts.platform_commission_amount,
    (SELECT pr.amount FROM platform_revenue pr WHERE pr.subscription_id = ts.id LIMIT 1),
    0
  ),
  trainer_share_amount = COALESCE(
    ts.trainer_share_amount,
    GREATEST(
      COALESCE(ts.final_amount, 0) - COALESCE(
        (SELECT pr.amount FROM platform_revenue pr WHERE pr.subscription_id = ts.id LIMIT 1),
        0
      ),
      0
    )
  )
WHERE ts.trainer_share_amount IS NULL OR ts.platform_commission_amount IS NULL;

-- backfill: تاریخ‌های escrow برای اشتراک‌هایی که برنامه ثبت شده
UPDATE trainer_subscriptions ts
SET
  program_edit_until = COALESCE(
    program_edit_until,
    program_registration_date + INTERVAL '3 days'
  ),
  earnings_hold_start_at = COALESCE(
    earnings_hold_start_at,
    program_registration_date + INTERVAL '3 days'
  ),
  earnings_withdrawable_at = COALESCE(
    earnings_withdrawable_at,
    program_registration_date + INTERVAL '6 days'
  ),
  earnings_escrow_status = CASE
    WHEN earnings_frozen = TRUE THEN 'frozen'
    WHEN program_registration_date IS NULL THEN 'in_platform'
    WHEN NOW() < program_registration_date + INTERVAL '3 days' THEN 'edit_window'
    WHEN NOW() < program_registration_date + INTERVAL '6 days' THEN 'hold'
    ELSE 'withdrawable'
  END
WHERE program_registration_date IS NOT NULL
  AND (earnings_hold_start_at IS NULL OR earnings_escrow_status = 'in_platform');
