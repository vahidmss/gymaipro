// GymAI Popular Exercises — CORE (توابع مشترک + منوی batch)
// Code Snippets: Run everywhere | بدون تگ php
// ترتیب: 1) CORE  2) BATCH1  3) BATCH2  4) BATCH3  5) BATCH4

if (!defined('GYMAI_EXERCISE_POST_TYPE')) {
    define('GYMAI_EXERCISE_POST_TYPE', 'exercises');
}

if (!function_exists('gymai_pop20_exercise_url')) {
    function gymai_pop20_exercise_url($slug) {
        if (!function_exists('home_url')) {
            return '';
        }
        return home_url('/exercises/' . rawurlencode((string) $slug) . '/');
    }
}

if (!function_exists('gymai_pop20_resolve_combos')) {
    function gymai_pop20_resolve_combos(array $def) {
        if (empty($def['combos']) || !is_array($def['combos'])) {
            return $def;
        }
        foreach ($def['combos'] as $i => $combo) {
            if (!empty($combo['slug']) && empty($combo['url'])) {
                $def['combos'][$i]['url'] = gymai_pop20_exercise_url($combo['slug']);
            }
        }
        return $def;
    }
}

if (!function_exists('gymai_existing_exercise_slugs_blocklist')) {
    function gymai_existing_exercise_slugs_blocklist() {
        return array(
            'دیپ-پارالل',
            'هایپراکستنشن-فیله-کمر',
            'پلانک-plank',
            'پلانک',
            'پرس-پا-دستگاه',
            'جلوبازو-دمبل-نشسته',
            'زیربغل-سیمکش-دست-باز',
            'ددلیفت-رومانیایی',
            'زیربغل-هالتر-خمیده',
            'پرس-سینه-دستگاه',
            'پشت-پا-دستگاه',
            'پشت-بازو-سیمکش',
            'نشر-جانب-دمبل',
            'اسکات-هالتر',
            'پرس-سرشانه-دستگاه',
        );
    }
}

if (!function_exists('gymai_pop20_latin_digits')) {
    function gymai_pop20_latin_digits($text) {
        $map = array('۰' => '0', '۱' => '1', '۲' => '2', '۳' => '3', '۴' => '4', '۵' => '5', '۶' => '6', '۷' => '7', '۸' => '8', '۹' => '9');
        return strtr((string) $text, $map);
    }
}

if (!function_exists('gymai_pop20_app_short_description')) {
    function gymai_pop20_app_short_description(array $def) {
        $m = $def['meta'];
        $parts = array(
            $m['short_description'],
            $def['summary'],
            'عضله هدف: ' . $def['quick']['main'] . '. تجهیزات: ' . $def['quick']['equipment'] . '. سطح: ' . $def['quick']['difficulty'] . '.',
        );
        if (!empty($def['tips'][0])) {
            $parts[] = 'نکته کلیدی: ' . $def['tips'][0];
        }
        if (!empty($def['tips'][1])) {
            $parts[] = $def['tips'][1];
        }
        if (!empty($def['program'][0])) {
            $p = $def['program'][0];
            $parts[] = 'پیشنهاد ' . $p[0] . ': ' . $p[1] . ' ست، ' . $p[2] . ' تکرار، استراحت ' . $p[3] . '.';
        }
        if (!empty($def['rank_extra'])) {
            $parts[] = $def['rank_extra'];
        }
        return trim(preg_replace('/\s+/u', ' ', implode(' ', array_filter($parts))));
    }
}

if (!function_exists('gymai_pop20_seo_title')) {
    function gymai_pop20_seo_title(array $def) {
        $m = $def['meta'];
        $sets = gymai_pop20_latin_digits($m['recommended_sets']);
        $reps = gymai_pop20_latin_digits($m['rep_range_hypertrophy'] ? $m['rep_range_hypertrophy'] : '8-12');
        return $def['title'] . ' | آموزش 0 تا 100 — ' . $sets . ' ست × ' . $reps . ' | GymAI Pro';
    }
}

if (!function_exists('gymai_pop20_external_links')) {
    function gymai_pop20_external_links(array $ex) {
        $links = array(
            array(
                'https://pubmed.ncbi.nlm.nih.gov/?term=resistance+training+exercise',
                'PubMed — مقالات تمرین مقاومتی',
            ),
            array(
                'https://en.wikipedia.org/wiki/Strength_training',
                'ویکی‌پدیا — Strength Training',
            ),
        );
        if (!empty($ex['aliases'][0])) {
            $term = rawurlencode($ex['aliases'][0]);
            $links[] = array(
                'https://pubmed.ncbi.nlm.nih.gov/?term=' . $term,
                'PubMed — ' . $ex['aliases'][0],
            );
        }
        $pattern = isset($ex['meta']['movement_pattern']) ? $ex['meta']['movement_pattern'] : '';
        $wiki = array(
            'horizontal_push' => 'https://en.wikipedia.org/wiki/Bench_press',
            'vertical_pull' => 'https://en.wikipedia.org/wiki/Pull-up',
            'vertical_push' => 'https://en.wikipedia.org/wiki/Overhead_press',
            'hinge' => 'https://en.wikipedia.org/wiki/Deadlift',
            'squat' => 'https://en.wikipedia.org/wiki/Squat_(exercise)',
            'lunge' => 'https://en.wikipedia.org/wiki/Lunge_(exercise)',
            'spinal_flexion' => 'https://en.wikipedia.org/wiki/Crunch_(exercise)',
        );
        if (isset($wiki[$pattern])) {
            $links[] = array($wiki[$pattern], 'ویکی‌پدیا — مرجع حرکت');
        }
        return $links;
    }
}

if (!function_exists('gymai_popular_20_meta_description')) {
    function gymai_popular_20_meta_description($title, $tips_count, $mistakes_count, $sets, $reps, $extra = '') {
        $sets = gymai_pop20_latin_digits($sets);
        $reps = gymai_pop20_latin_digits($reps);
        $base = sprintf(
            'آموزش 0 تا 100 %s: تکنیک اجرا، %d نکته طلایی، %d اشتباه رایج، برنامه %s ست %s تکرار',
            $title,
            $tips_count,
            $mistakes_count,
            $sets,
            $reps
        );
        if ($extra !== '') {
            $base .= ' — ' . $extra;
        }
        return $base . '.';
    }
}

if (!function_exists('gymai_render_popular_exercise_html')) {
    function gymai_render_popular_exercise_html(array $ex) {
        $ex = gymai_pop20_resolve_combos($ex);
        $name = $ex['title'];
        $alias_en = !empty($ex['aliases'][0]) ? $ex['aliases'][0] : $name;
        $img = $ex['image'];
        $aliases = implode('، ', $ex['aliases']);
        $m = $ex['meta'];
        $sets = gymai_pop20_latin_digits($m['recommended_sets']);
        $reps = gymai_pop20_latin_digits($m['rep_range_hypertrophy'] ? $m['rep_range_hypertrophy'] : '8-12');
        $mistake_count = count($ex['mistakes']);
        $tip_count = count($ex['tips']);

        $tips_html = '';
        foreach ($ex['tips'] as $tip) {
            $tips_html .= '<li>' . esc_html($tip) . '</li>';
        }

        $setup_html = $execution_html = $mistakes_rows = $program_rows = $muscles_html = $combo_html = $faq_html = $advanced_html = '';

        foreach ($ex['setup'] as $i => $line) {
            $setup_html .= '<li>' . esc_html($line) . '</li>';
        }
        foreach ($ex['execution'] as $i => $line) {
            $n = $i + 1;
            $execution_html .= '<li><strong>گام ' . $n . ':</strong> ' . esc_html($line) . '</li>';
        }
        foreach ($ex['muscles'] as $line) {
            $muscles_html .= '<li>' . esc_html($line) . '</li>';
        }
        foreach ($ex['mistakes'] as $row) {
            $mistakes_rows .= '<tr><td>' . esc_html($row[0]) . '</td><td>' . esc_html($row[1]) . '</td></tr>';
        }
        foreach ($ex['program'] as $row) {
            $program_rows .= '<tr><td>' . esc_html($row[0]) . '</td><td>' . esc_html($row[1]) . '</td><td>' . esc_html($row[2]) . '</td><td>' . esc_html($row[3]) . '</td></tr>';
        }
        foreach ($ex['combos'] as $combo) {
            if (!empty($combo['url'])) {
                $combo_html .= '<li><strong>' . esc_html($combo['label']) . '</strong> <a href="' . esc_url($combo['url']) . '">' . esc_html($combo['link_text']) . '</a></li>';
            } else {
                $combo_html .= '<li>' . esc_html($combo['label']) . '</li>';
            }
        }
        foreach ($ex['faqs'] as $faq) {
            $faq_html .= '<h3>' . esc_html($faq['q']) . '</h3><p>' . esc_html($faq['a']) . '</p>';
        }

        $faq_html .= '<h3>چند بار در هفته این تمرین را انجام دهم؟</h3>';
        $faq_html .= '<p>بسته به هدف و حجم کل برنامه، معمولاً <strong>1 تا 2 جلسه در هفته</strong> برای ' . esc_html($ex['quick']['main']) . ' کافی است. بین جلسات 48 تا 72 ساعت استراحت بگذارید.</p>';
        $faq_html .= '<h3>برای مبتدی مناسب است؟</h3>';
        $faq_html .= '<p>سطح این حرکت: <strong>' . esc_html($ex['quick']['difficulty']) . '</strong>. ' . esc_html($ex['summary']) . '</p>';

        $advanced_html .= '<li><strong>تمپو:</strong> ' . esc_html($m['tempo']) . ' — کنترل فاز منفی برای زمان تحت تنش بیشتر</li>';
        $advanced_html .= '<li><strong>RPE پیشنهادی:</strong> حدود ' . esc_html((string) $m['typical_rpe']) . ' از 10</li>';
        $advanced_html .= '<li><strong>استراحت بین ست‌ها:</strong> ' . gymai_pop20_latin_digits((string) $m['rest_seconds']) . ' ثانیه</li>';

        $external_html = '';
        foreach (gymai_pop20_external_links($ex) as $link) {
            $external_html .= '<a href="' . esc_url($link[0]) . '" target="_blank" rel="dofollow noopener">' . esc_html($link[1]) . '</a> | ';
        }
        $external_html = rtrim($external_html, ' | ');

        $why = 'این تمرین برای توسعه ' . $ex['quick']['main'] . ' طراحی شده و در برنامه‌های ' . $ex['quick']['type'] . ' جایگاه مشخصی دارد. '
            . 'با تمرکز روی ' . $ex['quick']['equipment'] . ' می‌توانید پیشرفت پایدار داشته باشید. '
            . esc_html($ex['summary']);

        $audience = 'مناسب ورزشکاران سطح ' . $ex['quick']['difficulty'] . ' که می‌خواهند '
            . $m['target_area'] . ' را هدف بگیرند. '
            . 'اگر تازه‌کار هستید با وزنه سبک‌تر شروع کنید؛ اگر پیشرفته‌اید می‌توانید بار یا تکرار را طبق جدول برنامه افزایش دهید.';

        $img_alt = 'آموزش ' . $ex['quick']['main'] . ' — ' . $ex['caption'];

        return '<!-- GymAI Pro SEO ' . esc_html($alias_en) . ' -->
<h1>آموزش 0 تا 100: ' . esc_html($name) . '</h1>
<p>' . wp_kses_post($ex['intro']) . '</p>
<p>' . esc_html($why) . '</p>
<p><strong>نام‌های بین‌المللی:</strong> ' . esc_html($aliases) . ' — در ادبیات بدنسازی معمولاً با عنوان <em>' . esc_html($alias_en) . '</em> شناخته می‌شود.</p>

<figure class="wp-block-image"><img src="' . esc_url($img) . '" alt="' . esc_attr($img_alt) . '" /><figcaption>' . esc_html($ex['caption']) . '</figcaption></figure>

<div class="wp-block-columns"><div class="wp-block-column"><div style="border-radius:10px;background:#f8f9fa;padding:15px;">
<h2>اطلاعات سریع</h2><ul>
<li><strong>عضله اصلی:</strong> ' . esc_html($ex['quick']['main']) . '</li>
<li><strong>عضلات فرعی:</strong> ' . esc_html($ex['quick']['secondary']) . '</li>
<li><strong>سطح:</strong> ' . esc_html($ex['quick']['difficulty']) . '</li>
<li><strong>تجهیزات:</strong> ' . esc_html($ex['quick']['equipment']) . '</li>
<li><strong>نوع:</strong> ' . esc_html($ex['quick']['type']) . '</li>
<li><strong>برنامه پیشنهادی:</strong> ' . esc_html($sets) . ' ست × ' . esc_html($reps) . ' تکرار</li>
</ul></div></div><div class="wp-block-column"><div style="border-radius:10px;background:#e8f4f8;padding:15px;">
<h2>' . (int) $tip_count . ' نکته طلایی</h2><ol>' . $tips_html . '</ol></div></div></div>

<h2>چرا این حرکت مهم است؟</h2>
<p>' . esc_html($ex['summary']) . ' ' . esc_html(isset($ex['rank_extra']) ? $ex['rank_extra'] : '') . '</p>
<p>در برنامه‌های حرفه‌ای، چنین حرکاتی معمولاً در کنار تمرین‌های مکمل قرار می‌گیرند تا تعادل عضلانی و پیشرفت خطی حفظ شود. رعایت فرم صحیح مهم‌تر از افزایش سریع وزنه است.</p>

<h2>برای چه کسانی مناسب است؟</h2>
<p>' . esc_html($audience) . '</p>

<h2>تکنیک اجرای صحیح</h2>
<h3>مرحله 1: آماده‌سازی</h3>
<ul>' . $setup_html . '</ul>
<h3>مرحله 2: اجرای حرکت</h3>
<ul>' . $execution_html . '</ul>
<p><strong>الگوی تنفس:</strong> ' . esc_html($ex['breathing']) . '. تنفس منظم به تثبیت Core و کنترل فشار خون durante ست کمک می‌کند.</p>

<h2>عضلات درگیر و نقش هر کدام</h2>
<ul>' . $muscles_html . '</ul>
<p>درگیری عضلاتی به زاویه مفصل، دامنه حرکت و توزیع بار بستگی دارد. برای حداکثر انتقال بار، قبل از هر ست وضعیت بدن را از نو تنظیم کنید.</p>

<h2>' . (int) $mistake_count . ' اشتباه رایج و راه‌حل</h2>
<table class="wp-block-table"><thead><tr><th>اشتباه</th><th>راه‌حل</th></tr></thead><tbody>' . $mistakes_rows . '</tbody></table>
<p>بیشتر آسیب‌ها ناشی از افزایش ناگهانی حجم یا اجرای ناقص در انتهای ست است. فیلمبرداری از کنار یا جلو برای خودتان می‌تواند اشتباهات پنهان را آشکار کند.</p>

<h2>برنامه تمرینی پیشنهادی (ست و تکرار)</h2>
<table class="wp-block-table"><thead><tr><th>هدف</th><th>ست</th><th>تکرار</th><th>استراحت</th></tr></thead><tbody>' . $program_rows . '</tbody></table>
<p>برای هدف <strong>' . esc_html($m['programming_goal']) . '</strong> می‌توانید از بازه قدرت (' . esc_html(gymai_pop20_latin_digits($m['rep_range_strength'])) . ')، حجم (' . esc_html($reps) . ') یا استقامت (' . esc_html(gymai_pop20_latin_digits($m['rep_range_endurance'])) . ') استفاده کنید.</p>

<h2>ترکیب با سایر حرکات (لینک داخلی)</h2>
<ul>' . $combo_html . '</ul>

<h2>نکات پیشرفته</h2>
<ul>' . $advanced_html . '</ul>

<h2>سوالات متداول</h2>
<div style="border-radius:8px;background:#f0fdf4;padding:15px;">' . $faq_html . '</div>

<h2>جمع‌بندی</h2>
<p>' . esc_html($ex['summary']) . '</p>
<p>✅ <strong>خلاصه کلیدی:</strong> ' . esc_html($ex['summary_keys']) . '</p>
<p>با اجرای منظم، ثبت بار و تکرار، و تمرکز روی کیفیت هر تکرار، می‌توانید در چند هفته پیشرفت ملموس در ' . esc_html($ex['quick']['main']) . ' ببینید.</p>

<div style="background:#f5f5f5;padding:15px;border-radius:10px;margin:30px 0;">
<h3>منابع و لینک‌های مفید</h3>
<p><strong>منابع خارجی:</strong> ' . $external_html . '</p>
<p><strong>اپلیکیشن GymAI Pro:</strong> برنامه تمرینی شخصی‌سازی‌شده و ردیابی پیشرفت.</p>
</div>';
    }
}

/**
 * امتیاز PHP ساختگی نمی‌زنیم — Rank Math فقط با analyzer.js (JS) امتیاز واقعی می‌دهد.
 * امتیاز قبلی را پاک نمی‌کنیم تا N/A نشود؛ recalc همان analyzer را overwrite می‌کند.
 */
if (!function_exists('gymai_pop20_get_rank_math_research_tests')) {
    function gymai_pop20_get_rank_math_research_tests() {
        if (!class_exists('\RankMath\Admin\Metabox\Screen')) {
            return array();
        }
        $screen = new \RankMath\Admin\Metabox\Screen();
        $screen->load_screen('post');
        return $screen->get_analysis();
    }
}

if (!function_exists('gymai_pop20_build_rank_math_score_payload')) {
    function gymai_pop20_build_rank_math_score_payload(array $post_ids) {
        if (!class_exists('\RankMath\Helper') || empty($post_ids)) {
            return array();
        }

        if (function_exists('rank_math')) {
            rank_math()->variables->setup();
        }

        add_filter(
            'rank_math/replacements/non_cacheable',
            function ($non_cacheable) {
                $non_cacheable[] = 'excerpt';
                $non_cacheable[] = 'excerpt_only';
                $non_cacheable[] = 'seo_description';
                $non_cacheable[] = 'keywords';
                $non_cacheable[] = 'focuskw';
                return $non_cacheable;
            }
        );

        $data = array();
        foreach ($post_ids as $post_id) {
            $post_id = (int) $post_id;
            $post = get_post($post_id);
            if (!$post instanceof WP_Post) {
                continue;
            }

            $keywords = array_map('trim', explode(',', \RankMath\Helper::get_post_meta('focus_keyword', $post_id)));
            $keyword = isset($keywords[0]) ? $keywords[0] : '';

            $values = array(
                'title' => \RankMath\Helper::replace_vars('%seo_title%', $post),
                'description' => \RankMath\Helper::replace_vars('%seo_description%', $post),
                'keywords' => $keywords,
                'keyword' => $keyword,
                'content' => wpautop($post->post_content),
                'url' => urldecode(get_the_permalink($post_id)),
                'hasContentAi' => !empty(\RankMath\Helper::get_post_meta('contentai_score', $post_id)),
                'post_type' => $post->post_type,
            );

            if (has_post_thumbnail($post_id)) {
                $thumbnail_id = get_post_thumbnail_id($post_id);
                $values['thumbnail'] = get_the_post_thumbnail_url($post_id);
                $values['thumbnailAlt'] = get_post_meta($thumbnail_id, '_wp_attachment_image_alt', true);
            }

            $data[(string) $post_id] = apply_filters('rank_math/recalculate_score/data', $values, $post_id);
        }

        return $data;
    }
}

if (!function_exists('gymai_pop20_rank_math_recalc_script')) {
    function gymai_pop20_rank_math_recalc_script() {
        return <<<'JS'
(function ($) {
    if (typeof window.rankMathAnalyzer === 'undefined' || !window.gymaiPop20Recalc) {
        return;
    }

    var cfg = window.gymaiPop20Recalc;
    var Paper = window.rankMathAnalyzer.Paper;
    var Analyzer = window.rankMathAnalyzer.Analyzer;
    var ResultManager = window.rankMathAnalyzer.ResultManager;
    var i18n = window.wp && window.wp.i18n ? window.wp.i18n : null;
    var statusEl = document.getElementById('gymai-pop20-recalc-status');
    var postIds = (cfg.postIds || []).map(String);
    var chunkSize = cfg.chunkSize || 3;
    var tests = (cfg.researchTests || []).filter(function (t) {
        return t !== 'keywordNotUsed';
    });
    var savedTotal = 0;
    var failedTotal = 0;

    function setStatus(msg) {
        if (statusEl) {
            statusEl.textContent = msg;
        }
    }

    if (!tests.length || !postIds.length) {
        setStatus('داده‌ای برای محاسبه امتیاز Rank Math نیست.');
        return;
    }

    function analyzePosts(postsData) {
        var postScores = {};
        var promises = [];

        Object.keys(postsData).forEach(function (postID) {
            var data = postsData[postID];
            if (!data || !data.keyword) {
                failedTotal += 1;
                return;
            }

            var resultManager = new ResultManager();
            var paper = new Paper();
            paper.setTitle(data.title || '');
            paper.setDescription(data.description || '');
            paper.setText(data.content || '');
            paper.setKeyword(data.keyword);
            paper.setKeywords(data.keywords || [data.keyword]);
            paper.setPermalink(data.url || '');
            paper.setUrl(data.url || '');
            if (data.thumbnail) {
                paper.setThumbnail(data.thumbnail);
            }
            paper.setContentAI(!!data.hasContentAi);

            var analyzer = new Analyzer({ i18n: i18n, analysis: tests });
            promises.push(
                analyzer.analyzeSome(tests, paper).then(function (results) {
                    resultManager.update(paper.getKeyword(), results, true);
                    postScores[postID] = resultManager.getScore(paper.getKeyword());
                }).catch(function () {
                    failedTotal += 1;
                })
            );
        });

        return Promise.allSettled(promises).then(function () {
            var ids = Object.keys(postScores);
            if (!ids.length) {
                return $.Deferred().reject().promise();
            }
            return $.ajax({
                url: cfg.restUrl,
                method: 'POST',
                beforeSend: function (xhr) {
                    xhr.setRequestHeader('X-WP-Nonce', cfg.nonce);
                },
                data: { postScores: postScores },
            }).then(function () {
                savedTotal += ids.length;
            });
        });
    }

    function fetchChunk(ids) {
        return $.ajax({
            url: cfg.ajaxUrl,
            method: 'POST',
            data: {
                action: 'gymai_pop20_score_payload',
                nonce: cfg.ajaxNonce,
                ids: ids,
            },
        }).then(function (resp) {
            if (!resp || !resp.success || !resp.data) {
                return $.Deferred().reject(resp).promise();
            }
            return resp.data;
        });
    }

    function runChunks(index) {
        if (index >= postIds.length) {
            if (savedTotal === 0) {
                setStatus('امتیازی ذخیره نشد. Rank Math فعال است؟');
                return;
            }
            var msg = 'امتیاز واقعی Rank Math ذخیره شد (' + savedTotal + ' از ' + postIds.length + ' پست).';
            if (failedTotal > 0) {
                msg += ' (' + failedTotal + ' خطا — دوباره دکمه recalc را بزن.)';
            }
            setStatus(msg);
            return;
        }

        var chunk = postIds.slice(index, index + chunkSize);
        var end = Math.min(index + chunk.length, postIds.length);
        setStatus('محاسبه امتیاز Rank Math: ' + (index + 1) + '–' + end + ' از ' + postIds.length + '...');

        fetchChunk(chunk)
            .then(analyzePosts)
            .then(function () {
                runChunks(index + chunkSize);
            })
            .catch(function () {
                failedTotal += chunk.length;
                runChunks(index + chunkSize);
            });
    }

    setStatus('در حال محاسبه امتیاز واقعی Rank Math (' + postIds.length + ' پست)...');
    runChunks(0);
})(jQuery);
JS;
    }
}

if (!function_exists('gymai_pop20_enqueue_rank_math_recalc')) {
    function gymai_pop20_enqueue_rank_math_recalc(array $post_ids) {
        if (!function_exists('rank_math') || empty($post_ids)) {
            return false;
        }

        $post_ids = array_values(array_unique(array_filter(array_map('intval', $post_ids))));
        if (empty($post_ids)) {
            return false;
        }

        wp_enqueue_script('wp-i18n');
        wp_enqueue_script(
            'rank-math-analyzer',
            rank_math()->plugin_url() . 'assets/admin/js/analyzer.js',
            array('wp-i18n'),
            rank_math()->version,
            true
        );

        wp_register_script('gymai-pop20-rankmath-recalc', false, array('jquery', 'rank-math-analyzer'), '1.2', true);
        wp_enqueue_script('gymai-pop20-rankmath-recalc');
        wp_add_inline_script('gymai-pop20-rankmath-recalc', gymai_pop20_rank_math_recalc_script());

        wp_localize_script(
            'gymai-pop20-rankmath-recalc',
            'gymaiPop20Recalc',
            array(
                'postIds' => $post_ids,
                'chunkSize' => 3,
                'researchTests' => gymai_pop20_get_rank_math_research_tests(),
                'restUrl' => esc_url_raw(rest_url('rankmath/v1/updateSeoScore')),
                'nonce' => wp_create_nonce('wp_rest'),
                'ajaxUrl' => admin_url('admin-ajax.php'),
                'ajaxNonce' => wp_create_nonce('gymai_pop20_recalc'),
            )
        );

        return true;
    }
}

if (!function_exists('gymai_pop20_ajax_score_payload')) {
    function gymai_pop20_ajax_score_payload() {
        check_ajax_referer('gymai_pop20_recalc', 'nonce');
        if (!current_user_can('manage_options')) {
            wp_send_json_error(array('message' => 'Forbidden'), 403);
        }

        $ids = isset($_POST['ids']) ? wp_unslash($_POST['ids']) : array();
        if (!is_array($ids)) {
            $ids = array($ids);
        }
        $ids = array_values(array_unique(array_filter(array_map('intval', $ids))));
        if (empty($ids)) {
            wp_send_json_error(array('message' => 'No IDs'), 400);
        }

        wp_send_json_success(gymai_pop20_build_rank_math_score_payload($ids));
    }
    add_action('wp_ajax_gymai_pop20_score_payload', 'gymai_pop20_ajax_score_payload');
}

if (!function_exists('gymai_pop20_meta_label')) {
    function gymai_pop20_meta_label($type, $key) {
        $maps = array(
            'muscle' => array(
                'chest' => 'سینه',
                'chest_upper' => 'سینه بالایی',
                'chest_middle' => 'سینه میانی',
                'chest_lower' => 'سینه پایینی',
                'back' => 'پشت',
                'back_lat' => 'زیربغل',
                'lats' => 'زیربغل',
                'rhomboids' => 'رومبوئید',
                'traps_middle' => 'ذوزنقه میانی',
                'traps_upper' => 'ذوزنقه بالایی',
                'back_trap' => 'ذوزنقه',
                'lower_back' => 'کمر',
                'shoulder_anterior' => 'سرشانه قدامی',
                'shoulder_lateral' => 'سرشانه جانبی',
                'shoulder_posterior' => 'سرشانه خلفی',
                'triceps' => 'پشت‌بازو',
                'biceps' => 'جلوبازو',
                'forearms' => 'ساعد',
                'quads' => 'چهارسر ران',
                'hamstrings' => 'همسترینگ',
                'glutes' => 'باسن',
                'calves' => 'ساق پا',
                'calf' => 'ساق پا',
                'abs' => 'شکم',
                'obliques' => 'پهلو',
                'hip_flexors' => 'خم‌کننده لگن',
                'adductors' => 'داخل ران',
                'full_body' => 'تمام بدن',
            ),
            'equipment' => array(
                'barbell' => 'هالتر',
                'dumbbell' => 'دمبل',
                'machine' => 'ماشین',
                'bodyweight' => 'وزن بدن',
                'cable' => 'سیم‌کش',
                'kettlebell' => 'کتل‌بل',
                'bench' => 'نیمکت',
                'rack' => 'رک',
                'bar' => 'میله بارفیکس',
                'pull_up_bar' => 'میله بارفیکس',
                'plate' => 'صفحه وزنه',
                'resistance_band' => 'کش',
            ),
            'movement' => array(
                'vertical_push' => 'فشار عمودی',
                'horizontal_push' => 'فشار افقی',
                'vertical_pull' => 'کشش عمودی',
                'horizontal_pull' => 'کشش افقی',
                'squat' => 'اسکوات',
                'lunge' => 'لانج',
                'hinge' => 'هیپ هینج',
                'hip_hinge' => 'هیپ هینج',
                'hip_extension' => 'اکستنشن لگن',
                'knee_extension' => 'باز کردن زانو',
                'knee_flexion' => 'خم کردن زانو',
                'calf_raise' => 'ساق',
                'elbow_flexion' => 'خم کردن آرنج',
                'elbow_extension' => 'باز کردن آرنج',
                'shoulder_flexion' => 'فلکشن شانه',
                'shoulder_abduction' => 'نشر جانب',
                'lateral_raise' => 'نشر جانب',
                'horizontal_abduction' => 'فلای معکوس',
                'anti_extension' => 'ضد اکستنشن',
                'anti_rotation' => 'ضد چرخش',
                'rotation' => 'چرخشی',
                'spinal_flexion' => 'کرانچ',
                'spinal_rotation' => 'چرخش ستون فقرات',
                'dynamic_plank' => 'پلانک پویا',
                'carry' => 'حمل وزنه',
                'isometric' => 'ایزومتریک',
                'back_extension' => 'اکستنشن کمر',
            ),
            'body' => array(
                'compound' => 'چند مفصلی',
                'isolation' => 'تک مفصلی',
                'core_dominant' => 'Core',
                'full_body' => 'کل بدن',
            ),
            'goal' => array(
                'hypertrophy' => 'حجم',
                'strength' => 'قدرت',
                'endurance' => 'استقامت',
                'conditioning' => 'آمادگی جسمانی',
            ),
            'formula' => array(
                'brzycki' => 'برزیکی',
                'epley' => 'اپلی',
            ),
        );

        return isset($maps[$type][$key]) ? $maps[$type][$key] : (string) $key;
    }
}

if (!function_exists('gymai_pop20_meta_labels')) {
    function gymai_pop20_meta_labels($type, array $keys) {
        return implode('، ', array_map(function ($key) use ($type) {
            return gymai_pop20_meta_label($type, $key);
        }, $keys));
    }
}

if (!function_exists('gymai_pop20_normalize_muscle_targets')) {
    function gymai_pop20_normalize_muscle_targets(array $targets, $main_muscle) {
        $map = array(
            'lats' => 'back_lat',
            'traps_middle' => 'back_trap',
            'traps_upper' => 'back_trap',
            'calves' => 'calf',
            'obliques' => 'abs',
        );
        $out = array();
        foreach ($targets as $key => $value) {
            $norm_key = isset($map[$key]) ? $map[$key] : $key;
            $value = (int) $value;
            if ($value <= 0) {
                continue;
            }
            $out[$norm_key] = isset($out[$norm_key]) ? max($out[$norm_key], $value) : $value;
        }

        $main_key = isset($map[$main_muscle]) ? $map[$main_muscle] : $main_muscle;
        if ($main_key !== '' && !isset($out[$main_key])) {
            $out[$main_key] = 90;
        }

        arsort($out);
        return $out;
    }
}

if (!function_exists('gymai_apply_popular_exercise_meta')) {
    function gymai_apply_popular_exercise_meta($post_id, array $def, $content) {
        $m = $def['meta'];
        $title = $def['title'];
        $image = $def['image'];

        $app_desc = gymai_pop20_app_short_description($def);
        $secondary_muscles = gymai_pop20_meta_labels('muscle', $m['secondary_muscle_keys']);
        $equipment = gymai_pop20_meta_labels('equipment', $m['equipment_keys']);
        $muscle_targets = gymai_pop20_normalize_muscle_targets($m['muscle_targets'], $m['main_muscle']);

        $meta = array(
            'name_app' => $title,
            'other_names' => $def['aliases'],
            'short_description' => $app_desc,
            'detailed_description' => $app_desc,
            'seo_content' => wp_strip_all_tags($content),
            'main_muscle' => $m['main_muscle'],
            'secondary_muscle_keys' => $m['secondary_muscle_keys'],
            'secondary_muscles' => $secondary_muscles,
            'target_area' => $m['target_area'],
            'difficulty' => $m['difficulty'],
            'equipment_keys' => $m['equipment_keys'],
            'equipment' => $equipment,
            'exercise_type' => $m['exercise_type'],
            'movement_pattern' => $m['movement_pattern'],
            'movement_pattern_label' => gymai_pop20_meta_label('movement', $m['movement_pattern']),
            'body_engagement' => $m['body_engagement'],
            'body_engagement_label' => gymai_pop20_meta_label('body', $m['body_engagement']),
            'mechanics_type' => $m['mechanics_type'],
            'force_type' => $m['force_type'],
            'plane_of_motion' => $m['plane_of_motion'],
            'laterality' => $m['laterality'],
            'posture' => $m['posture'],
            'grip_type' => isset($m['grip_type']) ? $m['grip_type'] : '',
            'resistance_profile' => $m['resistance_profile'],
            'joint_focus' => $m['joint_focus'],
            'muscle_targets_json' => wp_json_encode($muscle_targets, JSON_UNESCAPED_UNICODE),
            'met' => (string) $m['met'],
            'movement_distance_cm' => (string) $m['movement_distance_cm'],
            'calories_per_1000kg' => (string) $m['calories_per_1000kg'],
            'exercise_difficulty_score' => (string) $m['exercise_difficulty_score'],
            'typical_rpe' => (string) $m['typical_rpe'],
            'estimated_1rm_formula' => isset($m['estimated_1rm_formula']) ? $m['estimated_1rm_formula'] : '',
            'estimated_1rm_formula_label' => isset($m['estimated_1rm_formula']) ? gymai_pop20_meta_label('formula', $m['estimated_1rm_formula']) : '',
            'programming_goal' => $m['programming_goal'],
            'programming_goal_label' => gymai_pop20_meta_label('goal', $m['programming_goal']),
            'recommended_sets' => $m['recommended_sets'],
            'rep_range_strength' => $m['rep_range_strength'],
            'rep_range_hypertrophy' => $m['rep_range_hypertrophy'],
            'rep_range_endurance' => $m['rep_range_endurance'],
            'rest_seconds' => (string) $m['rest_seconds'],
            'tempo' => $m['tempo'],
            'setup' => implode("\n", $def['setup']),
            'execution' => implode("\n", $def['execution']),
            'breathing' => $def['breathing'],
            'common_mistakes' => implode("\n", array_map(function ($row) {
                return $row[0];
            }, $def['mistakes'])),
            'contraindications' => implode("\n", isset($def['contraindications']) ? $def['contraindications'] : array('درد حاد مفصل مرتبط', 'آسیب فعال — با پزشک مشورت کنید')),
            'tip_1' => isset($def['tips'][0]) ? $def['tips'][0] : '',
            'tip_2' => isset($def['tips'][1]) ? $def['tips'][1] : '',
            'tip_3' => isset($def['tips'][2]) ? $def['tips'][2] : '',
            'video_url' => '',
            'image_url' => $image,
            'thumbnail_url' => $image,
            'views_count' => '0',
            'likes_count' => '0',
        );

        foreach ($meta as $key => $value) {
            update_post_meta($post_id, $key, $value);
        }
        update_post_meta($post_id, '_gymai_v2_meta_saved', (string) time());

        $sets = $m['recommended_sets'];
        $reps = $m['rep_range_hypertrophy'] ? $m['rep_range_hypertrophy'] : '۸–۱۲';
        $desc = gymai_popular_20_meta_description(
            $title,
            count($def['tips']),
            count($def['mistakes']),
            $sets,
            $reps,
            isset($def['rank_extra']) ? $def['rank_extra'] : ''
        );

        $seo_title = gymai_pop20_seo_title($def);
        $canonical = gymai_pop20_exercise_url($def['slug']);

        $rank = array(
            'rank_math_title' => $seo_title,
            'rank_math_description' => $desc,
            'rank_math_focus_keyword' => $title,
            'rank_math_canonical_url' => $canonical,
            'rank_math_facebook_title' => $seo_title,
            'rank_math_facebook_description' => $desc,
            'rank_math_facebook_image' => $image,
            'rank_math_twitter_title' => $seo_title,
            'rank_math_twitter_description' => $desc,
            'rank_math_twitter_image' => $image,
            'rank_math_robots' => array('index'),
            'rank_math_rich_snippet' => 'article',
            'rank_math_snippet_article_type' => 'BlogPosting',
        );
        foreach ($rank as $rkey => $rvalue) {
            update_post_meta($post_id, $rkey, $rvalue);
        }
    }
}

if (!function_exists('gymai_pop20_run_batch')) {
    function gymai_pop20_run_batch(array $defs, $update_existing = false) {
        $blocklist = array_flip(gymai_existing_exercise_slugs_blocklist());
        $created = $skipped = $updated = 0;
        $errors = array();
        $touched_ids = array();

        foreach ($defs as $def) {
            $slug = $def['slug'];
            if (isset($blocklist[$slug])) {
                $skipped++;
                $errors[] = 'رد (لیست موجود): ' . $slug;
                continue;
            }

            $existing = get_page_by_path($slug, OBJECT, GYMAI_EXERCISE_POST_TYPE);
            $content = gymai_render_popular_exercise_html($def);

            if ($existing instanceof WP_Post) {
                if (!$update_existing) {
                    $skipped++;
                    continue;
                }
                wp_update_post(array(
                    'ID' => $existing->ID,
                    'post_title' => $def['title'],
                    'post_content' => $content,
                ));
                gymai_apply_popular_exercise_meta($existing->ID, $def, $content);
                $touched_ids[] = (int) $existing->ID;
                $updated++;
                continue;
            }

            $post_id = wp_insert_post(array(
                'post_title' => $def['title'],
                'post_name' => $slug,
                'post_type' => GYMAI_EXERCISE_POST_TYPE,
                'post_status' => 'publish',
                'post_content' => $content,
            ), true);

            if (is_wp_error($post_id)) {
                $errors[] = $def['title'] . ': ' . $post_id->get_error_message();
                continue;
            }

            gymai_apply_popular_exercise_meta((int) $post_id, $def, $content);
            $touched_ids[] = (int) $post_id;
            $created++;
        }

        return array(
            'created' => $created,
            'skipped' => $skipped,
            'updated' => $updated,
            'errors' => $errors,
            'touched_ids' => array_values(array_unique(array_filter($touched_ids))),
        );
    }
}

if (!function_exists('gymai_pop20_load_batch_files')) {
    function gymai_pop20_load_batch_files() {
        static $done = false;
        if ($done) {
            return;
        }
        $done = true;

        $map = array(
            'gymai_pop20_batch1_definitions' => array(
                defined('WP_CONTENT_DIR') ? WP_CONTENT_DIR . '/gymai-seed/pop20-batch1.php' : '',
                defined('WP_PLUGIN_DIR') ? WP_PLUGIN_DIR . '/gymai-popular-20-seed/pop20-batch1.php' : '',
            ),
            'gymai_pop20_batch2_definitions' => array(
                defined('WP_CONTENT_DIR') ? WP_CONTENT_DIR . '/gymai-seed/pop20-batch2.php' : '',
                defined('WP_PLUGIN_DIR') ? WP_PLUGIN_DIR . '/gymai-popular-20-seed/pop20-batch2.php' : '',
            ),
            'gymai_pop20_batch3_definitions' => array(
                defined('WP_CONTENT_DIR') ? WP_CONTENT_DIR . '/gymai-seed/pop20-batch3.php' : '',
                defined('WP_PLUGIN_DIR') ? WP_PLUGIN_DIR . '/gymai-popular-20-seed/pop20-batch3.php' : '',
            ),
            'gymai_pop20_batch4_definitions' => array(
                defined('WP_CONTENT_DIR') ? WP_CONTENT_DIR . '/gymai-seed/pop20-batch4.php' : '',
                defined('WP_PLUGIN_DIR') ? WP_PLUGIN_DIR . '/gymai-popular-20-seed/pop20-batch4.php' : '',
            ),
            'gymai_pop20_batch5_definitions' => array(
                defined('WP_CONTENT_DIR') ? WP_CONTENT_DIR . '/gymai-seed/pop20-batch5.php' : '',
                defined('WP_PLUGIN_DIR') ? WP_PLUGIN_DIR . '/gymai-popular-20-seed/pop20-batch5.php' : '',
            ),
            'gymai_pop20_batch6_definitions' => array(
                defined('WP_CONTENT_DIR') ? WP_CONTENT_DIR . '/gymai-seed/pop20-batch6.php' : '',
                defined('WP_PLUGIN_DIR') ? WP_PLUGIN_DIR . '/gymai-popular-20-seed/pop20-batch6.php' : '',
            ),
            'gymai_pop20_batch7_definitions' => array(
                defined('WP_CONTENT_DIR') ? WP_CONTENT_DIR . '/gymai-seed/pop20-batch7.php' : '',
                defined('WP_PLUGIN_DIR') ? WP_PLUGIN_DIR . '/gymai-popular-20-seed/pop20-batch7.php' : '',
            ),
            'gymai_pop20_batch8_definitions' => array(
                defined('WP_CONTENT_DIR') ? WP_CONTENT_DIR . '/gymai-seed/pop20-batch8.php' : '',
                defined('WP_PLUGIN_DIR') ? WP_PLUGIN_DIR . '/gymai-popular-20-seed/pop20-batch8.php' : '',
            ),
            'gymai_pop20_batch9_definitions' => array(
                defined('WP_CONTENT_DIR') ? WP_CONTENT_DIR . '/gymai-seed/pop20-batch9.php' : '',
                defined('WP_PLUGIN_DIR') ? WP_PLUGIN_DIR . '/gymai-popular-20-seed/pop20-batch9.php' : '',
            ),
            'gymai_pop20_batch10_definitions' => array(
                defined('WP_CONTENT_DIR') ? WP_CONTENT_DIR . '/gymai-seed/pop20-batch10.php' : '',
                defined('WP_PLUGIN_DIR') ? WP_PLUGIN_DIR . '/gymai-popular-20-seed/pop20-batch10.php' : '',
            ),
            'gymai_pop20_batch11_definitions' => array(
                defined('WP_CONTENT_DIR') ? WP_CONTENT_DIR . '/gymai-seed/pop20-batch11.php' : '',
                defined('WP_PLUGIN_DIR') ? WP_PLUGIN_DIR . '/gymai-popular-20-seed/pop20-batch11.php' : '',
            ),
        );

        foreach ($map as $func => $paths) {
            if (function_exists($func)) {
                continue;
            }
            foreach ($paths as $path) {
                if ($path !== '' && is_readable($path)) {
                    require_once $path;
                    break;
                }
            }
        }
    }
}

if (!function_exists('gymai_pop20_batch_status')) {
    function gymai_pop20_batch_status() {
        gymai_pop20_load_batch_files();
        return array(
            'batch1' => function_exists('gymai_pop20_batch1_definitions'),
            'batch2' => function_exists('gymai_pop20_batch2_definitions'),
            'batch3' => function_exists('gymai_pop20_batch3_definitions'),
            'batch4' => function_exists('gymai_pop20_batch4_definitions'),
            'batch5' => function_exists('gymai_pop20_batch5_definitions'),
            'batch6' => function_exists('gymai_pop20_batch6_definitions'),
            'batch7' => function_exists('gymai_pop20_batch7_definitions'),
            'batch8' => function_exists('gymai_pop20_batch8_definitions'),
            'batch9' => function_exists('gymai_pop20_batch9_definitions'),
            'batch10' => function_exists('gymai_pop20_batch10_definitions'),
            'batch11' => function_exists('gymai_pop20_batch11_definitions'),
        );
    }
}

if (!function_exists('gymai_pop20_get_seeded_exercise_ids')) {
    function gymai_pop20_get_seeded_exercise_ids() {
        $by_meta = get_posts(array(
            'post_type' => GYMAI_EXERCISE_POST_TYPE,
            'post_status' => array('publish', 'draft', 'pending', 'private'),
            'posts_per_page' => -1,
            'fields' => 'ids',
            'meta_key' => '_gymai_v2_meta_saved',
            'orderby' => 'ID',
            'order' => 'ASC',
        ));

        $by_keyword = get_posts(array(
            'post_type' => GYMAI_EXERCISE_POST_TYPE,
            'post_status' => array('publish', 'draft', 'pending', 'private'),
            'posts_per_page' => -1,
            'fields' => 'ids',
            'meta_query' => array(
                array(
                    'key' => 'rank_math_focus_keyword',
                    'value' => '',
                    'compare' => '!=',
                ),
            ),
            'orderby' => 'ID',
            'order' => 'ASC',
        ));

        $ids = array_merge(
            is_array($by_meta) ? $by_meta : array(),
            is_array($by_keyword) ? $by_keyword : array()
        );

        return array_values(array_unique(array_map('intval', $ids)));
    }
}

if (!function_exists('gymai_pop20_schedule_rank_math_recalc')) {
    function gymai_pop20_schedule_rank_math_recalc(array $post_ids) {
        $post_ids = array_values(array_unique(array_filter(array_map('intval', $post_ids))));
        if (empty($post_ids)) {
            return;
        }
        set_transient('gymai_pop20_recalc_ids', $post_ids, 5 * MINUTE_IN_SECONDS);
    }
}

if (!function_exists('gymai_pop20_handle_admin_request')) {
    function gymai_pop20_handle_admin_request() {
        if (!is_admin() || !current_user_can('manage_options')) {
            return;
        }

        $page = isset($_GET['page']) ? sanitize_key(wp_unslash($_GET['page'])) : '';
        if ($page !== 'gymai-popular-20-exercises') {
            return;
        }

        if (!isset($_POST['gymai_pop20_nonce']) || !wp_verify_nonce(sanitize_text_field(wp_unslash($_POST['gymai_pop20_nonce'])), 'gymai_pop20')) {
            return;
        }

        gymai_pop20_load_batch_files();
        $status = gymai_pop20_batch_status();
        $flash = array(
            'result' => null,
            'batch_label' => '',
            'recalc_scheduled' => false,
        );

        if (!empty($_POST['recalc_scores_only'])) {
            $ids = gymai_pop20_get_seeded_exercise_ids();
            gymai_pop20_schedule_rank_math_recalc($ids);
            $flash['recalc_scheduled'] = !empty($ids);
            $flash['batch_label'] = 'محاسبه امتیاز Rank Math';
        } else {
            $update = !empty($_POST['update_existing']);
            $which = isset($_POST['batch']) ? sanitize_key(wp_unslash($_POST['batch'])) : '';

            if ($which === '1' && $status['batch1']) {
                $flash['result'] = gymai_pop20_run_batch(gymai_pop20_batch1_definitions(), $update);
                $flash['batch_label'] = '۱۰ حرکت اول';
            } elseif ($which === '2' && $status['batch2']) {
                $flash['result'] = gymai_pop20_run_batch(gymai_pop20_batch2_definitions(), $update);
                $flash['batch_label'] = '۱۰ حرکت دوم';
            } elseif ($which === '3' && $status['batch3']) {
                $flash['result'] = gymai_pop20_run_batch(gymai_pop20_batch3_definitions(), $update);
                $flash['batch_label'] = '۲۰ حرکت سوم (۲۱–۴۰)';
            } elseif ($which === '4' && $status['batch4']) {
                $flash['result'] = gymai_pop20_run_batch(gymai_pop20_batch4_definitions(), $update);
                $flash['batch_label'] = '۲۰ حرکت چهارم (۴۱–۶۰)';
            } elseif ($which === '5' && $status['batch5']) {
                $flash['result'] = gymai_pop20_run_batch(gymai_pop20_batch5_definitions(), $update);
                $flash['batch_label'] = '۲۰ حرکت پنجم (۶۱–۸۰)';
            } elseif ($which === '6' && $status['batch6']) {
                $flash['result'] = gymai_pop20_run_batch(gymai_pop20_batch6_definitions(), $update);
                $flash['batch_label'] = '۲۰ حرکت ششم (۸۱–۱۰۰)';
            } elseif ($which === '7' && $status['batch7']) {
                $flash['result'] = gymai_pop20_run_batch(gymai_pop20_batch7_definitions(), $update);
                $flash['batch_label'] = '۲۰ حرکت هفتم (۱۰۱–۱۲۰)';
            } elseif ($which === '8' && $status['batch8']) {
                $flash['result'] = gymai_pop20_run_batch(gymai_pop20_batch8_definitions(), $update);
                $flash['batch_label'] = '۲۰ حرکت هشتم (۱۲۱–۱۴۰)';
            } elseif ($which === '9' && $status['batch9']) {
                $flash['result'] = gymai_pop20_run_batch(gymai_pop20_batch9_definitions(), $update);
                $flash['batch_label'] = '۲۰ حرکت نهم (۱۴۱–۱۶۰)';
            } elseif ($which === '10' && $status['batch10']) {
                $flash['result'] = gymai_pop20_run_batch(gymai_pop20_batch10_definitions(), $update);
                $flash['batch_label'] = '۲۰ حرکت دهم (۱۶۱–۱۸۰)';
            } elseif ($which === '11' && $status['batch11']) {
                $flash['result'] = gymai_pop20_run_batch(gymai_pop20_batch11_definitions(), $update);
                $flash['batch_label'] = '۲۰ حرکت یازدهم (۱۸۱–۲۰۰)';
            } else {
                $flash['result'] = array(
                    'created' => 0,
                    'skipped' => 0,
                    'updated' => 0,
                    'errors' => array(
                        'داده batch لود نشد. اسنیپت BATCH را فعال کن یا فایل pop20-batchN.php را در wp-content/gymai-seed/ بگذار.',
                    ),
                    'touched_ids' => array(),
                );
            }

            if (is_array($flash['result']) && !empty($flash['result']['touched_ids'])) {
                gymai_pop20_schedule_rank_math_recalc($flash['result']['touched_ids']);
                $flash['recalc_scheduled'] = true;
            }
        }

        set_transient('gymai_pop20_admin_flash', $flash, MINUTE_IN_SECONDS);
    }
    add_action('admin_init', 'gymai_pop20_handle_admin_request');
}

if (!function_exists('gymai_pop20_admin_enqueue_recalc')) {
    function gymai_pop20_admin_enqueue_recalc($hook) {
        if ($hook !== 'tools_page_gymai-popular-20-exercises') {
            return;
        }
        $ids = get_transient('gymai_pop20_recalc_ids');
        if (empty($ids) || !is_array($ids)) {
            return;
        }
        delete_transient('gymai_pop20_recalc_ids');
        gymai_pop20_enqueue_rank_math_recalc($ids);
    }
    add_action('admin_enqueue_scripts', 'gymai_pop20_admin_enqueue_recalc');
}

if (!function_exists('gymai_pop20_admin_page')) {
    function gymai_pop20_admin_page() {
        if (!current_user_can('manage_options')) {
            wp_die('دسترسی کافی ندارید.');
        }

        gymai_pop20_load_batch_files();
        $status = gymai_pop20_batch_status();

        $flash = get_transient('gymai_pop20_admin_flash');
        delete_transient('gymai_pop20_admin_flash');
        if (!is_array($flash)) {
            $flash = array(
                'result' => null,
                'batch_label' => '',
                'recalc_scheduled' => false,
            );
        }

        $result = $flash['result'];
        $batch_label = $flash['batch_label'];
        $recalc_scheduled = !empty($flash['recalc_scheduled']) || (bool) get_transient('gymai_pop20_recalc_ids');

        $b1_ok = $status['batch1'];
        $b2_ok = $status['batch2'];
        $b3_ok = $status['batch3'];
        $b4_ok = $status['batch4'];
        $b5_ok = $status['batch5'];
        $b6_ok = $status['batch6'];
        $b7_ok = $status['batch7'];
        $b8_ok = $status['batch8'];
        $b9_ok = $status['batch9'];
        $b10_ok = $status['batch10'];
        $b11_ok = $status['batch11'];
        $all_ok = $b1_ok && $b2_ok && $b3_ok && $b4_ok && $b5_ok && $b6_ok && $b7_ok && $b8_ok && $b9_ok && $b10_ok && $b11_ok;
        ?>
        <div class="wrap">
            <h1>GymAI Exercises (۲۰۰ حرکت پرطرفدار)</h1>
            <p>برای <strong>بروزرسانی سئو</strong> روی حرکات موجود، تیک «بروزرسانی موجود» را بزن و batch را دوباره اجرا کن.</p>
            <p>امتیاز Rank Math: بعد از ایجاد، از لیست پست‌ها «بروزرسانی» بزن (همان روشی که خودت انجام می‌دهی).</p>

            <?php if ($recalc_scheduled) : ?>
                <div class="notice notice-info"><p id="gymai-pop20-recalc-status">در صف محاسبه امتیاز Rank Math...</p></div>
            <?php endif; ?>

            <?php if (!$all_ok) : ?>
                <div class="notice notice-warning"><p>
                    <?php if (!$b1_ok) : ?><strong>Batch 1 لود نشد</strong> — اسنیپت یا <code>pop20-batch1.php</code><br><?php endif; ?>
                    <?php if (!$b2_ok) : ?><strong>Batch 2 لود نشد</strong> — اسنیپت یا <code>pop20-batch2.php</code><br><?php endif; ?>
                    <?php if (!$b3_ok) : ?><strong>Batch 3 لود نشد</strong> — اسنیپت یا <code>pop20-batch3.php</code><br><?php endif; ?>
                    <?php if (!$b4_ok) : ?><strong>Batch 4 لود نشد</strong> — اسنیپت یا <code>pop20-batch4.php</code><br><?php endif; ?>
                    <?php if (!$b5_ok) : ?><strong>Batch 5 لود نشد</strong> — اسنیپت یا <code>pop20-batch5.php</code><br><?php endif; ?>
                    <?php if (!$b6_ok) : ?><strong>Batch 6 لود نشد</strong> — اسنیپت یا <code>pop20-batch6.php</code><br><?php endif; ?>
                    <?php if (!$b7_ok) : ?><strong>Batch 7 لود نشد</strong> — اسنیپت یا <code>pop20-batch7.php</code><br><?php endif; ?>
                    <?php if (!$b8_ok) : ?><strong>Batch 8 لود نشد</strong> — اسنیپت یا <code>pop20-batch8.php</code><br><?php endif; ?>
                    <?php if (!$b9_ok) : ?><strong>Batch 9 لود نشد</strong> — اسنیپت یا <code>pop20-batch9.php</code><br><?php endif; ?>
                    <?php if (!$b10_ok) : ?><strong>Batch 10 لود نشد</strong> — اسنیپت یا <code>pop20-batch10.php</code><br><?php endif; ?>
                    <?php if (!$b11_ok) : ?><strong>Batch 11 لود نشد</strong> — اسنیپت یا <code>pop20-batch11.php</code><br><?php endif; ?>
                    مسیر پیشنهادی: <code>wp-content/gymai-seed/</code>
                </p></div>
            <?php else : ?>
                <div class="notice notice-info"><p>هر ۱۱ batch آماده‌اند — batch 7 تا 11 = ۱۰۰ حرکت جدید (۱۰۱ تا ۲۰۰).</p></div>
            <?php endif; ?>

            <?php if (is_array($result)) : ?>
                <div class="notice notice-success"><p>
                    <?php echo esc_html($batch_label); ?> —
                    ایجاد: <?php echo (int) $result['created']; ?> |
                    بروزرسانی: <?php echo (int) $result['updated']; ?> |
                    رد: <?php echo (int) $result['skipped']; ?>
                </p></div>
                <?php if (!empty($result['errors'])) : ?>
                    <details><summary>جزئیات</summary><ul>
                        <?php foreach ($result['errors'] as $e) : ?><li><?php echo esc_html($e); ?></li><?php endforeach; ?>
                    </ul></details>
                <?php endif; ?>
            <?php elseif ($batch_label !== '') : ?>
                <div class="notice notice-success"><p><?php echo esc_html($batch_label); ?> — در حال اجرا...</p></div>
            <?php endif; ?>

            <h2>Batch 1 — حرکات ۱ تا ۱۰</h2>
            <p>پرس سینه دمبل/هالتر، پرس سرشانه، بارفیکس، شنا، ددلیفت، فلای، کراس، پرس شیب‌دار، جلو بازو هالتر</p>
            <form method="post" style="margin-bottom:24px;">
                <?php wp_nonce_field('gymai_pop20', 'gymai_pop20_nonce'); ?>
                <input type="hidden" name="batch" value="1" />
                <p><label><input type="checkbox" name="update_existing" value="1" /> بروزرسانی موجود</label></p>
                <?php submit_button('اجرای ۱۰ حرکت اول', 'primary', 'submit', false); ?>
            </form>

            <h2>Batch 2 — حرکات ۱۱ تا ۲۰</h2>
            <p>جلو بازو دمبل، کرانچ، لانج، پشت بازو، کول، پای آویزان، کتل‌بل، رویینگ، شنا الماسی</p>
            <form method="post" style="margin-bottom:24px;">
                <?php wp_nonce_field('gymai_pop20', 'gymai_pop20_nonce'); ?>
                <input type="hidden" name="batch" value="2" />
                <p><label><input type="checkbox" name="update_existing" value="1" /> بروزرسانی موجود</label></p>
                <?php submit_button('اجرای ۱۰ حرکت دوم', 'secondary', 'submit', false); ?>
            </form>

            <h2>Batch 3 — حرکات ۲۱ تا ۴۰ (پرطرفدارترین‌ها)</h2>
            <p>اسکات گابلت، پرس سرشانه دمبل، زیربغل سیمکش، اکستنشن پا، هیپ تراست، رویینگ هالتر، نشر جانب، جلو بازو چکشی، اسپلیت اسکات، ساق، دراز نشست، پلانک جانبی، face pull، پول اور و...</p>
            <form method="post" style="margin-bottom:24px;">
                <?php wp_nonce_field('gymai_pop20', 'gymai_pop20_nonce'); ?>
                <input type="hidden" name="batch" value="3" />
                <p><label><input type="checkbox" name="update_existing" value="1" /> بروزرسانی موجود</label></p>
                <?php submit_button('اجرای ۲۰ حرکت سوم', 'primary', 'submit', false); ?>
            </form>

            <h2>Batch 4 — حرکات ۴۱ تا ۶۰</h2>
            <p>اسکات فرانت، پل باسن، جمع زانو، زیربغل دست جمع، نشر جلو، شراگ، پشت بازو سیمکش، شنا شیب منفی، رومانیایی دمبل، سومو، فارمر واک، چرخش روسی، کوهنورد و...</p>
            <form method="post" style="margin-bottom:24px;">
                <?php wp_nonce_field('gymai_pop20', 'gymai_pop20_nonce'); ?>
                <input type="hidden" name="batch" value="4" />
                <p><label><input type="checkbox" name="update_existing" value="1" /> بروزرسانی موجود</label></p>
                <?php submit_button('اجرای ۲۰ حرکت چهارم', 'secondary', 'submit', false); ?>
            </form>

            <h2>Batch 5 — حرکات ۶۱ تا ۸۰ (جدید)</h2>
            <p>اسکات اسمیت، پرس سینه شیب منفی، فلای سیمکش، تی‌بار، بارفیکس کمکی، چین آپ، پندلی‌رو، پرس زمین، پرس آرنولد، کیک بک، استپ آپ، ساق نشسته، گود مورنینگ، چرخ شکم و...</p>
            <form method="post" style="margin-bottom:24px;">
                <?php wp_nonce_field('gymai_pop20', 'gymai_pop20_nonce'); ?>
                <input type="hidden" name="batch" value="5" />
                <p><label><input type="checkbox" name="update_existing" value="1" /> بروزرسانی موجود</label></p>
                <?php submit_button('اجرای ۲۰ حرکت پنجم', 'primary', 'submit', false); ?>
            </form>

            <h2>Batch 6 — حرکات ۸۱ تا ۱۰۰ (جدید)</h2>
            <p>شنا با زانو، پرس سینه اسمیت، لگ پرس، جلو بازو اینکلاین، پشت بازو خرچنگ، فشار پشت بازو، کرانچ سیمکش، فلای پک، بورپی، ددباگ، پالوف، لانج هالتر، وال سیت و...</p>
            <form method="post">
                <?php wp_nonce_field('gymai_pop20', 'gymai_pop20_nonce'); ?>
                <input type="hidden" name="batch" value="6" />
                <p><label><input type="checkbox" name="update_existing" value="1" /> بروزرسانی موجود</label></p>
                <?php submit_button('اجرای ۲۰ حرکت ششم', 'secondary', 'submit', false); ?>
            </form>

            <h2>Batch 7 — حرکات ۱۰۱ تا ۱۲۰ (جدید)</h2>
            <p>اسکات جعبه، بلغاری هالتر، کوزاک، لندماین، نوردیک، هیپ تراست هالتر، تراپ بار، لانج جانبی، پرش جعبه و...</p>
            <form method="post" style="margin-bottom:24px;">
                <?php wp_nonce_field('gymai_pop20', 'gymai_pop20_nonce'); ?>
                <input type="hidden" name="batch" value="7" />
                <p><label><input type="checkbox" name="update_existing" value="1" /> بروزرسانی موجود</label></p>
                <?php submit_button('اجرای ۲۰ حرکت هفتم', 'primary', 'submit', false); ?>
            </form>

            <h2>Batch 8 — حرکات ۱۲۱ تا ۱۴۰ (جدید)</h2>
            <p>مدوز رو، رویینگ معکوس، بارفیکس دست باز، RDL هالتر، پول‌اور دمبل، inverted row و...</p>
            <form method="post" style="margin-bottom:24px;">
                <?php wp_nonce_field('gymai_pop20', 'gymai_pop20_nonce'); ?>
                <input type="hidden" name="batch" value="8" />
                <p><label><input type="checkbox" name="update_existing" value="1" /> بروزرسانی موجود</label></p>
                <?php submit_button('اجرای ۲۰ حرکت هشتم', 'secondary', 'submit', false); ?>
            </form>

            <h2>Batch 9 — حرکات ۱۴۱ تا ۱۶۰ (جدید)</h2>
            <p>پرس دمبل شیب، فلای زمین، پرس سوندر، پرس لندماین، HSPU، پرس اسمیت سرشانه و...</p>
            <form method="post" style="margin-bottom:24px;">
                <?php wp_nonce_field('gymai_pop20', 'gymai_pop20_nonce'); ?>
                <input type="hidden" name="batch" value="9" />
                <p><label><input type="checkbox" name="update_existing" value="1" /> بروزرسانی موجود</label></p>
                <?php submit_button('اجرای ۲۰ حرکت نهم', 'primary', 'submit', false); ?>
            </form>

            <h2>Batch 10 — حرکات ۱۶۱ تا ۱۸۰ (جدید)</h2>
            <p>پریچر کرل، EZ bar، concentration curl، ساعد، پشت بازو نشسته، 21s و...</p>
            <form method="post" style="margin-bottom:24px;">
                <?php wp_nonce_field('gymai_pop20', 'gymai_pop20_nonce'); ?>
                <input type="hidden" name="batch" value="10" />
                <p><label><input type="checkbox" name="update_existing" value="1" /> بروزرسانی موجود</label></p>
                <?php submit_button('اجرای ۲۰ حرکت دهم', 'secondary', 'submit', false); ?>
            </form>

            <h2>Batch 11 — حرکات ۱۸۱ تا ۲۰۰ (جدید)</h2>
            <p>V-Up، hollow body، battle ropes، box jump، thruster، clean &amp; press، jump rope، farmer walk و...</p>
            <form method="post">
                <?php wp_nonce_field('gymai_pop20', 'gymai_pop20_nonce'); ?>
                <input type="hidden" name="batch" value="11" />
                <p><label><input type="checkbox" name="update_existing" value="1" /> بروزرسانی موجود</label></p>
                <?php submit_button('اجرای ۲۰ حرکت یازدهم', 'primary', 'submit', false); ?>
            </form>
        </div>
        <?php
    }
}

if (!function_exists('gymai_pop20_register_admin_menu')) {
    function gymai_pop20_register_admin_menu() {
        add_management_page(
            'GymAI Exercises',
            'GymAI Exercises',
            'manage_options',
            'gymai-popular-20-exercises',
            'gymai_pop20_admin_page'
        );
    }
    add_action('admin_menu', 'gymai_pop20_register_admin_menu');
}
