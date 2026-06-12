<?php
/**
 * بررسی آپلود — بعد از تست این فایل را حذف کن.
 * باز کن: /wp-content/plugins/gymai-popular-20-seed/verify-install.php
 */
header('Content-Type: text/plain; charset=utf-8');

$dir = __DIR__;
$main = $dir . '/gymai-popular-20-seed.php';
$data = $dir . '/add_exercises_popular_20.php';

echo "GymAI Popular 20 — verify\n\n";

foreach (array('main' => $main, 'data' => $data) as $label => $path) {
    echo "$label: ";
    if (!file_exists($path)) {
        echo "MISSING\n";
        continue;
    }
    $size = filesize($path);
    echo "OK ($size bytes)\n";
}

if (file_exists($main) && filesize($main) > 8000) {
    echo "\nERROR: فایل اصلی پلاگین خیلی بزرگ است!\n";
    echo "احتمالاً add_exercises_popular_20.php را اشتباهی داخل gymai-popular-20-seed.php چسباندی.\n";
    echo "فایل اصلی باید حدود 3000 بایت باشد.\n";
} elseif (file_exists($main)) {
    echo "\nOK: اندازه فایل اصلی درست است.\n";
}

if (!file_exists($data)) {
    echo "\nERROR: فایل add_exercises_popular_20.php را آپلود کن.\n";
} elseif (filesize($data) < 50000) {
    echo "\nWARNING: فایل داده کوچک است — شاید ناقص آپلود شده.\n";
} else {
    echo "OK: فایل داده حجم مناسب دارد.\n";
}

echo "\nPHP: " . PHP_VERSION . "\n";
