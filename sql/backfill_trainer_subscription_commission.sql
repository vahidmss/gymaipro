-- پر کردن trainer_share_amount و platform_commission_amount
-- برای اشتراک‌های پرداخت‌شده‌ای که escrow ثبت نشده (مثلاً پرداخت کیف‌پول قدیمی)

UPDATE trainer_subscriptions ts
SET
  platform_commission_amount = COALESCE(
    NULLIF(ts.platform_commission_amount, 0),
    (
      SELECT pr.amount
      FROM platform_revenue pr
      WHERE pr.subscription_id = ts.id
      LIMIT 1
    ),
    (
      SELECT ROUND(ts.final_amount * cs.commission_percentage / 100.0)::INTEGER
      FROM commission_settings cs
      WHERE cs.is_active = TRUE
      ORDER BY cs.created_at DESC
      LIMIT 1
    ),
    0
  ),
  trainer_share_amount = COALESCE(
    NULLIF(ts.trainer_share_amount, 0),
    GREATEST(
      ts.final_amount - COALESCE(
        NULLIF(ts.platform_commission_amount, 0),
        (
          SELECT pr.amount
          FROM platform_revenue pr
          WHERE pr.subscription_id = ts.id
          LIMIT 1
        ),
        (
          SELECT ROUND(ts.final_amount * cs.commission_percentage / 100.0)::INTEGER
          FROM commission_settings cs
          WHERE cs.is_active = TRUE
          ORDER BY cs.created_at DESC
          LIMIT 1
        ),
        0
      ),
      0
    )
  ),
  earnings_escrow_status = COALESCE(ts.earnings_escrow_status, 'in_platform'),
  updated_at = NOW()
WHERE ts.payment_transaction_id IS NOT NULL
  AND ts.status IN ('paid', 'active', 'completed')
  AND (
    ts.trainer_share_amount IS NULL
    OR ts.platform_commission_amount IS NULL
    OR ts.trainer_share_amount = 0
  );
