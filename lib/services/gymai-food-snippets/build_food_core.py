#!/usr/bin/env python3
"""Build CODE_SNIPPET_FOOD_CORE.php from gymai_food_meta_seed.php engine."""
import re
from pathlib import Path

ROOT = Path(__file__).parent
engine_src = (ROOT.parent / 'gymai_food_meta_seed.php').read_text(encoding='utf-8')

engine_src = re.sub(r'^<\?php\s*\n', '', engine_src)
engine_src = re.sub(r"/\*\*[\s\S]*?\*/\s*", '', engine_src, count=1)
engine_src = re.sub(
    r"if \(!defined\('ABSPATH'\)\) \{\s*\n\s*exit;\s*\n\}\s*\n",
    '',
    engine_src,
)
engine_src = re.sub(
    r"if \(!defined\('GYMAI_FOOD_POST_TYPE'\)\) \{\s*\n\s*define\('GYMAI_FOOD_POST_TYPE', 'foods'\);\s*\n\}\s*\n",
    '',
    engine_src,
)


def extract_function(content: str, name: str) -> str:
    pattern = rf'function {re.escape(name)}\('
    m = re.search(pattern, content)
    if not m:
        raise SystemExit(f'function not found: {name}')
    brace = content.find('{', m.start())
    depth = 0
    for i in range(brace, len(content)):
        if content[i] == '{':
            depth += 1
        elif content[i] == '}':
            depth -= 1
            if depth == 0:
                return content[m.start() : i + 1]
    raise SystemExit(f'unclosed: {name}')


def wrap(name: str, body: str) -> str:
    lines = [f"if (!function_exists('{name}')) {{"]
    for line in body.splitlines():
        lines.append('    ' + line if line.strip() else '')
    lines.append('}')
    return '\n'.join(lines)


func_names = re.findall(r'^function (gymai_food_\w+)\(', engine_src, re.M)
if 'gymai_food_run_batch' not in func_names:
    func_names.append('gymai_food_run_batch')

header = """// GymAI Foods — CORE (موتور seed + منوی batch)
// Code Snippets: Run everywhere | بدون تگ php
// ترتیب: 1) CORE  2) BATCH1  3) BATCH2 ...

if (!defined('GYMAI_FOOD_POST_TYPE')) {
    define('GYMAI_FOOD_POST_TYPE', 'foods');
}

"""

parts = [header]
for name in func_names:
    parts.append(wrap(name, extract_function(engine_src, name)))

parts.append(
    """
if (!function_exists('gymai_food_max_batches')) {
    function gymai_food_max_batches() {
        return (int) apply_filters('gymai_food_max_batches', 20);
    }
}

if (!function_exists('gymai_food_load_batch_files')) {
    function gymai_food_load_batch_files() {
        static $done = false;
        if ($done) {
            return;
        }
        $done = true;
        $max = gymai_food_max_batches();
        for ($n = 1; $n <= $max; $n++) {
            $func = 'gymai_food_batch' . $n . '_definitions';
            if (function_exists($func)) {
                continue;
            }
            $paths = array(
                defined('WP_CONTENT_DIR') ? WP_CONTENT_DIR . '/gymai-seed/food-batch' . $n . '.php' : '',
                defined('WP_PLUGIN_DIR') ? WP_PLUGIN_DIR . '/gymai-food-seed/food-batch' . $n . '.php' : '',
            );
            foreach ($paths as $path) {
                if ($path !== '' && is_readable($path)) {
                    require_once $path;
                    break;
                }
            }
        }
    }
}

if (!function_exists('gymai_food_batch_status')) {
    function gymai_food_batch_status() {
        gymai_food_load_batch_files();
        $max = gymai_food_max_batches();
        $status = array();
        for ($n = 1; $n <= $max; $n++) {
            $status['batch' . $n] = function_exists('gymai_food_batch' . $n . '_definitions');
        }
        return $status;
    }
}

if (!function_exists('gymai_food_batch_label')) {
    function gymai_food_batch_label($n) {
        $labels = array(
            1 => '۱۰ خوراکی پایه (۱–۱۰)',
            2 => 'خوراکی ۱۱–۲۰',
            3 => 'خوراکی ۲۱–۳۰',
        );
        if (isset($labels[$n])) {
            return $labels[$n];
        }
        $start = (($n - 1) * 10) + 1;
        $end = $n * 10;
        return 'خوراکی ' . $start . '–' . $end;
    }
}

if (!function_exists('gymai_food_handle_admin_request')) {
    function gymai_food_handle_admin_request() {
        if (!is_admin() || !current_user_can('manage_options')) {
            return null;
        }
        $page = isset($_GET['page']) ? sanitize_key(wp_unslash($_GET['page'])) : '';
        if ($page !== 'gymai-food-seed') {
            return null;
        }
        if (!isset($_POST['gymai_food_nonce']) || !wp_verify_nonce(sanitize_text_field(wp_unslash($_POST['gymai_food_nonce'])), 'gymai_food_seed')) {
            return null;
        }

        gymai_food_load_batch_files();
        if (!empty($_POST['relink_all'])) {
            return array(
                'result' => gymai_food_relink_all_posts(),
                'batch_label' => 'بازسازی لینک داخلی همه خوراکی‌ها',
                'relink' => true,
            );
        }
        $status = gymai_food_batch_status();
        $force = !empty($_POST['force_update']);
        $which = isset($_POST['batch']) ? sanitize_key(wp_unslash($_POST['batch'])) : '';
        $key = 'batch' . $which;
        if ($which === '' || empty($status[$key])) {
            return array('error' => 'batch نامعتبر یا لود نشده است.');
        }
        $func = 'gymai_food_batch' . $which . '_definitions';
        $dataset = call_user_func($func);
        return array(
            'result' => gymai_food_run_batch($dataset, $force),
            'batch_label' => gymai_food_batch_label((int) $which),
        );
    }
}

if (!function_exists('gymai_food_seed_admin_page')) {
    function gymai_food_seed_admin_page() {
        if (!current_user_can('manage_options')) {
            wp_die('دسترسی ندارید');
        }

        gymai_food_load_batch_files();
        $status = gymai_food_batch_status();
        $flash = gymai_food_handle_admin_request();
        $loaded = array();
        foreach ($status as $key => $ok) {
            if ($ok) {
                $loaded[] = $key;
            }
        }
        ?>
        <div class="wrap">
            <h1>GymAI — Seed خوراکی (CORE + Batch)</h1>
            <p>الگوی مشابه تمرین‌های بدنسازی: یک بار CORE فعال، سپس هر batch جدا.</p>
            <?php if (empty($loaded)) : ?>
                <div class="notice notice-error">
                    <p><strong>هیچ batch لود نشد.</strong> اسنیپت BATCH1 را فعال کنید یا فایل را در <code>wp-content/gymai-seed/food-batch1.php</code> بگذارید.</p>
                </div>
            <?php else : ?>
                <p>Batchهای آماده: <code><?php echo esc_html(implode(', ', $loaded)); ?></code></p>
            <?php endif; ?>

            <form method="post" style="margin-top:16px;">
                <?php wp_nonce_field('gymai_food_seed', 'gymai_food_nonce'); ?>
                <p><label><input type="checkbox" name="force_update" value="1" checked="checked" />
                    به‌روزرسانی محتوا، لینک داخلی و Rank Math</label></p>
                <table class="widefat" style="max-width:720px;">
                    <thead><tr><th>Batch</th><th>وضعیت</th><th>اجرا</th></tr></thead>
                    <tbody>
                    <?php for ($n = 1; $n <= gymai_food_max_batches(); $n++) :
                        $key = 'batch' . $n;
                        if (empty($status[$key])) {
                            continue;
                        }
                        ?>
                        <tr>
                            <td><strong>Batch <?php echo (int) $n; ?></strong><br><small><?php echo esc_html(gymai_food_batch_label($n)); ?></small></td>
                            <td><span style="color:green;">✓ لود شد</span></td>
                            <td><button type="submit" name="batch" value="<?php echo (int) $n; ?>" class="button button-primary">Seed</button></td>
                        </tr>
                    <?php endfor; ?>
                    </tbody>
                </table>
            </form>

            <?php if (!empty($loaded)) : ?>
            <form method="post" style="margin-top:24px;padding:12px;border:1px solid #ccd0d4;max-width:720px;">
                <?php wp_nonce_field('gymai_food_seed', 'gymai_food_nonce'); ?>
                <h2 style="margin-top:0;">لینک داخلی بین batchها</h2>
                <p>بعد از seed همه batchها، این دکمه محتوا و <code>substitutes_json</code> را با لینک به همه ۱۰۰ خوراکی بازسازی می‌کند.</p>
                <button type="submit" name="relink_all" value="1" class="button button-secondary">بازسازی لینک داخلی (همه)</button>
            </form>
            <?php endif; ?>

            <?php if (is_array($flash) && !empty($flash['result'])) : ?>
                <div class="notice notice-success" style="margin-top:16px;">
                    <p><strong><?php echo esc_html($flash['batch_label'] ?? ''); ?></strong></p>
                    <?php if (!empty($flash['relink'])) : ?>
                        <p>به‌روزرسانی محتوا: <?php echo (int) $flash['result']['updated']; ?></p>
                    <?php else : ?>
                        <p>ایجاد: <?php echo (int) ($flash['result']['created'] ?? 0); ?> — به‌روز: <?php echo (int) ($flash['result']['updated'] ?? 0); ?></p>
                    <?php endif; ?>
                    <?php if (!empty($flash['result']['errors'])) : ?>
                        <ul><?php foreach ($flash['result']['errors'] as $e) : ?>
                            <li><?php echo esc_html($e); ?></li>
                        <?php endforeach; ?></ul>
                    <?php endif; ?>
                </div>
            <?php elseif (is_array($flash) && !empty($flash['error'])) : ?>
                <div class="notice notice-error" style="margin-top:16px;"><p><?php echo esc_html($flash['error']); ?></p></div>
            <?php endif; ?>
        </div>
        <?php
    }
}

if (!function_exists('gymai_food_register_admin_menu')) {
    function gymai_food_register_admin_menu() {
        add_management_page(
            'GymAI Seed Foods',
            'GymAI Seed Foods',
            'manage_options',
            'gymai-food-seed',
            'gymai_food_seed_admin_page'
        );
    }
    add_action('admin_menu', 'gymai_food_register_admin_menu');
}

add_action('rest_api_init', function () {
    register_rest_route('gymai/v1', '/seed-foods-batch/(?P<batch>\\d+)', array(
        'methods' => 'POST',
        'permission_callback' => static function () {
            return current_user_can('manage_options');
        },
        'callback' => static function ($request) {
            gymai_food_load_batch_files();
            $n = (int) $request->get_param('batch');
            $func = 'gymai_food_batch' . $n . '_definitions';
            if (!function_exists($func)) {
                return new WP_REST_Response(array('error' => 'batch not loaded'), 404);
            }
            return new WP_REST_Response(gymai_food_run_batch(call_user_func($func), true), 200);
        },
    ));
});
"""
)

out = ROOT / 'CODE_SNIPPET_FOOD_CORE.php'
out.write_text('\n\n'.join(parts).strip() + '\n', encoding='utf-8')
print('OK', out.stat().st_size, 'bytes', len(func_names), 'engine functions')
