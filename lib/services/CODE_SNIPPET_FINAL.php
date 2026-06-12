// ============================================================
// GymAI — فقط این یک snippet (بدون <?php)
// محل اجرا: همه جا (Run everywhere)
// جایگزین: کد قدیمی متاباکس + snippetهای Seed + REST جدا
// ============================================================

$gymai_rest_meta_keys = array(
    'short_description', 'movement_pattern', 'body_engagement',
    'estimated_1rm_formula', 'muscle_targets_json', 'met',
    'movement_distance_cm', 'calories_per_1000kg',
    'exercise_difficulty_score', 'typical_rpe', 'target_area',
);
add_action('init', function () use ($gymai_rest_meta_keys) {
    foreach ($gymai_rest_meta_keys as $key) {
        register_post_meta('exercises', $key, array(
            'single' => true, 'type' => 'string',
            'show_in_rest' => true, 'auth_callback' => '__return_true',
        ));
    }
}, 5);
add_filter('rest_prepare_exercises', function ($response, $post, $request) use ($gymai_rest_meta_keys) {
    if (!is_object($response) || !method_exists($response, 'get_data')) {
        return $response;
    }
    $data = $response->get_data();
    if (!isset($data['meta']) || !is_array($data['meta'])) {
        $data['meta'] = array();
    }
    foreach ($gymai_rest_meta_keys as $key) {
        $data['meta'][$key] = (string) get_post_meta($post->ID, $key, true);
    }
    $response->set_data($data);
    return $response;
}, 20, 3);

if (!function_exists('gymai_add_exercise_meta_box')) {
    add_action('add_meta_boxes', 'gymai_add_exercise_meta_box');
    function gymai_add_exercise_meta_box() {
        add_meta_box(
            'exercise_details',
            'جزئیات حرکت (GymAI)',
            'gymai_exercise_meta_box_callback',
            'exercises',
            'normal',
            'high'
        );
    }
}

if (!function_exists('gymai_render_muscle_input')) {
    function gymai_render_muscle_input($key, $label, $value) {
        echo '<div class="muscle-row">';
        echo '<span class="muscle-name">' . esc_html($label) . '</span>';
        echo '<input type="number" class="muscle-number" id="muscle_' . esc_attr($key) . '" min="0" max="100" step="5" value="' . esc_attr((string) $value) . '" />';
        echo '</div>';
    }
}

if (!function_exists('gymai_exercise_meta_box_callback')) {
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
        $other_names = is_array($get('other_names')) ? implode(', ', $get('other_names')) : $get('other_names');
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
        $estimated_1rm_formula = $get('estimated_1rm_formula') ? $get('estimated_1rm_formula') : 'برزیکی';
        $typical_rpe = $get('typical_rpe');
        $muscle_targets_json = $get('muscle_targets_json');
        $movement_pattern = $get('movement_pattern');
        $body_engagement = $get('body_engagement');
        $target_area = $get('target_area');
        $muscle_targets = json_decode((string) $muscle_targets_json, true);
        if (!is_array($muscle_targets)) {
            $muscle_targets = array();
        }
        $muscle_val = static function ($key) use ($muscle_targets) {
            return isset($muscle_targets[$key]) ? (int) $muscle_targets[$key] : 0;
        };
        ?>
        <style>
            .exercise-section{margin-bottom:20px;border:1px solid #ccd0d4;border-radius:5px;background:#fff}
            .exercise-section-header{padding:12px 15px;background:#f8f9fa;border-bottom:1px solid #ccd0d4;font-weight:bold;cursor:pointer}
            .exercise-section-content{padding:15px}
            .exercise-table{width:100%;border-collapse:collapse}
            .exercise-table th{width:200px;text-align:right;padding:10px;background:#f8f9fa;vertical-align:top}
            .exercise-table td{padding:10px}
            .exercise-table input,.exercise-table select,.exercise-table textarea{width:100%;box-sizing:border-box}
            .muscle-grid{display:grid;grid-template-columns:1fr 1fr;gap:15px}
            .muscle-row{display:flex;justify-content:space-between;align-items:center;margin:8px 0;padding:8px;background:#f9f9f9;border-radius:6px}
            .muscle-number{width:90px!important;text-align:center}
            .json-preview{background:#f1f1f1;padding:10px;font-family:monospace;font-size:12px;white-space:pre-wrap}
        </style>
        <script>
        function gymaiToggleSection(id){var e=document.getElementById('section-'+id);if(e)e.style.display=e.style.display==='none'?'block':'none';}
        function gymaiUpdateMuscleJSON(){
            var keys=['chest_upper','chest_middle','chest_lower','shoulder_anterior','shoulder_lateral','shoulder_posterior','triceps','biceps','forearms','back_lat','back_trap','lower_back','quads','hamstrings','glutes','calf','abs'];
            var r={},i,inp,v;
            for(i=0;i<keys.length;i++){inp=document.getElementById('muscle_'+keys[i]);if(!inp)continue;v=parseInt(inp.value,10)||0;if(v>0)r[keys[i]]=v;}
            var j=document.getElementById('muscle_targets_json');
            if(j)j.value=JSON.stringify(r);
            var p=document.getElementById('json_preview');
            if(p)p.textContent=JSON.stringify(r,null,2);
        }
        function gymaiResetAllMuscles(){document.querySelectorAll('.muscle-number').forEach(function(i){i.value=0;});gymaiUpdateMuscleJSON();}
        function gymaiSuggestForLegCurl(){gymaiResetAllMuscles();['hamstrings:95','glutes:15','calf:25'].forEach(function(s){var p=s.split(':'),el=document.getElementById('muscle_'+p[0]);if(el)el.value=p[1];});gymaiUpdateMuscleJSON();}
        document.addEventListener('DOMContentLoaded',function(){gymaiUpdateMuscleJSON();document.querySelectorAll('.muscle-number').forEach(function(i){i.addEventListener('input',gymaiUpdateMuscleJSON);});});
        </script>

        <div class="exercise-section">
            <div class="exercise-section-header" onclick="gymaiToggleSection('basic')">اطلاعات پایه</div>
            <div id="section-basic" class="exercise-section-content">
                <table class="exercise-table">
                    <tr><th>نام اپ</th><td><input type="text" name="name_app" value="<?php echo esc_attr($name_app); ?>" /></td></tr>
                    <tr><th>نام‌های دیگر</th><td><input type="text" name="other_names" value="<?php echo esc_attr($other_names); ?>" placeholder="با کاما" /></td></tr>
                    <tr><th>عضله اصلی</th><td><select name="main_muscle">
                        <option value="">—</option>
                        <?php foreach (array('سینه','پشت','سرشانه','جلوبازو','پشت‌بازو','پا','همسترینگ','باسن','شکم','ساق پا','کمر') as $m) {
                            echo '<option value="' . esc_attr($m) . '" ' . selected($main_muscle, $m, false) . '>' . esc_html($m) . '</option>';
                        } ?>
                    </select></td></tr>
                    <tr><th>عضلات فرعی</th><td><input type="text" name="secondary_muscles" value="<?php echo esc_attr($secondary_muscles); ?>" /></td></tr>
                    <tr><th>دشواری</th><td><select name="difficulty">
                        <option value="مبتدی" <?php selected($difficulty, 'مبتدی'); ?>>مبتدی</option>
                        <option value="متوسط" <?php selected($difficulty, 'متوسط'); ?>>متوسط</option>
                        <option value="پیشرفته" <?php selected($difficulty, 'پیشرفته'); ?>>پیشرفته</option>
                    </select></td></tr>
                    <tr><th>تجهیزات</th><td><select name="equipment">
                        <?php foreach (array('ماشین'=>'ماشین','هالتر'=>'هالتر','دمبل'=>'دمبل','کابل'=>'کابل','کش'=>'کش','بدون تجهیزات'=>'بدون تجهیزات') as $v=>$l) {
                            echo '<option value="' . esc_attr($v) . '" ' . selected($equipment, $v, false) . '>' . esc_html($l) . '</option>';
                        } ?>
                    </select></td></tr>
                    <tr><th>نوع تمرین</th><td><select name="exercise_type">
                        <option value="قدرتی" <?php selected($exercise_type, 'قدرتی'); ?>>قدرتی</option>
                        <option value="حجمی" <?php selected($exercise_type, 'حجمی'); ?>>حجمی</option>
                        <option value="استقامتی" <?php selected($exercise_type, 'استقامتی'); ?>>استقامتی</option>
                    </select></td></tr>
                    <tr><th>ناحیه هدف</th><td><input type="text" name="target_area" value="<?php echo esc_attr($target_area); ?>" /></td></tr>
                    <tr><th>ویدیو</th><td><input type="url" name="video_url" value="<?php echo esc_attr($video_url); ?>" /></td></tr>
                </table>
            </div>
        </div>

        <div class="exercise-section">
            <div class="exercise-section-header" onclick="gymaiToggleSection('app')">اپلیکیشن</div>
            <div id="section-app" class="exercise-section-content">
                <table class="exercise-table">
                    <tr><th>توضیح کوتاه</th><td><textarea name="short_description" rows="5"><?php echo esc_textarea($short_description); ?></textarea></td></tr>
                    <tr><th>MET</th><td><input type="number" step="0.1" name="met" value="<?php echo esc_attr($met); ?>" /></td></tr>
                    <tr><th>مسافت cm</th><td><input type="number" name="movement_distance_cm" value="<?php echo esc_attr($movement_distance_cm); ?>" /></td></tr>
                    <tr><th>کالری/1000kg</th><td><input type="number" name="calories_per_1000kg" value="<?php echo esc_attr($calories_per_1000kg); ?>" /></td></tr>
                </table>
            </div>
        </div>

        <div class="exercise-section">
            <div class="exercise-section-header" onclick="gymaiToggleSection('adv')">پیشرفته</div>
            <div id="section-adv" class="exercise-section-content">
                <table class="exercise-table">
                    <tr><th>امتیاز 1-10</th><td><input type="number" min="1" max="10" name="exercise_difficulty_score" value="<?php echo esc_attr($exercise_difficulty_score); ?>" /></td></tr>
                    <tr><th>فرمول 1RM</th><td><select name="estimated_1rm_formula">
                        <option value="برزیکی" <?php selected($estimated_1rm_formula, 'برزیکی'); ?>>برزیکی</option>
                        <option value="اپلی" <?php selected($estimated_1rm_formula, 'اپلی'); ?>>اپلی</option>
                    </select></td></tr>
                    <tr><th>RPE</th><td><input type="number" step="0.5" name="typical_rpe" value="<?php echo esc_attr($typical_rpe); ?>" /></td></tr>
                    <tr><th>الگوی حرکت</th><td><select name="movement_pattern">
                        <option value="">—</option>
                        <?php foreach (array('فشار عمودی','فشار افقی','کشش عمودی','کشش افقی','اسکوات','لگد') as $p) {
                            echo '<option value="' . esc_attr($p) . '" ' . selected($movement_pattern, $p, false) . '>' . esc_html($p) . '</option>';
                        } ?>
                    </select></td></tr>
                    <tr><th>درگیری</th><td><select name="body_engagement">
                        <option value="تک مفصلی" <?php selected($body_engagement, 'تک مفصلی'); ?>>تک مفصلی</option>
                        <option value="چند مفصلی" <?php selected($body_engagement, 'چند مفصلی'); ?>>چند مفصلی</option>
                        <option value="کل بدن" <?php selected($body_engagement, 'کل بدن'); ?>>کل بدن</option>
                    </select></td></tr>
                </table>
            </div>
        </div>

        <div class="exercise-section">
            <div class="exercise-section-header" onclick="gymaiToggleSection('muscle')">هیت‌مپ</div>
            <div id="section-muscle" class="exercise-section-content">
                <p><button type="button" class="button" onclick="gymaiResetAllMuscles()">صفر</button>
                <button type="button" class="button" onclick="gymaiSuggestForLegCurl()">پشت‌پا</button></p>
                <div class="muscle-grid">
                    <div><?php
                    foreach (array('chest_upper'=>'سینه بالا','chest_middle'=>'سینه میانی','chest_lower'=>'سینه پایین','shoulder_anterior'=>'شانه قدام','shoulder_lateral'=>'شانه جانب','shoulder_posterior'=>'شانه خلف','triceps'=>'پشت‌بازو','biceps'=>'جلوبازو','forearms'=>'ساعد') as $k=>$l) {
                        gymai_render_muscle_input($k, $l, $muscle_val($k));
                    }
                    ?></div>
                    <div><?php
                    foreach (array('back_lat'=>'زیربغل','back_trap'=>'ذوزنقه','lower_back'=>'کمر','quads'=>'چهارسر','hamstrings'=>'همسترینگ','glutes'=>'باسن','calf'=>'ساق','abs'=>'شکم') as $k=>$l) {
                        gymai_render_muscle_input($k, $l, $muscle_val($k));
                    }
                    ?></div>
                </div>
                <input type="hidden" id="muscle_targets_json" name="muscle_targets_json" value="<?php echo esc_attr($muscle_targets_json); ?>" />
                <div class="json-preview"><pre id="json_preview"></pre></div>
            </div>
        </div>

        <div class="exercise-section">
            <div class="exercise-section-header" onclick="gymaiToggleSection('tips')">نکات</div>
            <div id="section-tips" class="exercise-section-content">
                <table class="exercise-table">
                    <tr><th>نکته ۱</th><td><textarea name="tip_1" rows="3"><?php echo esc_textarea($tip_1); ?></textarea></td></tr>
                    <tr><th>نکته ۲</th><td><textarea name="tip_2" rows="3"><?php echo esc_textarea($tip_2); ?></textarea></td></tr>
                    <tr><th>نکته ۳</th><td><textarea name="tip_3" rows="3"><?php echo esc_textarea($tip_3); ?></textarea></td></tr>
                </table>
            </div>
        </div>
        <?php
    }
}

if (!function_exists('gymai_save_exercise_meta_box')) {
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
        foreach (array('short_description', 'tip_1', 'tip_2', 'tip_3') as $field) {
            if (array_key_exists($field, $_POST)) {
                update_post_meta($post_id, $field, sanitize_textarea_field(wp_unslash($_POST[$field])));
            }
        }
        foreach (array('name_app', 'main_muscle', 'secondary_muscles', 'difficulty', 'equipment', 'exercise_type', 'target_area', 'other_names', 'video_url', 'movement_pattern', 'body_engagement', 'estimated_1rm_formula') as $field) {
            if (array_key_exists($field, $_POST)) {
                update_post_meta($post_id, $field, sanitize_text_field(wp_unslash($_POST[$field])));
            }
        }
        foreach (array('met', 'movement_distance_cm', 'calories_per_1000kg', 'exercise_difficulty_score', 'typical_rpe', 'views_count', 'likes_count') as $field) {
            if (array_key_exists($field, $_POST)) {
                $raw = wp_unslash($_POST[$field]);
                update_post_meta($post_id, $field, ($raw === '') ? '' : (string) (0 + $raw));
            }
        }
        if (array_key_exists('muscle_targets_json', $_POST)) {
            $decoded = json_decode(wp_unslash($_POST['muscle_targets_json']), true);
            if (is_array($decoded)) {
                $flags = defined('JSON_UNESCAPED_UNICODE') ? JSON_UNESCAPED_UNICODE : 0;
                update_post_meta($post_id, 'muscle_targets_json', wp_json_encode($decoded, $flags));
            }
        }
        update_post_meta($post_id, '_gymai_meta_saved', (string) time());
    }
}
