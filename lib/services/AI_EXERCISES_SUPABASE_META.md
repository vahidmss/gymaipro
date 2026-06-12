# فیلدهای متا `ai_exercises` در Supabase

## اجرای migration

1. Supabase Dashboard → **SQL Editor**
2. محتوای فایل را اجرا کنید:
   `supabase/migrations/20260522120000_ai_exercises_meta_fields.sql`

یا با CLI:

```bash
supabase db push
```

## ستون‌های جدید

| ستون | نوع | منبع وردپرس (`meta`) |
|------|-----|----------------------|
| `short_description` | text | short_description |
| `detailed_description` | text | detailed_description |
| `learn` | text | learn |
| `seo_content` | text | seo_content |
| `movement_pattern` | text | movement_pattern |
| `body_engagement` | text | body_engagement |
| `estimated_1rm_formula` | text | estimated_1rm_formula |
| `muscle_targets_json` | **jsonb** | muscle_targets_json |
| `met` | numeric | met |
| `movement_distance_cm` | int | movement_distance_cm |
| `calories_per_1000kg` | int | calories_per_1000kg |
| `exercise_difficulty_score` | smallint | exercise_difficulty_score |
| `typical_rpe` | numeric | typical_rpe |
| `views_count` | int | views_count |
| `likes_count` | int | likes_count |
| `wordpress_modified` | timestamptz | `modified` پست REST |
| `synced_at` | timestamptz | زمان sync |

ستون‌های قبلی (بدون تغییر): `id`, `name`, `content`, `main_muscle`, `secondary_muscles`, `tips`, `video_url`, `image_url`, `other_names`, `difficulty`, `equipment`, `exercise_type`, `estimated_duration`, `target_area`, …

## migration دوم (extended v3.6)

`supabase/migrations/20260604150000_ai_exercises_extended_json.sql` — ستون `exercise_extended_json`

## Sync (پیاده‌سازی شده)

- `ExerciseSyncService` — WP v2 + ادغام `gymai/v3/exercises` (v3.6)
- `ExerciseV3SyncMapper` — programming / instructions / safety در `exercise_extended_json`
- `AIExerciseReadService` — `muscle_targets_json` + توضیحات کوتاه
- پنل ادمین → **Sync تمرین‌ها**

## هیت‌مپ

`muscle_targets_json` نمونه:

```json
{"hamstrings":95,"glutes":85,"quads":30,"lower_back":40,"forearms":35}
```

کلیدهای استاندارد اپ: `chest_upper`, `chest_middle`, `hamstrings`, `back_lat`, `quads`, … (۱۷ کلید — همان متاباکس وردپرس).
