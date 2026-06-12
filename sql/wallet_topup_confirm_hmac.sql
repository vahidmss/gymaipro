-- اجرا در SQL Editor روی api.gymaipro.ir
-- رفع wallet_topup_confirm_hmac + grant برای wallet_topup_apply_v2

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS gym_internal_secrets (
  name text PRIMARY KEY,
  value text NOT NULL
);

ALTER TABLE gym_internal_secrets ENABLE ROW LEVEL SECURITY;

INSERT INTO gym_internal_secrets (name, value)
VALUES ('topup_hmac', 'vahidsalamkonamoobebine@@!!!khokechi123')
ON CONFLICT (name) DO UPDATE SET value = EXCLUDED.value;

GRANT EXECUTE ON FUNCTION public.wallet_topup_apply_v2(text, text, text, text) TO service_role;

CREATE OR REPLACE FUNCTION public.wallet_topup_confirm_hmac(
  p_session_id text,
  p_gateway text,
  p_gateway_ref text,
  p_signature text
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_secret text;
  v_payload text;
  v_expected text;
BEGIN
  SELECT value INTO v_secret
  FROM gym_internal_secrets
  WHERE name = 'topup_hmac'
  LIMIT 1;

  IF v_secret IS NULL OR v_secret = '' THEN
    RETURN jsonb_build_object('ok', false, 'error', 'secret_not_configured');
  END IF;

  -- همان فرمت PHP: session_id|gateway|gateway_ref
  v_payload := p_session_id || '|' || p_gateway || '|' || p_gateway_ref;
  v_expected := encode(hmac(v_payload, v_secret, 'sha256'), 'hex');

  IF lower(trim(coalesce(p_signature, ''))) <> lower(v_expected) THEN
    RETURN jsonb_build_object('ok', false, 'error', 'bad_signature');
  END IF;

  RETURN wallet_topup_apply_v2(p_session_id, p_gateway, p_gateway_ref, 'IRT');
END;
$$;

REVOKE ALL ON FUNCTION public.wallet_topup_confirm_hmac(text, text, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.wallet_topup_confirm_hmac(text, text, text, text) TO anon, authenticated, service_role;

NOTIFY pgrst, 'reload schema';
