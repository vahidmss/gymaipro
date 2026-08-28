// GymAI Popular — BATCH 17 (۴ حرکت — کاردیو باشگاهی ۳۰۱ تا ۳۰۴)
// Code Snippets: Run everywhere | بدون تگ php
// هوازی واقعی: زمان‌محور، نه ست × تکرار قدرتی.
// MET از Compendium of Physical Activities (Ainsworth 2011).

if (!function_exists('gymai_pop20_batch17_definitions')) {
function gymai_pop20_batch17_definitions() {
    $base_img = 'https://gymaipro.ir/wp-content/uploads/2026/08/';
    $defs = [];
    $add = function (array $row) use (&$defs, $base_img) {
        if (empty($row['image'])) {
            $key = !empty($row['image_key']) ? $row['image_key'] : ('exercise-batch17-' . str_pad((string) (count($defs) + 1), 2, '0', STR_PAD_LEFT));
            $row['image'] = $base_img . $key . '.jpg';
        }
        $defs[] = $row;
    };

    $add([
        'image_key' => 'exercise-batch17-01',
        'slug' => 'تردمیل',
        'title' => 'تردمیل',
        'aliases' => [
            'Treadmill Walk',
            'Treadmill',
            'تردمیل پیاده‌روی',
            'پیاده‌روی تردمیل',
            'پیاده روی تردمیل',
            'گرم کردن تردمیل',
            'Walking',
        ],
        'intro' => '<strong>تردمیل</strong> (Treadmill Walk) پیاده‌روی روی نوار متحرک؛ رایج‌ترین گرم‌کردن و پایان جلسه در باشگاه‌های ایران است. برای تازه‌وارد سرعت ۴–۵ کیلومتر در ساعت، شیب ۰–۲٪، بدون دویدن.',
        'caption' => 'تردمیل — پیاده‌روی کنترل‌شده برای گرم‌کردن',
        'quick' => [
            'main' => 'کل بدن',
            'secondary' => 'چهارسر، همسترینگ، باسن، ساق',
            'difficulty' => 'مبتدی',
            'equipment' => 'دستگاه',
            'type' => 'هوازی',
        ],
        'tips' => [
            'دست‌ها کنار بدن تاب بخورد؛ به دسته‌ها آویزان نشوید مگر برای تعادل لحظه‌ای.',
            'نگاه جلو؛ قدم کامل پاشنه به پنجه؛ بدون پرش.',
            'اگر حرف زدن سخت شد، سرعت را کم کنید (RPE حدود ۳–۴ از ۱۰).',
        ],
        'setup' => [
            'کنار نوار بایستید؛ کلیپ ایمنی را به لباس وصل کنید.',
            'با سرعت خیلی کم (حدود ۲–۳ کیلومتر در ساعت) شروع کنید، بعد به ۴–۵ برسید.',
            'شیب را در شروع ۰ بگذارید؛ بعد از ۲ دقیقه می‌توانید ۱–۲٪ اضافه کنید.',
            'کفش ورزشی، ستون فقرات خنثی، شکم کمی سفت.',
        ],
        'execution' => [
            'روی نوار در مرکز بمانید؛ به عقب یا جلو بیش از حد نزدیک نشوید.',
            'گام طبیعی؛ پاشنه اول فرود بیاید.',
            'بازوها مثل پیاده‌روی معمولی تاب بخورند.',
            'برای توقف: سرعت را کم کنید، نوار که ایستاد پیاده شوید — هرگز در حال حرکت نپرید.',
        ],
        'breathing' => 'تنفس بینی/دهان آرام و منظم؛ اگر نفس‌نفس شدید شد سرعت را کم کنید.',
        'muscles' => [
            'اصلی: کل بدن (الگوی گام)',
            'کمکی: چهارسر، همسترینگ، باسن، ساق',
            'تثبیت: Core و مچ پا',
        ],
        'mistakes' => [
            ['گرفتن دسته و خم شدن به جلو', 'دست‌ها آزاد؛ تنه صاف'],
            ['دویدن از جلسه اول', 'تا عادت قلبی-تنفسی نیاید فقط پیاده بروید'],
            ['شیب زیاد یا سرعت ناگهانی', '۴–۵ کیلومتر، شیب حداکثر ۲٪'],
        ],
        'program' => [
            ['گرم‌کردن', '1', '۵–۱۰ دقیقه', '—'],
            ['پایان جلسه', '1', '۵–۸ دقیقه', '—'],
            ['هوازی جدا', '1', '۲۰–۳۰ دقیقه', '—'],
        ],
        'combos' => [['label' => 'جایگزین گرم‌کردن: ', 'link_text' => 'دوچرخه ثابت', 'slug' => 'دوچرخه-ثابت']],
        'faqs' => [
            ['q' => 'چند دقیقه؟', 'a' => 'گرم‌کردن ۵–۱۰ دقیقه پیاده‌روی. پایان جلسه ۵–۸ دقیقه آرام. جلسه هوازی جدا ۲۰–۳۰ دقیقه.'],
            ['q' => 'برای مبتدی مناسب است؟', 'a' => 'بله؛ امن‌ترین ورود به باشگاه. دویدن را با حرکت جداگانه «تردمیل دویدن» شروع کنید.'],
        ],
        'summary' => 'تردمیل پیاده‌روی برای گرم‌کردن و ورود ایمن تازه‌وارد به باشگاه استاندارد است.',
        'summary_keys' => 'هوازی | گام | ۵–۱۰ دقیقه',
        'contraindications' => [
            'درد قفسه سینه، تنگی نفس غیرعادی یا سرگیجه — توقف و مراجعه پزشکی',
            'آسیب حاد مچ پا یا زانو که با گام زدن بدتر می‌شود',
        ],
        'meta' => [
            'main_muscle' => 'full_body', 'secondary_muscle_keys' => ['quads', 'hamstrings', 'glutes', 'calves'],
            'difficulty' => 'beginner', 'equipment_keys' => ['machine'],
            'exercise_type' => 'cardio', 'movement_pattern' => 'gait', 'body_engagement' => 'compound',
            'mechanics_type' => 'compound', 'force_type' => 'dynamic', 'plane_of_motion' => 'sagittal', 'laterality' => 'bilateral',
            'posture' => 'standing', 'grip_type' => '', 'resistance_profile' => 'machine_stack', 'joint_focus' => 'multi',
            'muscle_targets' => ['quads' => 50, 'hamstrings' => 45, 'glutes' => 40, 'calf' => 45, 'abs' => 30],
            'met' => 3.5, 'movement_distance_cm' => 0, 'calories_per_1000kg' => 0, 'exercise_difficulty_score' => 2, 'typical_rpe' => 3.5,
            'estimated_1rm_formula' => '', 'programming_goal' => 'conditioning', 'recommended_sets' => '1',
            'rep_range_strength' => '—', 'rep_range_hypertrophy' => '۵–۱۰ دقیقه', 'rep_range_endurance' => '۲۰–۳۰ دقیقه',
            'rest_seconds' => 0, 'tempo' => 'پیوسته',
            'short_description' => 'پیاده‌روی تردمیل ۴–۵ کیلومتر در ساعت برای گرم‌کردن مبتدی (MET حدود ۳٫۵).',
            'target_area' => 'هوازی',
        ],
        'rank_extra' => 'Compendium: walking ~3.0 mph ≈ 3.5 MET.',
    ]);

    $add([
        'image_key' => 'exercise-batch17-02',
        'slug' => 'تردمیل-دویدن',
        'title' => 'تردمیل دویدن',
        'aliases' => [
            'Treadmill Run',
            'Treadmill Jog',
            'Jogging',
            'دویدن تردمیل',
            'دویدن آرام تردمیل',
            'جاگینگ',
        ],
        'intro' => '<strong>تردمیل دویدن</strong> (Treadmill Jog) دویدن یا جاگ آرام روی نوار. برای کسی که چند هفته پیاده‌روی را تحمل کرده؛ تازه‌وارد هفتهٔ اول با «تردمیل» (پیاده‌روی) شروع کند، نه با این حرکت.',
        'caption' => 'تردمیل دویدن — جاگ آرام، نه اسپرینت',
        'quick' => [
            'main' => 'کل بدن',
            'secondary' => 'چهارسر، همسترینگ، باسن، ساق',
            'difficulty' => 'متوسط',
            'equipment' => 'دستگاه',
            'type' => 'هوازی',
        ],
        'tips' => [
            'جاگ آرام ۷–۹ کیلومتر در ساعت؛ اسپرینت برای مبتدی ممنوع.',
            'شیب ۰–۱٪ کافی است؛ شیب بالا فشار زانو را زیاد می‌کند.',
            'اگر نتوانستید جمله بگویید، سرعت زیاد است.',
        ],
        'setup' => [
            '۵ دقیقه پیاده‌روی روی همین دستگاه قبل از دویدن.',
            'کلیپ ایمنی وصل باشد.',
            'بعد از دویدن ۲–۳ دقیقه پیاده‌روی برای سرد کردن.',
            'کفش دویدن با کفی مناسب.',
        ],
        'execution' => [
            'از پیاده‌روی به جاگ برسید؛ سرعت را یک‌باره بالا نبرید.',
            'فرود نرم روی میان‌پا؛ پاشنه نکوبید.',
            'تنه کمی جلو، نگاه افق.',
            'پایان: سرعت را پله‌ای کم کنید تا پیاده‌روی، بعد پیاده شوید.',
        ],
        'breathing' => 'ریتم ۲ گام دم / ۲ گام بازدم؛ اگر بریده شد سرعت را کم کنید.',
        'muscles' => [
            'اصلی: کل بدن (الگوی دویدن)',
            'کمکی: چهارسر، همسترینگ، باسن، ساق',
            'تثبیت: Core و مچ پا',
        ],
        'mistakes' => [
            ['شروع با سرعت بالا', 'اول پیاده‌روی، بعد جاگ'],
            ['گرفتن دسته هنگام دویدن', 'تعادل خود بدن'],
            ['پریدن از روی نوار در حال حرکت', 'اول توقف کامل'],
        ],
        'program' => [
            ['جاگ آسان', '1', '۸–۱۵ دقیقه', '—'],
            ['اینتروال مبتدی', '1', '۱ دقیقه جاگ / ۱ دقیقه پیاده × ۶', '—'],
            ['هوازی', '1', '۲۰ دقیقه', '—'],
        ],
        'combos' => [['label' => 'نسخه مبتدی: ', 'link_text' => 'تردمیل', 'slug' => 'تردمیل']],
        'faqs' => [
            ['q' => 'از کی بدوم؟', 'a' => 'بعد از ۲–۴ هفته پیاده‌روی منظم بدون درد زانو یا تنگی نفس غیرعادی.'],
            ['q' => 'برای تازه‌وارد هفته اول؟', 'a' => 'خیر. در برنامهٔ شروع باشگاه فقط پیاده‌روی «تردمیل» استفاده شود.'],
        ],
        'summary' => 'جاگ روی تردمیل برای هوازی بعد از یادگیری پیاده‌روی؛ برای هفتهٔ اول مبتدی مناسب نیست.',
        'summary_keys' => 'هوازی | جاگ | ۷–۹ کیلومتر',
        'contraindications' => [
            'درد قفسه سینه، آسم کنترل‌نشده، یا فشار خون کنترل‌نشده بدون تأیید پزشک',
            'آسیب حاد زانو، شین اسپلینت، یا درد مچ پا',
        ],
        'meta' => [
            'main_muscle' => 'full_body', 'secondary_muscle_keys' => ['quads', 'hamstrings', 'glutes', 'calves'],
            'difficulty' => 'intermediate', 'equipment_keys' => ['machine'],
            'exercise_type' => 'cardio', 'movement_pattern' => 'cardio', 'body_engagement' => 'compound',
            'mechanics_type' => 'compound', 'force_type' => 'dynamic', 'plane_of_motion' => 'sagittal', 'laterality' => 'bilateral',
            'posture' => 'standing', 'grip_type' => '', 'resistance_profile' => 'machine_stack', 'joint_focus' => 'multi',
            'muscle_targets' => ['quads' => 55, 'hamstrings' => 50, 'glutes' => 45, 'calf' => 50, 'abs' => 35],
            'met' => 8.0, 'movement_distance_cm' => 0, 'calories_per_1000kg' => 0, 'exercise_difficulty_score' => 4, 'typical_rpe' => 6,
            'estimated_1rm_formula' => '', 'programming_goal' => 'endurance', 'recommended_sets' => '1',
            'rep_range_strength' => '—', 'rep_range_hypertrophy' => '۸–۱۵ دقیقه', 'rep_range_endurance' => '۲۰ دقیقه',
            'rest_seconds' => 0, 'tempo' => 'پیوسته',
            'short_description' => 'جاگ تردمیل حدود ۷–۹ کیلومتر در ساعت (MET حدود ۸)؛ بعد از یادگیری پیاده‌روی.',
            'target_area' => 'هوازی',
        ],
        'rank_extra' => 'Compendium: jogging general ≈ 7.0–8.3 MET.',
    ]);

    $add([
        'image_key' => 'exercise-batch17-03',
        'slug' => 'دوچرخه-ثابت',
        'title' => 'دوچرخه ثابت',
        'aliases' => [
            'Stationary Bike',
            'Exercise Bike',
            'Upright Bike',
            'بایک ثابت',
            'دوچرخه باشگاه',
            'دوچرخه ایستاده',
        ],
        'intro' => '<strong>دوچرخه ثابت</strong> (Stationary / Upright Bike) پدال‌زنی نشسته روی دوچرخهٔ سالن. جایگزین رایج تردمیل وقتی نوار شلوغ است یا زانو با دویدن راحت نیست. با «کرانچ دوچرخه» (حرکت شکم روی زمین) فرق دارد.',
        'caption' => 'دوچرخه ثابت — گرم‌کردن کم‌ضربه',
        'quick' => [
            'main' => 'کل بدن',
            'secondary' => 'چهارسر، همسترینگ، ساق',
            'difficulty' => 'مبتدی',
            'equipment' => 'دستگاه',
            'type' => 'هوازی',
        ],
        'tips' => [
            'زین طوری باشد که در پایین‌ترین نقطه زانو کمی خم بماند (قفل کامل نه).',
            'مقاومت سبک تا متوسط؛ زانو نباید به داخل جمع شود.',
            'دست‌ها روی دسته بدون آویزان شدن با وزن بدن.',
        ],
        'setup' => [
            'ارتفاع زین: پاشنه روی پدال در پایین، زانو تقریباً صاف — بعد پنجه روی پدال، زانو کمی خم.',
            'دسته را طوری بگیرید که شانه بالا نرود.',
            'مقاومت را از کم شروع کنید.',
            'کفش بسته؛ بند پدال اگر هست محکم شود.',
        ],
        'execution' => [
            'پدال دایره‌ای و یکنواخت، نه فقط فشار دادن به پایین.',
            'تنه کمی جلو، کمر گرد نشود.',
            '۶۰–۸۰ دور در دقیقه برای گرم‌کردن کافی است.',
            'پایان: مقاومت را کم کنید، ۱ دقیقه آرام پدال بزنید، بعد پیاده شوید.',
        ],
        'breathing' => 'تنفس منظم؛ اگر ران می‌سوزد و نفس می‌برد مقاومت را کم کنید نه اینکه بایستید ناگهانی.',
        'muscles' => [
            'اصلی: چهارسر و الگوی هوازی پا',
            'کمکی: همسترینگ، ساق، باسن',
            'تثبیت: Core',
        ],
        'mistakes' => [
            ['زین خیلی پایین (زانو جلو می‌آید)', 'ارتفاع زین را درست کنید'],
            ['مقاومت خیلی سنگین از اول', 'گرم‌کردن با مقاومت کم'],
            ['قوز کردن روی دسته', 'سینه باز، شانه پایین'],
        ],
        'program' => [
            ['گرم‌کردن', '1', '۵–۱۰ دقیقه', '—'],
            ['پایان جلسه', '1', '۵–۸ دقیقه', '—'],
            ['هوازی', '1', '۱۵–۲۵ دقیقه', '—'],
        ],
        'combos' => [['label' => 'جایگزین: ', 'link_text' => 'تردمیل', 'slug' => 'تردمیل']],
        'faqs' => [
            ['q' => 'جای تردمیل می‌توانم بگذارم؟', 'a' => 'بله؛ برای گرم‌کردن ۵–۱۰ دقیقه معادل پیاده‌روی تردمیل است.'],
            ['q' => 'با کرانچ دوچرخه یکی است؟', 'a' => 'خیر. آن حرکت شکم روی زمین است. این دستگاه پدال سالن است.'],
        ],
        'summary' => 'دوچرخه ثابت گرم‌کردن کم‌ضربه و جایگزین تردمیل در باشگاه ایران است.',
        'summary_keys' => 'هوازی | پدال | ۵–۱۰ دقیقه',
        'contraindications' => [
            'درد حاد زانو که با پدال بدتر می‌شود',
            'بی‌حسی یا درد تیرکشنده به پا (بدون بررسی پزشکی)',
        ],
        'meta' => [
            'main_muscle' => 'full_body', 'secondary_muscle_keys' => ['quads', 'hamstrings', 'calves', 'glutes'],
            'difficulty' => 'beginner', 'equipment_keys' => ['machine'],
            'exercise_type' => 'cardio', 'movement_pattern' => 'cardio', 'body_engagement' => 'compound',
            'mechanics_type' => 'compound', 'force_type' => 'dynamic', 'plane_of_motion' => 'sagittal', 'laterality' => 'bilateral',
            'posture' => 'seated', 'grip_type' => 'neutral', 'resistance_profile' => 'machine_stack', 'joint_focus' => 'multi',
            'muscle_targets' => ['quads' => 60, 'hamstrings' => 40, 'calf' => 35, 'glutes' => 35, 'abs' => 20],
            'met' => 5.0, 'movement_distance_cm' => 0, 'calories_per_1000kg' => 0, 'exercise_difficulty_score' => 2, 'typical_rpe' => 4,
            'estimated_1rm_formula' => '', 'programming_goal' => 'conditioning', 'recommended_sets' => '1',
            'rep_range_strength' => '—', 'rep_range_hypertrophy' => '۵–۱۰ دقیقه', 'rep_range_endurance' => '۱۵–۲۵ دقیقه',
            'rest_seconds' => 0, 'tempo' => 'پیوسته',
            'short_description' => 'دوچرخه ثابت سالن، مقاومت سبک، ۶۰–۸۰ RPM برای گرم‌کردن (MET حدود ۵).',
            'target_area' => 'هوازی',
        ],
        'rank_extra' => 'Compendium: stationary cycling light–moderate ≈ 3.5–5.5 MET.',
    ]);

    $add([
        'image_key' => 'exercise-batch17-04',
        'slug' => 'الپتیکال',
        'title' => 'الپتیکال',
        'aliases' => [
            'Elliptical',
            'Elliptical Trainer',
            'Cross Trainer',
            'کراس ترینر',
            'الپتیکال دستگاه',
            'اسکی فضایی',
        ],
        'intro' => '<strong>الپتیکال</strong> (Elliptical / Cross Trainer) گام بیضوی روی دستگاه؛ کم‌ضربه‌تر از دویدن و کمی کامل‌تر از دوچرخه چون دست‌ها هم درگیر می‌شوند. جایگزین خوب تردمیل برای زانوی حساس.',
        'caption' => 'الپتیکال — گام بیضوی کم‌ضربه',
        'quick' => [
            'main' => 'کل بدن',
            'secondary' => 'چهارسر، باسن، همسترینگ، سرشانه',
            'difficulty' => 'مبتدی',
            'equipment' => 'دستگاه',
            'type' => 'هوازی',
        ],
        'tips' => [
            'پاشنه روی پدال بماند؛ روی پنجه بلند نشوید.',
            'دسته‌های متحرک را هل بدهید و بکشید؛ فقط پا کار نکند.',
            'مقاومت کم تا متوسط؛ اگر زانو صدا داد دامنه را کوچک‌تر کنید.',
        ],
        'setup' => [
            'پاها کامل روی پدال؛ بدن در مرکز دستگاه.',
            'دسته‌های متحرک را بگیرید (نه فقط دسته ثابت مگر تعادل لازم باشد).',
            'مقاومت و شیب (اگر دارد) از کم شروع شود.',
            'تنه صاف؛ به دسته آویزان نشوید.',
        ],
        'execution' => [
            'گام بیضوی نرم به جلو؛ زانو در مسیر پنجه.',
            'هماهنگی دست و پای مخالف مثل راه رفتن.',
            'ریتم ثابت؛ پرش یا کوبیدن پدال نباشد.',
            'پایان: مقاومت را کم کنید، ۱ دقیقه آرام، بعد بایستید و پیاده شوید.',
        ],
        'breathing' => 'تنفس پیوسته؛ شدت در حدی که بتوانید حرف بزنید.',
        'muscles' => [
            'اصلی: کل بدن (پا + دست)',
            'کمکی: چهارسر، باسن، همسترینگ، ساق، سرشانه',
            'تثبیت: Core',
        ],
        'mistakes' => [
            ['آویزان شدن از دسته', 'پا کار اصلی را بکند'],
            ['فقط پنجه روی پدال', 'کف پا کامل روی پدال'],
            ['مقاومت خیلی زیاد از اول', '۵–۱۰ دقیقه روان، بعد مقاومت'],
        ],
        'program' => [
            ['گرم‌کردن', '1', '۵–۱۰ دقیقه', '—'],
            ['پایان جلسه', '1', '۵–۸ دقیقه', '—'],
            ['هوازی', '1', '۱۵–۲۵ دقیقه', '—'],
        ],
        'combos' => [['label' => 'جایگزین: ', 'link_text' => 'تردمیل', 'slug' => 'تردمیل']],
        'faqs' => [
            ['q' => 'برای زانو بهتر از تردمیل است؟', 'a' => 'معمولاً بله؛ ضربهٔ فرود ندارد. اگر زانو درد دارد با مقاومت خیلی کم شروع کنید.'],
            ['q' => 'جای گرم‌کردن تردمیل؟', 'a' => 'بله؛ ۵–۱۰ دقیقه معادل پیاده‌روی است.'],
        ],
        'summary' => 'الپتیکال گرم‌کردن کم‌ضربه تمام‌بدن و جایگزین تردمیل برای زانوی حساس است.',
        'summary_keys' => 'هوازی | بیضوی | کم‌ضربه',
        'contraindications' => [
            'سرگیجه یا تعادل ضعیف روی دستگاه متحرک',
            'درد حاد شانه اگر دسته‌های متحرک درد می‌سازند — فقط دسته ثابت',
        ],
        'meta' => [
            'main_muscle' => 'full_body', 'secondary_muscle_keys' => ['quads', 'glutes', 'hamstrings', 'shoulder_anterior'],
            'difficulty' => 'beginner', 'equipment_keys' => ['machine'],
            'exercise_type' => 'cardio', 'movement_pattern' => 'cardio', 'body_engagement' => 'compound',
            'mechanics_type' => 'compound', 'force_type' => 'dynamic', 'plane_of_motion' => 'sagittal', 'laterality' => 'bilateral',
            'posture' => 'standing', 'grip_type' => 'neutral', 'resistance_profile' => 'machine_stack', 'joint_focus' => 'multi',
            'muscle_targets' => ['quads' => 50, 'glutes' => 45, 'hamstrings' => 40, 'calf' => 30, 'shoulder_anterior' => 30, 'abs' => 25],
            'met' => 5.0, 'movement_distance_cm' => 0, 'calories_per_1000kg' => 0, 'exercise_difficulty_score' => 2, 'typical_rpe' => 4,
            'estimated_1rm_formula' => '', 'programming_goal' => 'conditioning', 'recommended_sets' => '1',
            'rep_range_strength' => '—', 'rep_range_hypertrophy' => '۵–۱۰ دقیقه', 'rep_range_endurance' => '۱۵–۲۵ دقیقه',
            'rest_seconds' => 0, 'tempo' => 'پیوسته',
            'short_description' => 'الپتیکال / کراس‌ترینر، گام بیضوی کم‌ضربه برای گرم‌کردن (MET حدود ۵).',
            'target_area' => 'هوازی',
        ],
        'rank_extra' => 'Compendium: elliptical trainer, moderate ≈ 5.0 MET.',
    ]);

    return $defs;
}
}
