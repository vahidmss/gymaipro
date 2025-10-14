-- اتمیک‌سازی شارژ کیف پول: تومان→ریال (×10) و ثبت تراکنش
create or replace function public.wallet_topup_apply_v2(
  p_session_id text,
  p_gateway text,
  p_gateway_ref text,
  p_units text default 'IRT'  -- 'IRT' = تومان, 'IRR' = ریال
) returns jsonb
language plpgsql
as $$
declare
  v_user uuid;
  v_amount int;           -- مبلغ ذخیره‌شده در payment_sessions (بر حسب IRT توصیه شده)
  v_credit int;           -- مبلغ نهایی که به کیف پول می‌رود (بر حسب ریال)
  v_wallet_id text;
  v_balance_before int := 0;
  v_balance_after int := 0;
  v_now timestamptz := now();
  v_row record;
begin
  -- 1) سشن را از pending → completed تغییر بده و اطلاعات لازم را بگیر
  update payment_sessions
     set status = 'completed',
         gateway = p_gateway,
         gateway_ref = p_gateway_ref,
         completed_at = v_now,
         updated_at = v_now
   where session_id = p_session_id
     and status = 'pending'
  returning user_id, amount
    into v_user, v_amount;

  if v_user is null then
    -- یا سشن نامعتبره، یا قبلاً پردازش شده
    return jsonb_build_object('ok', true, 'alreadyProcessed', true);
  end if;

  -- 2) تبدیل واحد (پیش‌فرض: تومان→ریال)
  if upper(coalesce(p_units, 'IRT')) = 'IRT' then
    v_credit := coalesce(v_amount, 0) * 10;
  else
    v_credit := coalesce(v_amount, 0);
  end if;

  -- 3) به‌روزرسانی یا ایجاد کیف پول (در یک تراکنش)
  -- تلاش برای خواندن والت فعلی (برای محاسبه before/after)
  select id, balance
    into v_row
    from wallets
   where user_id = v_user
   for update;  -- قفل خوش‌خیم

  if not found then
    -- والت وجود ندارد: ایجاد
    insert into wallets (
      id, user_id, balance, available_balance, blocked_balance,
      total_charged, total_spent, is_active, is_verified,
      minimum_balance, maximum_balance,
      last_transaction_date, metadata, created_at, updated_at
    ) values (
      gen_random_uuid()::text, v_user, v_credit, v_credit, 0,
      v_credit, 0, true, false,
      10000, 100000000,
      v_now, '{}'::jsonb, v_now, v_now
    )
    returning id, balance into v_wallet_id, v_balance_after;

    v_balance_before := 0;
  else
    -- والت موجود: جمع‌زدن امن
    v_wallet_id := v_row.id;
    v_balance_before := coalesce(v_row.balance, 0);

    update wallets
       set balance            = balance + v_credit,
           available_balance  = available_balance + v_credit,
           total_charged      = total_charged + v_credit,
           last_transaction_date = v_now,
           updated_at         = v_now
     where id = v_wallet_id
     returning balance into v_balance_after;
  end if;

  -- 4) ثبت لاگ تراکنش
  insert into wallet_transactions (
    id, wallet_id, user_id, type, amount,
    balance_before, balance_after,
    description, reference_id, metadata, created_at
  ) values (
    gen_random_uuid(), v_wallet_id, v_user, 'charge', v_credit,
    v_balance_before, v_balance_after,
    'شارژ کیف پول - ' || coalesce(p_gateway, 'unknown'),
    p_session_id,
    jsonb_build_object('gateway', p_gateway, 'gateway_ref', p_gateway_ref, 'session_id', p_session_id),
    v_now
  );

  return jsonb_build_object('ok', true, 'wallet_id', v_wallet_id, 'balance_after', v_balance_after);
end;
$$;

-- اختیاری: اگر RLS فعاله، به اجرای این تابع توسط service role نیازی به policy نیست.


