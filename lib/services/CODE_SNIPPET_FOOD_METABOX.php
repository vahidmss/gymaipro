// ============================================================
// GymAI — متاباکس خوراکی + REST meta
// بدون <?php — افزونه Code Snippets — Run everywhere
// پست‌تایپ را با JetEngine بساز: اسلاگ = foods
// Snippet CPT (CODE_SNIPPET_FOOD_CPT) را فعال نکن!
// ============================================================

$gymai_food_rest_meta_keys = array(
    'name_app', 'other_names', 'food_group', 'food_type', 'meal_times',
    'short_description', 'serving_notes', 'nutrition_basis', 'serving_size_grams',
    'default_serving_unit', 'serving_units_json', 'substitutes_json',
    'allergens', 'glycemic_index', 'sample_image_forapp',
    'tip_1', 'tip_2', 'tip_3',
    'protein', 'calories', 'carbohydrates', 'fat', 'saturated_fat',
    'fiber', 'sugar', 'cholesterol', 'sodium', 'potassium',
    'views_count', 'likes_count',
);
add_action('init', function () use ($gymai_food_rest_meta_keys) {
    if (!post_type_exists('foods')) {
        return;
    }
    foreach ($gymai_food_rest_meta_keys as $key) {
        register_post_meta('foods', $key, array(
            'single' => true, 'type' => 'string',
            'show_in_rest' => true, 'auth_callback' => '__return_true',
        ));
    }
}, 20);
add_filter('rest_prepare_foods', function ($response, $post, $request) use ($gymai_food_rest_meta_keys) {
    if (!is_object($response) || !method_exists($response, 'get_data')) {
        return $response;
    }
    $data = $response->get_data();
    if (!isset($data['meta']) || !is_array($data['meta'])) {
        $data['meta'] = array();
    }
    foreach ($gymai_food_rest_meta_keys as $key) {
        $data['meta'][$key] = (string) get_post_meta($post->ID, $key, true);
    }
    $response->set_data($data);
    return $response;
}, 20, 3);


if (!function_exists('gymai_food_unit_catalog')) {
    function gymai_food_unit_catalog() {
        return array(
            'gram'           => array('label' => 'گرم',              'grams' => 1,   'step' => 1,   'decimals' => 0),
            'piece'          => array('label' => 'عدد (تکه)',        'grams' => 30,  'step' => 0.5, 'decimals' => 1),
            'tablespoon'     => array('label' => 'قاشق غذاخوری',   'grams' => 15,  'step' => 0.5, 'decimals' => 1),
            'teaspoon'       => array('label' => 'قاشق چای‌خوری',  'grams' => 5,   'step' => 0.5, 'decimals' => 1),
            'cup'            => array('label' => 'پیمانه / لیوان',  'grams' => 200, 'step' => 0.5, 'decimals' => 1),
            'palm_carb'      => array('label' => 'کف دست (کربو)',  'grams' => 20,  'step' => 0.5, 'decimals' => 1),
            'palm_protein'   => array('label' => 'کف دست (پروتئین)','grams' => 85, 'step' => 0.5, 'decimals' => 1),
            'fist'           => array('label' => 'مشت',              'grams' => 150, 'step' => 0.5, 'decimals' => 1),
            'thumb_fat'      => array('label' => 'انگشت شست (چربی)','grams' => 10,  'step' => 0.5, 'decimals' => 1),
            'ml'             => array('label' => 'میلی‌لیتر',        'grams' => 1,   'step' => 10,  'decimals' => 0),
        );
    }
}
if (!function_exists('gymai_food_group_options')) {
    function gymai_food_group_options() {
        return array(
            'پروتئین'      => 'پروتئین (گوشت، مرغ، ماهی، تخم‌مرغ)',
            'کربوهیدرات'   => 'کربوهیدرات (نان، برنج، ماکارونی)',
            'چربی'         => 'چربی (روغن، آجیل، کره)',
            'لبنیات'       => 'لبنیات',
            'سبزیجات'      => 'سبزیجات',
            'میوه'         => 'میوه',
            'حبوبات'       => 'حبوبات',
            'مکمل'         => 'مکمل / پودر',
            'نوشیدنی'      => 'نوشیدنی',
            'سایر'         => 'سایر',
        );
    }
}
if (!function_exists('gymai_food_type_options')) {
    function gymai_food_type_options() {
        return array(
            'solid'       => 'جامد',
            'liquid'      => 'مایع',
            'powder'      => 'پودری',
            'supplement'  => 'مکمل',
        );
    }
}
if (!function_exists('gymai_food_meal_time_options')) {
    function gymai_food_meal_time_options() {
        return array('صبحانه', 'میان‌وعده صبح', 'ناهار', 'میان‌وعده عصر', 'شام', 'قبل تمرین', 'بعد تمرین', 'قبل خواب');
    }
}
if (!function_exists('gymai_add_food_meta_box')) {
    add_action('add_meta_boxes', 'gymai_add_food_meta_box');
    function gymai_add_food_meta_box() {
        add_meta_box(
            'food_details',
            '🍽️ جزئیات کامل خوراکی (GymAI)',
            'gymai_food_meta_box_callback',
            'foods',
            'normal',
            'high'
        );
    }
}
if (!function_exists('gymai_food_meta_box_callback')) {
    function gymai_food_meta_box_callback($post) {
        wp_nonce_field('food_meta_box', 'food_meta_box_nonce');

        $get = static function ($key) use ($post) {
            return get_post_meta($post->ID, $key, true);
        };

        $name_app            = $get('name_app');
        $other_names         = is_array($get('other_names')) ? implode(', ', $get('other_names')) : $get('other_names');
        $food_group          = $get('food_group');
        $food_type           = $get('food_type') ?: 'solid';
        $meal_times          = $get('meal_times');
        $short_description   = $get('short_description');
        $serving_notes       = $get('serving_notes');
        $nutrition_basis     = $get('nutrition_basis') ?: 'per_100g';
        $serving_size_grams  = $get('serving_size_grams') ?: '100';
        $default_serving_unit = $get('default_serving_unit') ?: 'gram';
        $serving_units_json  = $get('serving_units_json');
        $substitutes_json    = $get('substitutes_json');
        $allergens           = $get('allergens');
        $glycemic_index      = $get('glycemic_index');
        $tip_1               = $get('tip_1');
        $tip_2               = $get('tip_2');
        $tip_3               = $get('tip_3');
        $views_count         = $get('views_count');
        $likes_count         = $get('likes_count');
        $sample_image_forapp = $get('sample_image_forapp');

        // ارزش غذایی — فیلدهای فعلی اپ
        $protein       = $get('protein');
        $calories      = $get('calories');
        $carbohydrates = $get('carbohydrates');
        $fat           = $get('fat');
        $saturated_fat = $get('saturated_fat');
        $fiber         = $get('fiber');
        $sugar         = $get('sugar');
        $cholesterol   = $get('cholesterol');
        $sodium        = $get('sodium');
        $potassium     = $get('potassium');

        $serving_units = json_decode((string) $serving_units_json, true);
        if (!is_array($serving_units)) {
            $serving_units = array(
                'default_unit' => 'gram',
                'units'        => array(
                    array(
                        'key'        => 'gram',
                        'label'      => 'گرم',
                        'grams'      => 1,
                        'step'       => 1,
                        'decimals'   => 0,
                        'is_primary' => true,
                        'hint'       => '',
                    ),
                ),
            );
        }
        if (!isset($serving_units['units']) || !is_array($serving_units['units'])) {
            $serving_units['units'] = array();
        }

        $meal_times_arr = array_filter(array_map('trim', explode(',', (string) $meal_times)));
        $unit_catalog   = gymai_food_unit_catalog();
        ?>
        <style>
            .food-section { background:#fff; border:1px solid #ccd0d4; border-radius:5px; margin-bottom:20px; }
            .food-section-header { background:#f8f9fa; padding:12px 15px; border-bottom:1px solid #ccd0d4; font-weight:bold; cursor:pointer; }
            .food-section-content { padding:15px; }
            .food-table { width:100%; border-collapse:collapse; }
            .food-table th { width:200px; text-align:right; padding:10px; background:#f8f9fa; vertical-align:top; border-bottom:1px solid #eee; }
            .food-table td { padding:10px; border-bottom:1px solid #eee; }
            .food-table input, .food-table select { width:100%; max-width:100%; padding:6px 8px; border:1px solid #ddd; border-radius:4px; box-sizing:border-box; }
            .food-table textarea { width:100%; min-height:80px; padding:6px 8px; border:1px solid #ddd; border-radius:4px; box-sizing:border-box; }
            .field-note { font-size:11px; color:#666; margin-top:5px; }
            .unit-builder { border:1px solid #e2e4e7; border-radius:8px; padding:12px; background:#fafafa; }
            .unit-row { display:grid; grid-template-columns:1.2fr 1fr 0.7fr 0.7fr 0.5fr 0.5fr auto; gap:8px; align-items:center; margin-bottom:8px; padding:8px; background:#fff; border:1px solid #eee; border-radius:6px; }
            .unit-row input, .unit-row select { width:100%; padding:5px 6px; }
            .unit-row .primary-badge { font-size:11px; color:#2271b1; }
            .json-preview { background:#f1f1f1; padding:10px; border-radius:5px; font-family:monospace; font-size:12px; margin-top:10px; white-space:pre-wrap; word-break:break-all; }
            .preset-btn { margin:4px 4px 4px 0; }
            .meal-chip { display:inline-block; margin:4px 4px 0 0; }
            .nutrition-grid { display:grid; grid-template-columns:repeat(3,1fr); gap:12px; }
            @media (max-width:960px) { .nutrition-grid { grid-template-columns:1fr; } .unit-row { grid-template-columns:1fr; } }
            .guide-box { background:#fff8e5; border:1px solid #f0d78c; padding:10px 12px; border-radius:6px; margin-bottom:12px; font-size:12px; }
        </style>

        <script>
        var gymaiFoodUnitCatalog = <?php echo wp_json_encode(gymai_food_unit_catalog(), JSON_UNESCAPED_UNICODE); ?>;

        function gymaiToggleFoodSection(sectionId) {
            var el = document.getElementById('food-section-' + sectionId);
            if (!el) return;
            el.style.display = (el.style.display === 'none') ? 'block' : 'none';
        }

        function gymaiGetUnitRowsContainer() {
            return document.getElementById('gymai_serving_units_rows');
        }

        function gymaiAddUnitRow(data) {
            data = data || {};
            var container = gymaiGetUnitRowsContainer();
            if (!container) return;

            var key = data.key || '';
            var label = data.label || '';
            var grams = data.grams != null ? data.grams : '';
            var step = data.step != null ? data.step : 1;
            var decimals = data.decimals != null ? data.decimals : 0;
            var hint = data.hint || '';
            var isPrimary = !!data.is_primary;

            var row = document.createElement('div');
            row.className = 'unit-row';
            row.innerHTML =
                '<select class="unit-key-select" onchange="gymaiOnUnitKeyChange(this)">' +
                    '<option value="">— واحد سفارشی —</option>' +
                    Object.keys(gymaiFoodUnitCatalog).map(function(k) {
                        var u = gymaiFoodUnitCatalog[k];
                        var selected = (k === key) ? ' selected' : '';
                        return '<option value="' + k + '"' + selected + '>' + u.label + '</option>';
                    }).join('') +
                '</select>' +
                '<input type="text" class="unit-label" placeholder="برچسب نمایشی" value="' + (label || '') + '" />' +
                '<input type="number" class="unit-grams" min="0" step="0.1" placeholder="گرم معادل" value="' + grams + '" />' +
                '<input type="number" class="unit-step" min="0.1" step="0.5" placeholder="گام (۰.۵ یا ۱)" value="' + step + '" />' +
                '<input type="number" class="unit-decimals" min="0" max="2" step="1" placeholder="اعشار" value="' + decimals + '" />' +
                '<label style="font-size:12px;"><input type="radio" name="gymai_primary_unit" class="unit-primary" ' + (isPrimary ? 'checked' : '') + ' /> پیش‌فرض</label>' +
                '<button type="button" class="button button-link-delete" onclick="gymaiRemoveUnitRow(this)">حذف</button>' +
                '<input type="text" class="unit-hint" placeholder="راهنما (مثلاً: یک تکه نان سنگک متوسط)" value="' + (hint || '') + '" style="grid-column:1/-1;margin-top:4px;" />';

            container.appendChild(row);

            var select = row.querySelector('.unit-key-select');
            if (key && select) {
                select.value = key;
            }
            gymaiBindUnitRowEvents(row);
            gymaiUpdateServingUnitsJSON();
        }

        function gymaiOnUnitKeyChange(selectEl) {
            var key = selectEl.value;
            var row = selectEl.closest('.unit-row');
            if (!row || !key || !gymaiFoodUnitCatalog[key]) return;
            var u = gymaiFoodUnitCatalog[key];
            row.querySelector('.unit-label').value = u.label;
            row.querySelector('.unit-grams').value = u.grams;
            row.querySelector('.unit-step').value = u.step;
            row.querySelector('.unit-decimals').value = u.decimals;
            gymaiUpdateServingUnitsJSON();
        }

        function gymaiRemoveUnitRow(btn) {
            var row = btn.closest('.unit-row');
            if (row) row.remove();
            gymaiUpdateServingUnitsJSON();
        }

        function gymaiBindUnitRowEvents(row) {
            row.querySelectorAll('input, select').forEach(function(el) {
                el.addEventListener('input', gymaiUpdateServingUnitsJSON);
                el.addEventListener('change', gymaiUpdateServingUnitsJSON);
            });
        }

        function gymaiUpdateServingUnitsJSON() {
            var rows = document.querySelectorAll('#gymai_serving_units_rows .unit-row');
            var units = [];
            var defaultUnit = 'gram';

            rows.forEach(function(row) {
                var keySelect = row.querySelector('.unit-key-select');
                var key = keySelect ? keySelect.value : '';
                if (!key) {
                    key = 'custom_' + Math.random().toString(36).slice(2, 8);
                }
                var label = row.querySelector('.unit-label').value.trim();
                var grams = parseFloat(row.querySelector('.unit-grams').value) || 0;
                var step = parseFloat(row.querySelector('.unit-step').value) || 1;
                var decimals = parseInt(row.querySelector('.unit-decimals').value, 10) || 0;
                var hint = row.querySelector('.unit-hint').value.trim();
                var isPrimary = row.querySelector('.unit-primary').checked;
                if (isPrimary) defaultUnit = key;
                if (grams <= 0 || !label) return;
                units.push({ key: key, label: label, grams: grams, step: step, decimals: decimals, is_primary: isPrimary, hint: hint });
            });

            if (units.length === 0) {
                units.push({ key: 'gram', label: 'گرم', grams: 1, step: 1, decimals: 0, is_primary: true, hint: '' });
                defaultUnit = 'gram';
            }

            var hasPrimary = units.some(function(u) { return u.is_primary; });
            if (!hasPrimary) {
                units[0].is_primary = true;
                defaultUnit = units[0].key;
            }

            var payload = { default_unit: defaultUnit, units: units };
            var jsonField = document.getElementById('serving_units_json');
            if (jsonField) jsonField.value = JSON.stringify(payload);
            var preview = document.getElementById('serving_units_preview');
            if (preview) preview.textContent = JSON.stringify(payload, null, 2);
            var defaultField = document.getElementById('default_serving_unit');
            if (defaultField) defaultField.value = defaultUnit;
        }

        function gymaiApplyUnitPreset(preset) {
            var container = gymaiGetUnitRowsContainer();
            if (!container) return;
            container.innerHTML = '';

            var presets = {
                bread: [
                    { key: 'piece', label: 'عدد (تکه)', grams: 35, step: 0.5, decimals: 1, is_primary: true, hint: 'یک تکه نان سنگک یا بربری متوسط' },
                    { key: 'palm_carb', label: 'کف دست (کربو)', grams: 20, step: 0.5, decimals: 1, hint: 'معادل یک واحد کربوهیدرات' },
                    { key: 'gram', label: 'گرم', grams: 1, step: 1, decimals: 0, hint: '' }
                ],
                rice: [
                    { key: 'tablespoon', label: 'قاشق غذاخوری', grams: 15, step: 0.5, decimals: 1, is_primary: true, hint: 'برنج پخته' },
                    { key: 'cup', label: 'پیمانه / لیوان', grams: 150, step: 0.5, decimals: 1, hint: 'لیوان برنج پخته' },
                    { key: 'palm_carb', label: 'کف دست (کربو)', grams: 20, step: 0.5, decimals: 1, hint: '' },
                    { key: 'gram', label: 'گرم', grams: 1, step: 1, decimals: 0, hint: '' }
                ],
                protein: [
                    { key: 'palm_protein', label: 'کف دست (پروتئین)', grams: 85, step: 0.5, decimals: 1, is_primary: true, hint: 'یک وعده پروتئین' },
                    { key: 'gram', label: 'گرم', grams: 1, step: 1, decimals: 0, hint: '' }
                ],
                vegetable: [
                    { key: 'fist', label: 'مشت', grams: 150, step: 0.5, decimals: 1, is_primary: true, hint: 'سبزیجات خام یا پخته' },
                    { key: 'gram', label: 'گرم', grams: 1, step: 1, decimals: 0, hint: '' }
                ],
                fat: [
                    { key: 'tablespoon', label: 'قاشق غذاخوری', grams: 14, step: 0.5, decimals: 1, is_primary: true, hint: 'روغن مایع' },
                    { key: 'teaspoon', label: 'قاشق چای‌خوری', grams: 5, step: 0.5, decimals: 1, hint: '' },
                    { key: 'thumb_fat', label: 'انگشت شست (چربی)', grams: 10, step: 0.5, decimals: 1, hint: '' },
                    { key: 'gram', label: 'گرم', grams: 1, step: 1, decimals: 0, hint: '' }
                ],
                fruit: [
                    { key: 'piece', label: 'عدد', grams: 120, step: 0.5, decimals: 1, is_primary: true, hint: 'یک عدد میوه متوسط' },
                    { key: 'fist', label: 'مشت', grams: 150, step: 0.5, decimals: 1, hint: '' },
                    { key: 'gram', label: 'گرم', grams: 1, step: 1, decimals: 0, hint: '' }
                ],
                liquid: [
                    { key: 'cup', label: 'لیوان', grams: 200, step: 0.5, decimals: 1, is_primary: true, hint: 'مایعات — ۱ گرم ≈ ۱ میلی‌لیتر' },
                    { key: 'ml', label: 'میلی‌لیتر', grams: 1, step: 10, decimals: 0, hint: '' },
                    { key: 'gram', label: 'گرم', grams: 1, step: 1, decimals: 0, hint: '' }
                ],
                supplement: [
                    { key: 'tablespoon', label: 'قاشق غذاخوری', grams: 10, step: 0.5, decimals: 1, is_primary: true, hint: 'پودر مکمل' },
                    { key: 'scoop', label: 'اسکوپ', grams: 30, step: 0.5, decimals: 1, hint: 'بسته‌بندی مکمل' },
                    { key: 'gram', label: 'گرم', grams: 1, step: 1, decimals: 0, hint: '' }
                ]
            };

            var list = presets[preset] || presets.protein;
            list.forEach(function(item) { gymaiAddUnitRow(item); });
        }

        function gymaiUpdateMealTimesHidden() {
            var checked = [];
            document.querySelectorAll('.meal-time-checkbox:checked').forEach(function(cb) {
                checked.push(cb.value);
            });
            var field = document.getElementById('meal_times');
            if (field) field.value = checked.join(',');
        }

        document.addEventListener('DOMContentLoaded', function() {
            var container = gymaiGetUnitRowsContainer();
            var existing = <?php echo wp_json_encode($serving_units, JSON_UNESCAPED_UNICODE); ?>;

            if (container) {
                if (existing.units && existing.units.length) {
                    existing.units.forEach(function(u) { gymaiAddUnitRow(u); });
                } else {
                    gymaiAddUnitRow({ key: 'gram', label: 'گرم', grams: 1, step: 1, decimals: 0, is_primary: true });
                }
            }

            document.querySelectorAll('.meal-time-checkbox').forEach(function(cb) {
                cb.addEventListener('change', gymaiUpdateMealTimesHidden);
            });
            gymaiUpdateMealTimesHidden();
            gymaiUpdateServingUnitsJSON();
        });
        </script>

        <div class="guide-box">
            <strong>راهنما:</strong> ارزش غذایی را بر اساس <em>۱۰۰ گرم</em> وارد کنید.
            در بخش «واحدهای سرو» معادل گرم هر واحد (عدد، قاشق، کف دست…) را تعریف کنید تا اپ بتواند
            برنامه غذایی بنویسد و لاگ کند. مثال: نان → عدد (۳۵ گرم) + کف دست (۲۰ گرم).
        </div>

        <!-- بخش ۱: اطلاعات پایه -->
        <div class="food-section">
            <div class="food-section-header" onclick="gymaiToggleFoodSection('basic')">📋 اطلاعات پایه</div>
            <div id="food-section-basic" class="food-section-content">
                <table class="food-table">
                    <tr>
                        <th><label for="name_app">نام در اپ</label></th>
                        <td>
                            <input type="text" id="name_app" name="name_app" value="<?php echo esc_attr($name_app); ?>" placeholder="اگر خالی باشد از عنوان پست استفاده می‌شود" />
                        </td>
                    </tr>
                    <tr>
                        <th><label for="other_names">نام‌های دیگر</label></th>
                        <td>
                            <input type="text" id="other_names" name="other_names" value="<?php echo esc_attr($other_names); ?>" placeholder="برای جستجو — با کاما جدا کنید" />
                        </td>
                    </tr>
                    <tr>
                        <th><label for="food_group">گروه غذایی</label></th>
                        <td>
                            <select id="food_group" name="food_group">
                                <option value="">— انتخاب —</option>
                                <?php foreach (gymai_food_group_options() as $val => $label) : ?>
                                    <option value="<?php echo esc_attr($val); ?>" <?php selected($food_group, $val); ?>><?php echo esc_html($label); ?></option>
                                <?php endforeach; ?>
                            </select>
                        </td>
                    </tr>
                    <tr>
                        <th><label for="food_type">نوع</label></th>
                        <td>
                            <select id="food_type" name="food_type">
                                <?php foreach (gymai_food_type_options() as $val => $label) : ?>
                                    <option value="<?php echo esc_attr($val); ?>" <?php selected($food_type, $val); ?>><?php echo esc_html($label); ?></option>
                                <?php endforeach; ?>
                            </select>
                        </td>
                    </tr>
                    <tr>
                        <th>وعده‌های پیشنهادی</th>
                        <td>
                            <?php foreach (gymai_food_meal_time_options() as $mt) : ?>
                                <label class="meal-chip">
                                    <input type="checkbox" class="meal-time-checkbox" value="<?php echo esc_attr($mt); ?>" <?php checked(in_array($mt, $meal_times_arr, true)); ?> />
                                    <?php echo esc_html($mt); ?>
                                </label>
                            <?php endforeach; ?>
                            <input type="hidden" id="meal_times" name="meal_times" value="<?php echo esc_attr($meal_times); ?>" />
                        </td>
                    </tr>
                    <tr>
                        <th><label for="sample_image_forapp">تصویر نمونه (URL)</label></th>
                        <td>
                            <input type="url" id="sample_image_forapp" name="sample_image_forapp" value="<?php echo esc_attr($sample_image_forapp); ?>" />
                            <p class="field-note">اگر تصویر شاخص نباشد، اپ از این URL استفاده می‌کند.</p>
                        </td>
                    </tr>
                </table>
            </div>
        </div>

        <!-- بخش ۲: ارزش غذایی -->
        <div class="food-section">
            <div class="food-section-header" onclick="gymaiToggleFoodSection('nutrition')">🔬 ارزش غذایی</div>
            <div id="food-section-nutrition" class="food-section-content">
                <table class="food-table">
                    <tr>
                        <th>مبنای محاسبه</th>
                        <td>
                            <select name="nutrition_basis">
                                <option value="per_100g" <?php selected($nutrition_basis, 'per_100g'); ?>>به ازای ۱۰۰ گرم (پیشنهادی)</option>
                                <option value="per_serving" <?php selected($nutrition_basis, 'per_serving'); ?>>به ازای یک سرو</option>
                            </select>
                            <input type="number" name="serving_size_grams" value="<?php echo esc_attr($serving_size_grams); ?>" min="1" step="1" style="width:120px;margin-top:8px;" placeholder="گرم سرو" />
                            <p class="field-note">اپ فعلاً بر ۱۰۰ گرم کار می‌کند؛ فیلد سرو برای آینده ذخیره می‌شود.</p>
                        </td>
                    </tr>
                </table>
                <div class="nutrition-grid">
                    <table class="food-table">
                        <tr><th>کالری (kcal)</th><td><input type="number" step="0.1" name="calories" value="<?php echo esc_attr($calories); ?>" /></td></tr>
                        <tr><th>پروتئین (g)</th><td><input type="number" step="0.1" name="protein" value="<?php echo esc_attr($protein); ?>" /></td></tr>
                        <tr><th>کربوهیدرات (g)</th><td><input type="number" step="0.1" name="carbohydrates" value="<?php echo esc_attr($carbohydrates); ?>" /></td></tr>
                    </table>
                    <table class="food-table">
                        <tr><th>چربی (g)</th><td><input type="number" step="0.1" name="fat" value="<?php echo esc_attr($fat); ?>" /></td></tr>
                        <tr><th>چربی اشباع (g)</th><td><input type="number" step="0.1" name="saturated_fat" value="<?php echo esc_attr($saturated_fat); ?>" /></td></tr>
                        <tr><th>فیبر (g)</th><td><input type="number" step="0.1" name="fiber" value="<?php echo esc_attr($fiber); ?>" /></td></tr>
                    </table>
                    <table class="food-table">
                        <tr><th>قند (g)</th><td><input type="number" step="0.1" name="sugar" value="<?php echo esc_attr($sugar); ?>" /></td></tr>
                        <tr><th>کلسترول (mg)</th><td><input type="number" step="0.1" name="cholesterol" value="<?php echo esc_attr($cholesterol); ?>" /></td></tr>
                        <tr><th>سدیم (mg)</th><td><input type="number" step="0.1" name="sodium" value="<?php echo esc_attr($sodium); ?>" /></td></tr>
                        <tr><th>پتاسیم (mg)</th><td><input type="number" step="0.1" name="potassium" value="<?php echo esc_attr($potassium); ?>" /></td></tr>
                    </table>
                </div>
                <table class="food-table" style="margin-top:12px;">
                    <tr>
                        <th><label for="glycemic_index">شاخص گلیسمی (GI)</label></th>
                        <td><input type="number" id="glycemic_index" name="glycemic_index" min="0" max="100" value="<?php echo esc_attr($glycemic_index); ?>" /></td>
                    </tr>
                    <tr>
                        <th><label for="allergens">آلرژن‌ها</label></th>
                        <td><input type="text" id="allergens" name="allergens" value="<?php echo esc_attr($allergens); ?>" placeholder="گلوتن، لبنیات، آجیل…" /></td>
                    </tr>
                </table>
            </div>
        </div>

        <!-- بخش ۳: واحدهای سرو — قلب سیستم برنامه غذایی -->
        <div class="food-section">
            <div class="food-section-header" onclick="gymaiToggleFoodSection('units')">⚖️ واحدهای سرو و اندازه‌گیری</div>
            <div id="food-section-units" class="food-section-content">
                <p>
                    <strong>پیش‌تنظیم سریع:</strong>
                    <button type="button" class="button preset-btn" onclick="gymaiApplyUnitPreset('bread')">نان</button>
                    <button type="button" class="button preset-btn" onclick="gymaiApplyUnitPreset('rice')">برنج</button>
                    <button type="button" class="button preset-btn" onclick="gymaiApplyUnitPreset('protein')">پروتئین</button>
                    <button type="button" class="button preset-btn" onclick="gymaiApplyUnitPreset('vegetable')">سبزی</button>
                    <button type="button" class="button preset-btn" onclick="gymaiApplyUnitPreset('fat')">چربی</button>
                    <button type="button" class="button preset-btn" onclick="gymaiApplyUnitPreset('fruit')">میوه</button>
                    <button type="button" class="button preset-btn" onclick="gymaiApplyUnitPreset('liquid')">مایع</button>
                    <button type="button" class="button preset-btn" onclick="gymaiApplyUnitPreset('supplement')">مکمل</button>
                    <button type="button" class="button button-primary preset-btn" onclick="gymaiAddUnitRow()">+ واحد جدید</button>
                </p>
                <div class="unit-builder">
                    <div id="gymai_serving_units_rows"></div>
                </div>
                <input type="hidden" id="serving_units_json" name="serving_units_json" value="<?php echo esc_attr($serving_units_json); ?>" />
                <input type="hidden" id="default_serving_unit" name="default_serving_unit" value="<?php echo esc_attr($default_serving_unit); ?>" />
                <div class="json-preview"><strong>serving_units_json:</strong><pre id="serving_units_preview"></pre></div>
                <table class="food-table" style="margin-top:12px;">
                    <tr>
                        <th><label for="serving_notes">یادداشت سرو</label></th>
                        <td>
                            <textarea id="serving_notes" name="serving_notes" rows="3" placeholder="مثلاً: برنج باید پخته باشد؛ نان را بدون روغن در نظر بگیرید"><?php echo esc_textarea($serving_notes); ?></textarea>
                        </td>
                    </tr>
                </table>
            </div>
        </div>

        <!-- بخش ۴: اپلیکیشن -->
        <div class="food-section">
            <div class="food-section-header" onclick="gymaiToggleFoodSection('app')">📱 اپلیکیشن و راهنما</div>
            <div id="food-section-app" class="food-section-content">
                <table class="food-table">
                    <tr>
                        <th><label for="short_description">توضیح کوتاه</label></th>
                        <td><textarea id="short_description" name="short_description" rows="3"><?php echo esc_textarea($short_description); ?></textarea></td>
                    </tr>
                    <tr>
                        <th><label for="tip_1">نکته ۱</label></th>
                        <td><textarea id="tip_1" name="tip_1" rows="2"><?php echo esc_textarea($tip_1); ?></textarea></td>
                    </tr>
                    <tr>
                        <th><label for="tip_2">نکته ۲</label></th>
                        <td><textarea id="tip_2" name="tip_2" rows="2"><?php echo esc_textarea($tip_2); ?></textarea></td>
                    </tr>
                    <tr>
                        <th><label for="tip_3">نکته ۳</label></th>
                        <td><textarea id="tip_3" name="tip_3" rows="2"><?php echo esc_textarea($tip_3); ?></textarea></td>
                    </tr>
                    <tr>
                        <th><label for="substitutes_json">جایگزین‌ها (JSON)</label></th>
                        <td>
                            <textarea id="substitutes_json" name="substitutes_json" rows="4" placeholder='[{"food_id":123,"ratio":1},{"food_id":456,"ratio":0.8}]'><?php echo esc_textarea($substitutes_json); ?></textarea>
                            <p class="field-note">food_id وردپرس + نسبت جایگزینی (۱ = معادل کامل)</p>
                        </td>
                    </tr>
                </table>
            </div>
        </div>

        <!-- بخش ۵: آمار -->
        <div class="food-section">
            <div class="food-section-header" onclick="gymaiToggleFoodSection('stats')">📊 آمار</div>
            <div id="food-section-stats" class="food-section-content">
                <table class="food-table">
                    <tr>
                        <th>بازدید / لایک</th>
                        <td>
                            <input type="number" name="views_count" value="<?php echo esc_attr($views_count); ?>" readonly style="width:48%;display:inline-block;" />
                            <input type="number" name="likes_count" value="<?php echo esc_attr($likes_count); ?>" readonly style="width:48%;display:inline-block;" />
                        </td>
                    </tr>
                </table>
            </div>
        </div>
        <?php
    }
}
if (!function_exists('gymai_save_food_meta_box')) {
    add_action('save_post_foods', 'gymai_save_food_meta_box', 10, 3);
    function gymai_save_food_meta_box($post_id, $post, $update) {
        if (!isset($_POST['food_meta_box_nonce'])) {
            return;
        }
        if (!wp_verify_nonce(sanitize_text_field(wp_unslash($_POST['food_meta_box_nonce'])), 'food_meta_box')) {
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

        $textarea_fields = array(
            'short_description', 'serving_notes', 'tip_1', 'tip_2', 'tip_3',
        );
        $text_fields = array(
            'name_app', 'other_names', 'food_group', 'food_type', 'meal_times',
            'nutrition_basis', 'allergens', 'default_serving_unit', 'sample_image_forapp',
        );
        $number_fields = array(
            'protein', 'calories', 'carbohydrates', 'fat', 'saturated_fat', 'fiber',
            'sugar', 'cholesterol', 'sodium', 'potassium', 'glycemic_index',
            'serving_size_grams', 'views_count', 'likes_count',
        );
        $json_fields = array('serving_units_json', 'substitutes_json');

        foreach ($textarea_fields as $field) {
            if (!array_key_exists($field, $_POST)) {
                continue;
            }
            update_post_meta($post_id, $field, sanitize_textarea_field(wp_unslash($_POST[$field])));
        }

        foreach ($text_fields as $field) {
            if (!array_key_exists($field, $_POST)) {
                continue;
            }
            update_post_meta($post_id, $field, sanitize_text_field(wp_unslash($_POST[$field])));
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

        foreach ($json_fields as $field) {
            if (!array_key_exists($field, $_POST)) {
                continue;
            }
            $decoded = json_decode(wp_unslash($_POST[$field]), true);
            if (is_array($decoded)) {
                update_post_meta(
                    $post_id,
                    $field,
                    wp_json_encode($decoded, JSON_UNESCAPED_UNICODE)
                );
            }
        }

        update_post_meta($post_id, '_gymai_food_meta_saved', (string) time());
    }
}
