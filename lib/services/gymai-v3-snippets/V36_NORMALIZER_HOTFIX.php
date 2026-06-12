// ============================================================
// GymAI v3 Normalizer — جایگزینی ۳ تابع (v3.6 hotfix)
// این کد را داخل اسنیپت «GymAI v3 — API Normalizer» جایگزین کن.
// فقط همین ۳ تابع را پیدا کن و با نسخه زیر عوض کن.
// ============================================================

// --- 1) جایگزین gymai_norm3_detect_main_muscle ---

function gymai_norm3_detect_main_muscle($post_id, $raw_main, &$notes = array()) {
    $raw = gymai_norm3_map_value($raw_main, 'muscles', '');

    // اگر meta ذخیره‌شده معتبر است، inference را رد کن (باگ «لت» در «هالتر»)
    if ($raw !== '') {
        return $raw;
    }

    $text = gymai_norm3_text_bundle($post_id);
    $detected = '';

    if (gymai_norm3_has_any($text, array('pallof', 'پالوف', 'ضد چرخش'))) {
        $detected = 'abs';
    } elseif (gymai_norm3_has_any($text, array('lateral raise', 'نشر جانب', 'نشر جانبی'))) {
        $detected = 'shoulder_lateral';
    } elseif (gymai_norm3_has_any($text, array('rear delt', 'نشر خم', 'فلای معکوس'))) {
        $detected = 'shoulder_posterior';
    } elseif (gymai_norm3_has_any($text, array('triceps', 'skull crusher', 'پشت بازو', 'پشت‌بازو', 'french press', 'فرنچ'))) {
        $detected = 'triceps';
    } elseif (gymai_norm3_has_any($text, array('biceps', 'جلو بازو', 'جلوبازو'))) {
        $detected = 'biceps';
    } elseif (gymai_norm3_has_any($text, array('leg curl', 'پشت پا دستگاه', 'hamstring curl'))) {
        $detected = 'hamstrings';
    } elseif (gymai_norm3_has_any($text, array('hyperextension', 'هایپراکستنشن', 'فیله کمر'))) {
        $detected = 'lower_back';
    } elseif (gymai_norm3_has_any($text, array('plank', 'پلانک'))) {
        $detected = 'abs';
    } elseif (gymai_norm3_has_any($text, array('lunge', 'لانج', 'لایج'))) {
        $detected = 'quads';
    } elseif (gymai_norm3_has_any($text, array('leg press', 'پرس پا', 'squat', 'اسکوات', 'اسکات'))) {
        $detected = 'quads';
    } elseif (gymai_norm3_has_any($text, array('romanian deadlift', 'rdl', 'ددلیفت رومانیایی'))) {
        $detected = 'hamstrings';
    } elseif (gymai_norm3_has_any($text, array(
        'lat pulldown', 'pulldown', 'pull up', 'pullup', 'بارفیکس',
        'زیر بغل', 'زیربغل', 'lat pull',
    ))) {
        // عمداً «لت» تنها حذف شد — داخل «هالتر» match می‌شد
        $detected = 'back_lat';
    } elseif (gymai_norm3_has_any($text, array('chest press', 'bench press', 'پرس سینه', 'dip', 'dips', 'شنا سوئدی'))) {
        $detected = 'chest';
    } elseif (gymai_norm3_has_any($text, array('shoulder press', 'پرس سرشانه'))) {
        $detected = 'shoulders';
    }

    if ($detected === '') {
        $detected = 'full_body';
    }
    if ($raw !== '' && $detected !== $raw) {
        $notes[] = 'main_muscle corrected: ' . $raw . ' → ' . $detected;
    }
    if ($raw === '' && $detected !== '') {
        $notes[] = 'main_muscle inferred: ' . $detected;
    }
    return $detected;
}

// --- 2) جایگزین gymai_norm3_detect_movement (بخش lat + lunge + pallof) ---
// در تابع detect_movement موجود، این تغییرات را اعمال کن:
//
// A) قبل از leg press، اضافه کن:
//    elseif (gymai_norm3_has_any($text, array('pallof', 'پالوف'))) {
//        $detected = 'anti_rotation';
//    } elseif (gymai_norm3_has_any($text, array('lunge', 'لانج', 'لایج'))) {
//        $detected = 'lunge';
//
// B) در بلاک lat pulldown، «لت» را حذف کن:
//    'lat pulldown', 'pulldown', 'بارفیکس', 'pull up', 'pullup',
//    'زیر بغل سیم کش', 'زیربغل سیم کش', 'زیربغل', 'زیر بغل'
//    (بدون 'لت' تنها)

// --- 3) جایگزین gymai_norm3_get_muscle_targets — بلاک lat ---
// در if اول get_muscle_targets، «لت» را حذف کن:
//
// if (gymai_norm3_has_any($text, array(
//     'lat pulldown', 'pulldown', 'بارفیکس', 'pull up', 'pullup',
//     'زیر بغل سیم کش', 'زیربغل سیم کش', 'زیربغل', 'زیر بغل',
// ))) {
//
// و قبل از آن اضافه کن:
// elseif (gymai_norm3_has_any($text, array('lunge', 'لانج', 'لایج'))) {
//     gymai_norm3_target_set($targets, 'quads', 85, true);
//     gymai_norm3_target_set($targets, 'glutes', 75);
//     gymai_norm3_target_set($targets, 'hamstrings', 45);
//     $notes[] = 'muscle_targets adjusted for lunge';
// } elseif (gymai_norm3_has_any($text, array('pallof', 'پالوف'))) {
//     gymai_norm3_target_set($targets, 'abs', 85, true);
//     gymai_norm3_target_set($targets, 'obliques', 70);
//     $notes[] = 'muscle_targets adjusted for pallof';
