#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Merge batch1 (10) + catalog90 + catalog50 => foods_bulk_meta.json (150 items)."""
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).parent
JSON_PATH = ROOT.parent / 'foods_bulk_meta.json'
CATALOG90_PATH = ROOT / 'foods_catalog_90.json'
CATALOG50_PATH = ROOT / 'foods_catalog_50.json'

# گام‌های مجاز در متاباکس وردپرس (HTML step=0.1 اما 0.25 خطا می‌دهد)
ALLOWED_STEPS = {1, 0.5, 0.1, 10}

IMG = [
    'https://images.unsplash.com/photo-1498837167922-ddd27525b352?w=800&q=80',
    'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&q=80',
    'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800&q=80',
    'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=800&q=80',
    'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&q=80',
    'https://images.unsplash.com/photo-1482049016688-a7bd8fa7e6a1?w=800&q=80',
    'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=800&q=80',
    'https://images.unsplash.com/photo-1511690743698-d9d85f2fbf38?w=800&q=80',
    'https://images.unsplash.com/photo-1473093295045-ddd4c915dc20?w=800&q=80',
    'https://images.unsplash.com/photo-1455619452474-d2be8b1e70cb?w=800&q=80',
]


def slug_from_kw(kw: str) -> str:
    kw = (kw or '').strip()
    s = re.sub(r'\s+', '-', kw)
    return re.sub(r'-+', '-', s).strip('-')


def legacy_slug(title: str, aliases_en: list | None = None) -> str:
    base = (aliases_en[0] if aliases_en else title).lower()
    base = re.sub(r'[^\w\s-]', '', base)
    base = re.sub(r'[\s_]+', '-', base)
    return base.strip('-') or 'food-item'


def serving_template(kind: str, hint: str = '') -> dict:
    templates = {
        'protein': {
            'default_unit': 'palm_protein',
            'units': [
                {'key': 'palm_protein', 'label': 'کف دست (پروتئین)', 'grams': 85, 'step': 0.5, 'decimals': 1, 'is_primary': True, 'hint': hint or 'یک وعده پروتئین'},
                {'key': 'gram', 'label': 'گرم', 'grams': 1, 'step': 1, 'decimals': 0, 'is_primary': False, 'hint': ''},
            ],
        },
        'carb_cooked': {
            'default_unit': 'tablespoon',
            'units': [
                {'key': 'tablespoon', 'label': 'قاشق غذاخوری', 'grams': 15, 'step': 0.5, 'decimals': 1, 'is_primary': True, 'hint': 'پخته'},
                {'key': 'cup', 'label': 'پیمانه / لیوان', 'grams': 150, 'step': 0.5, 'decimals': 1, 'is_primary': False, 'hint': ''},
                {'key': 'palm_carb', 'label': 'کف دست (کربو)', 'grams': 20, 'step': 0.5, 'decimals': 1, 'is_primary': False, 'hint': ''},
                {'key': 'gram', 'label': 'گرم', 'grams': 1, 'step': 1, 'decimals': 0, 'is_primary': False, 'hint': ''},
            ],
        },
        'bread': {
            'default_unit': 'piece',
            'units': [
                {'key': 'piece', 'label': 'عدد / تکه', 'grams': 35, 'step': 0.5, 'decimals': 1, 'is_primary': True, 'hint': hint},
                {'key': 'palm_carb', 'label': 'کف دست (کربو)', 'grams': 20, 'step': 0.5, 'decimals': 1, 'is_primary': False, 'hint': ''},
                {'key': 'gram', 'label': 'گرم', 'grams': 1, 'step': 1, 'decimals': 0, 'is_primary': False, 'hint': ''},
            ],
        },
        'egg': {
            'default_unit': 'piece',
            'units': [
                {'key': 'piece', 'label': 'عدد', 'grams': 50, 'step': 1, 'decimals': 0, 'is_primary': True, 'hint': 'یک عدد بزرگ'},
                {'key': 'gram', 'label': 'گرم', 'grams': 1, 'step': 1, 'decimals': 0, 'is_primary': False, 'hint': ''},
            ],
        },
        'dairy_cup': {
            'default_unit': 'cup',
            'units': [
                {'key': 'cup', 'label': 'پیمانه', 'grams': 150, 'step': 0.5, 'decimals': 1, 'is_primary': True, 'hint': hint},
                {'key': 'tablespoon', 'label': 'قاشق غذاخوری', 'grams': 20, 'step': 1, 'decimals': 0, 'is_primary': False, 'hint': ''},
                {'key': 'gram', 'label': 'گرم', 'grams': 1, 'step': 1, 'decimals': 0, 'is_primary': False, 'hint': ''},
            ],
        },
        'liquid': {
            'default_unit': 'cup',
            'units': [
                {'key': 'cup', 'label': 'لیوان', 'grams': 240, 'step': 0.5, 'decimals': 1, 'is_primary': True, 'hint': ''},
                {'key': 'tablespoon', 'label': 'قاشق غذاخوری', 'grams': 15, 'step': 0.5, 'decimals': 1, 'is_primary': False, 'hint': ''},
                {'key': 'gram', 'label': 'گرم', 'grams': 1, 'step': 1, 'decimals': 0, 'is_primary': False, 'hint': ''},
            ],
        },
        'oil': {
            'default_unit': 'tablespoon',
            'units': [
                {'key': 'tablespoon', 'label': 'قاشق غذاخوری', 'grams': 14, 'step': 0.5, 'decimals': 1, 'is_primary': True, 'hint': ''},
                {'key': 'teaspoon', 'label': 'قاشق چای‌خوری', 'grams': 5, 'step': 0.5, 'decimals': 1, 'is_primary': False, 'hint': ''},
                {'key': 'gram', 'label': 'گرم', 'grams': 1, 'step': 1, 'decimals': 0, 'is_primary': False, 'hint': ''},
            ],
        },
        'nut': {
            'default_unit': 'gram',
            'units': [
                {'key': 'gram', 'label': 'گرم', 'grams': 1, 'step': 1, 'decimals': 0, 'is_primary': True, 'hint': 'وعده ۲۵–۳۰ گرم'},
                {'key': 'piece', 'label': 'عدد', 'grams': 1.2, 'step': 1, 'decimals': 0, 'is_primary': False, 'hint': ''},
            ],
        },
        'fruit': {
            'default_unit': 'piece',
            'units': [
                {'key': 'piece', 'label': 'عدد متوسط', 'grams': 120, 'step': 0.5, 'decimals': 1, 'is_primary': True, 'hint': hint},
                {'key': 'gram', 'label': 'گرم', 'grams': 1, 'step': 1, 'decimals': 0, 'is_primary': False, 'hint': ''},
            ],
        },
        'veg': {
            'default_unit': 'cup',
            'units': [
                {'key': 'cup', 'label': 'پیمانه', 'grams': 100, 'step': 0.5, 'decimals': 1, 'is_primary': True, 'hint': ''},
                {'key': 'gram', 'label': 'گرم', 'grams': 1, 'step': 1, 'decimals': 0, 'is_primary': False, 'hint': ''},
            ],
        },
        'scoop': {
            'default_unit': 'scoop',
            'units': [
                {'key': 'scoop', 'label': 'اسکوپ', 'grams': 30, 'step': 0.5, 'decimals': 1, 'is_primary': True, 'hint': 'حدود ۳۰ گرم پودر'},
                {'key': 'gram', 'label': 'گرم', 'grams': 1, 'step': 1, 'decimals': 0, 'is_primary': False, 'hint': ''},
            ],
        },
        'portion': {
            'default_unit': 'cup',
            'units': [
                {'key': 'cup', 'label': 'پیمانه', 'grams': 200, 'step': 0.5, 'decimals': 1, 'is_primary': True, 'hint': hint},
                {'key': 'gram', 'label': 'گرم', 'grams': 1, 'step': 1, 'decimals': 0, 'is_primary': False, 'hint': ''},
            ],
        },
    }
    return templates.get(kind, templates['veg'])


def normalize_serving_units(food: dict) -> None:
    su = food.get('serving_units')
    if not isinstance(su, dict):
        return
    units = su.get('units')
    if not isinstance(units, list):
        return
    for u in units:
        if not isinstance(u, dict):
            continue
        step = float(u.get('step', 1))
        if step == 0.25 or step not in ALLOWED_STEPS:
            u['step'] = 0.5 if step <= 0.75 else 1.0
        if int(u.get('decimals', 0)) > 1 and float(u.get('step', 1)) >= 0.5:
            u['decimals'] = 1


def expand_item(item: dict, idx: int) -> dict:
    title = item['title']
    kw = title
    slug = slug_from_kw(kw)
    group = item['food_group']
    unit_kind = item.get('unit_kind', 'veg')
    su = serving_template(unit_kind)
    fat = float(item['fat'])
    aliases = item.get('aliases_en', [title])
    return {
        'slug': slug,
        'title': title,
        'excerpt': f'مرجع علمی {title}: ماکروها و کالری در ۱۰۰ گرم — تغذیه ورزشی و بدنسازی.',
        'category': item['category'],
        'rank_math_title': f'{title} | کالری، پروتئین و ارزش غذایی در ۱۰۰ گرم',
        'rank_math_description': f'جدول تغذیه‌ای {title} در هر ۱۰۰ گرم. کاربرد در تغذیه ورزشی، GI و واحد سرو.',
        'rank_math_focus_keyword': kw,
        'name_app': title,
        'other_names': item.get('other_names', title),
        'food_group': group,
        'food_type': 'liquid' if unit_kind in ('liquid', 'oil') else 'solid',
        'meal_times': item['meal_times'],
        'nutrition_basis': 'per_100g',
        'serving_size_grams': '100',
        'default_serving_unit': su['default_unit'],
        'protein': str(item['protein']),
        'calories': str(item['calories']),
        'carbohydrates': str(item['carbohydrates']),
        'fat': str(fat),
        'saturated_fat': str(round(fat * 0.35, 1)),
        'fiber': str(item.get('fiber', 0)),
        'sugar': str(max(0, round(float(item['carbohydrates']) * 0.12, 1))),
        'cholesterol': '0' if group not in ('لبنیات', 'پروتئین') else '15',
        'sodium': str(item.get('sodium', 0)),
        'potassium': str(item.get('potassium', 0)),
        'glycemic_index': str(item.get('glycemic_index', 0)),
        'allergens': item.get('allergens', ''),
        'short_description': item['short_description'],
        'serving_notes': f'ارزش‌ها برای {title} در حالت استاندارد آماده مصرف (۱۰۰ گرم) گزارش شده است.',
        'tip_1': item['tip_1'],
        'tip_2': item['tip_2'],
        'tip_3': item['tip_3'],
        'substitutes_json': [],
        'serving_units': su,
        'legacy_slug': item.get('legacy_slug') or legacy_slug(title, aliases),
        'migrate_slugs': item.get('migrate_slugs') or [],
        'image_url': IMG[idx % len(IMG)],
        'aliases_en': aliases,
        'related_slugs': [],
        'intro': item.get('intro', f'{title} در مرجع تغذیه ورزشی GymAI Pro بررسی می‌شود.'),
        'substitutes': [],
    }


COMPLEMENT_GROUP = {
    'پروتئین': 'کربوهیدرات',
    'کربوهیدرات': 'پروتئین',
    'لبنیات': 'کربوهیدرات',
    'حبوبات': 'کربوهیدرات',
    'سبزیجات': 'پروتئین',
    'میوه': 'لبنیات',
    'چربی': 'پروتئین',
    'غذای آماده': 'سبزیجات',
    'مکمل': 'پروتئین',
}


def assign_related_and_substitutes(foods: list[dict]) -> None:
    by_group: dict[str, list[str]] = {}
    for f in foods:
        by_group.setdefault(f['food_group'], []).append(f['slug'])

    for f in foods:
        slug = f['slug']
        group = f['food_group']
        peers = [s for s in by_group.get(group, []) if s != slug]
        related = peers[:2]
        comp = COMPLEMENT_GROUP.get(group)
        if comp:
            for s in by_group.get(comp, []):
                if s != slug and s not in related:
                    related.append(s)
                    break
        while len(related) < 3:
            for s in peers:
                if s not in related:
                    related.append(s)
                if len(related) >= 3:
                    break
            break
        f['related_slugs'] = related[:3]
        subs = []
        for alt_slug in peers[:2]:
            subs.append({'slug': alt_slug, 'ratio': 1.0})
        f['substitutes'] = subs


def main() -> None:
    existing = json.loads(JSON_PATH.read_text(encoding='utf-8'))
    # فقط ۱۰ تای پایه غنی‌شده حفظ می‌شود؛ ۹۰ تای بعدی همیشه از catalog تازه ساخته می‌شود.
    batch1 = (existing.get('foods') or [])[:10]
    catalog90 = json.loads(CATALOG90_PATH.read_text(encoding='utf-8')).get('items') or []
    catalog50 = []
    if CATALOG50_PATH.is_file():
        catalog50 = json.loads(CATALOG50_PATH.read_text(encoding='utf-8')).get('items') or []
    catalog = catalog90 + catalog50

    merged = list(batch1)
    for idx, item in enumerate(catalog):
        merged.append(expand_item(item, len(batch1) + idx))

    assign_related_and_substitutes(merged)
    for food in merged:
        normalize_serving_units(food)

    out = {
        'version': 3,
        'description': '۱۵۰ خوراکی GymAI — batch1 غنی + ۱۴۰ کاتالوگ — مرجع علمی + Rank Math',
        'foods': merged[:150],
    }
    JSON_PATH.write_text(json.dumps(out, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(f'Wrote {len(out["foods"])} foods to {JSON_PATH.name}')


if __name__ == '__main__':
    main()
