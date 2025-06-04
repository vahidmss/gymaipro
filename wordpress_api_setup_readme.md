# راهنمای نصب و راه‌اندازی API وردپرس برای همگام‌سازی با اپلیکیشن

این راهنما نحوه نصب و پیکربندی API وردپرس برای همگام‌سازی با اپلیکیشن فلاتر را توضیح می‌دهد.

## گام‌ها

### 1. افزودن کدهای API به وردپرس

دو روش برای اضافه کردن کدهای API وجود دارد:

#### روش اول: استفاده از فایل functions.php تم فعال

1. وارد پنل مدیریت وردپرس شوید
2. به بخش "ظاهر" > "ویرایشگر تم" بروید
3. از منوی سمت راست، فایل `functions.php` را انتخاب کنید
4. کدهای زیر را در انتهای فایل اضافه کنید:

```php
// API Registration Endpoint with improved error handling and dual table checks
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
    
    // اطمینان از اینکه شماره موبایل بدون صفر در ابتدا باشد
    if (substr($mobile, 0, 1) === '0') {
        $mobile = substr($mobile, 1);
    }

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

    // ذخیره در جدول smart_login_users اگر وجود داشته باشد
    if ($table_exists) {
        $wpdb->insert(
            $smart_login_table,
            array(
                'user_id' => $user_id,
                'mobile' => $mobile,
                'verified' => 1,
                'created_at' => current_time('mysql')
            )
        );
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

function gymai_check_user_exists($request) {
    global $wpdb;
    
    $mobile = sanitize_text_field($request->get_param('mobile'));

    if (empty($mobile)) {
        return new WP_Error('missing_data', 'Mobile number is missing', array('status' => 400));
    }
    
    // اطمینان از اینکه شماره موبایل بدون صفر در ابتدا باشد
    if (substr($mobile, 0, 1) === '0') {
        $mobile = substr($mobile, 1);
    }

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
    $smart_login_data = null;
    
    if ($table_exists) {
        $smart_query = $wpdb->prepare(
            "SELECT user_id, mobile, verified FROM {$smart_login_table} WHERE mobile = %s LIMIT 1",
            $mobile
        );
        $smart_login_data = $wpdb->get_row($smart_query);
        
        if ($smart_login_data) {
            $user_id_from_smart = $smart_login_data->user_id;
        }
    }
    
    // تصمیم گیری درباره اینکه کدام شناسه کاربر را برگردانیم
    $user_id = $user_id_from_meta ?: $user_id_from_smart;
    
    // اطلاعات اضافی کاربر را دریافت می‌کنیم اگر وجود داشته باشد
    $user_data = null;
    if ($user_id) {
        $user = get_userdata($user_id);
        if ($user) {
            $user_data = array(
                'ID' => $user->ID,
                'user_login' => $user->user_login,
                'display_name' => $user->display_name
            );
        }
    }
    
    return array(
        'exists' => !empty($user_id),
        'user_id' => $user_id ? (int)$user_id : null,
        'found_in' => !empty($user_id_from_meta) ? 'user_meta' : (!empty($user_id_from_smart) ? 'smart_login' : null),
        'user_data' => $user_data,
        'smart_login_data' => $smart_login_data ? array(
            'mobile' => $smart_login_data->mobile,
            'verified' => (bool)$smart_login_data->verified
        ) : null
    );
}

### 2. پیکربندی آدرس API در اپلیکیشن

در فایل `lib/services/wordpress_service.dart` آدرس API وردپرس را به آدرس سایت خود تغییر دهید:

```dart
final String baseUrl = 'https://yourgymai.com/wp-json/gymai/v1';
```

آدرس فوق را با آدرس واقعی سایت وردپرس خود جایگزین کنید.

### 3. تست API

برای اطمینان از اینکه API به درستی کار می‌کند، می‌توانید از ابزارهایی مانند Postman استفاده کنید:

#### تست ثبت نام:
```
POST https://yourgymai.com/wp-json/gymai/v1/register
Content-Type: application/json

{
  "username": "testuser",
  "mobile": "09123456789"
}
```

#### تست بررسی وجود کاربر:
```
GET https://yourgymai.com/wp-json/gymai/v1/check-user?mobile=09123456789
```

## نکات امنیتی

1. در یک محیط تولید واقعی، باید مکانیزم‌های احراز هویت و امنیتی بیشتری اضافه کنید
2. استفاده از HTTPS برای انتقال داده‌ها ضروری است
3. اضافه کردن محدودیت درخواست (rate limiting) برای جلوگیری از حملات DDOS توصیه می‌شود
4. بررسی کنید که API فقط از دامنه‌های مجاز قابل دسترسی باشد (CORS)

## گسترش قابلیت‌ها

برای تکمیل همگام‌سازی، می‌توانید اندپوینت‌های زیر را نیز اضافه کنید:

1. همگام‌سازی پروفایل کاربر (بروزرسانی اطلاعات پروفایل)
2. همگام‌سازی برنامه‌های تمرینی
3. امکان ورود با OTP در وردپرس

## عیب‌یابی

اگر با مشکلی مواجه شدید:

1. اطمینان حاصل کنید که REST API وردپرس به درستی کار می‌کند
2. لاگ‌های وردپرس را بررسی کنید
3. مطمئن شوید که افزونه‌ها یا تنظیمات امنیتی، دسترسی به API را مسدود نکرده‌اند
4. بررسی کنید که مقادیر `permission_callback` به درستی تنظیم شده باشند 