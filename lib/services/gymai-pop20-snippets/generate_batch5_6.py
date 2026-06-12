# -*- coding: utf-8 -*-
"""Generate pop20-batch5.php and pop20-batch6.php from batch5_6_specs.py"""
import os
from batch5_6_specs import B5, B6, PROG

BASE = os.path.dirname(os.path.abspath(__file__))


def php_str(s):
    return "'" + s.replace("\\", "\\\\").replace("'", "\\'") + "'"


def spec_to_ex(row):
    (
        slug, title, en, main_m, sec, equip, diff, pattern, mech, force, posture,
        area, short, intro_tail, combo_slug, combo_title, rank_extra, targets,
    ) = row
    main_fa = {
        'quads': 'چهارسر', 'chest': 'سینه', 'back_lat': 'زیربغل', 'shoulder_anterior': 'سرشانه قدامی',
        'shoulder_lateral': 'سرشانه جانب', 'shoulder_posterior': 'سرشانه پشت', 'glutes': 'باسن',
        'hamstrings': 'همسترینگ', 'biceps': 'جلوبازو', 'triceps': 'پشت بازو', 'abs': 'شکم',
        'calves': 'ساق پا', 'lower_back': 'کمر', 'full_body': 'تمام بدن',
    }.get(main_m, area)
    sec_fa = '، '.join({
        'glutes': 'باسن', 'hamstrings': 'همسترینگ', 'abs': 'Core', 'triceps': 'پشت بازو',
        'shoulder_anterior': 'سرشانه', 'biceps': 'جلوبازو', 'rhomboids': 'پشت میانی',
        'traps_middle': 'ذوزنقه', 'obliques': 'پهلو', 'forearms': 'ساعد', 'lats': 'زیربغل',
    }.get(s, s) for s in sec) if sec else '—'
    equip_fa = {
        'machine': 'دستگاه', 'barbell': 'هالتر', 'dumbbell': 'دمبل', 'cable': 'سیم‌کش',
        'bench': 'نیمکت', 'bodyweight': 'وزن بدن', 'bar': 'میله', 'kettlebell': 'کتل‌بل',
    }
    eq_parts = []
    for e in equip:
        eq_parts.append(equip_fa.get(e, e))
    equip_display = ' و '.join(eq_parts)
    diff_fa = {'beginner': 'مبتدی', 'intermediate': 'متوسط', 'advanced': 'پیشرفته'}[diff]
    type_fa = 'ایزوله' if mech == 'isolation' else 'قدرتی / حجمی'

    intro = (
        f"<strong>{title}</strong> ({en}) {intro_tail} "
        f"در برنامه‌های بدنسازی و فیتنس ایران نام آشنایی است و معمولاً با {equip_display} اجرا می‌شود."
    )
    grip = 'pronated' if 'pull' in force and 'barbell' in equip else 'neutral'
    if posture in ('supine', 'prone', 'incline_seated', 'kneeling', 'bent_over', 'hanging', 'support'):
        pass
    if 'cable' in equip:
        res = 'cable_constant'
    elif 'machine' in equip:
        res = 'machine_stack'
    elif 'bodyweight' in equip:
        res = 'bodyweight'
    else:
        res = 'free_weight'

    meta = {
        'main_muscle': main_m,
        'secondary_muscle_keys': sec,
        'difficulty': diff,
        'equipment_keys': equip,
        'exercise_type': 'strength' if main_m != 'full_body' else 'conditioning',
        'movement_pattern': pattern,
        'body_engagement': mech,
        'mechanics_type': mech,
        'force_type': force,
        'plane_of_motion': 'sagittal',
        'laterality': 'bilateral',
        'posture': posture,
        'grip_type': grip,
        'resistance_profile': res,
        'joint_focus': 'multi',
        'muscle_targets': targets,
        'met': 4 if mech == 'isolation' else 5.5,
        'movement_distance_cm': 40 if mech == 'isolation' else 48,
        'calories_per_1000kg': 38 if mech == 'isolation' else 44,
        'exercise_difficulty_score': 3 if diff == 'beginner' else (5 if diff == 'advanced' else 4),
        'typical_rpe': 7 if diff == 'beginner' else 7.5,
        'estimated_1rm_formula': 'brzycki' if mech == 'compound' else '',
        'programming_goal': 'hypertrophy',
        'recommended_sets': '3-4',
        'rep_range_strength': '6-10',
        'rep_range_hypertrophy': '8-12',
        'rep_range_endurance': '12-15',
        'rest_seconds': 60 if mech == 'isolation' else 90,
        'tempo': '2-1-2',
        'short_description': short,
        'target_area': area,
    }

    return {
        'slug': slug,
        'title': title,
        'aliases': [en, en.replace(' ', ''), title],
        'intro': intro,
        'caption': f"{title} — {main_fa}، اجرای کنترل‌شده",
        'quick': {
            'main': main_fa,
            'secondary': sec_fa,
            'difficulty': diff_fa,
            'equipment': equip_display,
            'type': type_fa,
        },
        'tips': [
            f"تمرکز روی {main_fa} در تمام دامنه حرکت.",
            "تمپو کنترل‌شده؛ بدون پرتاب یا قلدری.",
            "گرم‌کردن مفصل و عضله قبل از ست سنگین.",
        ],
        'setup': [
            f"تنظیم {equip_display} و وضعیت بدن.",
            "وضعیت خنثی کمر و Core سفت.",
            "دامنه مفصل بدون درد.",
            "تنفس آماده قبل از شروع.",
        ],
        'execution': [
            "شروع کنترل‌شده از وضعیت اولیه.",
            "حرکت در مسیر صحیح بدون قفل اجباری مفصل.",
            "مکث کوتاه در نقطه انقباض (در صورت نیاز).",
            "بازگشت آهسته به وضعیت شروع.",
        ],
        'breathing': 'بازدم در فاز سخت — دم در فاز بازگشت.',
        'muscles': [
            f"اصلی: {main_fa}",
            f"کمکی: {sec_fa}" if sec_fa != '—' else "کمکی: عضلات کمکی",
            "تثبیت: Core و مفاصل اطراف",
        ],
        'mistakes': [
            ['پرتاب وزنه یا بدن', 'تمپو ۲-۱-۲'],
            ['دامنه ناقص', 'دامنه کامل بدون درد'],
            ['کمر یا شانه گرد', 'وضعیت خنثی'],
        ],
        'program': PROG,
        'combos': {'label': 'با ', 'link_text': combo_title, 'slug': combo_slug} if combo_slug else None,
        'faqs': [
            ['چند ست و تکرار؟', '۳–۴ ست × ۸–۱۲ برای حجم؛ ۴–۵ ست × ۵–۸ برای قدرت.'],
            ['برای مبتدی مناسب است؟', 'بله با وزنه سبک و تمرکز روی فرم.' if diff == 'beginner' else 'نیاز به تسلط پایه دارد؛ با وزنه سبک شروع کن.'],
        ],
        'summary': f"{title} برای {area} و {main_fa} در برنامه منظم نتیجه خوب می‌دهد.",
        'summary_keys': f"{main_fa} | تمپو کنترل | دامنه کامل",
        'meta': meta,
        'rank_extra': rank_extra,
    }


def emit_exercise(batch_num, idx, ex):
    ik = f"exercise-batch{batch_num}-{idx:02d}"
    lines = ["    $add(["]
    lines.append(f"        'image_key' => {php_str(ik)},")
    lines.append(f"        'slug' => {php_str(ex['slug'])},")
    lines.append(f"        'title' => {php_str(ex['title'])},")
    lines.append(f"        'aliases' => [{', '.join(php_str(a) for a in ex['aliases'])}],")
    lines.append(f"        'intro' => {php_str(ex['intro'])},")
    lines.append(f"        'caption' => {php_str(ex['caption'])},")
    q = ex['quick']
    lines.append(
        f"        'quick' => ['main' => {php_str(q['main'])}, 'secondary' => {php_str(q['secondary'])}, "
        f"'difficulty' => {php_str(q['difficulty'])}, 'equipment' => {php_str(q['equipment'])}, 'type' => {php_str(q['type'])}],"
    )
    lines.append(f"        'tips' => [{', '.join(php_str(t) for t in ex['tips'])}],")
    lines.append(f"        'setup' => [{', '.join(php_str(s) for s in ex['setup'])}],")
    lines.append(f"        'execution' => [{', '.join(php_str(e) for e in ex['execution'])}],")
    lines.append(f"        'breathing' => {php_str(ex['breathing'])},")
    lines.append(f"        'muscles' => [{', '.join(php_str(m) for m in ex['muscles'])}],")
    ms = ", ".join(f"[{php_str(m[0])}, {php_str(m[1])}]" for m in ex['mistakes'])
    lines.append(f"        'mistakes' => [{ms}],")
    pr = ", ".join(f"[{php_str(p[0])}, {php_str(p[1])}, {php_str(p[2])}, {php_str(p[3])}]" for p in ex['program'])
    lines.append(f"        'program' => [{pr}],")
    if ex.get('combos'):
        c = ex['combos']
        lines.append(
            f"        'combos' => [['label' => {php_str(c['label'])}, 'link_text' => {php_str(c['link_text'])}, 'slug' => {php_str(c['slug'])}]],"
        )
    else:
        lines.append("        'combos' => [],")
    fq = ", ".join(f"[{php_str(f[0])}, {php_str(f[1])}]" for f in ex['faqs'])
    lines.append(f"        'faqs' => [{fq}],")
    lines.append(f"        'summary' => {php_str(ex['summary'])},")
    lines.append(f"        'summary_keys' => {php_str(ex['summary_keys'])},")
    m = ex['meta']
    mt = ", ".join(f"{php_str(k)} => {v}" for k, v in m['muscle_targets'].items())
    sec = ", ".join(php_str(s) for s in m['secondary_muscle_keys'])
    eq = ", ".join(php_str(e) for e in m['equipment_keys'])
    lines.append("        'meta' => [")
    lines.append(f"            'main_muscle' => {php_str(m['main_muscle'])}, 'secondary_muscle_keys' => [{sec}],")
    lines.append(f"            'difficulty' => {php_str(m['difficulty'])}, 'equipment_keys' => [{eq}],")
    lines.append(
        f"            'exercise_type' => {php_str(m['exercise_type'])}, 'movement_pattern' => {php_str(m['movement_pattern'])}, "
        f"'body_engagement' => {php_str(m['body_engagement'])},"
    )
    lines.append(
        f"            'mechanics_type' => {php_str(m['mechanics_type'])}, 'force_type' => {php_str(m['force_type'])}, "
        f"'plane_of_motion' => {php_str(m['plane_of_motion'])}, 'laterality' => {php_str(m['laterality'])},"
    )
    lines.append(
        f"            'posture' => {php_str(m['posture'])}, 'grip_type' => {php_str(m['grip_type'])}, "
        f"'resistance_profile' => {php_str(m['resistance_profile'])}, 'joint_focus' => {php_str(m['joint_focus'])},"
    )
    lines.append(f"            'muscle_targets' => [{mt}],")
    lines.append(
        f"            'met' => {m['met']}, 'movement_distance_cm' => {m['movement_distance_cm']}, "
        f"'calories_per_1000kg' => {m['calories_per_1000kg']}, 'exercise_difficulty_score' => {m['exercise_difficulty_score']}, "
        f"'typical_rpe' => {m['typical_rpe']},"
    )
    lines.append(
        f"            'estimated_1rm_formula' => {php_str(m.get('estimated_1rm_formula', ''))}, "
        f"'programming_goal' => {php_str(m['programming_goal'])}, 'recommended_sets' => {php_str(m['recommended_sets'])},"
    )
    lines.append(
        f"            'rep_range_strength' => {php_str(m['rep_range_strength'])}, "
        f"'rep_range_hypertrophy' => {php_str(m['rep_range_hypertrophy'])}, "
        f"'rep_range_endurance' => {php_str(m['rep_range_endurance'])}, "
        f"'rest_seconds' => {m['rest_seconds']}, 'tempo' => {php_str(m['tempo'])},"
    )
    lines.append(f"            'short_description' => {php_str(m['short_description'])},")
    lines.append(f"            'target_area' => {php_str(m['target_area'])},")
    lines.append("        ],")
    lines.append(f"        'rank_extra' => {php_str(ex['rank_extra'])},")
    lines.append("    ]);")
    lines.append("")
    return "\n".join(lines)


def write_batch(batch_num, specs, func_name):
    header = f"""// GymAI Popular — BATCH {batch_num} (20 حرکت)
// Code Snippets: Run everywhere | بدون تگ php

if (!function_exists('{func_name}')) {{
function {func_name}() {{
    $base_img = 'https://gymaipro.ir/wp-content/uploads/2026/06/';
    $defs = [];
    $add = function (array $row) use (&$defs, $base_img) {{
        if (empty($row['image'])) {{
            $key = !empty($row['image_key']) ? $row['image_key'] : ('exercise-batch{batch_num}-' . str_pad((string) (count($defs) + 1), 2, '0', STR_PAD_LEFT));
            $row['image'] = $base_img . $key . '.jpg';
        }}
        $defs[] = $row;
    }};

"""
    body = []
    for i, row in enumerate(specs, 1):
        body.append(emit_exercise(batch_num, i, spec_to_ex(row)))
    footer = """
    return $defs;
}
}
"""
    path = os.path.join(BASE, f"pop20-batch{batch_num}.php")
    with open(path, "w", encoding="utf-8") as f:
        f.write(header + "\n".join(body) + footer)
    print(f"Wrote {path} ({len(specs)} exercises)")


if __name__ == "__main__":
    write_batch(5, B5, "gymai_pop20_batch5_definitions")
    write_batch(6, B6, "gymai_pop20_batch6_definitions")
