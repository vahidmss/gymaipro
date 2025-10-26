/**
 * اضافه کردن اندپوینت بررسی وجود کاربر در وردپرس
 * این کد را به فایل functions.php تم خود یا یک افزونه سفارشی اضافه کنید
 */

// اندپوینت بررسی وجود کاربر
add_action('rest_api_init', function () {
    register_rest_route('gymai/v1', '/check-user/', array(
        'methods' => 'GET',
        'callback' => 'gymai_check_user_exists',
        'permission_callback' => '__return_true',
    ));
});

/**
 * بررسی وجود کاربر با شماره موبایل
 */
function gymai_check_user_exists($request) {
    $mobile = sanitize_text_field($request->get_param('mobile'));

    if (empty($mobile)) {
        return new WP_Error('missing_data', 'Mobile number is missing', array('status' => 400));
    }
    
    // حذف صفر ابتدایی از شماره موبایل اگر وجود داشته باشد
    if (substr($mobile, 0, 1) === '0') {
        $mobile_without_zero = substr($mobile, 1);
    } else {
        $mobile_without_zero = $mobile;
    }

    global $wpdb;
    
    // بررسی در جدول متا
    $query = $wpdb->prepare(
        "SELECT user_id FROM {$wpdb->usermeta} WHERE meta_key = 'mobile_from_meta' AND (meta_value = %s OR meta_value = %s) LIMIT 1",
        $mobile, $mobile_without_zero
    );
    $user_id_from_meta = $wpdb->get_var($query);
    
    // بررسی در جدول smart_login_users
    $query_smart = $wpdb->prepare(
        "SELECT user_id FROM {$wpdb->prefix}gymaiprokamangir_smart_login_users WHERE mobile = %s OR mobile = %s LIMIT 1",
        $mobile, $mobile_without_zero
    );
    $user_id_from_smart = $wpdb->get_var($query_smart);
    
    $user_id = $user_id_from_meta ?: $user_id_from_smart;
    
    return array(
        'exists' => !empty($user_id),
        'user_id' => $user_id ? (int)$user_id : null,
        'found_in' => !empty($user_id_from_meta) ? 'user_meta' : (!empty($user_id_from_smart) ? 'smart_login' : null)
    );
}

/**
 * برای اضافه کردن اندپوینت‌های دیگر به API وردپرس:
 * 
 * 1. اضافه کردن امکان همگام‌سازی کاربر از سوپابیس به وردپرس
 * 2. اضافه کردن امکان بروزرسانی اطلاعات کاربر در هر دو سیستم
 * 3. اضافه کردن امکان ورود با OTP در وردپرس
 * 
 * می‌توانید با الگوهای مشابه اندپوینت‌های بالا، این قابلیت‌ها را پیاده‌سازی کنید.
 */ 