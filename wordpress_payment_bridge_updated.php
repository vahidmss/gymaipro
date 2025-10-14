/* === GymAI Topup Bridge for Zibal (Updated for Edge Function) === */
if (!defined('ABSPATH')) { exit; }

/** ===== تنظیمات را اینجا پر/چک کن ===== */
const GYM_TOPUP_GATEWAY       = 'zibal';                 // ثابت: زیبال
const GYM_TOPUP_MERCHANT      = '68cd4851a45c720017e12178'; // مرچنت کد زیبال شما
const GYM_TOPUP_SECRET        = 'vahidsalamkonamoobebine@@!!!khokechi123'; // ← اینو خودت بذار (همین در بک‌اند هم باشد)
const GYM_TOPUP_APP_API       = 'https://oaztoennovtcfcxvnswa.supabase.co';       // آدرس Supabase شما
const GYM_TOPUP_DEEPLINK_OK   = 'gymaipro://wallet/topup?status=success';
const GYM_TOPUP_DEEPLINK_FAIL = 'gymaipro://wallet/topup?status=failed';
/* زیبال مبلغ را «ریال» می‌خواهد. اگر در اپ «تومان» می‌فرستی، IRT بگذار تا ×۱۰ شود. */
const GYM_TOPUP_CURRENCY      = 'IRT'; // IRT=تومان ، IRR=ریال

/** ===== مسیرهای لازم را ثبت می‌کنیم: /pay/topup و /pay/callback ===== */
add_action('init', function () {
  add_rewrite_rule('^pay/topup/?',    'index.php?app_topup=1', 'top');
  add_rewrite_rule('^pay/callback/?', 'index.php?app_callback=1', 'top');
  // ثبت کوئری‌وارهای سفارشی
  add_rewrite_tag('%app_topup%', '1');
  add_rewrite_tag('%app_callback%', '1');

  // یک‌بار فلش کردن قوانین بازنویسی (برای Code Snippets / بدون اکتیویشن)
  if (!get_option('gym_topup_rewrite_flushed')) {
    flush_rewrite_rules();
    update_option('gym_topup_rewrite_flushed', 1);
  }
});

// اطمینان از پذیرش کوئری‌وارها در وردپرس
add_filter('query_vars', function ($vars) {
  $vars[] = 'app_topup';
  $vars[] = 'app_callback';
  return $vars;
});

add_action('template_redirect', function () {
  // چک مستقیم کوئری‌وارها و همچنین مسیر درخواست برای اطمینان
  $request_uri = isset($_SERVER['REQUEST_URI']) ? trim(parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH), '/') : '';
  if (get_query_var('app_topup') || $request_uri === 'pay/topup')   { gymai_render_checkout(); exit; }
  if (get_query_var('app_callback') || $request_uri === 'pay/callback'){ gymai_handle_callback(); exit; }
});

/** ابزارهای کمکی */
function gymai_h($s){ return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); }

/** دریافت اطلاعات جلسه از Supabase */
function gymai_get_session_data($session_id) {
  $url = GYM_TOPUP_APP_API . '/rest/v1/payment_sessions?session_id=eq.' . urlencode($session_id) . '&select=*';
  
  $response = wp_remote_get($url, [
    'headers' => [
      'apikey' => 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9henRvZW5ub3Z0Y2ZjeHZuc3dhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDY4NzYzNzEsImV4cCI6MjA2MjQ1MjM3MX0.UywfAvKyqUjByLQHRnRqJ85Bal6NdvAOwQQJXVaQfGk', // کلید anon Supabase
      'Authorization' => 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9henRvZW5ub3Z0Y2ZjeHZuc3dhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDY4NzYzNzEsImV4cCI6MjA2MjQ1MjM3MX0.UywfAvKyqUjByLQHRnRqJ85Bal6NdvAOwQQJXVaQfGk',
      'Content-Type' => 'application/json',
    ],
    'timeout' => 15
  ]);

  if (is_wp_error($response)) {
    return false;
  }

  $body = wp_remote_retrieve_body($response);
  $data = json_decode($body, true);
  
  if (empty($data) || !isset($data[0])) {
    return false;
  }

  return $data[0];
}

/** صفحه شروع پرداخت: /pay/topup?session_id=... */
function gymai_render_checkout(){
  $session_id = isset($_GET['session_id']) ? sanitize_text_field($_GET['session_id']) : '';
  
  if (empty($session_id)) {
    status_header(400); 
    echo 'Missing session ID'; 
    return; 
  }

  // دریافت اطلاعات جلسه از Supabase
  $session = gymai_get_session_data($session_id);
  if (!$session) {
    status_header(404); 
    echo 'Session not found or expired'; 
    return; 
  }

  // بررسی انقضا
  $expires_at = strtotime($session['expires_at']);
  if (time() > $expires_at) {
    status_header(400); 
    echo 'Session expired'; 
    return; 
  }

  // بررسی وضعیت
  if ($session['status'] !== 'pending') {
    status_header(400); 
    echo 'Session already processed'; 
    return; 
  }

  $amount = intval($session['amount']);
  $desc = 'GymAI Wallet Topup #' . $session_id;
  $callback = add_query_arg([
      'gw' => 'zibal',
      'sid'=> rawurlencode($session_id),
      'debug' => '1'
  ], home_url('/pay/callback'));

  // زیبال مبلغ را «ریال» می‌خواهد
  $z_amount = (GYM_TOPUP_CURRENCY==='IRT') ? $amount*10 : $amount;

  // درخواست ایجاد تراکنش به زیبال
  $resp = wp_remote_post('https://gateway.zibal.ir/v1/request', [
    'timeout'=>15, 'headers'=>['Content-Type'=>'application/json'],
    'body'=>wp_json_encode([
      'merchant'    => GYM_TOPUP_MERCHANT,
      'callbackUrl' => $callback,
      'amount'      => $z_amount,
      'orderId'     => $session_id,
      'description' => $desc
    ])
  ]);

  $pay_url = false;
  if(!is_wp_error($resp)){
    $j = json_decode(wp_remote_retrieve_body($resp), true);
    // result=100 → موفق؛ trackId می‌دهد
    if( ($j['result'] ?? null) === 100 && !empty($j['trackId']) ){
      $pay_url = 'https://gateway.zibal.ir/start/' . $j['trackId'];
    }
  }

  echo "<!doctype html><html><head><meta charset='utf-8'><meta name='viewport' content='width=device-width, initial-scale=1'>
        <title>شارژ کیف پول</title></head><body style='font-family:sans-serif;max-width:640px;margin:40px auto'>";
  echo "<h2>شارژ کیف پول</h2><p>مبلغ: <b>".gymai_h($amount)." ".gymai_h(GYM_TOPUP_CURRENCY)."</b></p>";
  if($pay_url){
    echo "<a href='".gymai_h($pay_url)."' style='display:inline-block;padding:12px 18px;border:1px solid #ccc;border-radius:8px;text-decoration:none'>پرداخت</a>";
  } else {
    echo "<div style='padding:12px;border:1px solid #e00;border-radius:8px'>ایجاد تراکنش ناموفق بود. لطفاً مجدد تلاش کنید.</div>";
  }
  echo "</body></html>";
}

/** کال‌بک: /pay/callback?gw=zibal&sid=... (+ پارامترهای زیبال مثل trackId و ...) */
function gymai_handle_callback(){
  $sid = isset($_GET['sid'])? preg_replace('/[^A-Za-z0-9_\-]/','',$_GET['sid']) : '';
  $deeplink = GYM_TOPUP_DEEPLINK_FAIL;
  $ok = false; $ref = '';
  $is_debug = isset($_GET['debug']) && $_GET['debug'] == '1';
  $verify_body = null; $inquiry_body = null;

  // زیبال در کال‌بک trackId می‌فرستد؛ باید verify کنیم
  $trackId = isset($_REQUEST['trackId']) ? sanitize_text_field($_REQUEST['trackId']) : '';
  if($trackId){
    $resp = wp_remote_post('https://gateway.zibal.ir/v1/verify', [
      'timeout'=>15, 'headers'=>['Content-Type'=>'application/json'],
      'body'=>wp_json_encode(['merchant'=>GYM_TOPUP_MERCHANT, 'trackId'=>$trackId])
    ]);
    if(!is_wp_error($resp)){
      $verify_body = wp_remote_retrieve_body($resp);
      $j = json_decode($verify_body, true);
      // result=100 → موفق
      $result = intval($j['result'] ?? 0);
      if( $result === 100 || $result === 201 ){
        $ok  = true;
        $ref = (string)($j['refNumber'] ?? $trackId);
      }
    }
  }

  // اگر trackId نبود یا verify موفق نشد، با orderId استعلام بگیر
  if(!$ok){
    $resp2 = wp_remote_post('https://gateway.zibal.ir/v1/inquiry', [
      'timeout'=>15, 'headers'=>['Content-Type'=>'application/json'],
      'body'=>wp_json_encode(['merchant'=>GYM_TOPUP_MERCHANT, 'orderId'=>$sid])
    ]);
    if(!is_wp_error($resp2)){
      $inquiry_body = wp_remote_retrieve_body($resp2);
      $j2 = json_decode($inquiry_body, true);
      $result2 = intval($j2['result'] ?? 0);
      if( $result2 === 100 || $result2 === 201 ){
        $ok  = true;
        $ref = (string)($j2['refNumber'] ?? $j2['trackId'] ?? $sid);
      }
    }
  }

  // در برخی کانفیگ‌ها، پارامتر success=1 ارسال می‌شود؛ در صورت وجود، به عنوان موفق در نظر بگیر
  if(!$ok && isset($_REQUEST['success']) && intval($_REQUEST['success']) === 1 && !empty($sid)){
    $ok = true;
    if (empty($ref)) { $ref = (string)($_REQUEST['trackId'] ?? $sid); }
  }

  // اعلام نتیجهٔ موفق به بک‌اند اپ (Edge Function)
  if($ok && $sid){
    $payload = ['session_id'=>$sid, 'gateway'=>'zibal', 'gateway_ref'=>$ref];
    // امضا باید دقیقاً روی همان بدنه‌ای باشد که ارسال می‌شود
    $payload_json = wp_json_encode($payload);
    $sig = hash_hmac('sha256', $payload_json, GYM_TOPUP_SECRET);
    
    // فراخوانی Edge Function
    // فراخوانی ادج فانکشن اصلی (هم‌نام با کدی که در ریپو داریم)
    $edge_function_url = GYM_TOPUP_APP_API . '/functions/v1/wallet-topup-confirm';
    $r = wp_remote_post($edge_function_url, [
      'timeout'=>15, 
      'headers'=>[
        'Content-Type'=>'application/json',
        'Authorization'=>'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9henRvZW5ub3Z0Y2ZjeHZuc3dhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDY4NzYzNzEsImV4cCI6MjA2MjQ1MjM3MX0.UywfAvKyqUjByLQHRnRqJ85Bal6NdvAOwQQJXVaQfGk',
        'x-signature'=>$sig  // ← تغییر: x-signature به جای X-Signature
      ],
      'body'=>$payload_json
    ]);
    
    $edge_code = is_wp_error($r) ? 0 : wp_remote_retrieve_response_code($r);
    $edge_body = is_wp_error($r) ? $r->get_error_message() : wp_remote_retrieve_body($r);
    if($is_debug){
      echo "<div style='margin:12px 0;padding:12px;border:1px dashed #999;border-radius:8px'><b>EDGE CALL</b><br>";
      echo "<div><b>url:</b> ".gymai_h($edge_function_url)."</div>";
      echo "<div><b>code:</b> ".gymai_h((string)$edge_code)."</div>";
      echo "<div><b>resp:</b><pre style='white-space:pre-wrap'>".gymai_h((string)$edge_body)."</pre></div>";
      echo "</div>";
    }

    if(!is_wp_error($r) && $edge_code===200){
      $deeplink = GYM_TOPUP_DEEPLINK_OK;
    }
  }

  echo "<!doctype html><html><head><meta charset='utf-8'><meta name='viewport' content='width=device-width, initial-scale=1'>
        <title>نتیجه پرداخت</title></head><body style='font-family:sans-serif;max-width:640px;margin:40px auto'>";
  echo $ok ? "<h2>پرداخت موفق</h2>" : "<h2>پرداخت ناموفق</h2>";
  if($ref){ echo "<p>کد پیگیری: <b>".gymai_h($ref)."</b></p>"; }
  if($is_debug){
    echo "<div style='margin:12px 0;padding:12px;border:1px dashed #999;border-radius:8px'><b>DEBUG</b><br>";
    if($verify_body){ echo "<div><b>verify:</b><pre style='white-space:pre-wrap'>".gymai_h($verify_body)."</pre></div>"; }
    if($inquiry_body){ echo "<div><b>inquiry:</b><pre style='white-space:pre-wrap'>".gymai_h($inquiry_body)."</pre></div>"; }
    echo "</div>";
  }
  if ($ok) {
    // هدایت خودکار به اپ در پرداخت موفق (با دیپ‌لینک)
    $safe_deeplink = gymai_h($deeplink);
    echo "<script>(function(){var u='".$safe_deeplink."';try{window.location.replace(u);}catch(e){window.location.href=u;}setTimeout(function(){window.location.href=u;},700);})();</script>";
    echo "<p style='margin-top:12px'>در حال بازگشت خودکار به اپ... اگر منتقل نشدید، روی دکمه زیر بزنید.</p>";
  }
  echo "<p><a href='".gymai_h($deeplink)."' style='display:inline-block;padding:12px 18px;border:1px solid #ccc;border-radius:8px;text-decoration:none'>بازگشت به اپ</a></p>";
  echo "</body></html>";
}
