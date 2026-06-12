<?php
/**
 * Plugin Name: GymAI Exercise Meta Seed
 * Description: Seed خودکار متا و هیت‌مپ ۱۰ حرکت + متاباکس اصلاح‌شده
 * Version: 1.0.0
 * Author: GymAI Pro
 */

if (!defined('ABSPATH')) {
    exit;
}

$gymai_seed_dir = __DIR__;
require_once $gymai_seed_dir . '/updated_exercise_meta_box.php';
require_once $gymai_seed_dir . '/gymai_exercise_meta_seed.php';
