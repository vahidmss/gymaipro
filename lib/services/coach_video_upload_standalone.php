<?php
/**
 * فایل مستقل آپلود ویدیو مربی
 * این فایل باید مستقیماً روی هاست دانلود (dl.gymaipro.ir) قرار بگیرد
 * مسیر: /domains/dl.gymaipro.ir/public_html/upload-video.php
 * 
 * Version: 2025.01.15
 */

// تنظیمات
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Authorization, Content-Type');

// Handle preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// فقط POST مجاز است
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'error' => 'Method not allowed',
        'message' => 'فقط درخواست POST مجاز است',
    ]);
    exit;
}

// 1. بررسی JWT Token
$auth_header = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
if (empty($auth_header) || !preg_match('/Bearer\s+(.+)/i', $auth_header, $matches)) {
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'error' => 'unauthorized',
        'message' => 'Authorization token is missing',
    ]);
    exit;
}

$jwt_token = $matches[1];

// 2. بررسی اعتبار JWT با Supabase
$supabase_url = 'https://oaztoennovtcfcxvnswa.supabase.co';
$supabase_anon_key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9henRvZW5ub3Z0Y2ZjeHZuc3dhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDY4NzYzNzEsImV4cCI6MjA2MjQ1MjM3MX0.UywfAvKyqUjByLQHRnRqJ85Bal6NdvAOwQQJXVaQfGk';

// بررسی کاربر با Supabase
$ch = curl_init($supabase_url . '/auth/v1/user');
curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER => [
        'Authorization: Bearer ' . $jwt_token,
        'apikey: ' . $supabase_anon_key,
    ],
    CURLOPT_TIMEOUT => 10,
]);

$user_response = curl_exec($ch);
$http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

if ($http_code !== 200) {
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'error' => 'unauthorized',
        'message' => 'Invalid or expired token',
    ]);
    exit;
}

$user_data = json_decode($user_response, true);
$user_id = $user_data['id'] ?? null;

if (empty($user_id)) {
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'error' => 'unauthorized',
        'message' => 'User ID not found in token',
    ]);
    exit;
}

// 3. بررسی role و دریافت username
$ch = curl_init($supabase_url . '/rest/v1/profiles?id=eq.' . $user_id . '&select=role,username');
curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER => [
        'Authorization: Bearer ' . $jwt_token,
        'apikey: ' . $supabase_anon_key,
        'Content-Type: application/json',
    ],
    CURLOPT_TIMEOUT => 10,
]);

$profile_response = curl_exec($ch);
$profile_http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

if ($profile_http_code !== 200) {
    http_response_code(403);
    echo json_encode([
        'success' => false,
        'error' => 'forbidden',
        'message' => 'Failed to verify user role',
    ]);
    exit;
}

$profile_data = json_decode($profile_response, true);
if (empty($profile_data) || !isset($profile_data[0]['role'])) {
    http_response_code(403);
    echo json_encode([
        'success' => false,
        'error' => 'forbidden',
        'message' => 'User profile not found',
    ]);
    exit;
}

$user_role = $profile_data[0]['role'];
$username = $profile_data[0]['username'] ?? $user_id; // fallback to user_id if username not found

if (!in_array($user_role, ['admin', 'trainer'])) {
    http_response_code(403);
    echo json_encode([
        'success' => false,
        'error' => 'forbidden',
        'message' => 'Only admins and trainers can upload videos',
    ]);
    exit;
}

// 4. بررسی فایل آپلود شده
if (empty($_FILES['video'])) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'error' => 'missing_file',
        'message' => 'Video file is required',
    ]);
    exit;
}

$file = $_FILES['video'];

// بررسی خطاهای آپلود
if ($file['error'] !== UPLOAD_ERR_OK) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'error' => 'upload_error',
        'message' => 'File upload error: ' . $file['error'],
    ]);
    exit;
}

// بررسی نوع فایل
$allowed_extensions = ['mp4', 'mov', 'avi', 'webm'];
$file_extension = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));

if (!in_array($file_extension, $allowed_extensions)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'error' => 'invalid_file_type',
        'message' => 'Only video files are allowed (MP4, MOV, AVI, WEBM)',
    ]);
    exit;
}

// بررسی حجم فایل (حداکثر 100MB)
$max_size = 100 * 1024 * 1024; // 100MB
if ($file['size'] > $max_size) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'error' => 'file_too_large',
        'message' => 'File size exceeds maximum allowed (100MB)',
    ]);
    exit;
}

// 5. ساخت مسیر مقصد (با username)
// پاک کردن کاراکترهای غیرمجاز از username برای استفاده در مسیر
$safe_username = preg_replace('/[^a-zA-Z0-9_-]/', '_', $username);
$base_path = __DIR__ . '/coaches_video';
$trainer_folder = $base_path . '/' . $safe_username;

// ساخت پوشه مربی اگر وجود نداشته باشد
if (!file_exists($trainer_folder)) {
    if (!mkdir($trainer_folder, 0755, true)) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'error' => 'directory_error',
            'message' => 'Failed to create trainer directory',
        ]);
        exit;
    }
}

// تولید نام فایل منحصر به فرد
$timestamp = time();
$random_string = bin2hex(random_bytes(4));
$file_name = $timestamp . '_' . $random_string . '.' . $file_extension;
$file_path = $trainer_folder . '/' . $file_name;

// 6. انتقال فایل
if (!move_uploaded_file($file['tmp_name'], $file_path)) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'move_error',
        'message' => 'Failed to move uploaded file',
    ]);
    exit;
}

// تنظیم مجوزهای فایل
chmod($file_path, 0644);

// 7. تولید URL کامل (با username)
$video_url = 'https://dl.gymaipro.ir/coaches_video/' . $safe_username . '/' . $file_name;

// 8. برگرداندن پاسخ موفق
http_response_code(200);
echo json_encode([
    'success' => true,
    'video_url' => $video_url,
    'file_name' => $file_name,
    'file_size' => $file['size'],
    'trainer_id' => $user_id,
    'trainer_username' => $safe_username,
    'uploaded_at' => date('Y-m-d H:i:s'),
], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);

