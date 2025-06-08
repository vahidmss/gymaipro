<?php
/**
 * GymAI API Endpoints
 * 
 * This file contains WordPress API endpoints for synchronizing with GymAI Flutter app
 */

// Test endpoint to verify the plugin is working
add_action('rest_api_init', function () {
    register_rest_route('gymai/v1', '/test/', array(
        'methods' => 'GET',
        'callback' => 'gymai_test_endpoint',
        'permission_callback' => '__return_true',
    ));
});

function gymai_test_endpoint() {
    return array(
        'status' => 'success',
        'message' => 'GymAI API is working correctly',
        'time' => current_time('mysql'),
        'version' => '1.0'
    );
}

// API Registration Endpoint
add_action('rest_api_init', function () {
    register_rest_route('gymai/v1', '/register/', array(
        'methods' => 'POST',
        'callback' => 'gymai_register_user',
        'permission_callback' => '__return_true',
    ));
});

function gymai_register_user($request) {
    global $wpdb;
    
    $username = sanitize_user($request->get_param('username'));
    $mobile = sanitize_text_field($request->get_param('mobile'));

    if (empty($username) || empty($mobile)) {
        return new WP_Error('missing_data', 'Username or mobile is missing', array('status' => 400));
    }
    
    // ذخیره شماره موبایل با فرمت ۹ ابتدایی - بدون تغییر
    // در اپلیکیشن شماره به فرمت ۹ ابتدایی آماده شده، اینجا دیگر تغییر نمی‌دهیم
    
    // ساخت ایمیل فیک با موبایل
    $email = $mobile . '@example.com';

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

    // بررسی وجود کاربر با شماره موبایل
    if (!empty($user_id_from_meta) || !empty($user_id_from_smart)) {
        return new WP_Error(
            'user_exists', 
            'User with this mobile number already exists', 
            array(
                'status' => 409,
                'user_id' => !empty($user_id_from_meta) ? $user_id_from_meta : $user_id_from_smart,
                'found_in' => !empty($user_id_from_meta) ? 'user_meta' : 'smart_login'
            )
        );
    }

    // بررسی یکتا بودن یوزرنیم
    if (username_exists($username)) {
        return new WP_Error(
            'username_exists', 
            'Username already exists', 
            array('status' => 409)
        );
    }

    // ساخت یوزر
    $user_id = wp_create_user($username, wp_generate_password(), $email);

    if (is_wp_error($user_id)) {
        return $user_id;
    }

    // ذخیره شماره موبایل در متا
    update_user_meta($user_id, 'mobile_from_meta', $mobile);
    
    // اضافه کردن متای جدید برای حفظ سازگاری
    update_user_meta($user_id, 'user_mobile', $mobile);

    // ذخیره در جدول smart_login_users اگر وجود داشته باشد
    if ($table_exists) {
        // بررسی وجود رکورد
        $existing_record = $wpdb->get_var(
            $wpdb->prepare("SELECT user_id FROM {$smart_login_table} WHERE user_id = %d", $user_id)
        );
        
        if ($existing_record) {
            // اگر رکورد وجود دارد، آن را به‌روزرسانی کنیم
            $wpdb->update(
                $smart_login_table,
                array(
                    'mobile' => $mobile,
                    'verified' => 1,
                    'updated_at' => current_time('mysql')
                ),
                array('user_id' => $user_id)
            );
        } else {
            // ایجاد رکورد جدید
            $result = $wpdb->insert(
                $smart_login_table,
                array(
                    'user_id' => $user_id,
                    'mobile' => $mobile,
                    'verified' => 1,
                    'created_at' => current_time('mysql')
                )
            );
            
            // بررسی خطای درج
            if ($result === false) {
                error_log("Error inserting into {$smart_login_table}: " . $wpdb->last_error);
            }
        }
    }

    return array(
        'success' => true,
        'user_id' => $user_id,
        'username' => $username,
        'email' => $email,
        'mobile' => $mobile,
    );
}

// اندپوینت بررسی وجود کاربر با پشتیبانی از هر دو جدول
add_action('rest_api_init', function () {
    register_rest_route('gymai/v1', '/check-user/', array(
        'methods' => 'GET',
        'callback' => 'gymai_check_user_exists',
        'permission_callback' => '__return_true',
    ));
});

// بررسی وجود کاربر با شماره موبایل
function gymai_check_user_exists($request) {
    $mobile = sanitize_text_field($request->get_param('mobile'));

    if (empty($mobile)) {
        return new WP_Error('missing_data', 'Mobile number is missing', array('status' => 400));
    }
    
    // حذف صفر ابتدایی از شماره موبایل اگر وجود داشته باشد
    if (substr($mobile, 0, 1) === '0') {
        $mobile = substr($mobile, 1);
    }

    global $wpdb;
    
    // بررسی در جدول متا
    $query = $wpdb->prepare(
        "SELECT user_id FROM {$wpdb->usermeta} WHERE meta_key = 'mobile_from_meta' AND meta_value = %s LIMIT 1",
        $mobile
    );
    $user_id_from_meta = $wpdb->get_var($query);
    
    // بررسی در جدول smart_login_users
    $smart_login_table = $wpdb->prefix . 'gymaiprokamangir_smart_login_users';
    $table_exists = $wpdb->get_var("SHOW TABLES LIKE '{$smart_login_table}'") == $smart_login_table;
    
    $user_id_from_smart = null;
    if ($table_exists) {
        $query_smart = $wpdb->prepare(
            "SELECT user_id FROM {$smart_login_table} WHERE mobile = %s LIMIT 1",
            $mobile
        );
        $user_id_from_smart = $wpdb->get_var($query_smart);
    }
    
    $user_id = $user_id_from_meta ?: $user_id_from_smart;
    
    // دریافت اطلاعات کاربر اگر وجود داشت
    $user_data = null;
    $smart_login_data = null;
    
    if ($user_id) {
        $user = get_userdata($user_id);
        if ($user) {
            $user_data = array(
                'ID' => $user->ID,
                'user_login' => $user->user_login,
                'display_name' => $user->display_name,
                'user_email' => $user->user_email,
            );
            
            // دریافت فیلدهای متا
            $first_name = get_user_meta($user_id, 'first_name', true);
            $last_name = get_user_meta($user_id, 'last_name', true);
            
            if (!empty($first_name)) {
                $user_data['first_name'] = $first_name;
            }
            
            if (!empty($last_name)) {
                $user_data['last_name'] = $last_name;
            }
        }
        
        // دریافت اطلاعات از جدول smart_login اگر وجود داشت
        if ($table_exists && $user_id_from_smart) {
            $smart_login_query = $wpdb->prepare(
                "SELECT * FROM {$smart_login_table} WHERE user_id = %d LIMIT 1",
                $user_id_from_smart
            );
            $smart_login_data = $wpdb->get_row($smart_login_query, ARRAY_A);
        }
    }
    
    return array(
        'exists' => !empty($user_id),
        'user_id' => $user_id ? (int)$user_id : null,
        'found_in' => !empty($user_id_from_meta) ? 'user_meta' : (!empty($user_id_from_smart) ? 'smart_login' : null),
        'user_data' => $user_data,
        'smart_login_data' => $smart_login_data
    );
}

// اندپوینت به‌روزرسانی پروفایل کاربر
add_action('rest_api_init', function () {
    register_rest_route('gymai/v1', '/update-profile/', array(
        'methods' => 'POST',
        'callback' => 'gymai_update_user_profile',
        'permission_callback' => '__return_true',
    ));
});

// به‌روزرسانی پروفایل کاربر
function gymai_update_user_profile($request) {
    $mobile = sanitize_text_field($request->get_param('mobile'));
    $profile_data = $request->get_param('profile_data');
    
    if (empty($mobile)) {
        return new WP_Error('missing_mobile', 'شماره موبایل وارد نشده است', array('status' => 400));
    }
    
    if (empty($profile_data) || !is_array($profile_data)) {
        return new WP_Error('invalid_data', 'داده‌های پروفایل معتبر نیست', array('status' => 400));
    }
    
    global $wpdb;
    
    // جستجوی کاربر با شماره موبایل
    $meta_query = $wpdb->prepare(
        "SELECT user_id FROM {$wpdb->usermeta} WHERE meta_key = 'mobile_from_meta' AND meta_value = %s LIMIT 1",
        $mobile
    );
    $user_id = $wpdb->get_var($meta_query);
    
    // اگر در متا پیدا نشد، در جدول smart_login جستجو کنیم (اگر وجود داشته باشد)
    if (empty($user_id)) {
        $table_exists = $wpdb->get_var("SHOW TABLES LIKE '{$wpdb->prefix}smart_login'") == "{$wpdb->prefix}smart_login";
        
        if ($table_exists) {
            $smart_login_query = $wpdb->prepare(
                "SELECT user_id FROM {$wpdb->prefix}smart_login WHERE mobile = %s LIMIT 1",
                $mobile
            );
            $user_id = $wpdb->get_var($smart_login_query);
        }
    }
    
    if (empty($user_id)) {
        return new WP_Error('user_not_found', 'کاربری با این شماره موبایل یافت نشد', array('status' => 404));
    }
    
    $updated_fields = array();
    
    // به‌روزرسانی متادیتاهای کاربر
    
    // نام و نام خانوادگی
    if (isset($profile_data['first_name'])) {
        update_user_meta($user_id, 'first_name', sanitize_text_field($profile_data['first_name']));
        $updated_fields[] = 'first_name';
    }
    
    if (isset($profile_data['last_name'])) {
        update_user_meta($user_id, 'last_name', sanitize_text_field($profile_data['last_name']));
        $updated_fields[] = 'last_name';
    }
    
    // به‌روزرسانی نام نمایشی بر اساس نام و نام خانوادگی اگر هر دو موجود باشند
    if (isset($profile_data['first_name']) && isset($profile_data['last_name'])) {
        $display_name = $profile_data['first_name'] . ' ' . $profile_data['last_name'];
        wp_update_user(array(
            'ID' => $user_id,
            'display_name' => $display_name
        ));
        $updated_fields[] = 'display_name';
    }
    
    // عکس پروفایل - از دو فیلد پشتیبانی می‌کنیم
    if (isset($profile_data['profile_picture'])) {
        update_user_meta($user_id, 'profile_picture', esc_url_raw($profile_data['profile_picture']));
        $updated_fields[] = 'profile_picture';
    } elseif (isset($profile_data['avatar_url'])) {
        update_user_meta($user_id, 'profile_picture', esc_url_raw($profile_data['avatar_url']));
        $updated_fields[] = 'profile_picture';
    }
    
    // سن
    if (isset($profile_data['age'])) {
        update_user_meta($user_id, 'age', intval($profile_data['age']));
        $updated_fields[] = 'age';
    }
    
    // وزن
    if (isset($profile_data['weight'])) {
        update_user_meta($user_id, 'weight', floatval($profile_data['weight']));
        $updated_fields[] = 'weight';
    }
    
    // قد
    if (isset($profile_data['height'])) {
        update_user_meta($user_id, 'height', floatval($profile_data['height']));
        $updated_fields[] = 'height';
    }
    
    // تاریخ تولد
    if (isset($profile_data['birth_date'])) {
        update_user_meta($user_id, 'birth_date', sanitize_text_field($profile_data['birth_date']));
        $updated_fields[] = 'birth_date';
    }
    
    // جنسیت
    if (isset($profile_data['gender'])) {
        update_user_meta($user_id, 'gender', sanitize_text_field($profile_data['gender']));
        $updated_fields[] = 'gender';
    }
    
    // سایر فیلدهای اختیاری
    
    // بیو
    if (isset($profile_data['bio'])) {
        update_user_meta($user_id, 'bio', sanitize_textarea_field($profile_data['bio']));
        $updated_fields[] = 'bio';
    }
    
    // سطح تجربه
    if (isset($profile_data['experience_level'])) {
        update_user_meta($user_id, 'experience_level', sanitize_text_field($profile_data['experience_level']));
        $updated_fields[] = 'experience_level';
    }
    
    // دور کمر
    if (isset($profile_data['waist_circumference'])) {
        update_user_meta($user_id, 'waist_circumference', floatval($profile_data['waist_circumference']));
        $updated_fields[] = 'waist_circumference';
    }
    
    // بازخورد به اپلیکیشن
    return array(
        'success' => true,
        'user_id' => $user_id,
        'updated_fields' => $updated_fields,
        'message' => 'پروفایل با موفقیت به‌روزرسانی شد'
    );
}
?> 