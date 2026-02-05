<?php
/**
 * Plugin Name: GYMAI Coach Video Upload API
 * Description: REST API endpoint for uploading coach exercise videos to download server
 * Version: 2025.01.15
 * Author: GYMAI
 */

if (!defined('ABSPATH')) exit;

// Register REST API endpoint
add_action('rest_api_init', function () {
    register_rest_route('gymai/v1', '/upload-coach-video', array(
        'methods' => 'POST',
        'callback' => 'gymai_upload_coach_video',
        'permission_callback' => '__return_true', // We'll check auth in callback
    ));
});

/**
 * آپلود ویدیو مربی
 */
function gymai_upload_coach_video($request) {
    // 1. بررسی JWT Token
    $auth_header = $request->get_header('Authorization');
    if (empty($auth_header) || !preg_match('/Bearer\s+(.+)/i', $auth_header, $matches)) {
        return new WP_Error(
            'unauthorized',
            'Authorization token is missing',
            array('status' => 401)
        );
    }
    
    $jwt_token = $matches[1];
    
    // 2. بررسی اعتبار JWT با Supabase
    $supabase_url = 'https://oaztoennovtcfcxvnswa.supabase.co';
    $supabase_anon_key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9henRvZW5ub3Z0Y2ZjeHZuc3dhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDY4NzYzNzEsImV4cCI6MjA2MjQ1MjM3MX0.UywfAvKyqUjByLQHRnRqJ85Bal6NdvAOwQQJXVaQfGk';
    
    $user_response = wp_remote_get(
        $supabase_url . '/auth/v1/user',
        array(
            'headers' => array(
                'Authorization' => 'Bearer ' . $jwt_token,
                'apikey' => $supabase_anon_key,
            ),
            'timeout' => 10,
        )
    );
    
    if (is_wp_error($user_response) || wp_remote_retrieve_response_code($user_response) !== 200) {
        return new WP_Error(
            'unauthorized',
            'Invalid or expired token',
            array('status' => 401)
        );
    }
    
    $user_data = json_decode(wp_remote_retrieve_body($user_response), true);
    $user_id = isset($user_data['id']) ? $user_data['id'] : (isset($user_data->id) ? $user_data->id : null);
    
    if (empty($user_id)) {
        return new WP_Error(
            'unauthorized',
            'User ID not found in token',
            array('status' => 401)
        );
    }
    
    // 3. بررسی role (admin یا trainer)
    $profile_response = wp_remote_get(
        $supabase_url . '/rest/v1/profiles?id=eq.' . $user_id . '&select=role',
        array(
            'headers' => array(
                'Authorization' => 'Bearer ' . $jwt_token,
                'apikey' => $supabase_anon_key,
                'Content-Type' => 'application/json',
            ),
            'timeout' => 10,
        )
    );
    
    if (is_wp_error($profile_response) || wp_remote_retrieve_response_code($profile_response) !== 200) {
        return new WP_Error(
            'forbidden',
            'Failed to verify user role',
            array('status' => 403)
        );
    }
    
    $profile_data = json_decode(wp_remote_retrieve_body($profile_response), true);
    if (empty($profile_data) || !isset($profile_data[0]['role'])) {
        return new WP_Error(
            'forbidden',
            'User profile not found',
            array('status' => 403)
        );
    }
    
    $user_role = $profile_data[0]['role'];
    if (!in_array($user_role, array('admin', 'trainer'))) {
        return new WP_Error(
            'forbidden',
            'Only admins and trainers can upload videos',
            array('status' => 403)
        );
    }
    
    // 4. بررسی فایل آپلود شده
    if (empty($_FILES['video'])) {
        return new WP_Error(
            'missing_file',
            'Video file is required',
            array('status' => 400)
        );
    }
    
    $file = $_FILES['video'];
    
    // بررسی خطاهای آپلود
    if ($file['error'] !== UPLOAD_ERR_OK) {
        return new WP_Error(
            'upload_error',
            'File upload error: ' . $file['error'],
            array('status' => 400)
        );
    }
    
    // بررسی نوع فایل
    $allowed_types = array('video/mp4', 'video/quicktime', 'video/x-msvideo', 'video/webm');
    $file_type = wp_check_filetype($file['name']);
    $mime_type = $file['type'];
    
    if (!in_array($mime_type, $allowed_types) && !in_array($file_type['ext'], array('mp4', 'mov', 'avi', 'webm'))) {
        return new WP_Error(
            'invalid_file_type',
            'Only video files are allowed (MP4, MOV, AVI, WEBM)',
            array('status' => 400)
        );
    }
    
    // بررسی حجم فایل (حداکثر 100MB)
    $max_size = 100 * 1024 * 1024; // 100MB
    if ($file['size'] > $max_size) {
        return new WP_Error(
            'file_too_large',
            'File size exceeds maximum allowed (100MB)',
            array('status' => 400)
        );
    }
    
    // 5. ساخت مسیر مقصد
    $base_path = '/domains/dl.gymaipro.ir/public_html/coaches_video';
    $trainer_folder = $base_path . '/' . $user_id;
    
    // ساخت پوشه مربی اگر وجود نداشته باشد
    if (!file_exists($trainer_folder)) {
        if (!wp_mkdir_p($trainer_folder)) {
            return new WP_Error(
                'directory_error',
                'Failed to create trainer directory',
                array('status' => 500)
            );
        }
        // تنظیم مجوزهای پوشه
        chmod($trainer_folder, 0755);
    }
    
    // تولید نام فایل منحصر به فرد
    $file_extension = $file_type['ext'] ?: 'mp4';
    $timestamp = time();
    $random_string = wp_generate_password(8, false);
    $file_name = $timestamp . '_' . $random_string . '.' . $file_extension;
    $file_path = $trainer_folder . '/' . $file_name;
    
    // 6. انتقال فایل
    if (!move_uploaded_file($file['tmp_name'], $file_path)) {
        return new WP_Error(
            'move_error',
            'Failed to move uploaded file',
            array('status' => 500)
        );
    }
    
    // تنظیم مجوزهای فایل
    chmod($file_path, 0644);
    
    // 7. تولید URL کامل
    $video_url = 'https://dl.gymaipro.ir/coaches_video/' . $user_id . '/' . $file_name;
    
    // 8. برگرداندن پاسخ
    return rest_ensure_response(array(
        'success' => true,
        'video_url' => $video_url,
        'file_name' => $file_name,
        'file_size' => $file['size'],
        'trainer_id' => $user_id,
        'uploaded_at' => date('Y-m-d H:i:s'),
    ));
}

