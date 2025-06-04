<?php
/**
 * Enhanced Mobile Number Integration for WordPress
 * 
 * این فایل برای پشتیبانی از استخراج شماره موبایل از جداول افزونه دروازه (Smart Login) 
 * و متاهای کاربر در وردپرس طراحی شده است.
 */

// بررسی و نمایش متا‌های کاربر و اطلاعات جدول smart_login_users (برای دیباگ)
add_shortcode('show_user_mobile_info', function() {
    if (is_user_logged_in()) {
        $user_id = get_current_user_id();
        $meta = get_user_meta($user_id);
        
        // بررسی جدول های دروازه
        global $wpdb;
        $tables_to_check = [
            $wpdb->prefix . 'kamangir_smart_login_users',
            $wpdb->prefix . 'gymaiprokamangir_smart_login_users'
        ];
        
        $output = '<h3>اطلاعات متای کاربر:</h3>';
        $output .= '<pre>' . print_r($meta, true) . '</pre>';
        
        foreach ($tables_to_check as $table) {
            $table_exists = $wpdb->get_var("SHOW TABLES LIKE '{$table}'") == $table;
            
            if ($table_exists) {
                $mobile_data = $wpdb->get_row(
                    $wpdb->prepare("SELECT * FROM {$table} WHERE user_id = %d", $user_id),
                    ARRAY_A
                );
                
                $output .= '<h3>اطلاعات موبایل از جدول ' . $table . ':</h3>';
                $output .= '<pre>' . ($mobile_data ? print_r($mobile_data, true) : 'پیدا نشد') . '</pre>';
            }
        }
        
        $output .= '<h3>شماره موبایل استخراج شده:</h3>';
        $output .= '<pre>' . gymai_get_user_mobile($user_id) . '</pre>';
        
        return $output;
    } else {
        return 'برای مشاهده اطلاعات باید وارد حساب کاربری خود شوید.';
    }
});

/**
 * دریافت شماره موبایل کاربر با اولویت به جدول افزونه دروازه
 * 
 * @param int|null $user_id شناسه کاربر (اختیاری، در صورت عدم ارسال کاربر فعلی در نظر گرفته می‌شود)
 * @return string شماره موبایل کاربر
 */
function gymai_get_user_mobile($user_id = null) {
    if (!$user_id) {
        if (!is_user_logged_in()) {
            return '';
        }
        $user_id = get_current_user_id();
    }
    
    global $wpdb;
    
    // ابتدا بررسی در جدول افزونه دروازه
    $kamangir_table = $wpdb->prefix . 'kamangir_smart_login_users';
    $table_exists = $wpdb->get_var("SHOW TABLES LIKE '{$kamangir_table}'") == $kamangir_table;
    
    if ($table_exists) {
        $mobile = $wpdb->get_var(
            $wpdb->prepare("SELECT mobile FROM {$kamangir_table} WHERE user_id = %d", $user_id)
        );
        
        if (!empty($mobile)) {
            // اضافه کردن صفر در ابتدای شماره اگر نداشته باشد
            return (substr($mobile, 0, 1) === '0') ? $mobile : '0' . $mobile;
        }
    }
    
    // اگر در جدول دروازه نبود، از متاهای مختلف بررسی شود
    $meta_keys = ['smartlogin_mobile', 'mobile_from_meta', 'user_mobile', 'billing_phone'];
    
    foreach ($meta_keys as $meta_key) {
        $mobile = get_user_meta($user_id, $meta_key, true);
        if (!empty($mobile)) {
            // اضافه کردن صفر در ابتدای شماره اگر نداشته باشد
            return (substr($mobile, 0, 1) === '0') ? $mobile : '0' . $mobile;
        }
    }
    
    return '';
}

// مقداردهی فیلد موبایل برای فرم‌ها
add_filter('gform_field_value_mobile_from_meta', function() {
    if (is_user_logged_in()) {
        return gymai_get_user_mobile();
    }
    return '';
});

// مقداردهی فیلد موبایل از دروازه
add_filter('gform_field_value_smartlogin_mobile', function() {
    if (is_user_logged_in()) {
        return gymai_get_user_mobile();
    }
    return '';
});

/**
 * اضافه کردن hook به‌روزرسانی اطلاعات کاربر در Gravity Forms
 * این هوک وظیفه به‌روزرسانی اطلاعات موبایل در متا را دارد
 * توجه: این کد در متاهای کاربر ذخیره می‌کند و به جدول دروازه دست نمی‌زند
 * زیرا افزونه دروازه خودش مسئول ذخیره در جدول خودش است
 */
add_action('gform_after_submission', function($entry, $form) {
    // فقط برای کاربران لاگین شده
    if (!is_user_logged_in()) {
        return;
    }
    
    $user_id = get_current_user_id();
    
    // بررسی فیلدهای فرم
    foreach ($form['fields'] as $field) {
        // بررسی اگر فیلد شماره موبایل بود
        if (isset($field->inputName) && ($field->inputName === 'mobile_from_meta' || $field->inputName === 'smartlogin_mobile')) {
            $mobile = rgar($entry, $field->id);
            
            if (!empty($mobile)) {
                // اطمینان از فرمت صحیح (با صفر ابتدایی)
                if (substr($mobile, 0, 1) !== '0') {
                    $mobile = '0' . $mobile;
                }
                
                // ذخیره در متاهای کاربر برای دسترسی آسان‌تر
                update_user_meta($user_id, 'mobile_from_meta', $mobile);
                update_user_meta($user_id, 'user_mobile', $mobile);
                // همچنین ذخیره بدون صفر ابتدایی برای هماهنگی با افزونه دروازه
                update_user_meta($user_id, 'smartlogin_mobile', ltrim($mobile, '0'));
            }
        }
    }
}, 10, 2);

// برای استفاده در تم وردپرس، این فایل را در functions.php کپی کنید یا آن را include کنید
?> 