<?php
/**
 * Plugin Name: GymAI Pro Authentication Integration
 * Description: Integrates WordPress authentication with GymAI Pro mobile app
 * Version: 1.0.0
 * Author: Your Name
 * 
 * این پلاگین کاربران را به صورت خودکار با استفاده از توکن Supabase در سایت وردپرس لاگین می‌کند
 */

// اندپوینت دریافت توکن از اپلیکیشن
add_action('rest_api_init', function () {
    register_rest_route('gymai/v1', '/store-token/', array(
        'methods' => 'POST',
        'callback' => 'gymai_store_auth_token',
        'permission_callback' => '__return_true',
    ));
});

/**
 * ذخیره توکن احراز هویت Supabase در متاهای کاربر
 */
function gymai_store_auth_token($request) {
    // دریافت پارامترهای ارسالی
    $mobile = sanitize_text_field($request->get_param('mobile'));
    $access_token = sanitize_text_field($request->get_param('access_token'));
    $refresh_token = sanitize_text_field($request->get_param('refresh_token'));
    $expires_at = sanitize_text_field($request->get_param('expires_at'));
    
    if (empty($mobile) || empty($access_token)) {
        return new WP_Error('missing_data', 'شماره موبایل یا توکن ارسال نشده است', array('status' => 400));
    }
    
    // نرمال‌سازی شماره موبایل
    if (substr($mobile, 0, 1) === '0') {
        $mobile = substr($mobile, 1);
    }
    
    // پیدا کردن کاربر با شماره موبایل
    global $wpdb;
    
    // بررسی در جدول متا
    $meta_query = $wpdb->prepare(
        "SELECT user_id FROM {$wpdb->usermeta} WHERE meta_key = 'mobile_from_meta' AND meta_value = %s LIMIT 1",
        $mobile
    );
    $user_id_from_meta = $wpdb->get_var($meta_query);
    
    // بررسی در جدول smart_login_users
    $smart_login_table = $wpdb->prefix . 'gymaiprokamangir_smart_login_users';
    $table_exists = $wpdb->get_var("SHOW TABLES LIKE '{$smart_login_table}'") == $smart_login_table;
    
    $user_id_from_smart = null;
    if ($table_exists) {
        $smart_query = $wpdb->prepare(
            "SELECT user_id FROM {$smart_login_table} WHERE mobile = %s LIMIT 1",
            $mobile
        );
        $user_id_from_smart = $wpdb->get_var($smart_query);
    }
    
    $user_id = $user_id_from_meta ?: $user_id_from_smart;
    
    if (!$user_id) {
        return new WP_Error('user_not_found', 'کاربری با این شماره موبایل یافت نشد', array('status' => 404));
    }
    
    // ذخیره توکن‌ها در متاهای کاربر
    update_user_meta($user_id, 'gymai_supabase_token', $access_token);
    update_user_meta($user_id, 'gymai_supabase_refresh_token', $refresh_token);
    update_user_meta($user_id, 'gymai_supabase_token_expires', $expires_at);
    update_user_meta($user_id, 'gymai_supabase_token_updated', current_time('mysql'));
    
    return array(
        'success' => true,
        'message' => 'توکن با موفقیت ذخیره شد',
        'user_id' => $user_id
    );
}

/**
 * بررسی پارامتر direct_login در URL
 * اگر این پارامتر وجود داشته باشد، کاربر را با استفاده از کوکی لاگین می‌کند
 */
add_action('template_redirect', 'gymai_check_direct_login', 5);

function gymai_check_direct_login() {
    // اگر کاربر قبلاً لاگین شده، کاری نکن
    if (is_user_logged_in()) {
        return;
    }
    
    // بررسی پارامتر direct_login
    if (isset($_GET['direct_login']) && $_GET['direct_login'] === 'true') {
        // بررسی وجود کوکی توکن
        $token = isset($_COOKIE['gymai_auth_token']) ? sanitize_text_field($_COOKIE['gymai_auth_token']) : '';
        
        if (empty($token)) {
            return;
        }
        
        // جستجوی کاربر با این توکن
        global $wpdb;
        $meta_query = $wpdb->prepare(
            "SELECT user_id FROM {$wpdb->usermeta} WHERE meta_key = 'gymai_supabase_token' AND meta_value = %s LIMIT 1",
            $token
        );
        $user_id = $wpdb->get_var($meta_query);
        
        if (!$user_id) {
            return;
        }
        
        // بررسی تاریخ انقضای توکن
        $expires_at = get_user_meta($user_id, 'gymai_supabase_token_expires', true);
        
        if (!empty($expires_at)) {
            $now = new DateTime();
            $expiry = new DateTime($expires_at);
            
            if ($now > $expiry) {
                // توکن منقضی شده است
                return;
            }
        }
        
        // لاگین کردن کاربر
        wp_set_current_user($user_id);
        wp_set_auth_cookie($user_id, true);
        
        // ریدایرکت به صفحه اصلی بدون پارامتر
        wp_redirect(home_url());
        exit;
    }
}

/**
 * بررسی و لاگین خودکار کاربر با توکن کوکی
 */
add_action('wp_loaded', 'gymai_auto_login_from_cookie', 5);

function gymai_auto_login_from_cookie() {
    // اگر کاربر قبلاً لاگین شده، کاری نکن
    if (is_user_logged_in()) {
        return;
    }
    
    // بررسی وجود کوکی توکن
    $token = isset($_COOKIE['gymai_auth_token']) ? sanitize_text_field($_COOKIE['gymai_auth_token']) : '';
    
    if (empty($token)) {
        return;
    }
    
    // جستجوی کاربر با این توکن
    global $wpdb;
    $meta_query = $wpdb->prepare(
        "SELECT user_id FROM {$wpdb->usermeta} WHERE meta_key = 'gymai_supabase_token' AND meta_value = %s LIMIT 1",
        $token
    );
    $user_id = $wpdb->get_var($meta_query);
    
    if (!$user_id) {
        return;
    }
    
    // بررسی تاریخ انقضای توکن
    $expires_at = get_user_meta($user_id, 'gymai_supabase_token_expires', true);
    
    if (!empty($expires_at)) {
        $now = new DateTime();
        $expiry = new DateTime($expires_at);
        
        if ($now > $expiry) {
            // توکن منقضی شده است
            return;
        }
    }
    
    // لاگین کردن کاربر
    wp_set_current_user($user_id);
    wp_set_auth_cookie($user_id, true);
}

/**
 * اسکریپت JavaScript برای تنظیم کوکی از localStorage
 * این اسکریپت localStorage مرورگر را بررسی می‌کند و اگر توکن وجود داشت
 * آن را در کوکی ذخیره می‌کند تا PHP بتواند آن را بخواند
 */
add_action('wp_footer', 'gymai_token_sync_script');

function gymai_token_sync_script() {
    ?>
    <script>
    document.addEventListener('DOMContentLoaded', function() {
        try {
            // بررسی وجود توکن در localStorage
            const supabaseToken = localStorage.getItem('supabase.auth.token');
            
            if (supabaseToken) {
                // تبدیل JSON به آبجکت
                const tokenData = JSON.parse(supabaseToken);
                
                if (tokenData && tokenData.currentSession && tokenData.currentSession.access_token) {
                    // تنظیم کوکی با توکن
                    document.cookie = "gymai_auth_token=" + tokenData.currentSession.access_token + "; path=/; max-age=2592000"; // 30 روز
                    
                    // در صورتی که کاربر لاگین نشده باشد، صفحه را ریفرش کن
                    if (!document.body.classList.contains('logged-in')) {
                        location.reload();
                    }
                }
            }
        } catch (error) {
            console.error('خطا در بررسی توکن:', error);
        }
    });
    </script>
    <?php
}

/**
 * افزودن اندپوینت API برای ست کردن کوکی از اپلیکیشن
 */
add_action('rest_api_init', function () {
    register_rest_route('gymai/v1', '/set-cookie/', array(
        'methods' => 'POST',
        'callback' => 'gymai_set_auth_cookie',
        'permission_callback' => '__return_true',
    ));
});

function gymai_set_auth_cookie($request) {
    $token = sanitize_text_field($request->get_param('token'));
    $mobile = sanitize_text_field($request->get_param('mobile'));
    
    if (empty($token) || empty($mobile)) {
        return new WP_Error('missing_data', 'توکن یا شماره موبایل ارسال نشده است', array('status' => 400));
    }
    
    // نرمال‌سازی شماره موبایل
    if (substr($mobile, 0, 1) === '0') {
        $mobile = substr($mobile, 1);
    }
    
    // پیدا کردن کاربر با شماره موبایل
    global $wpdb;
    
    // بررسی در جدول متا
    $meta_query = $wpdb->prepare(
        "SELECT user_id FROM {$wpdb->usermeta} WHERE meta_key = 'mobile_from_meta' AND meta_value = %s LIMIT 1",
        $mobile
    );
    $user_id_from_meta = $wpdb->get_var($meta_query);
    
    // بررسی در جدول smart_login_users
    $smart_login_table = $wpdb->prefix . 'gymaiprokamangir_smart_login_users';
    $table_exists = $wpdb->get_var("SHOW TABLES LIKE '{$smart_login_table}'") == $smart_login_table;
    
    $user_id_from_smart = null;
    if ($table_exists) {
        $smart_query = $wpdb->prepare(
            "SELECT user_id FROM {$smart_login_table} WHERE mobile = %s LIMIT 1",
            $mobile
        );
        $user_id_from_smart = $wpdb->get_var($smart_query);
    }
    
    $user_id = $user_id_from_meta ?: $user_id_from_smart;
    
    if (!$user_id) {
        return new WP_Error('user_not_found', 'کاربری با این شماره موبایل یافت نشد', array('status' => 404));
    }
    
    // ذخیره توکن در متای کاربر
    update_user_meta($user_id, 'gymai_supabase_token', $token);
    
    // تنظیم کوکی
    $domain = parse_url(home_url(), PHP_URL_HOST);
    setcookie('gymai_auth_token', $token, time() + 2592000, '/', $domain, is_ssl(), true);
    
    return array(
        'success' => true,
        'message' => 'توکن با موفقیت تنظیم شد',
        'user_id' => $user_id
    );
} 