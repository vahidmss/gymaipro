#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Generate Supabase SQL to populate ai_exercises meta columns."""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BULK_META = ROOT / "lib" / "services" / "exercises_bulk_meta.json"
OUT_SQL = Path(__file__).resolve().parent / "populate_ai_exercises_meta_bulk.sql"

# نام‌های معادل در دیتابیس کاربر ↔ name_app در exercises_bulk_meta.json
NAME_ALIASES: dict[str, list[str]] = {
    "پرس سرشانه دستگاه": ["پرس سرشانه دستگاه"],
    "پرس سینه دستگاه": ["پرس سینه دستگاه"],
    "پشت پا دستگاه": [
        "پشت‌پا خوابیده دستگاه",
        "پشت پا خوابیده دستگاه",
        "پشت‌پا نشسته دستگاه",
    ],
    "زیربغل سیم‌کش": [
        "پارویی سیمکش نشسته",
        "لت پول‌دان دست باز",
        "لت پولدان دست باز",
    ],
    "اسکات هالتر": ["اسکوات هالتر"],
    "جلوبازو دمبل نشسته": ["جلوبازو دمبل تناوبی", "جلوبازو دمبل"],
    "نشر جانب دمبل": ["نشر جانب دمبل"],
    "پشت بازو سیم‌کش": [
        "پشت‌بازو سیمکش طناب",
        "پشت‌بازو سیمکش میله صاف",
    ],
    "زیربغل هالتر خمیده": ["زیربغل هالتر خم", "روو هالتر خم"],
    "ددلیفت رومانیایی": ["ددلیفت رومانیایی"],
}


def sql_str(s: str) -> str:
    return "'" + s.replace("'", "''") + "'"


def load_bulk_meta() -> dict:
    data = json.loads(BULK_META.read_text(encoding="utf-8"))
    return data.get("exercises", {})


def meta_update_block(meta: dict) -> str:
    mt = json.dumps(meta.get("muscle_targets") or {}, ensure_ascii=False)
    tips = [meta.get("tip_1", ""), meta.get("tip_2", ""), meta.get("tip_3", "")]

    fields = {
        "short_description": meta.get("short_description") or "",
        "movement_pattern": meta.get("movement_pattern") or "",
        "body_engagement": meta.get("body_engagement") or "",
        "estimated_1rm_formula": meta.get("estimated_1rm_formula") or "",
        "muscle_targets_json": mt,
        "met": meta.get("met") or None,
        "movement_distance_cm": meta.get("movement_distance_cm") or None,
        "calories_per_1000kg": meta.get("calories_per_1000kg") or None,
        "exercise_difficulty_score": meta.get("exercise_difficulty_score") or None,
        "typical_rpe": meta.get("typical_rpe") or None,
    }

    sets = []
    for col, val in fields.items():
        if col == "muscle_targets_json":
            sets.append(f"  {col} = '{mt}'::jsonb")
        elif val is None or val == "":
            continue
        elif col in ("met", "typical_rpe"):
            sets.append(f"  {col} = {val}")
        elif col in (
            "movement_distance_cm",
            "calories_per_1000kg",
            "exercise_difficulty_score",
        ):
            sets.append(f"  {col} = {int(val)}")
        else:
            sets.append(f"  {col} = {sql_str(str(val))}")

    if any(tips):
        tips_sql = "ARRAY[" + ", ".join(sql_str(t) for t in tips if t) + "]"
        sets.append(f"  tips = {tips_sql}")

    sets.append("  synced_at = now()")
    return ",\n".join(sets)


def build_sql() -> str:
    bulk = load_bulk_meta()
    lines: list[str] = [
        "-- =============================================================================",
        "-- پر کردن فیلدهای متا در public.ai_exercises",
        "-- اجرا در Supabase → SQL Editor (بعد از migration 20260522120000)",
        "-- =============================================================================",
        "BEGIN;",
        "",
        "-- ─── ۱) توضیحات از ستون‌های موجود (content + source JSON) ───",
        "UPDATE public.ai_exercises",
        "SET",
        "  short_description = NULLIF(TRIM(content), ''),",
        "  detailed_description = COALESCE(",
        "    NULLIF(TRIM(detailed_description), ''),",
        "    CASE",
        "      WHEN source IS NULL OR TRIM(source::text) IN ('', 'null') THEN NULL",
        "      WHEN source::text ~ '^\\s*\\{' THEN NULLIF(TRIM(source::jsonb->>'detailedDescription'), '')",
        "      ELSE NULL",
        "    END",
        "  ),",
        "  synced_at = now()",
        "WHERE content IS NOT NULL OR source IS NOT NULL;",
        "",
        "-- ─── ۲) الگوی حرکت (heuristic از نام / تجهیزات) ───",
        "UPDATE public.ai_exercises SET movement_pattern = CASE",
        "  WHEN movement_pattern IS NOT NULL AND TRIM(movement_pattern) <> '' THEN movement_pattern",
        "  WHEN name ~* '(اسکوات|Squat|گابلت|هک اسکوات|فرانت اسکوات|اسپلیت)' THEN 'اسکوات'",
        "  WHEN name ~* '(ددلیفت|Deadlift|RDL|گودمورنینگ|رک پول)' THEN 'لگد'",
        "  WHEN name ~* '(بنچ|Bench|پرس سینه|پرس تخت|پرس دست جمع)' THEN 'فشار افقی'",
        "  WHEN name ~* '(پرس سرشانه|Overhead|OHP|آرنولد|پوش پرس|پرس پشت|Military)' THEN 'فشار عمودی'",
        "  WHEN name ~* '(لت پول|لت پولدان|لت قفل|پول.?دان|Pulldown|بارفیکس|چین.?آپ|Pull.?Up)' THEN 'کشش عمودی'",
        "  WHEN name ~* '(روو|زیربغل|پارویی|T.?Bar|تی.?بار)' AND name !~* '(روئینگ|Rowing|بایک|Bike|اسالت)' THEN 'کشش افقی'",
        "  WHEN name ~* 'Row' AND name !~* '(روئینگ|Rowing|بایک|Bike|اسالت)' THEN 'کشش افقی'",
        "  WHEN name ~* '(کرل|Curl|جلوبازو|همر|چکشی)' AND name !~* 'پشت' THEN 'کشش عمودی'",
        "  WHEN name ~* '(پوش.?دان|پشت.?بازو|Triceps|اسکال|کرشر|دیپ پشت)' THEN 'فشار عمودی'",
        "  WHEN name ~* '(پرس|فشار)' THEN 'فشار افقی'",
        "  WHEN name ~* '(نشر|Raise|فلای|Fly|کراس|قفسه|پک)' THEN 'فشار عمودی'",
        "  WHEN name ~* '(کرانچ|پلانک|شکم|Crunch|Leg Raise|رول.?اوت|وی.?آپ)' THEN 'چرخشی'",
        "  WHEN name ~* '(تردمیل|دویدن|پیاده|دوچرخه|الپتیکال|هوازی|طناب|برپی|بایک|Bike|اسپین|استپر|روئینگ|Rowing|اسکی|Erg|جامپینگ|بوکس|شنای|شنا|کرال)' THEN 'هوازی'",
        "  WHEN name ~* '(کلین|اسنچ|جرک|سوئینگ|فارمر|سورتمه|اسلد)' THEN 'فانکشنال'",
        "  ELSE movement_pattern",
        "END,",
        "  synced_at = now()",
        "WHERE movement_pattern IS NULL OR TRIM(movement_pattern) = '';",
        "",
        "-- ─── ۳) درگیری بدن ───",
        "UPDATE public.ai_exercises SET body_engagement = CASE",
        "  WHEN body_engagement IS NOT NULL AND TRIM(body_engagement) <> '' THEN body_engagement",
        "  WHEN name ~* '(کرل|فلای|قفسه|نشر جانب|نشر جلو|اکستنشن|کرل|کیک|مچ|ساق|جلوپا دستگاه|پشت.?پا|Leg Curl|Extension|Raise|Fly|کرانچ|پلانک|واکیووم)'",
        "    AND name !~* '(اسکوات|ددلیفت|پرس|روو|لت|بارفیکس|دیپ|شنا)' THEN 'تک مفصلی'",
        "  WHEN name ~* '(اسکوات|ددلیفت|پرس|روو|لت|بارفیکس|دیپ|شنا|کلین|تراستر|لانج)' THEN 'چند مفصلی'",
        "  ELSE 'چند مفصلی'",
        "END,",
        "  synced_at = now()",
        "WHERE body_engagement IS NULL OR TRIM(body_engagement) = '';",
        "",
        "-- ─── ۴) MET تقریبی ───",
        "UPDATE public.ai_exercises SET met = CASE",
        "  WHEN met IS NOT NULL THEN met",
        "  WHEN exercise_type ~* 'هوازی' OR estimated_duration::int <= 45 THEN 8.0",
        "  WHEN name ~* '(کرل|فلای|نشر|اکستنشن|مچ|ساق|Leg Curl|Extension)' THEN 3.5",
        "  WHEN name ~* '(اسکوات|ددلیفت|پرس|روو|لت)' THEN 6.0",
        "  WHEN name ~* '(پلانک|کرانچ|شکم)' THEN 4.0",
        "  ELSE 5.0",
        "END,",
        "  synced_at = now()",
        "WHERE met IS NULL;",
        "",
        "-- ─── ۵) RPE و امتیاز سختی از difficulty فارسی ───",
        "UPDATE public.ai_exercises SET",
        "  typical_rpe = COALESCE(typical_rpe, CASE difficulty",
        "    WHEN 'مبتدی' THEN 7.0",
        "    WHEN 'متوسط' THEN 7.5",
        "    WHEN 'پیشرفته' THEN 8.5",
        "    ELSE 7.5",
        "  END),",
        "  exercise_difficulty_score = COALESCE(exercise_difficulty_score, CASE difficulty",
        "    WHEN 'مبتدی' THEN 4",
        "    WHEN 'متوسط' THEN 6",
        "    WHEN 'پیشرفته' THEN 8",
        "    ELSE 5",
        "  END),",
        "  estimated_1rm_formula = COALESCE(NULLIF(TRIM(estimated_1rm_formula), ''), 'برزیکی'),",
        "  synced_at = now();",
        "",
        "-- ─── ۶) شمارنده‌ها (اگر خالی است) ───",
        "UPDATE public.ai_exercises SET",
        "  views_count = COALESCE(views_count, 0),",
        "  likes_count = COALESCE(likes_count, 0)",
        "WHERE views_count IS NULL OR likes_count IS NULL;",
        "",
        "-- ─── ۷) هیت‌مپ و متا کامل — ۱۰ تمرین برنامه مبتدی (تطبیق نام + ID وردپرس) ───",
    ]

    for wp_id, meta in bulk.items():
        name_app = meta.get("name_app", "")
        aliases = NAME_ALIASES.get(name_app, [name_app])
        all_names = list(dict.fromkeys([name_app] + aliases))
        names_sql = ", ".join(sql_str(n) for n in all_names)
        block = meta_update_block(meta)
        lines.append(f"-- {name_app} (WP meta id {wp_id})")
        lines.append("UPDATE public.ai_exercises SET")
        lines.append(block)
        lines.append(f"WHERE id::text = {sql_str(wp_id)} OR name IN ({names_sql});")
        lines.append("")

    lines.extend(
        [
            "COMMIT;",
            "",
            "-- بررسی نمونه:",
            "-- SELECT id, name, short_description IS NOT NULL AS has_short,",
            "--        detailed_description IS NOT NULL AS has_detail,",
            "--        movement_pattern, muscle_targets_json",
            "-- FROM public.ai_exercises ORDER BY id::int LIMIT 20;",
        ]
    )
    return "\n".join(lines)


def main() -> None:
    sql = build_sql()
    OUT_SQL.write_text(sql, encoding="utf-8")
    print(f"Wrote {OUT_SQL} ({len(sql)} chars)")


if __name__ == "__main__":
    main()
