<?php
// متاباکس سفارشی برای حرکت‌های تمرینی (نسخه به‌روزرسانی شده)
add_action('add_meta_boxes', 'add_exercise_meta_box');
function add_exercise_meta_box() {
    add_meta_box(
        'exercise_details',
        'جزئیات حرکت تمرینی',
        'exercise_meta_box_callback',
        'exercises',
        'normal',
        'high'
    );
}

// محتوای متاباکس
function exercise_meta_box_callback($post) {
    wp_nonce_field('exercise_meta_box', 'exercise_meta_box_nonce');
    
    $name_app = get_post_meta($post->ID, 'name_app', true);
    $main_muscle = get_post_meta($post->ID, 'main_muscle', true);
    $secondary_muscles = get_post_meta($post->ID, 'secondary_muscles', true);
    $difficulty = get_post_meta($post->ID, 'difficulty', true);
    $equipment = get_post_meta($post->ID, 'equipment', true);
    $exercise_type = get_post_meta($post->ID, 'exercise_type', true);
    $learn = get_post_meta($post->ID, 'learn', true);
    $tip_1 = get_post_meta($post->ID, 'tip_1', true);
    $tip_2 = get_post_meta($post->ID, 'tip_2', true);
    $tip_3 = get_post_meta($post->ID, 'tip_3', true);
    $video_url = get_post_meta($post->ID, 'video_url', true);
    $image_url = get_post_meta($post->ID, 'image_url', true);
    $other_names = get_post_meta($post->ID, 'other_names', true);
    $views_count = get_post_meta($post->ID, 'views_count', true);
    $likes_count = get_post_meta($post->ID, 'likes_count', true);
    $detailed_description = get_post_meta($post->ID, 'detailed_description', true);
    $seo_content = get_post_meta($post->ID, 'seo_content', true);
    
    ?>
    <style>
    .exercise-meta-table { width: 100%; }
    .exercise-meta-table th { width: 150px; text-align: right; padding: 10px; vertical-align: top; }
    .exercise-meta-table td { padding: 10px; }
    .exercise-meta-table input, .exercise-meta-table select, .exercise-meta-table textarea { width: 100%; }
    .exercise-meta-table textarea { height: 100px; }
    .exercise-meta-table textarea.large { height: 200px; }
    .exercise-meta-table textarea.extra-large { height: 300px; }
    .field-description { font-size: 12px; color: #666; margin-top: 5px; }
    .section-divider { border-top: 2px solid #ddd; margin: 20px 0; padding-top: 20px; }
    .section-title { font-weight: bold; color: #333; margin-bottom: 10px; }
    </style>
    
    <table class="exercise-meta-table">
        <!-- بخش اطلاعات اصلی -->
        <tr>
            <th><label for="name_app">نام اصلی حرکت:</label></th>
            <td><input type="text" id="name_app" name="name_app" value="<?php echo esc_attr($name_app); ?>" placeholder="مثال: بنچ پرس هالتر تخت" /></td>
        </tr>
        
        <tr>
            <th><label for="main_muscle">عضله اصلی:</label></th>
            <td>
                <select id="main_muscle" name="main_muscle">
                    <option value="">انتخاب کنید</option>
                    <option value="سینه" <?php selected($main_muscle, 'سینه'); ?>>سینه</option>
                    <option value="پشت" <?php selected($main_muscle, 'پشت'); ?>>پشت</option>
                    <option value="سرشانه" <?php selected($main_muscle, 'سرشانه'); ?>>سرشانه</option>
                    <option value="جلوبازو" <?php selected($main_muscle, 'جلوبازو'); ?>>جلوبازو</option>
                    <option value="پشت‌بازو" <?php selected($main_muscle, 'پشت‌بازو'); ?>>پشت‌بازو</option>
                    <option value="ساعد" <?php selected($main_muscle, 'ساعد'); ?>>ساعد</option>
                    <option value="پا" <?php selected($main_muscle, 'پا'); ?>>پا</option>
                    <option value="باسن" <?php selected($main_muscle, 'باسن'); ?>>باسن</option>
                    <option value="شکم" <?php selected($main_muscle, 'شکم'); ?>>شکم</option>
                    <option value="کمر" <?php selected($main_muscle, 'کمر'); ?>>کمر</option>
                    <option value="ساق پا" <?php selected($main_muscle, 'ساق پا'); ?>>ساق پا</option>
                    <option value="همسترینگ" <?php selected($main_muscle, 'همسترینگ'); ?>>همسترینگ</option>
                    <option value="چهارسر" <?php selected($main_muscle, 'چهارسر'); ?>>چهارسر</option>
                    <option value="کل بدن" <?php selected($main_muscle, 'کل بدن'); ?>>کل بدن</option>
                </select>
            </td>
        </tr>
        
        <tr>
            <th><label for="secondary_muscles">عضلات فرعی:</label></th>
            <td><input type="text" id="secondary_muscles" name="secondary_muscles" value="<?php echo esc_attr($secondary_muscles); ?>" placeholder="مثال: سرشانه، پشت‌بازو" /></td>
        </tr>
        
        <tr>
            <th><label for="difficulty">سطح دشواری:</label></th>
            <td>
                <select id="difficulty" name="difficulty">
                    <option value="">انتخاب کنید</option>
                    <option value="مبتدی" <?php selected($difficulty, 'مبتدی'); ?>>مبتدی</option>
                    <option value="متوسط" <?php selected($difficulty, 'متوسط'); ?>>متوسط</option>
                    <option value="پیشرفته" <?php selected($difficulty, 'پیشرفته'); ?>>پیشرفته</option>
                </select>
            </td>
        </tr>
        
        <tr>
            <th><label for="equipment">تجهیزات مورد نیاز:</label></th>
            <td>
                <select id="equipment" name="equipment">
                    <option value="">انتخاب کنید</option>
                    <option value="بدون تجهیزات" <?php selected($equipment, 'بدون تجهیزات'); ?>>بدون تجهیزات</option>
                    <option value="هالتر" <?php selected($equipment, 'هالتر'); ?>>هالتر</option>
                    <option value="دمبل" <?php selected($equipment, 'دمبل'); ?>>دمبل</option>
                    <option value="ماشین" <?php selected($equipment, 'ماشین'); ?>>ماشین</option>
                    <option value="کابل" <?php selected($equipment, 'کابل'); ?>>کابل</option>
                    <option value="کش" <?php selected($equipment, 'کش'); ?>>کش</option>
                    <option value="وزنه" <?php selected($equipment, 'وزنه'); ?>>وزنه</option>
                    <option value="نیمکت" <?php selected($equipment, 'نیمکت'); ?>>نیمکت</option>
                    <option value="توپ سوئیسی" <?php selected($equipment, 'توپ سوئیسی'); ?>>توپ سوئیسی</option>
                    <option value="TRX" <?php selected($equipment, 'TRX'); ?>>TRX</option>
                    <option value="کتل‌بل" <?php selected($equipment, 'کتل‌بل'); ?>>کتل‌بل</option>
                    <option value="بارفیکس" <?php selected($equipment, 'بارفیکس'); ?>>بارفیکس</option>
                    <option value="دیپ" <?php selected($equipment, 'دیپ'); ?>>دیپ</option>
                    <option value="چندگانه" <?php selected($equipment, 'چندگانه'); ?>>چندگانه</option>
                </select>
            </td>
        </tr>
        
        <tr>
            <th><label for="exercise_type">نوع تمرین:</label></th>
            <td>
                <select id="exercise_type" name="exercise_type">
                    <option value="">انتخاب کنید</option>
                    <option value="قدرتی" <?php selected($exercise_type, 'قدرتی'); ?>>قدرتی</option>
                    <option value="هوازی" <?php selected($exercise_type, 'هوازی'); ?>>هوازی</option>
                    <option value="انعطاف‌پذیری" <?php selected($exercise_type, 'انعطاف‌پذیری'); ?>>انعطاف‌پذیری</option>
                    <option value="تعادلی" <?php selected($exercise_type, 'تعادلی'); ?>>تعادلی</option>
                    <option value="فانکشنال" <?php selected($exercise_type, 'فانکشنال'); ?>>فانکشنال</option>
                    <option value="کاردیو" <?php selected($exercise_type, 'کاردیو'); ?>>کاردیو</option>
                    <option value="کششی" <?php selected($exercise_type, 'کششی'); ?>>کششی</option>
                    <option value="پلایومتریک" <?php selected($exercise_type, 'پلایومتریک'); ?>>پلایومتریک</option>
                </select>
            </td>
        </tr>
        
        <tr>
            <th><label for="other_names">نام‌های دیگر:</label></th>
            <td><input type="text" id="other_names" name="other_names" value="<?php echo esc_attr($other_names); ?>" placeholder="نام‌های دیگر حرکت (با کاما جدا کنید)" /></td>
        </tr>
        
        <!-- بخش محتوا -->
        <tr class="section-divider">
            <td colspan="2">
                <div class="section-title">📝 محتوای حرکت</div>
            </td>
        </tr>
        
        <tr>
            <th><label for="learn">توضیحات کوتاه:</label></th>
            <td>
                <textarea id="learn" name="learn" placeholder="توضیحات کوتاه و مختصر نحوه انجام حرکت..."><?php echo esc_textarea($learn); ?></textarea>
                <div class="field-description">توضیحات کوتاه برای نمایش در اپلیکیشن (حدود 100-150 کلمه)</div>
            </td>
        </tr>
        
        <tr>
            <th><label for="detailed_description">توضیحات کامل:</label></th>
            <td>
                <textarea id="detailed_description" name="detailed_description" class="extra-large" placeholder="توضیحات کامل و جامع نحوه انجام حرکت شامل آماده‌سازی، اجرا، نکات تکنیکی، مزایا، اشتباهات رایج، پروگرمینگ و ترکیب‌های مؤثر..."><?php echo esc_textarea($detailed_description); ?></textarea>
                <div class="field-description">توضیحات کامل و جامع برای وب‌سایت (600-800 کلمه) شامل تمام جزئیات تکنیکی</div>
            </td>
        </tr>
        
        <tr>
            <th><label for="seo_content">محتوای سئو:</label></th>
            <td>
                <textarea id="seo_content" name="seo_content" class="extra-large" placeholder="محتوای بهینه‌شده برای موتورهای جستجو شامل کلمات کلیدی، مزایا، الگوهای تمرینی و ترکیب‌های مؤثر..."><?php echo esc_textarea($seo_content); ?></textarea>
                <div class="field-description">محتوای بهینه‌شده برای سئو و وب‌سایت (600-800 کلمه) با کلمات کلیدی مناسب</div>
            </td>
        </tr>
        
        <!-- بخش نکات -->
        <tr class="section-divider">
            <td colspan="2">
                <div class="section-title">💡 نکات مهم</div>
            </td>
        </tr>
        
        <tr>
            <th><label for="tip_1">نکته اول:</label></th>
            <td><textarea id="tip_1" name="tip_1" placeholder="نکته مهم اول..."><?php echo esc_textarea($tip_1); ?></textarea></td>
        </tr>
        
        <tr>
            <th><label for="tip_2">نکته دوم:</label></th>
            <td><textarea id="tip_2" name="tip_2" placeholder="نکته مهم دوم..."><?php echo esc_textarea($tip_2); ?></textarea></td>
        </tr>
        
        <tr>
            <th><label for="tip_3">نکته سوم:</label></th>
            <td><textarea id="tip_3" name="tip_3" placeholder="نکته مهم سوم..."><?php echo esc_textarea($tip_3); ?></textarea></td>
        </tr>
        
        <!-- بخش رسانه -->
        <tr class="section-divider">
            <td colspan="2">
                <div class="section-title">🎥 رسانه و آمار</div>
            </td>
        </tr>
        
        <tr>
            <th><label for="video_url">لینک ویدیو:</label></th>
            <td><input type="url" id="video_url" name="video_url" value="<?php echo esc_attr($video_url); ?>" placeholder="https://www.youtube.com/watch?v=..." /></td>
        </tr>
        
        <tr>
            <th><label for="image_url">لینک تصویر:</label></th>
            <td><input type="url" id="image_url" name="image_url" value="<?php echo esc_attr($image_url); ?>" placeholder="https://example.com/image.jpg" /></td>
        </tr>
        
        <tr>
            <th><label for="views_count">تعداد بازدید:</label></th>
            <td><input type="number" id="views_count" name="views_count" value="<?php echo esc_attr($views_count); ?>" min="0" readonly /></td>
        </tr>
        
        <tr>
            <th><label for="likes_count">تعداد لایک:</label></th>
            <td><input type="number" id="likes_count" name="likes_count" value="<?php echo esc_attr($likes_count); ?>" min="0" readonly /></td>
        </tr>
    </table>
    <?php
}

// ذخیره متا فیلدها
add_action('save_post', 'save_exercise_meta_box');
function save_exercise_meta_box($post_id) {
    if (!isset($_POST['exercise_meta_box_nonce'])) return;
    if (!wp_verify_nonce($_POST['exercise_meta_box_nonce'], 'exercise_meta_box')) return;
    if (defined('DOING_AUTOSAVE') && DOING_AUTOSAVE) return;
    if (!current_user_can('edit_post', $post_id)) return;
    
    $fields = array(
        'name_app', 'main_muscle', 'secondary_muscles', 'difficulty', 'equipment', 'exercise_type', 
        'learn', 'tip_1', 'tip_2', 'tip_3', 'video_url', 'image_url', 'other_names', 
        'views_count', 'likes_count', 'detailed_description', 'seo_content'
    );
    
    foreach ($fields as $field) {
        if (isset($_POST[$field])) {
            if (in_array($field, array('detailed_description', 'seo_content', 'learn', 'tip_1', 'tip_2', 'tip_3'))) {
                // برای فیلدهای متنی طولانی از sanitize_textarea_field استفاده می‌کنیم
                update_post_meta($post_id, $field, sanitize_textarea_field($_POST[$field]));
            } else {
                update_post_meta($post_id, $field, sanitize_text_field($_POST[$field]));
            }
        }
    }
}

// ثبت فیلدهای متا برای REST API
add_action('init', function() {
    $meta_fields = array(
        'name_app', 'main_muscle', 'secondary_muscles', 'difficulty', 'equipment', 'exercise_type', 
        'learn', 'tip_1', 'tip_2', 'tip_3', 'video_url', 'image_url', 'other_names', 
        'views_count', 'likes_count', 'detailed_description', 'seo_content'
    );
    
    foreach ($meta_fields as $field) {
        register_post_meta('exercises', $field, array(
            'type' => 'string',
            'single' => true,
            'show_in_rest' => true,
        ));
    }
});

// پیام موفقیت
add_action('admin_notices', function() {
    echo '<div class="notice notice-success"><p>✅ متاباکس حرکت‌های تمرینی به‌روزرسانی شد! (شامل فیلدهای جدید detailed_description و seo_content)</p></div>';
});
?>
