<?php
/**
 * Plugin Name: GymAI Popular 20 Exercises
 * Description: افزودن ۲۰ حرکت پرطرفدار — ابزارها → GymAI 20 Exercises
 * Version: 1.0.2
 * Author: GymAI Pro
 * Requires at least: 5.8
 * Requires PHP: 7.2
 */

if (!defined('ABSPATH')) {
    exit;
}

if (version_compare(PHP_VERSION, '7.2', '<')) {
    add_action('admin_notices', function () {
        echo '<div class="notice notice-error"><p>GymAI Popular 20: PHP 7.2+ لازم است.</p></div>';
    });
    return;
}

if (!defined('GYMAI_POP20_SEED_FILE')) {
    define('GYMAI_POP20_SEED_FILE', __DIR__ . '/add_exercises_popular_20.php');
}
if (!defined('GYMAI_POP20_PLUGIN_LOADS_MENU')) {
    define('GYMAI_POP20_PLUGIN_LOADS_MENU', true);
}

if (!function_exists('gymai_pop20_is_seed_page')) {
    function gymai_pop20_is_seed_page() {
        if (!is_admin()) {
            return false;
        }
        $page = isset($_GET['page']) ? sanitize_key(wp_unslash($_GET['page'])) : '';
        return $page === 'gymai-popular-20-exercises';
    }
}

if (!function_exists('gymai_pop20_load_seed_file')) {
    function gymai_pop20_load_seed_file() {
        static $loaded = false;
        if ($loaded) {
            return true;
        }
        if (!is_readable(GYMAI_POP20_SEED_FILE)) {
            return false;
        }
        require_once GYMAI_POP20_SEED_FILE;
        $loaded = true;
        return true;
    }
}

if (!function_exists('gymai_pop20_admin_router')) {
    function gymai_pop20_admin_router() {
        if (!current_user_can('manage_options')) {
            wp_die('دسترسی کافی ندارید.');
        }
        if (!gymai_pop20_load_seed_file()) {
            echo '<div class="wrap"><h1>GymAI 20 Exercises</h1>';
            echo '<div class="notice notice-error"><p><strong>فایل داده لود نشد.</strong></p>';
            echo '<p>فایل <code>add_exercises_popular_20.php</code> باید کنار فایل پلاگین باشد.</p>';
            echo '<p>حجم فایل اصلی پلاگین باید حدود ۳ کیلوبایت باشد — اگر خیلی بزرگ است، فایل اشتباه آپلود شده.</p></div></div>';
            return;
        }
        if (function_exists('gymai_popular_20_admin_page')) {
            gymai_popular_20_admin_page();
        }
    }
}

if (!function_exists('gymai_pop20_register_admin_menu')) {
    function gymai_pop20_register_admin_menu() {
        add_management_page(
            'GymAI 20 Exercises',
            'GymAI 20 Exercises',
            'manage_options',
            'gymai-popular-20-exercises',
            'gymai_pop20_admin_router'
        );
    }
    add_action('admin_menu', 'gymai_pop20_register_admin_menu');
}

if (!function_exists('gymai_pop20_missing_data_notice')) {
    function gymai_pop20_missing_data_notice() {
        if (!current_user_can('manage_options')) {
            return;
        }
        if (is_readable(GYMAI_POP20_SEED_FILE)) {
            return;
        }
        echo '<div class="notice notice-error"><p><strong>GymAI Popular 20:</strong> فایل ';
        echo '<code>add_exercises_popular_20.php</code> در پوشه پلاگین نیست.</p></div>';
    }
    add_action('admin_notices', 'gymai_pop20_missing_data_notice');
}
