// GymAI Foods — CORE (موتور seed + منوی batch)
// Code Snippets: Run everywhere | بدون تگ php
// ترتیب: 1) CORE  2) BATCH1  3) BATCH2 ...

if (!defined('GYMAI_FOOD_POST_TYPE')) {
    define('GYMAI_FOOD_POST_TYPE', 'foods');
}



if (!function_exists('gymai_food_latin_digits')) {
    function gymai_food_latin_digits($text) {
        $map = ['۰' => '0', '۱' => '1', '۲' => '2', '۳' => '3', '۴' => '4', '۵' => '5', '۶' => '6', '۷' => '7', '۸' => '8', '۹' => '9'];
        return strtr((string) $text, $map);
    }
}

if (!function_exists('gymai_food_slug_from_keyword')) {
    function gymai_food_slug_from_keyword($keyword) {
        $keyword = trim((string) $keyword);
        if ($keyword === '') {
            return '';
        }
        $slug = preg_replace('/\s+/u', '-', $keyword);
        $slug = preg_replace('/-+/u', '-', $slug);
        return trim($slug, '-');
    }
}

if (!function_exists('gymai_food_normalize_slug')) {
    function gymai_food_normalize_slug($slug) {
        $slug = trim((string) $slug);
        if ($slug === '') {
            return '';
        }
        if (preg_match('/^[\p{L}\p{M}\p{N}_\x{200C}-]+$/u', $slug)) {
            return $slug;
        }
        return sanitize_title($slug);
    }
}

if (!function_exists('gymai_food_resolve_post_slug')) {
    function gymai_food_resolve_post_slug(array $row) {
        $keyword = $row['rank_math_focus_keyword'] ?? ($row['title'] ?? '');
        $slug = gymai_food_slug_from_keyword($keyword);
        if ($slug !== '') {
            return gymai_food_normalize_slug($slug);
        }
        return gymai_food_normalize_slug($row['slug'] ?? '');
    }
}

if (!function_exists('gymai_food_public_url')) {
    function gymai_food_public_url($slug) {
        if (!function_exists('home_url')) {
            return '';
        }
        $slug = gymai_food_normalize_slug($slug);
        if ($slug === '') {
            return '';
        }
        return user_trailingslashit(home_url('/' . GYMAI_FOOD_POST_TYPE . '/' . $slug));
    }
}

if (!function_exists('gymai_food_build_slug_urls')) {
    function gymai_food_build_slug_urls(array $dataset, array $slug_to_id = []) {
        $urls = [];
        foreach ($dataset as $row) {
            $slug = gymai_food_resolve_post_slug($row);
            if ($slug === '') {
                continue;
            }
            $url = '';
            if (!empty($slug_to_id[$slug])) {
                $permalink = get_permalink((int) $slug_to_id[$slug]);
                if ($permalink && !is_wp_error($permalink)) {
                    $url = $permalink;
                }
            }
            if ($url === '') {
                $url = gymai_food_public_url($slug);
            }
            $entry = [
                'url' => $url,
                'title' => $row['title'] ?? $slug,
            ];
            $urls[$slug] = $entry;
            $raw = trim((string) ($row['slug'] ?? ''));
            if ($raw !== '' && $raw !== $slug) {
                $urls[$raw] = $entry;
            }
        }
        foreach ($dataset as $row) {
            foreach ($row['related_slugs'] ?? [] as $rel_slug) {
                if (!is_string($rel_slug) || $rel_slug === '') {
                    continue;
                }
                $key = gymai_food_normalize_slug($rel_slug);
                if ($key !== '' && isset($urls[$key])) {
                    $urls[$rel_slug] = $urls[$key];
                }
            }
        }
        return $urls;
    }
}

if (!function_exists('gymai_food_seo_title')) {
    function gymai_food_seo_title(array $row) {
        $title = $row['title'] ?? '';
        $cal = gymai_food_latin_digits($row['calories'] ?? '0');
        $pro = gymai_food_latin_digits($row['protein'] ?? '0');
        return $title . ' | ' . $cal . ' کالری و ' . $pro . ' گرم پروتئین در 100 گرم | GymAI Pro';
    }
}

if (!function_exists('gymai_food_seo_description')) {
    function gymai_food_seo_description(array $row) {
        $title = $row['title'] ?? '';
        $cal = gymai_food_latin_digits($row['calories'] ?? '0');
        $pro = gymai_food_latin_digits($row['protein'] ?? '0');
        $carb = gymai_food_latin_digits($row['carbohydrates'] ?? '0');
        $group = $row['food_group'] ?? '';
        return sprintf(
            'مرجع علمی %s: جدول ماکرونوترینت در ۱۰۰ گرم (%s kcal، %s گرم پروتئین، %s گرم کربوهیدرات)، شاخص گلیسمی، واحد سرو و کاربرد در تغذیه ورزشی — گروه %s.',
            $title,
            $cal,
            $pro,
            $carb,
            $group
        );
    }
}

if (!function_exists('gymai_food_group_science_paragraph')) {
    function gymai_food_group_science_paragraph($food_group, $kw) {
        $map = [
            'کربوهیدرات' => 'منابع کربوهیدراتی نقش مستقیمی در تأمین گلیکوژن عضلانی، پایداری قند خون و عملکرد در تمرینات مقاومتی دارند. شاخص گلیسمی (GI) و میزان فیبر دو شاخص کلیدی برای مقایسه کیفیت انرژی هستند.',
            'پروتئین' => 'پروتئین‌های با کیفیت بالا در سنتز پروتئین عضلانی (MPS)، ریکاوری و حفظ توده بدون چربی اهمیت دارند. پروفایل آمینواسیدی و میزان چربی همراه، انتخاب منبع را در رژیم ورزشی تعیین می‌کند.',
            'لبنیات' => 'فرآورده‌های لبنی منبع کلسیم، فسفر و پروتئین با جذب مناسب هستند. ترکیب کازئین و وی در برخی محصولات، آن‌ها را برای وعده‌های مختلف روز قابل برنامه‌ریزی می‌کند.',
            'چربی' => 'چربی‌های غذایی منبع انرژی پرتراکم، اسیدهای چرب ضروری و حامل ویتامین‌های محلول در چربی (A, D, E, K) هستند. نوع چربی (اشباع در مقابل غیراشباع) در سلامت متابولیک اهمیت دارد.',
            'حبوبات' => 'حبوبات ترکیبی از پروتئین گیاهی، فیبر محلول و نشاسته مقاوم ارائه می‌دهند. GI معمولاً پایین‌تر از غلات تصفیه‌شده است و برای سیری طولانی‌مدت مناسب‌اند.',
            'سبزیجات' => 'سبزیجات حجم غذایی با کالری پایین، فیبر، ویتامین‌ها و مواد معدنی فراهم می‌کنند. در کنترل اشتها و ترکیب وعده‌های متعادل نقش مهمی دارند.',
            'میوه' => 'میوه‌ها منبع کربوهیدرات طبیعی، فیبر و آنتی‌اکسیدان هستند. زمان‌بندی مصرف نسبت به هدف (کسری یا مازاد انرژی) در برنامه ورزشی اهمیت دارد.',
            'غذای آماده' => 'غذاهای آماده ایرانی اغلب ترکیبی از کربوهیدرات، پروتئین و چربی هستند؛ تحلیل ماکرو باید با در نظر گرفتن مواد همراه (برنج، روغن، نان) انجام شود.',
        ];
        $base = $map[$food_group] ?? 'ارزیابی علمی هر ماده غذایی بر اساس داده‌های استاندارد در هر ۱۰۰ گرم قابل خوراک و منابع معتبر تغذیه‌ای انجام می‌شود.';
        return $base . ' در ادامه، ' . $kw . ' را با نگاه تغذیه ورزشی و شواهد عملی مرور می‌کنیم.';
    }
}

if (!function_exists('gymai_food_gi_commentary')) {
    function gymai_food_gi_commentary($gi, $food_group) {
        $gi = gymai_food_latin_digits((string) $gi);
        if ($gi === '' || $gi === '0') {
            return 'این ماده غذایی منبع اصلی انرژی از ماکروی غیرکربوهیدراتی است؛ پاسخ گلیسمی معمولاً ناچیز تلقی می‌شود.';
        }
        $n = (int) $gi;
        if ($n >= 70) {
            return 'شاخص گلیسمی بالا (' . $gi . ') نشان می‌دهد پاسخ قند خون سریع‌تر است؛ زمان‌بندی مصرف (مثلاً نزدیک پایان تمرین) در برنامه‌ریزی اهمیت دارد.';
        }
        if ($n >= 56) {
            return 'شاخص گلیسمی متوسط (' . $gi . ') تعادلی بین آزادسازی انرژی و پایداری قند خون ایجاد می‌کند.';
        }
        return 'شاخص گلیسمی پایین (' . $gi . ') برای کنترل اشتها و پایداری انرژی در وعده‌های اصلی مفید است.';
    }
}

if (!function_exists('gymai_food_external_links')) {
    function gymai_food_external_links(array $row) {
        $group = $row['food_group'] ?? '';
        $links = [
            ['https://fdc.nal.usda.gov/', 'USDA FoodData Central'],
            ['https://www.nutrition.gov/topics/basic-nutrition', 'Nutrition.gov — راهنمای تغذیه پایه'],
            ['https://pubmed.ncbi.nlm.nih.gov/?term=sports+nutrition', 'PubMed — تغذیه ورزشی'],
        ];
        $wiki = [
            'کربوهیدرات' => ['https://en.wikipedia.org/wiki/Carbohydrate', 'ویکی‌پدیا — Carbohydrate'],
            'پروتئین' => ['https://en.wikipedia.org/wiki/Dietary_protein', 'ویکی‌پدیا — Dietary protein'],
            'چربی' => ['https://en.wikipedia.org/wiki/Dietary_fat', 'ویکی‌پدیا — Dietary fat'],
            'لبنیات' => ['https://en.wikipedia.org/wiki/Yogurt', 'ویکی‌پدیا — Yogurt'],
            'حبوبات' => ['https://en.wikipedia.org/wiki/Legume', 'ویکی‌پدیا — Legume'],
        ];
        if (isset($wiki[$group])) {
            $links[] = $wiki[$group];
        }
        if (!empty($row['aliases_en'][0])) {
            $term = rawurlencode($row['aliases_en'][0]);
            $links[] = ['https://pubmed.ncbi.nlm.nih.gov/?term=' . $term, 'PubMed — ' . $row['aliases_en'][0]];
        }
        return $links;
    }
}

if (!function_exists('gymai_food_normalize_serving_units')) {
    function gymai_food_normalize_serving_units(array $serving_units) {
        if (empty($serving_units['units']) || !is_array($serving_units['units'])) {
            return $serving_units;
        }
        $allowed = [1, 0.5, 0.1, 10];
        foreach ($serving_units['units'] as &$u) {
            if (!is_array($u)) {
                continue;
            }
            $step = isset($u['step']) ? (float) $u['step'] : 1.0;
            if ($step === 0.25 || !in_array($step, $allowed, true)) {
                $u['step'] = $step <= 0.75 ? 0.5 : 1.0;
            }
            if (!empty($u['decimals']) && (int) $u['decimals'] > 1 && (float) $u['step'] >= 0.5) {
                $u['decimals'] = 1;
            }
        }
        unset($u);
        return $serving_units;
    }
}

if (!function_exists('gymai_food_units_summary')) {
    function gymai_food_units_summary(array $row) {
        $units = $row['serving_units']['units'] ?? [];
        $parts = [];
        foreach ($units as $u) {
            if (empty($u['label']) || empty($u['grams'])) {
                continue;
            }
            $parts[] = $u['label'] . ' (~' . gymai_food_latin_digits((string) $u['grams']) . ' گرم)';
        }
        return implode('، ', array_slice($parts, 0, 4));
    }
}

if (!function_exists('gymai_food_title_for_slug')) {
    function gymai_food_title_for_slug($slug) {
        $slug = gymai_food_normalize_slug($slug);
        if ($slug === '') {
            return '';
        }
        foreach (gymai_food_collect_all_seed_rows() as $row) {
            $row_slug = gymai_food_resolve_post_slug($row);
            if ($row_slug === $slug) {
                return (string) ($row['title'] ?? $slug);
            }
        }
        return '';
    }
}

if (!function_exists('gymai_food_lookup_url_by_slug')) {
    function gymai_food_lookup_url_by_slug($slug) {
        $slug = gymai_food_normalize_slug($slug);
        if ($slug === '') {
            return null;
        }
        $post_id = gymai_food_find_existing_post_id($slug, $slug, '');
        if ($post_id > 0) {
            $permalink = get_permalink($post_id);
            if ($permalink && !is_wp_error($permalink)) {
                return [
                    'url' => $permalink,
                    'title' => get_the_title($post_id) ?: $slug,
                ];
            }
        }
        $url = gymai_food_public_url($slug);
        if ($url === '') {
            return null;
        }
        $title = gymai_food_title_for_slug($slug);
        return [
            'url' => $url,
            'title' => $title !== '' ? $title : $slug,
        ];
    }
}

if (!function_exists('gymai_food_resolve_slug_url_entry')) {
    function gymai_food_resolve_slug_url_entry($rel_slug, array $slug_urls) {
        $rel_slug = trim((string) $rel_slug);
        if ($rel_slug === '') {
            return null;
        }
        if (!empty($slug_urls[$rel_slug])) {
            return $slug_urls[$rel_slug];
        }
        $key = gymai_food_normalize_slug($rel_slug);
        if ($key !== '' && !empty($slug_urls[$key])) {
            return $slug_urls[$key];
        }
        return gymai_food_lookup_url_by_slug($key !== '' ? $key : $rel_slug);
    }
}

if (!function_exists('gymai_food_collect_all_seed_rows')) {
    function gymai_food_collect_all_seed_rows() {
        static $cache = null;
        if ($cache !== null) {
            return $cache;
        }
        if (function_exists('gymai_food_load_batch_files')) {
            gymai_food_load_batch_files();
        }
        $max = function_exists('gymai_food_max_batches') ? gymai_food_max_batches() : 20;
        $rows = [];
        $seen = [];
        for ($n = 1; $n <= $max; $n++) {
            $func = 'gymai_food_batch' . $n . '_definitions';
            if (!function_exists($func)) {
                continue;
            }
            $batch = call_user_func($func);
            if (!is_array($batch)) {
                continue;
            }
            foreach ($batch as $row) {
                if (!is_array($row)) {
                    continue;
                }
                $slug = gymai_food_resolve_post_slug($row);
                if ($slug === '' || isset($seen[$slug])) {
                    continue;
                }
                $seen[$slug] = true;
                $rows[] = $row;
            }
        }
        $cache = $rows;
        return $cache;
    }
}

if (!function_exists('gymai_food_merge_dataset_rows')) {
    function gymai_food_merge_dataset_rows(array $base, array $override) {
        $map = [];
        foreach ($base as $row) {
            if (!is_array($row)) {
                continue;
            }
            $slug = gymai_food_resolve_post_slug($row);
            if ($slug !== '') {
                $map[$slug] = $row;
            }
        }
        foreach ($override as $row) {
            if (!is_array($row)) {
                continue;
            }
            $slug = gymai_food_resolve_post_slug($row);
            if ($slug !== '') {
                $map[$slug] = $row;
            }
        }
        return array_values($map);
    }
}

if (!function_exists('gymai_food_extend_slug_to_id')) {
    function gymai_food_extend_slug_to_id(array $rows, array $slug_to_id) {
        $map = $slug_to_id;
        foreach ($rows as $row) {
            if (!is_array($row)) {
                continue;
            }
            $slug = gymai_food_resolve_post_slug($row);
            if ($slug === '' || isset($map[$slug])) {
                continue;
            }
            $legacy = gymai_food_normalize_slug($row['legacy_slug'] ?? '');
            $old_slug = gymai_food_normalize_slug($row['slug'] ?? '');
            $title = $row['title'] ?? $slug;
            $migrate = is_array($row['migrate_slugs'] ?? null) ? $row['migrate_slugs'] : [];
            $post_id = gymai_food_find_existing_post_id($slug, $legacy, $title, array_merge([$old_slug], $migrate));
            if ($post_id > 0) {
                $map[$slug] = $post_id;
            }
        }
        return $map;
    }
}

if (!function_exists('gymai_food_internal_links_html')) {
    function gymai_food_internal_links_html(array $row, array $slug_urls) {
        $related = $row['related_slugs'] ?? [];
        if (!is_array($related) || empty($related)) {
            return '<li>سایر خوراکی‌های پایگاه GymAI را از بخش خوراکی‌ها ببینید.</li>';
        }
        $html = '';
        foreach ($related as $rel_slug) {
            $entry = gymai_food_resolve_slug_url_entry($rel_slug, $slug_urls);
            if ($entry === null) {
                continue;
            }
            $html .= '<li><strong>' . esc_html($entry['title']) . '</strong> — <a href="' . esc_url($entry['url']) . '">مشاهده راهنمای ' . esc_html($entry['title']) . '</a></li>';
        }
        return $html !== '' ? $html : '<li>لیست کامل خوراکی‌ها در آرشیو GymAI Pro</li>';
    }
}

if (!function_exists('gymai_food_inline_internal_links_html')) {
    function gymai_food_inline_internal_links_html(array $row, array $slug_urls) {
        $related = $row['related_slugs'] ?? [];
        if (!is_array($related) || empty($related)) {
            return '';
        }
        $parts = [];
        foreach (array_slice($related, 0, 2) as $rel_slug) {
            $entry = gymai_food_resolve_slug_url_entry($rel_slug, $slug_urls);
            if ($entry === null) {
                continue;
            }
            $parts[] = '<a href="' . esc_url($entry['url']) . '">' . esc_html($entry['title']) . '</a>';
        }
        if (empty($parts)) {
            return '';
        }
        return ' برای وعده متعادل، ' . implode(' و ', $parts) . ' را هم در برنامه غذایی ببینید.';
    }
}

if (!function_exists('gymai_food_render_seo_html')) {
    function gymai_food_render_seo_html(array $row, array $slug_urls) {
        $kw = $row['rank_math_focus_keyword'] ?? ($row['title'] ?? '');
        $name = $row['name_app'] ?? $row['title'] ?? '';
        $cal = gymai_food_latin_digits($row['calories'] ?? '0');
        $pro = gymai_food_latin_digits($row['protein'] ?? '0');
        $carb = gymai_food_latin_digits($row['carbohydrates'] ?? '0');
        $fat = gymai_food_latin_digits($row['fat'] ?? '0');
        $fiber = gymai_food_latin_digits($row['fiber'] ?? '0');
        $gi = gymai_food_latin_digits($row['glycemic_index'] ?? '');
        $short = esc_html($row['short_description'] ?? '');
        $serving = esc_html($row['serving_notes'] ?? '');
        $tip1 = esc_html($row['tip_1'] ?? '');
        $tip2 = esc_html($row['tip_2'] ?? '');
        $tip3 = esc_html($row['tip_3'] ?? '');
        $group = esc_html($row['food_group'] ?? '');
        $meal_times = esc_html(str_replace(',', '، ', (string) ($row['meal_times'] ?? '')));
        $units = esc_html(gymai_food_units_summary($row));
        $aliases = esc_html($row['other_names'] ?? '');
        $alias_en = esc_html(!empty($row['aliases_en'][0]) ? $row['aliases_en'][0] : $name);
        $img = esc_url($row['image_url'] ?? '');
        $img_alt = 'تصویر ' . $kw . ' — ارزش غذایی و واحد سرو';
        $slug = $row['slug'] ?? '';
        $inline_internal = gymai_food_inline_internal_links_html($row, $slug_urls);

        $gi_row = ($gi !== '' && $gi !== '0')
            ? '<tr><td>شاخص گلیسمی (GI)</td><td>' . $gi . '</td></tr>'
            : '';

        $external_html = '';
        foreach (gymai_food_external_links($row) as $link) {
            $external_html .= '<a href="' . esc_url($link[0]) . '" target="_blank" rel="dofollow noopener">' . esc_html($link[1]) . '</a> | ';
        }
        $external_html = rtrim($external_html, ' | ');

        $internal_html = gymai_food_internal_links_html($row, $slug_urls);

        $intro = !empty($row['intro'])
            ? esc_html($row['intro'])
            : 'این راهنما بخشی از مرجع تغذیه ورزشی GymAI Pro است و داده‌های استاندارد هر ۱۰۰ گرم را برای مقایسه علمی ارائه می‌دهد.';

        $kw_html = esc_html($kw);
        $science = esc_html(gymai_food_group_science_paragraph($row['food_group'] ?? '', $kw));
        $gi_note = esc_html(gymai_food_gi_commentary($gi, $row['food_group'] ?? ''));

        return '<!-- GymAI Food SEO ' . esc_html($slug) . ' -->
    <h1>راهنمای علمی: ' . $kw_html . '</h1>
    <p>' . $intro . ' ' . $science . $inline_internal . '</p>
    <p>داده‌های جدول زیر بر مبنای <strong>۱۰۰ گرم</strong> قابل خوراک (بدون افزودنی غیرضروری) و منابع مرجع تغذیه‌ای است. این مطلب برای ورزشکاران، مربیان تغذیه و علاقه‌مندان به تغذیه سالم نوشته شده است.</p>
    <p>نام‌های رایج در ایران: ' . $aliases . ' — در ادبیات بین‌المللی معمولاً با عنوان <em>' . $alias_en . '</em> شناخته می‌شود.</p>

    <figure class="wp-block-image size-large"><img src="' . $img . '" alt="' . esc_attr($img_alt) . '" width="800" height="533" loading="lazy" /><figcaption>نمونه بصری ' . esc_html($name) . ' — ارزش‌های جدول برای حالت استاندارد آماده‌سازی</figcaption></figure>

    <div style="border-radius:10px;background:#f8f9fa;padding:15px;margin:20px 0;">
    <h2>جدول ارزش غذایی ' . $kw_html . ' (۱۰۰ گرم)</h2>
    <table class="wp-block-table"><tbody>
    <tr><td>کالری (انرژی)</td><td><strong>' . $cal . ' kcal</strong></td></tr>
    <tr><td>پروتئین</td><td>' . $pro . ' گرم</td></tr>
    <tr><td>کربوهیدرات</td><td>' . $carb . ' گرم</td></tr>
    <tr><td>چربی کل</td><td>' . $fat . ' گرم</td></tr>
    <tr><td>فیبر غذایی</td><td>' . $fiber . ' گرم</td></tr>
    ' . $gi_row . '
    <tr><td>گروه تغذیه‌ای</td><td>' . $group . '</td></tr>
    <tr><td>وعده‌های رایج</td><td>' . $meal_times . '</td></tr>
    </tbody></table>
    <p>' . $gi_note . '</p>
    </div>

    <h2>ترکیبات و اهمیت تغذیه‌ای</h2>
    <p>' . $short . '</p>
    <p>در برنامه‌های حجم، تعریف یا نگهداری، این ماده در گروه <strong>' . $group . '</strong> قرار می‌گیرد و بسته به هدف متابولیک (کسری، تعادل یا مازاد انرژی) جایگاه متفاوتی در سبد روزانه دارد. ترکیب همزمان با پروتئین و چربی سالم می‌تواند پروفایل گلیسمی و سیری وعده را بهبود دهد.</p>

    <h2>زمان‌بندی مصرف در طول روز</h2>
    <p>بسته به هدف تمرینی، وعده‌های پیشنهادی معمولاً شامل ' . $meal_times . ' است. در روزهای تمرین، توزیع انرژی نزدیک جلسه؛ در روزهای استراحت، تطبیق حجم با کل کالری روزانه اصول رایج برنامه‌ریزی هستند.</p>
    <ul>
    <li><strong>روز تمرین:</strong> تأمین انرژی و ریکاوری متناسب با شدت جلسه</li>
    <li><strong>روز استراحت:</strong> تنظیم حجم بر اساس نیاز واقعی، نه عادت</li>
    <li><strong>میان‌وعده:</strong> ترکیب با پروتئین یا فیبر برای پایداری قند خون</li>
    </ul>

    <h2>اصول اندازه‌گیری و واحد سرو</h2>
    <p>' . $serving . '</p>
    <p>برای تبدیل دقیق به گرم، واحدهای رایج عبارت‌اند از: <strong>' . $units . '</strong>. در پژوهش‌های تغذیه‌ای و برنامه‌های حرفه‌ای، وزن‌کشی آشپزخانه دقیق‌ترین روش است؛ در زندگی روزمره، واحدهای بصری (قاشق، عدد، کف دست) قابلیت پایبندی بیشتری دارند.</p>

    <h2>کاربرد در تغذیه ورزشی و بدنسازی</h2>
    <p>مربیان تغذیه معمولاً این منبع را در کنار سایر ماکروها می‌چینند تا تعادل انرژی، ریکاوری و ترکیب بدن حفظ شود. ' . $kw_html . ' به‌تنهایی «رژیم کامل» نیست؛ بخشی از الگوی غذایی متنوع است که باید با نیاز فردی، آلرژی‌ها و ترجیحات فرهنگی تطبیق داده شود.</p>

    <h2>نکات کاربردی (مبتنی بر تجربه مربیان)</h2>
    <ol>
    <li>' . $tip1 . '</li>
    <li>' . $tip2 . '</li>
    <li>' . $tip3 . '</li>
    </ol>

    <h2>ترکیب با سایر منابع غذایی</h2>
    <ul>' . $internal_html . '</ul>
    <p>وعده‌های متعادل اغلب ترکیبی از کربوهیدرات، پروتئین و چربی باکیفیت هستند. مطالعه راهنمای خوراکی‌های مرتبط در ادامه، به ساخت وعده‌های کامل‌تر کمک می‌کند.</p>

    <h2>مقایسه با جایگزین‌های رایج</h2>
    <p>هیچ ماده غذایی به‌تنهایی برتر مطلق نیست؛ انتخاب به دسترسی، بودجه، هدف تمرینی و تحمل گوارشی بستگی دارد. در برنامه‌های حرفه‌ای، جایگزینی با نسبت تبدیل مشابه (کالری و پروتئین معادل) رایج است.</p>
    <p>در صورت حساسیت غذایی یا بیماری متابولیک، با متخصص تغذیه یا پزشک مشورت کنید.</p>

    <h2>پرسش‌های متداول</h2>
    <div style="border-radius:8px;background:#f0fdf4;padding:15px;">
    <h3>هر ۱۰۰ گرم چند کیلوکالری انرژی دارد؟</h3>
    <p>حدود <strong>' . $cal . ' kcal</strong>. مقدار واقعی وعده به روش آماده‌سازی و اندازه سرو (گرم، قاشق، عدد) بستگی دارد.</p>
    <h4>نکته علمی در تفسیر داده‌ها</h4>
    <p>ارزش‌های جدول برای نمونه استاندارد (بدون روغن، سس یا شکر افزوده زیاد) گزارش شده‌اند. افزودنی‌ها می‌توانند کالری و چربی را به‌طور قابل توجهی تغییر دهند.</p>
    <h3>آیا برای عضله‌سازی مناسب است؟</h3>
    <p>با ' . $pro . ' گرم پروتئین در هر ۱۰۰ گرم و پروفایل ماکرو گروه ' . $group . '، در برنامه حجم یا نگهداری — در کنار منابع پروتئینی کافی در کل روز — قابل استفاده است.</p>
    <h3>تفاوت با نسخه‌های صنعتی یا آماده چیست؟</h3>
    <p>محصولات فرآوری‌شده ممکن است نمک، قند، چربی ترانس یا افزودنی متفاوت داشته باشند. همیشه برچسب ارزش غذایی را با داده‌های این جدول مقایسه کنید.</p>
    </div>

    <h2>جمع‌بندی</h2>
    <p>' . $short . '</p>
    <p>خلاصه عددی: <strong>' . $cal . ' kcal</strong>، <strong>' . $pro . ' گرم پروتئین</strong>، واحدهای رایج سرو (' . $units . '). ' . $kw_html . ' گزینه‌ای شناخته‌شده در تغذیه ورزشی ایرانی است که با برنامه‌ریزی صحیح می‌تواند در سبد غذایی سالم جایگاه پایدار داشته باشد.</p>

    <div style="background:#f5f5f5;padding:15px;border-radius:10px;margin:30px 0;">
    <h3>منابع علمی و مطالعه بیشتر</h3>
    <p><strong>پایگاه‌های مرجع (DoFollow):</strong> ' . $external_html . '</p>
    <p style="font-size:0.95em;color:#555;margin-top:12px;">ابزار GymAI Pro: برای محاسبه خودکار ماکرو بر اساس واحد سرو — مکمل این مرجع علمی، نه جایگزین مشاوره تخصصی.</p>
    </div>';
    }
}

if (!function_exists('gymai_food_apply_rank_math')) {
    function gymai_food_apply_rank_math($post_id, array $row, $slug) {
        $image = $row['image_url'] ?? '';
        $seo_title = gymai_food_seo_title($row);
        $desc = gymai_food_seo_description($row);
        $kw = $row['rank_math_focus_keyword'] ?? ($row['title'] ?? '');
        $canonical = gymai_food_public_url($slug);

        $rank = [
            'rank_math_title' => $seo_title,
            'rank_math_description' => $desc,
            'rank_math_focus_keyword' => $kw,
            'rank_math_canonical_url' => $canonical,
            'rank_math_facebook_title' => $seo_title,
            'rank_math_facebook_description' => $desc,
            'rank_math_facebook_image' => $image,
            'rank_math_twitter_title' => $seo_title,
            'rank_math_twitter_description' => $desc,
            'rank_math_twitter_image' => $image,
            'rank_math_robots' => ['index'],
            'rank_math_rich_snippet' => 'article',
            'rank_math_snippet_article_type' => 'BlogPosting',
            'rank_math_primary_category' => 'off',
            'rank_math_pillar_content' => 'off',
            'rank_math_breadcrumb_title' => $row['title'] ?? '',
        ];
        foreach ($rank as $key => $value) {
            update_post_meta($post_id, $key, $value);
        }
    }
}

if (!function_exists('gymai_food_find_existing_post_id')) {
    function gymai_food_find_existing_post_id($slug, $legacy_slug, $title, array $extra_slugs = []) {
        $candidates = array_filter(array_merge([$slug, $legacy_slug], $extra_slugs));
        foreach (array_unique($candidates) as $candidate) {
            $found = get_posts([
                'post_type' => GYMAI_FOOD_POST_TYPE,
                'name' => $candidate,
                'post_status' => 'any',
                'numberposts' => 1,
                'fields' => 'ids',
            ]);
            if (!empty($found)) {
                return (int) $found[0];
            }
        }
        global $wpdb;
        $id = $wpdb->get_var($wpdb->prepare(
            "SELECT ID FROM {$wpdb->posts} WHERE post_title = %s AND post_type = %s AND post_status != 'trash' LIMIT 1",
            $title,
            GYMAI_FOOD_POST_TYPE
        ));
        return $id ? (int) $id : 0;
    }
}

if (!function_exists('gymai_food_run_batch')) {
    function gymai_food_run_batch(array $dataset, $force_update = false) {
        if (empty($dataset)) {
            return ['created' => 0, 'updated' => 0, 'errors' => ['دیتاست خالی است.']];
        }
        $created = 0;
        $updated = 0;
        $errors = [];
        $slug_to_id = [];
        $rows_by_slug = [];
        $content_refresh = [];

        $meta_scalar = [
            'name_app', 'other_names', 'food_group', 'food_type', 'meal_times',
            'short_description', 'serving_notes', 'nutrition_basis', 'serving_size_grams',
            'default_serving_unit', 'allergens', 'glycemic_index', 'sample_image_forapp',
            'tip_1', 'tip_2', 'tip_3',
            'protein', 'calories', 'carbohydrates', 'fat', 'saturated_fat',
            'fiber', 'sugar', 'cholesterol', 'sodium', 'potassium',
        ];

        foreach ($dataset as $row) {
            $slug = gymai_food_resolve_post_slug($row);
            $legacy = gymai_food_normalize_slug($row['legacy_slug'] ?? '');
            $old_slug = gymai_food_normalize_slug($row['slug'] ?? '');
            $title = $row['title'] ?? $slug;
            if ($slug === '') {
                $errors[] = 'slug خالی برای: ' . $title;
                continue;
            }

            $migrate = is_array($row['migrate_slugs'] ?? null) ? $row['migrate_slugs'] : [];
            $post_id = gymai_food_find_existing_post_id($slug, $legacy, $title, array_merge([$old_slug], $migrate));
            $image = $row['image_url'] ?? '';
            $should_refresh_content = ($post_id <= 0) || $force_update;

            $postarr = [
                'post_title' => $title,
                'post_name' => $slug,
                'post_excerpt' => $row['excerpt'] ?? '',
                'post_status' => 'publish',
                'post_type' => GYMAI_FOOD_POST_TYPE,
            ];

            if ($post_id > 0) {
                if ($force_update) {
                    $postarr['ID'] = $post_id;
                    $res = wp_update_post($postarr, true);
                    if (is_wp_error($res)) {
                        $errors[] = $slug . ': ' . $res->get_error_message();
                        continue;
                    }
                    $updated++;
                }
            } else {
                $res = wp_insert_post($postarr, true);
                if (is_wp_error($res)) {
                    $errors[] = $slug . ': ' . $res->get_error_message();
                    continue;
                }
                $post_id = (int) $res;
                $created++;
            }

            $slug_to_id[$slug] = $post_id;
            $rows_by_slug[$slug] = $row;
            if ($should_refresh_content) {
                $content_refresh[$slug] = true;
            }

            if (!empty($row['category'])) {
                $term = $row['category'];
                if (!term_exists($term, 'food-categories')) {
                    wp_insert_term($term, 'food-categories');
                }
                wp_set_object_terms($post_id, $term, 'food-categories');
            }

            foreach ($meta_scalar as $key) {
                if (!isset($row[$key]) || $row[$key] === '') {
                    continue;
                }
                update_post_meta($post_id, $key, (string) $row[$key]);
            }

            if ($image !== '') {
                update_post_meta($post_id, 'sample_image_forapp', $image);
            }

            if (!empty($row['serving_units']) && is_array($row['serving_units'])) {
                $serving_units = gymai_food_normalize_serving_units($row['serving_units']);
                update_post_meta($post_id, 'serving_units_json', wp_json_encode($serving_units, JSON_UNESCAPED_UNICODE));
                if (!empty($row['serving_units']['default_unit'])) {
                    update_post_meta($post_id, 'default_serving_unit', (string) $row['serving_units']['default_unit']);
                }
            }

            if (empty(get_post_meta($post_id, 'views_count', true))) {
                update_post_meta($post_id, 'views_count', (string) wp_rand(120, 2400));
            }
            if (empty(get_post_meta($post_id, 'likes_count', true))) {
                update_post_meta($post_id, 'likes_count', (string) wp_rand(8, 180));
            }

            update_post_meta($post_id, '_gymai_food_seeded_at', (string) time());
        }

        $all_rows = gymai_food_collect_all_seed_rows();
        $merged_rows = gymai_food_merge_dataset_rows($all_rows, $dataset);
        $extended_slug_to_id = gymai_food_extend_slug_to_id($merged_rows, $slug_to_id);

        gymai_food_seed_apply_substitutes($dataset, $extended_slug_to_id);

        $slug_urls = gymai_food_build_slug_urls($merged_rows, $extended_slug_to_id);
        foreach ($rows_by_slug as $slug => $row) {
            if (empty($slug_to_id[$slug]) || empty($content_refresh[$slug])) {
                continue;
            }
            $post_id = (int) $slug_to_id[$slug];
            $content = gymai_food_render_seo_html($row, $slug_urls);
            $res = wp_update_post([
                'ID' => $post_id,
                'post_content' => $content,
            ], true);
            if (is_wp_error($res)) {
                $errors[] = $slug . ' (محتوا): ' . $res->get_error_message();
                continue;
            }
            gymai_food_apply_rank_math($post_id, $row, $slug);
        }

        return ['created' => $created, 'updated' => $updated, 'errors' => $errors];
    }
}

if (!function_exists('gymai_food_seed_apply_substitutes')) {
    function gymai_food_seed_apply_substitutes(array $dataset, array $slug_to_id) {
        foreach ($dataset as $row) {
            $slug = gymai_food_resolve_post_slug($row);
            if ($slug === '' || !isset($slug_to_id[$slug])) {
                continue;
            }
            $alts = $row['substitutes'] ?? [];
            if (!is_array($alts) || empty($alts)) {
                continue;
            }
            $post_id = $slug_to_id[$slug];
            $json = [];
            foreach ($alts as $alt) {
                $alt_slug = gymai_food_normalize_slug($alt['slug'] ?? '');
                if ($alt_slug === '' || !isset($slug_to_id[$alt_slug])) {
                    continue;
                }
                $json[] = [
                    'food_id' => (int) $slug_to_id[$alt_slug],
                    'ratio' => (float) ($alt['ratio'] ?? 1),
                ];
            }
            if (!empty($json)) {
                update_post_meta($post_id, 'substitutes_json', wp_json_encode($json, JSON_UNESCAPED_UNICODE));
            }
        }
    }
}

if (!function_exists('gymai_food_relink_all_posts')) {
    function gymai_food_relink_all_posts() {
        $all_rows = gymai_food_collect_all_seed_rows();
        if (empty($all_rows)) {
            return ['updated' => 0, 'errors' => ['هیچ batch لود نشده است.']];
        }

        $slug_to_id = [];
        foreach ($all_rows as $row) {
            $slug = gymai_food_resolve_post_slug($row);
            if ($slug === '') {
                continue;
            }
            $legacy = gymai_food_normalize_slug($row['legacy_slug'] ?? '');
            $old_slug = gymai_food_normalize_slug($row['slug'] ?? '');
            $title = $row['title'] ?? $slug;
            $migrate = is_array($row['migrate_slugs'] ?? null) ? $row['migrate_slugs'] : [];
            $post_id = gymai_food_find_existing_post_id($slug, $legacy, $title, array_merge([$old_slug], $migrate));
            if ($post_id > 0) {
                $slug_to_id[$slug] = $post_id;
            }
        }

        if (empty($slug_to_id)) {
            return ['updated' => 0, 'errors' => ['هیچ پست خوراکی در وردپرس پیدا نشد.']];
        }

        gymai_food_seed_apply_substitutes($all_rows, $slug_to_id);
        $slug_urls = gymai_food_build_slug_urls($all_rows, $slug_to_id);

        $updated = 0;
        $errors = [];
        foreach ($all_rows as $row) {
            $slug = gymai_food_resolve_post_slug($row);
            if ($slug === '' || empty($slug_to_id[$slug])) {
                continue;
            }
            $post_id = (int) $slug_to_id[$slug];
            $content = gymai_food_render_seo_html($row, $slug_urls);
            $res = wp_update_post([
                'ID' => $post_id,
                'post_content' => $content,
            ], true);
            if (is_wp_error($res)) {
                $errors[] = $slug . ' (relink): ' . $res->get_error_message();
                continue;
            }
            gymai_food_apply_rank_math($post_id, $row, $slug);
            $updated++;
        }

        return ['updated' => $updated, 'errors' => $errors];
    }
}


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
    register_rest_route('gymai/v1', '/seed-foods-batch/(?P<batch>\d+)', array(
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
