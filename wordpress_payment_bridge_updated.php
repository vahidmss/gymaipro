/* === GymAI Topup Bridge for Zibal === */
if (!defined('ABSPATH')) { exit; }

/** ===== تنظیمات ===== */
const GYM_TOPUP_GATEWAY       = 'zibal';
const GYM_TOPUP_MERCHANT      = '68cd4851a45c720017e12178';
const GYM_TOPUP_SECRET        = 'vahidsalamkonamoobebine@@!!!khokechi123';
const GYM_TOPUP_APP_API       = 'https://api.gymaipro.ir';
const GYM_TOPUP_SUPABASE_ANON = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyAgCiAgICAicm9sZSI6ICJhbm9uIiwKICAgICJpc3MiOiAic3VwYWJhc2UtZGVtbyIsCiAgICAiaWF0IjogMTY0MTc2OTIwMCwKICAgICJleHAiOiAxNzk5NTM1NjAwCn0.dc_X5iR_VP_qT0zsiyj_I_OZ2T9FtRU2BBNWN8Bu4GE';
/** کلید service_role — فقط روی سرور وردپرس (هرگز در اپ Flutter نگذار)
 *  self-hosted: روی سرور Supabase → grep SERVICE_ROLE_KEY ~/supabase-project/.env
 *  یا در wp-config.php: define('GYM_TOPUP_SERVICE_ROLE', 'eyJ...');
 *  یا متغیر محیطی روی هاست: GYM_TOPUP_SERVICE_ROLE
 */
if (!defined('GYM_TOPUP_SERVICE_ROLE')) {
  define('GYM_TOPUP_SERVICE_ROLE', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoic2VydmljZV9yb2xlIiwiaXNzIjoic3VwYWJhc2UiLCJpYXQiOjE3Njk5Mzk0NTIsImV4cCI6MTkyNzYxOTQ1Mn0.M4Qy1nsv9yiI72mn6EbptFR7nOjMGdR1Li5OcsH9NbQ');
}
const GYM_TOPUP_DEEPLINK_OK   = 'gymaipro://wallet/topup?status=success';
const GYM_TOPUP_DEEPLINK_FAIL = 'gymaipro://wallet/topup?status=failed';
const GYM_TOPUP_DEEPLINK_PROC = 'gymaipro://wallet/topup?status=processing';
const GYM_TOPUP_CURRENCY      = 'IRT';

add_action('init', function () {
  add_rewrite_rule('^pay/topup/?',    'index.php?app_topup=1', 'top');
  add_rewrite_rule('^pay/callback/?', 'index.php?app_callback=1', 'top');
  add_rewrite_tag('%app_topup%', '1');
  add_rewrite_tag('%app_callback%', '1');
  if (!get_option('gym_topup_rewrite_flushed')) {
    flush_rewrite_rules();
    update_option('gym_topup_rewrite_flushed', 1);
  }
});

add_filter('query_vars', function ($vars) {
  $vars[] = 'app_topup';
  $vars[] = 'app_callback';
  return $vars;
});

add_action('template_redirect', function () {
  $request_uri = isset($_SERVER['REQUEST_URI']) ? trim(parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH), '/') : '';
  if (get_query_var('app_topup') || $request_uri === 'pay/topup')   { gymai_render_checkout(); exit; }
  if (get_query_var('app_callback') || $request_uri === 'pay/callback'){ gymai_handle_callback(); exit; }
});

add_action('rest_api_init', function () {
  register_rest_route('gymaipro/v1', '/zibal/request', [
    'methods' => 'POST',
    'callback' => 'gymai_zibal_proxy_request',
    'permission_callback' => '__return_true',
  ]);
  register_rest_route('gymaipro/v1', '/zibal/verify', [
    'methods' => 'POST',
    'callback' => 'gymai_zibal_proxy_verify',
    'permission_callback' => '__return_true',
  ]);
  register_rest_route('gymaipro/v1', '/zibal/inquiry', [
    'methods' => 'POST',
    'callback' => 'gymai_zibal_proxy_inquiry',
    'permission_callback' => '__return_true',
  ]);
});

function gymai_zibal_proxy_request($request) {
  $params = $request->get_json_params();
  if (empty($params['amount']) || empty($params['callbackUrl'])) {
    return new WP_Error('missing_params', 'مقدار و callbackUrl الزامی است', ['status' => 400]);
  }
  $zibal_request = [
    'merchant' => GYM_TOPUP_MERCHANT,
    'amount' => intval($params['amount']),
    'callbackUrl' => sanitize_url($params['callbackUrl']),
    'description' => isset($params['description']) ? sanitize_text_field($params['description']) : 'پرداخت',
  ];
  if (isset($params['orderId'])) $zibal_request['orderId'] = sanitize_text_field($params['orderId']);
  if (isset($params['mobile'])) $zibal_request['mobile'] = sanitize_text_field($params['mobile']);
  if (isset($params['metadata'])) $zibal_request['metadata'] = $params['metadata'];

  $response = wp_remote_post('https://gateway.zibal.ir/v1/request', [
    'timeout' => 15,
    'headers' => ['Content-Type' => 'application/json', 'Accept' => 'application/json'],
    'body' => wp_json_encode($zibal_request),
  ]);
  if (is_wp_error($response)) {
    return new WP_Error('zibal_error', $response->get_error_message(), ['status' => 500]);
  }
  return new WP_REST_Response(json_decode(wp_remote_retrieve_body($response), true), wp_remote_retrieve_response_code($response));
}

function gymai_zibal_proxy_verify($request) {
  $params = $request->get_json_params();
  if (empty($params['trackId'])) {
    return new WP_Error('missing_trackid', 'trackId الزامی است', ['status' => 400]);
  }
  $response = wp_remote_post('https://gateway.zibal.ir/v1/verify', [
    'timeout' => 15,
    'headers' => ['Content-Type' => 'application/json', 'Accept' => 'application/json'],
    'body' => wp_json_encode(['merchant' => GYM_TOPUP_MERCHANT, 'trackId' => sanitize_text_field($params['trackId'])]),
  ]);
  if (is_wp_error($response)) {
    return new WP_Error('zibal_error', $response->get_error_message(), ['status' => 500]);
  }
  return new WP_REST_Response(json_decode(wp_remote_retrieve_body($response), true), wp_remote_retrieve_response_code($response));
}

function gymai_zibal_proxy_inquiry($request) {
  $params = $request->get_json_params();
  if (empty($params['trackId'])) {
    return new WP_Error('missing_trackid', 'trackId الزامی است', ['status' => 400]);
  }
  $response = wp_remote_post('https://gateway.zibal.ir/v1/inquiry', [
    'timeout' => 15,
    'headers' => ['Content-Type' => 'application/json', 'Accept' => 'application/json'],
    'body' => wp_json_encode(['merchant' => GYM_TOPUP_MERCHANT, 'trackId' => sanitize_text_field($params['trackId'])]),
  ]);
  if (is_wp_error($response)) {
    return new WP_Error('zibal_error', $response->get_error_message(), ['status' => 500]);
  }
  return new WP_REST_Response(json_decode(wp_remote_retrieve_body($response), true), wp_remote_retrieve_response_code($response));
}

function gymai_h($s){ return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); }

/** service_role از constant، wp-config یا env (به ترتیب اولویت) */
function gymai_get_service_role_key() {
  if (defined('GYM_TOPUP_SERVICE_ROLE')) {
    $from_define = GYM_TOPUP_SERVICE_ROLE;
    if (is_string($from_define) && $from_define !== '') {
      return $from_define;
    }
  }
  foreach (['GYM_TOPUP_SERVICE_ROLE', 'SERVICE_ROLE_KEY', 'SUPABASE_SERVICE_ROLE_KEY'] as $name) {
    $val = getenv($name);
    if (is_string($val) && $val !== '') {
      return $val;
    }
  }
  return '';
}

function gymai_supabase_headers($use_service_role = false) {
  $key = GYM_TOPUP_SUPABASE_ANON;
  if ($use_service_role) {
    $service = gymai_get_service_role_key();
    if ($service !== '') {
      $key = $service;
    }
  }
  return [
    'apikey' => $key,
    'Authorization' => 'Bearer ' . $key,
    'Content-Type' => 'application/json',
  ];
}

function gymai_format_toman($amount_irt) {
  return number_format((int)$amount_irt) . ' تومان';
}

function gymai_get_session_data($session_id) {
  $url = GYM_TOPUP_APP_API . '/rest/v1/payment_sessions?session_id=eq.' . urlencode($session_id) . '&select=*';
  $response = wp_remote_get($url, ['headers' => gymai_supabase_headers(), 'timeout' => 15]);
  if (is_wp_error($response)) return false;
  $data = json_decode(wp_remote_retrieve_body($response), true);
  if (empty($data) || !isset($data[0])) return false;
  return $data[0];
}

/** امضای HMAC — باید با wallet_topup_confirm_hmac در Postgres یکی باشد */
function gymai_topup_hmac_payload($session_id, $gateway_ref) {
  return $session_id . '|zibal|' . (string)$gateway_ref;
}

/** شارژ کیف پول — اول HMAC+anon (api.gymaipro.ir)، بعد service_role */
function gymai_apply_wallet_topup($session_id, $gateway_ref) {
  $sig = hash_hmac('sha256', gymai_topup_hmac_payload($session_id, $gateway_ref), GYM_TOPUP_SECRET);

  $hmac_response = wp_remote_post(GYM_TOPUP_APP_API . '/rest/v1/rpc/wallet_topup_confirm_hmac', [
    'timeout' => 20,
    'headers' => gymai_supabase_headers(false),
    'body' => wp_json_encode([
      'p_session_id' => $session_id,
      'p_gateway' => 'zibal',
      'p_gateway_ref' => (string)$gateway_ref,
      'p_signature' => $sig,
    ]),
  ]);

  $hmac_error = null;
  if (!is_wp_error($hmac_response)) {
    $code = wp_remote_retrieve_response_code($hmac_response);
    $body = wp_remote_retrieve_body($hmac_response);
    $json = json_decode($body, true);
    if ($code >= 200 && $code < 300 && is_array($json) && gymai_wallet_apply_succeeded($json)) {
      return ['ok' => true, 'result' => $json, 'via' => 'hmac'];
    }
    $hmac_error = $body;
  } else {
    $hmac_error = $hmac_response->get_error_message();
  }

  if (gymai_get_service_role_key() === '') {
    return ['ok' => false, 'error' => $hmac_error ?? 'service_role_not_configured'];
  }

  $response = wp_remote_post(GYM_TOPUP_APP_API . '/rest/v1/rpc/wallet_topup_apply_v2', [
    'timeout' => 20,
    'headers' => gymai_supabase_headers(true),
    'body' => wp_json_encode([
      'p_session_id' => $session_id,
      'p_gateway' => 'zibal',
      'p_gateway_ref' => (string)$gateway_ref,
      'p_units' => 'IRT',
    ]),
  ]);
  if (is_wp_error($response)) {
    return ['ok' => false, 'error' => $response->get_error_message(), 'hmac_error' => $hmac_error];
  }
  $code = wp_remote_retrieve_response_code($response);
  $body = wp_remote_retrieve_body($response);
  $json = json_decode($body, true);
  if ($code >= 200 && $code < 300 && is_array($json) && gymai_wallet_apply_succeeded($json)) {
    return ['ok' => true, 'result' => $json, 'via' => 'service_role'];
  }
  return ['ok' => false, 'error' => $body, 'code' => $code, 'hmac_error' => $hmac_error];
}

function gymai_wallet_apply_succeeded($json) {
  if (!is_array($json)) return false;
  if (!empty($json['ok'])) return true;
  if (!empty($json['alreadyProcessed'])) return true;
  if (!empty($json['wallet_id'])) return true;
  return false;
}

function gymai_render_page($title, $body_html, $extra_head = '') {
  echo '<!doctype html><html lang="fa" dir="rtl"><head><meta charset="utf-8">';
  echo '<meta name="viewport" content="width=device-width, initial-scale=1">';
  echo '<title>' . gymai_h($title) . ' | GymAI Pro</title>';
  echo '<link rel="preconnect" href="https://fonts.googleapis.com">';
  echo '<link href="https://fonts.googleapis.com/css2?family=Vazirmatn:wght@400;600;700&display=swap" rel="stylesheet">';
  echo '<style>
    *{box-sizing:border-box}
    body{margin:0;min-height:100vh;font-family:Vazirmatn,Tahoma,sans-serif;background:linear-gradient(145deg,#0b0f14,#151b24 45%,#0f1419);color:#f5f5f5;display:flex;align-items:center;justify-content:center;padding:24px 16px}
    .card{width:100%;max-width:420px;background:rgba(22,28,36,.95);border:1px solid rgba(212,175,55,.25);border-radius:20px;padding:28px 24px;box-shadow:0 20px 60px rgba(0,0,0,.45)}
    .logo{display:flex;align-items:center;gap:10px;margin-bottom:20px}
    .logo-badge{width:44px;height:44px;border-radius:12px;background:linear-gradient(135deg,#d4af37,#f5c518);display:flex;align-items:center;justify-content:center;font-weight:700;color:#111}
    .logo h1{margin:0;font-size:18px;font-weight:700}
    .logo p{margin:2px 0 0;font-size:12px;color:#9aa4b2}
    h2{margin:0 0 12px;font-size:20px;font-weight:700}
    .amount{font-size:28px;font-weight:700;color:#f5c518;margin:8px 0 20px}
    .muted{color:#9aa4b2;font-size:14px;line-height:1.7}
    .btn{display:block;width:100%;text-align:center;padding:14px 18px;border-radius:14px;text-decoration:none;font-weight:700;font-size:16px;border:none;cursor:pointer}
    .btn-primary{background:linear-gradient(135deg,#d4af37,#f5c518);color:#111}
    .btn-secondary{background:rgba(255,255,255,.08);color:#f5f5f5;border:1px solid rgba(255,255,255,.12);margin-top:12px}
    .alert{padding:14px;border-radius:12px;font-size:14px;line-height:1.6;margin:16px 0}
    .alert-error{background:rgba(239,68,68,.12);border:1px solid rgba(239,68,68,.35);color:#fecaca}
    .alert-success{background:rgba(34,197,94,.12);border:1px solid rgba(34,197,94,.35);color:#bbf7d0}
    .alert-warn{background:rgba(245,197,24,.12);border:1px solid rgba(245,197,24,.35);color:#fde68a}
    .spinner{width:42px;height:42px;border:3px solid rgba(245,197,24,.2);border-top-color:#f5c518;border-radius:50%;animation:spin .8s linear infinite;margin:20px auto}
    @keyframes spin{to{transform:rotate(360deg)}}
    .ref{background:rgba(255,255,255,.06);padding:10px 12px;border-radius:10px;font-size:13px;word-break:break-all;margin:12px 0}
    .debug{margin-top:16px;padding:12px;border:1px dashed rgba(255,255,255,.2);border-radius:10px;font-size:12px;color:#cbd5e1;white-space:pre-wrap}
  </style>';
  echo $extra_head;
  echo '</head><body><div class="card">';
  echo '<div class="logo"><div class="logo-badge">G</div><div><h1>GymAI Pro</h1><p>شارژ کیف پول</p></div></div>';
  echo $body_html;
  echo '</div></body></html>';
}

function gymai_render_checkout(){
  $session_id = isset($_GET['session_id']) ? sanitize_text_field($_GET['session_id']) : '';
  if (empty($session_id)) {
    status_header(400);
    gymai_render_page('خطا', '<h2>شناسه جلسه یافت نشد</h2><p class="muted">لطفاً دوباره از اپلیکیشن اقدام کنید.</p>');
    return;
  }

  $session = gymai_get_session_data($session_id);
  if (!$session) {
    status_header(404);
    gymai_render_page('خطا', '<h2>جلسه پرداخت نامعتبر است</h2><p class="muted">جلسه منقضی شده یا پیدا نشد. از اپ دوباره «ادامه پرداخت» را بزنید.</p>');
    return;
  }

  if (time() > strtotime($session['expires_at'])) {
    status_header(400);
    gymai_render_page('منقضی', '<h2>زمان پرداخت تمام شده</h2><p class="muted">لطفاً از اپلیکیشن یک جلسه جدید بسازید.</p>');
    return;
  }

  if ($session['status'] !== 'pending') {
    status_header(400);
    gymai_render_page('پردازش شده', '<h2>این پرداخت قبلاً انجام شده</h2><p class="muted">به اپلیکیشن برگردید و موجودی کیف پول را بررسی کنید.</p><a class="btn btn-primary" href="' . gymai_h(GYM_TOPUP_DEEPLINK_OK) . '">بازگشت به اپ</a>');
    return;
  }

  $amount = intval($session['amount']);
  $callback = add_query_arg(['gw' => 'zibal', 'sid' => rawurlencode($session_id)], home_url('/pay/callback'));
  $z_amount = (GYM_TOPUP_CURRENCY === 'IRT') ? $amount * 10 : $amount;

  $resp = wp_remote_post('https://gateway.zibal.ir/v1/request', [
    'timeout' => 15,
    'headers' => ['Content-Type' => 'application/json'],
    'body' => wp_json_encode([
      'merchant' => GYM_TOPUP_MERCHANT,
      'callbackUrl' => $callback,
      'amount' => $z_amount,
      'orderId' => $session_id,
      'description' => 'GymAI Wallet Topup #' . $session_id,
    ]),
  ]);

  $pay_url = false;
  $zibal_error = '';
  if (!is_wp_error($resp)) {
    $j = json_decode(wp_remote_retrieve_body($resp), true);
    if (($j['result'] ?? null) === 100 && !empty($j['trackId'])) {
      $pay_url = 'https://gateway.zibal.ir/start/' . $j['trackId'];
    } else {
      $zibal_error = wp_remote_retrieve_body($resp);
    }
  } else {
    $zibal_error = $resp->get_error_message();
  }

  if ($pay_url) {
    $safe = gymai_h($pay_url);
    $extra = "<meta http-equiv=\"refresh\" content=\"0;url={$safe}\"><script>window.location.replace('{$safe}');</script>";
    $body = '<h2>در حال انتقال به درگاه پرداخت</h2>';
    $body .= '<div class="spinner"></div>';
    $body .= '<p class="amount">' . gymai_h(gymai_format_toman($amount)) . '</p>';
    $body .= '<p class="muted">چند لحظه صبر کنید؛ به زیبال منتقل می‌شوید.</p>';
    $body .= '<a class="btn btn-primary" href="' . $safe . '">ورود به درگاه پرداخت</a>';
    gymai_render_page('انتقال به درگاه', $body, $extra);
    return;
  }

  gymai_render_page('خطا', '<h2>ایجاد تراکنش ناموفق بود</h2><div class="alert alert-error">اتصال به درگاه زیبال برقرار نشد. لطفاً چند دقیقه بعد دوباره تلاش کنید.</div><p class="ref">' . gymai_h($zibal_error) . '</p><a class="btn btn-secondary" href="' . gymai_h(GYM_TOPUP_DEEPLINK_FAIL) . '">بازگشت به اپ</a>');
}

function gymai_handle_callback(){
  $payment_type = isset($_GET['type']) ? sanitize_text_field($_GET['type']) : 'topup';
  $order_id = isset($_GET['orderId']) ? sanitize_text_field($_GET['orderId']) : '';
  $trainer_id = isset($_GET['trainerId']) ? sanitize_text_field($_GET['trainerId']) : '';
  $is_coach_plan = ($payment_type === 'coach_plan' || $payment_type === 'coach-plan');
  $sid = ($payment_type === 'trainer' || $is_coach_plan)
    ? $order_id
    : (isset($_GET['sid']) ? preg_replace('/[^A-Za-z0-9_\-]/', '', $_GET['sid']) : '');

  if ($payment_type === 'trainer' && !empty($trainer_id)) {
    $deeplink_ok = 'gymaipro://payment/trainer?status=success&transactionId=' . urlencode($order_id) . '&trainerId=' . urlencode($trainer_id);
    $deeplink_fail = 'gymaipro://payment/trainer?status=failed&transactionId=' . urlencode($order_id) . '&trainerId=' . urlencode($trainer_id);
  } elseif ($is_coach_plan) {
    $deeplink_ok = 'gymaipro://payment/coach-plan?status=success&transactionId=' . urlencode($order_id);
    $deeplink_fail = 'gymaipro://payment/coach-plan?status=failed&transactionId=' . urlencode($order_id);
  } else {
    $deeplink_ok = GYM_TOPUP_DEEPLINK_OK;
    $deeplink_fail = GYM_TOPUP_DEEPLINK_FAIL;
  }

  $deeplink = $deeplink_fail;
  $ok = false;
  $ref = '';
  $wallet_applied = false;
  $wallet_error = '';
  $is_debug = isset($_GET['debug']) && $_GET['debug'] == '1';
  $verify_body = null;
  $inquiry_body = null;

  $trackId = isset($_REQUEST['trackId']) ? sanitize_text_field($_REQUEST['trackId']) : '';
  if ($trackId) {
    $resp = wp_remote_post('https://gateway.zibal.ir/v1/verify', [
      'timeout' => 15,
      'headers' => ['Content-Type' => 'application/json'],
      'body' => wp_json_encode(['merchant' => GYM_TOPUP_MERCHANT, 'trackId' => $trackId]),
    ]);
    if (!is_wp_error($resp)) {
      $verify_body = wp_remote_retrieve_body($resp);
      $j = json_decode($verify_body, true);
      $result = intval($j['result'] ?? 0);
      if ($result === 100 || $result === 201) {
        $ok = true;
        $ref = (string)($j['refNumber'] ?? $trackId);
      }
    }
  }

  if (!$ok && $sid) {
    $resp2 = wp_remote_post('https://gateway.zibal.ir/v1/inquiry', [
      'timeout' => 15,
      'headers' => ['Content-Type' => 'application/json'],
      'body' => wp_json_encode(['merchant' => GYM_TOPUP_MERCHANT, 'orderId' => $sid]),
    ]);
    if (!is_wp_error($resp2)) {
      $inquiry_body = wp_remote_retrieve_body($resp2);
      $j2 = json_decode($inquiry_body, true);
      $result2 = intval($j2['result'] ?? 0);
      if ($result2 === 100 || $result2 === 201) {
        $ok = true;
        $ref = (string)($j2['refNumber'] ?? $j2['trackId'] ?? $sid);
      }
    }
  }

  if (!$ok && isset($_REQUEST['success']) && intval($_REQUEST['success']) === 1 && !empty($sid)) {
    $ok = true;
    if (empty($ref)) $ref = (string)($_REQUEST['trackId'] ?? $sid);
  }

  if ($ok && $sid && $payment_type !== 'trainer' && !$is_coach_plan) {
    $apply = gymai_apply_wallet_topup($sid, $ref);
    $wallet_applied = !empty($apply['ok']);
    if (!$wallet_applied) {
      $wallet_error = is_string($apply['error'] ?? null) ? $apply['error'] : wp_json_encode($apply);
    }
    if ($wallet_applied) {
      $deeplink = $deeplink_ok;
    } else {
      $deeplink = GYM_TOPUP_DEEPLINK_PROC;
    }
  }

  if ($payment_type === 'trainer' && $ok && !empty($trackId)) {
    $deeplink = 'gymaipro://payment/trainer?status=success&transactionId=' . urlencode($order_id) . '&trackId=' . urlencode($trackId) . '&trainerId=' . urlencode($trainer_id);
  } elseif ($payment_type === 'trainer' && !$ok) {
    $deeplink = $deeplink_fail;
  } elseif ($is_coach_plan && $ok && !empty($trackId)) {
    $deeplink = 'gymaipro://payment/coach-plan?status=success&transactionId=' . urlencode($order_id) . '&trackId=' . urlencode($trackId);
  } elseif ($is_coach_plan && !$ok) {
    $deeplink = $deeplink_fail;
  }

  $body = $ok
    ? ($wallet_applied ? '<h2>پرداخت موفق</h2><div class="alert alert-success">کیف پول شما شارژ شد.</div>' : '<h2>پرداخت دریافت شد</h2><div class="alert alert-warn">پرداخت ثبت شد اما شارژ کیف پول با تأخیر انجام می‌شود. اگر بعد از ۵ دقیقه موجودی تغییر نکرد با پشتیبانی تماس بگیرید.</div>')
    : '<h2>پرداخت ناموفق</h2><div class="alert alert-error">تراکنش لغو شد یا تأیید نشد.</div>';

  if ($ref) {
    $body .= '<div class="ref">کد پیگیری: <strong>' . gymai_h($ref) . '</strong></div>';
  }

  if ($is_debug) {
    $body .= '<div class="debug"><b>DEBUG</b>' . "\n";
    if ($verify_body) $body .= "verify: {$verify_body}\n";
    if ($inquiry_body) $body .= "inquiry: {$inquiry_body}\n";
    if ($wallet_error) $body .= "wallet: {$wallet_error}\n";
    $body .= '</div>';
  }

  $safe_deeplink = gymai_h($deeplink);
  $extra = "<script>(function(){
    var u='{$safe_deeplink}';
    try{window.location.replace(u);}catch(e){window.location.href=u;}
    setTimeout(function(){
      try{
        document.open();
        document.write('<html dir=\"rtl\"><head><meta name=\"viewport\" content=\"width=device-width,initial-scale=1\"><title>GymAI</title></head><body style=\"font-family:tahoma,sans-serif;text-align:center;padding:48px 24px;background:#0f0f0f;color:#fff\"><h2 style=\"color:#D4AF37\">پرداخت انجام شد</h2><p style=\"opacity:.85\">به اپ GymAI برگردید.</p><p style=\"font-size:13px;opacity:.6\">این صفحه را ببندید.</p></body></html>');
        document.close();
      }catch(e){}
    },400);
  })();</script>";
  $body .= '<p class="muted">در حال بازگشت به اپلیکیشن...</p>';
  $body .= '<a class="btn btn-primary" href="' . $safe_deeplink . '">بازگشت به GymAI Pro</a>';

  gymai_render_page($ok ? 'نتیجه پرداخت' : 'پرداخت ناموفق', $body, $extra);
}
