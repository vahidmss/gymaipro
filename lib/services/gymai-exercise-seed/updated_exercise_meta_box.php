<?php
/**
 * متاباکس حرکت‌های تمرینی — نسخه اصلاح‌شده
 * مشکل قبلی: HTML شکسته → فیلدها داخل فرم post نبودند → ذخیره نمی‌شد.
 *
 * نصب: این فایل را در functions.php تم یا پلاگین سفارشی include کنید.
 */

if (!defined('ABSPATH')) {
    exit;
}

// =============================================
// متاباکس
// =============================================
add_action('add_meta_boxes', 'gymai_add_exercise_meta_box');
function gymai_add_exercise_meta_box() {
    add_meta_box(
        'exercise_details',
        '🏋️‍♂️ جزئیات کامل حرکت تمرینی',
        'gymai_exercise_meta_box_callback',
        'exercises',
        'normal',
        'high'
    );
}

function gymai_exercise_meta_box_callback($post) {
    wp_nonce_field('exercise_meta_box', 'exercise_meta_box_nonce');

    $get = static function ($key) use ($post) {
        return get_post_meta($post->ID, $key, true);
    };

    $name_app = $get('name_app');
    $main_muscle = $get('main_muscle');
    $secondary_muscles = $get('secondary_muscles');
    $difficulty = $get('difficulty');
    $equipment = $get('equipment');
    $exercise_type = $get('exercise_type');
    $other_names = $get('other_names');
    $short_description = $get('short_description');
    $tip_1 = $get('tip_1');
    $tip_2 = $get('tip_2');
    $tip_3 = $get('tip_3');
    $video_url = $get('video_url');
    $views_count = $get('views_count');
    $likes_count = $get('likes_count');
    $met = $get('met');
    $movement_distance_cm = $get('movement_distance_cm');
    $calories_per_1000kg = $get('calories_per_1000kg');
    $exercise_difficulty_score = $get('exercise_difficulty_score');
    $estimated_1rm_formula = $get('estimated_1rm_formula') ?: 'برزیکی';
    $typical_rpe = $get('typical_rpe');
    $muscle_targets_json = $get('muscle_targets_json');
    $movement_pattern = $get('movement_pattern');
    $body_engagement = $get('body_engagement');
    $target_area = $get('target_area');

    $muscle_targets = json_decode((string) $muscle_targets_json, true);
    if (!is_array($muscle_targets)) {
        $muscle_targets = [];
    }

    $muscle_val = static function ($key) use ($muscle_targets) {
        return isset($muscle_targets[$key]) ? (int) $muscle_targets[$key] : 0;
    };
    ?>
    <style>
        .exercise-section { background:#fff; border:1px solid #ccd0d4; border-radius:5px; margin-bottom:20px; }
        .exercise-section-header { background:#f8f9fa; padding:12px 15px; border-bottom:1px solid #ccd0d4; font-weight:bold; cursor:pointer; }
        .exercise-section-content { padding:15px; }
        .exercise-table { width:100%; border-collapse:collapse; }
        .exercise-table th { width:200px; text-align:right; padding:10px; background:#f8f9fa; vertical-align:top; border-bottom:1px solid #eee; }
        .exercise-table td { padding:10px; border-bottom:1px solid #eee; }
        .exercise-table input, .exercise-table select { width:100%; max-width:100%; padding:6px 8px; border:1px solid #ddd; border-radius:4px; box-sizing:border-box; }
        .exercise-table textarea { width:100%; min-height:90px; padding:6px 8px; border:1px solid #ddd; border-radius:4px; box-sizing:border-box; }
        .exercise-table textarea.short { min-height:120px; }
        .field-note { font-size:11px; color:#666; margin-top:5px; }
        .muscle-grid { display:grid; grid-template-columns:repeat(2,1fr); gap:15px; }
        @media (max-width:960px) { .muscle-grid { grid-template-columns:1fr; } }
        .muscle-panel { padding:10px; border-radius:8px; }
        .muscle-panel.chest { background:#fff3e0; }
        .muscle-panel.legs { background:#e8fce8; }
        .muscle-row { display:flex; align-items:center; justify-content:space-between; gap:10px; margin:8px 0; padding:8px 12px; background:#f9f9f9; border-radius:8px; }
        .muscle-name { width:140px; font-weight:bold; font-size:13px; }
        .muscle-number { width:90px !important; text-align:center; font-weight:bold; }
        .json-preview { background:#f1f1f1; padding:10px; border-radius:5px; font-family:monospace; font-size:12px; margin-top:10px; white-space:pre-wrap; word-break:break-all; }
        .guide-box { background:#e8f4f8; padding:10px; border-radius:5px; margin-bottom:15px; }
        .guide-btn { color:#fff; border:none; padding:6px 14px; border-radius:4px; margin-left:8px; cursor:pointer; }
        .guide-btn.reset { background:#dc3545; }
        .guide-btn.leg { background:#17a2b8; }
    </style>

    <script>
    function gymaiToggleSection(sectionId) {
        var el = document.getElementById('section-' + sectionId);
        if (!el) return;
        el.style.display = (el.style.display === 'none') ? 'block' : 'none';
    }

    function gymaiUpdateMuscleJSON() {
        var keys = [
            'chest_upper','chest_middle','chest_lower',
            'shoulder_anterior','shoulder_lateral','shoulder_posterior',
            'triceps','biceps','forearms',
            'back_lat','back_trap','lower_back',
            'quads','hamstrings','glutes','calf','abs'
        ];
        var result = {};
        keys.forEach(function(key) {
            var input = document.getElementById('muscle_' + key);
            if (!input) return;
            var val = parseInt(input.value, 10) || 0;
            if (val > 0) result[key] = val;
        });
        var jsonField = document.getElementById('muscle_targets_json');
        if (jsonField) jsonField.value = JSON.stringify(result);
        var preview = document.getElementById('json_preview');
        if (preview) preview.textContent = JSON.stringify(result, null, 2);
    }

    function gymaiResetAllMuscles() {
        document.querySelectorAll('.muscle-number').forEach(function(input) {
            input.value = 0;
        });
        gymaiUpdateMuscleJSON();
    }

    function gymaiSuggestForLegCurl() {
        gymaiResetAllMuscles();
        var preset = { hamstrings: 95, glutes: 15, calf: 25, abs: 10 };
        Object.keys(preset).forEach(function(key) {
            var input = document.getElementById('muscle_' + key);
            if (input) input.value = preset[key];
        });
        gymaiUpdateMuscleJSON();
    }

    document.addEventListener('DOMContentLoaded', function() {
        gymaiUpdateMuscleJSON();
        document.querySelectorAll('.muscle-number').forEach(function(input) {
            input.addEventListener('input', gymaiUpdateMuscleJSON);
            input.addEventListener('change', gymaiUpdateMuscleJSON);
        });
    });
    </script>

    <!-- بخش 1: اطلاعات پایه -->
    <div class="exercise-section">
        <div class="exercise-section-header" onclick="gymaiToggleSection('basic')">📋 اطلاعات پایه حرکت</div>
        <div id="section-basic" class="exercise-section-content">
            <table class="exercise-table">
                <tr>
                    <th><label for="name_app">نام اصلی (اپ):</label></th>
                    <td><input type="text" id="name_app" name="name_app" value="<?php echo esc_attr($name_app); ?>" /></td>
                </tr>
                <tr>
                    <th><label for="other_names">نام‌های دیگر:</label></th>
                    <td><input type="text" id="other_names" name="other_names" value="<?php echo esc_attr($other_names); ?>" placeholder="با کاما جدا کنید" /></td>
                </tr>
                <tr>
                    <th><label for="main_muscle">عضله اصلی:</label></th>
                    <td>
                        <select id="main_muscle" name="main_muscle">
                            <option value="" <?php selected($main_muscle, ''); ?>>انتخاب کنید</option>
                            <?php
                            $muscles = ['سینه', 'پشت', 'سرشانه', 'جلوبازو', 'پشت‌بازو', 'پا', 'همسترینگ', 'باسن', 'شکم', 'ساق پا', 'کمر'];
                            foreach ($muscles as $m) {
                                echo '<option value="' . esc_attr($m) . '" ' . selected($main_muscle, $m, false) . '>' . esc_html($m) . '</option>';
                            }
                            ?>
                        </select>
                    </td>
                </tr>
                <tr>
                    <th><label for="secondary_muscles">عضلات فرعی:</label></th>
                    <td><input type="text" id="secondary_muscles" name="secondary_muscles" value="<?php echo esc_attr($secondary_muscles); ?>" /></td>
                </tr>
                <tr>
                    <th><label for="difficulty">سطح دشواری:</label></th>
                    <td>
                        <select id="difficulty" name="difficulty">
                            <option value="" <?php selected($difficulty, ''); ?>>انتخاب کنید</option>
                            <option value="مبتدی" <?php selected($difficulty, 'مبتدی'); ?>>مبتدی</option>
                            <option value="متوسط" <?php selected($difficulty, 'متوسط'); ?>>متوسط</option>
                            <option value="پیشرفته" <?php selected($difficulty, 'پیشرفته'); ?>>پیشرفته</option>
                        </select>
                    </td>
                </tr>
                <tr>
                    <th><label for="equipment">تجهیزات:</label></th>
                    <td>
                        <select id="equipment" name="equipment">
                            <option value="" <?php selected($equipment, ''); ?>>انتخاب کنید</option>
                            <option value="ماشین" <?php selected($equipment, 'ماشین'); ?>>ماشین (دستگاه)</option>
                            <option value="هالتر" <?php selected($equipment, 'هالتر'); ?>>هالتر</option>
                            <option value="دمبل" <?php selected($equipment, 'دمبل'); ?>>دمبل</option>
                            <option value="کابل" <?php selected($equipment, 'کابل'); ?>>کابل (سیم‌کش)</option>
                            <option value="کش" <?php selected($equipment, 'کش'); ?>>کش مقاومتی</option>
                            <option value="بدون تجهیزات" <?php selected($equipment, 'بدون تجهیزات'); ?>>بدون تجهیزات</option>
                        </select>
                    </td>
                </tr>
                <tr>
                    <th><label for="exercise_type">نوع تمرین:</label></th>
                    <td>
                        <select id="exercise_type" name="exercise_type">
                            <option value="" <?php selected($exercise_type, ''); ?>>انتخاب کنید</option>
                            <option value="قدرتی" <?php selected($exercise_type, 'قدرتی'); ?>>قدرتی</option>
                            <option value="حجمی" <?php selected($exercise_type, 'حجمی'); ?>>حجمی (هایپرتروفی)</option>
                            <option value="استقامتی" <?php selected($exercise_type, 'استقامتی'); ?>>استقامتی</option>
                        </select>
                    </td>
                </tr>
                <tr>
                    <th><label for="target_area">ناحیه هدف:</label></th>
                    <td><input type="text" id="target_area" name="target_area" value="<?php echo esc_attr($target_area); ?>" placeholder="مثلاً سینه، پشت، همسترینگ" /></td>
                </tr>
                <tr>
                    <th><label for="video_url">لینک ویدیو:</label></th>
                    <td><input type="url" id="video_url" name="video_url" value="<?php echo esc_attr($video_url); ?>" /></td>
                </tr>
            </table>
        </div>
    </div>

    <!-- بخش 2: اپ -->
    <div class="exercise-section">
        <div class="exercise-section-header" onclick="gymaiToggleSection('app')">📱 مخصوص اپلیکیشن</div>
        <div id="section-app" class="exercise-section-content">
            <table class="exercise-table">
                <tr>
                    <th><label for="short_description">توضیح کوتاه:</label></th>
                    <td>
                        <textarea id="short_description" name="short_description" class="short"><?php echo esc_textarea($short_description); ?></textarea>
                        <div class="field-note">در REST API و اپ نمایش داده می‌شود.</div>
                    </td>
                </tr>
                <tr>
                    <th><label for="met">MET:</label></th>
                    <td><input type="number" step="0.1" min="0" id="met" name="met" value="<?php echo esc_attr($met); ?>" /></td>
                </tr>
                <tr>
                    <th><label for="movement_distance_cm">مسافت حرکت (cm):</label></th>
                    <td><input type="number" step="1" min="0" id="movement_distance_cm" name="movement_distance_cm" value="<?php echo esc_attr($movement_distance_cm); ?>" /></td>
                </tr>
                <tr>
                    <th><label for="calories_per_1000kg">کالری / 1000kg:</label></th>
                    <td><input type="number" step="1" min="0" id="calories_per_1000kg" name="calories_per_1000kg" value="<?php echo esc_attr($calories_per_1000kg); ?>" /></td>
                </tr>
            </table>
        </div>
    </div>

    <!-- بخش 3: پیشرفته -->
    <div class="exercise-section">
        <div class="exercise-section-header" onclick="gymaiToggleSection('advanced')">🔬 دیتاهای پیشرفته</div>
        <div id="section-advanced" class="exercise-section-content">
            <table class="exercise-table">
                <tr>
                    <th><label for="exercise_difficulty_score">امتیاز دشواری (1-10):</label></th>
                    <td><input type="number" min="1" max="10" id="exercise_difficulty_score" name="exercise_difficulty_score" value="<?php echo esc_attr($exercise_difficulty_score); ?>" /></td>
                </tr>
                <tr>
                    <th><label for="estimated_1rm_formula">فرمول 1RM:</label></th>
                    <td>
                        <select id="estimated_1rm_formula" name="estimated_1rm_formula">
                            <option value="برزیکی" <?php selected($estimated_1rm_formula, 'برزیکی'); ?>>برزیکی</option>
                            <option value="اپلی" <?php selected($estimated_1rm_formula, 'اپلی'); ?>>اپلی</option>
                            <option value="برونزی" <?php selected($estimated_1rm_formula, 'برونزی'); ?>>برونزی</option>
                        </select>
                    </td>
                </tr>
                <tr>
                    <th><label for="typical_rpe">RPE معمول:</label></th>
                    <td><input type="number" step="0.5" min="1" max="10" id="typical_rpe" name="typical_rpe" value="<?php echo esc_attr($typical_rpe); ?>" /></td>
                </tr>
                <tr>
                    <th><label for="movement_pattern">الگوی حرکتی:</label></th>
                    <td>
                        <select id="movement_pattern" name="movement_pattern">
                            <option value="" <?php selected($movement_pattern, ''); ?>>—</option>
                            <?php
                            $patterns = ['فشار عمودی', 'فشار افقی', 'کشش عمودی', 'کشش افقی', 'اسکوات', 'لگد'];
                            foreach ($patterns as $p) {
                                echo '<option value="' . esc_attr($p) . '" ' . selected($movement_pattern, $p, false) . '>' . esc_html($p) . '</option>';
                            }
                            ?>
                        </select>
                    </td>
                </tr>
                <tr>
                    <th><label for="body_engagement">درگیری بدن:</label></th>
                    <td>
                        <select id="body_engagement" name="body_engagement">
                            <option value="" <?php selected($body_engagement, ''); ?>>—</option>
                            <option value="تک مفصلی" <?php selected($body_engagement, 'تک مفصلی'); ?>>تک مفصلی</option>
                            <option value="چند مفصلی" <?php selected($body_engagement, 'چند مفصلی'); ?>>چند مفصلی</option>
                            <option value="کل بدن" <?php selected($body_engagement, 'کل بدن'); ?>>کل بدن</option>
                        </select>
                    </td>
                </tr>
            </table>
        </div>
    </div>

    <!-- بخش 4: هیت‌مپ -->
    <div class="exercise-section">
        <div class="exercise-section-header" onclick="gymaiToggleSection('muscle')">💪 هیت مپ عضلات</div>
        <div id="section-muscle" class="exercise-section-content">
            <div class="guide-box">
                شدت درگیری 0 تا 100
                <button type="button" class="guide-btn reset" onclick="gymaiResetAllMuscles()">صفر کردن همه</button>
                <button type="button" class="guide-btn leg" onclick="gymaiSuggestForLegCurl()">پیشنهاد پشت پا</button>
            </div>
            <div class="muscle-grid">
                <div class="muscle-panel chest">
                    <h4>سینه و شانه</h4>
                    <?php
                    $chest_shoulder = [
                        'chest_upper' => 'سینه بالایی',
                        'chest_middle' => 'سینه میانی',
                        'chest_lower' => 'سینه پایینی',
                        'shoulder_anterior' => 'سرشانه قدامی',
                        'shoulder_lateral' => 'سرشانه میانی',
                        'shoulder_posterior' => 'سرشانه خلفی',
                    ];
                    foreach ($chest_shoulder as $key => $label) {
                        gymai_render_muscle_input($key, $label, $muscle_val($key));
                    }
                    ?>
                    <h4>بازو</h4>
                    <?php
                    gymai_render_muscle_input('triceps', 'پشت‌بازو', $muscle_val('triceps'));
                    gymai_render_muscle_input('biceps', 'جلوبازو', $muscle_val('biceps'));
                    gymai_render_muscle_input('forearms', 'ساعد', $muscle_val('forearms'));
                    ?>
                </div>
                <div class="muscle-panel legs">
                    <h4>پشت</h4>
                    <?php
                    gymai_render_muscle_input('back_lat', 'زیربغل', $muscle_val('back_lat'));
                    gymai_render_muscle_input('back_trap', 'ذوزنقه', $muscle_val('back_trap'));
                    gymai_render_muscle_input('lower_back', 'کمر', $muscle_val('lower_back'));
                    ?>
                    <h4>پا</h4>
                    <?php
                    gymai_render_muscle_input('quads', 'چهارسر', $muscle_val('quads'));
                    gymai_render_muscle_input('hamstrings', 'همسترینگ', $muscle_val('hamstrings'));
                    gymai_render_muscle_input('glutes', 'باسن', $muscle_val('glutes'));
                    gymai_render_muscle_input('calf', 'ساق', $muscle_val('calf'));
                    gymai_render_muscle_input('abs', 'شکم', $muscle_val('abs'));
                    ?>
                </div>
            </div>
            <input type="hidden" id="muscle_targets_json" name="muscle_targets_json" value="<?php echo esc_attr($muscle_targets_json); ?>" />
            <div class="json-preview"><strong>JSON:</strong><pre id="json_preview"><?php echo esc_html($muscle_targets_json ? wp_json_encode($muscle_targets, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE) : '{}'); ?></pre></div>
        </div>
    </div>

    <!-- بخش 5: نکات -->
    <div class="exercise-section">
        <div class="exercise-section-header" onclick="gymaiToggleSection('tips')">💡 نکات تمرینی</div>
        <div id="section-tips" class="exercise-section-content">
            <table class="exercise-table">
                <tr><th><label for="tip_1">نکته ۱:</label></th><td><textarea id="tip_1" name="tip_1"><?php echo esc_textarea($tip_1); ?></textarea></td></tr>
                <tr><th><label for="tip_2">نکته ۲:</label></th><td><textarea id="tip_2" name="tip_2"><?php echo esc_textarea($tip_2); ?></textarea></td></tr>
                <tr><th><label for="tip_3">نکته ۳:</label></th><td><textarea id="tip_3" name="tip_3"><?php echo esc_textarea($tip_3); ?></textarea></td></tr>
                <tr><th>بازدید / لایک</th><td>
                    <input type="number" name="views_count" value="<?php echo esc_attr($views_count); ?>" readonly style="width:48%;display:inline-block;" />
                    <input type="number" name="likes_count" value="<?php echo esc_attr($likes_count); ?>" readonly style="width:48%;display:inline-block;" />
                </td></tr>
            </table>
        </div>
    </div>
    <?php
}

function gymai_render_muscle_input($key, $label, $value) {
    echo '<div class="muscle-row">';
    echo '<span class="muscle-name">' . esc_html($label) . '</span>';
    echo '<input type="number" class="muscle-number" id="muscle_' . esc_attr($key) . '" min="0" max="100" step="5" value="' . esc_attr((string) $value) . '" />';
    echo '</div>';
}

// =============================================
// ذخیره — فقط برای CPT exercises
// =============================================
add_action('save_post_exercises', 'gymai_save_exercise_meta_box', 10, 3);
function gymai_save_exercise_meta_box($post_id, $post, $update) {
    if (!isset($_POST['exercise_meta_box_nonce'])) {
        return;
    }
    if (!wp_verify_nonce(sanitize_text_field(wp_unslash($_POST['exercise_meta_box_nonce'])), 'exercise_meta_box')) {
        return;
    }
    if (defined('DOING_AUTOSAVE') && DOING_AUTOSAVE) {
        return;
    }
    if (wp_is_post_revision($post_id)) {
        return;
    }
    if (!current_user_can('edit_post', $post_id)) {
        return;
    }

    $textarea_fields = ['short_description', 'tip_1', 'tip_2', 'tip_3'];
    $text_fields = [
        'name_app', 'main_muscle', 'secondary_muscles', 'difficulty',
        'equipment', 'exercise_type', 'target_area', 'other_names', 'video_url',
        'movement_pattern', 'body_engagement', 'estimated_1rm_formula',
    ];
    $number_fields = [
        'views_count', 'likes_count', 'met', 'movement_distance_cm',
        'calories_per_1000kg', 'exercise_difficulty_score', 'typical_rpe',
    ];

    foreach ($textarea_fields as $field) {
        if (!array_key_exists($field, $_POST)) {
            continue;
        }
        $value = sanitize_textarea_field(wp_unslash($_POST[$field]));
        update_post_meta($post_id, $field, $value);
    }

    foreach ($text_fields as $field) {
        if (!array_key_exists($field, $_POST)) {
            continue;
        }
        $value = sanitize_text_field(wp_unslash($_POST[$field]));
        update_post_meta($post_id, $field, $value);
    }

    foreach ($number_fields as $field) {
        if (!array_key_exists($field, $_POST)) {
            continue;
        }
        $raw = wp_unslash($_POST[$field]);
        if ($raw === '' || $raw === null) {
            update_post_meta($post_id, $field, '');
            continue;
        }
        update_post_meta($post_id, $field, is_numeric($raw) ? (string) (0 + $raw) : sanitize_text_field($raw));
    }

    if (array_key_exists('muscle_targets_json', $_POST)) {
        $json_raw = wp_unslash($_POST['muscle_targets_json']);
        $decoded = json_decode($json_raw, true);
        if (is_array($decoded)) {
            update_post_meta($post_id, 'muscle_targets_json', wp_json_encode($decoded, JSON_UNESCAPED_UNICODE));
        }
    }

    update_post_meta($post_id, '_last_saved', (string) time());
}

// =============================================
// REST API — register_post_meta (یک منبع، بدون تکرار)
// =============================================
add_action('init', 'gymai_register_exercise_meta_for_rest', 20);
function gymai_register_exercise_meta_for_rest() {
    $meta_keys = [
        'name_app', 'main_muscle', 'secondary_muscles', 'difficulty',
        'equipment', 'exercise_type', 'target_area', 'other_names', 'short_description',
        'tip_1', 'tip_2', 'tip_3', 'video_url', 'movement_pattern',
        'body_engagement', 'estimated_1rm_formula', 'muscle_targets_json',
        'views_count', 'likes_count', 'met', 'movement_distance_cm',
        'calories_per_1000kg', 'exercise_difficulty_score', 'typical_rpe',
    ];

    foreach ($meta_keys as $key) {
        register_post_meta('exercises', $key, [
            'type' => 'string',
            'single' => true,
            'show_in_rest' => true,
            'auth_callback' => static function () {
                return current_user_can('edit_posts');
            },
        ]);
    }
}
