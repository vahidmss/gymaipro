# ساختار ذخیره‌سازی مدیا — GymAI

## قانون کلی
- **حجیم / پرتعداد** → `dl.gymaipro.ir` (~1TB)
- **کوچک + خصوصی کم‌تعداد** → Supabase Storage

## درخت پوشه‌ها روی dl (آپلودهای جدید)

```
private_html/
├── coaches_music/{username}/              # آکادمی — ترک‌های موزیک
├── coaches_music_covers/{username}/       # آکادمی — کاور موزیک
├── coaches_video/{username}/              # ویدیوی عمومی مربی (بدون context)
│
├── channel/{username}/
│   ├── images/
│   ├── videos/
│   └── audio/                             # کانال مربی
│
├── custom_exercises/{username}/
│   ├── images/
│   └── videos/                            # تمرین اختصاصی
│
├── announcements/
│   ├── images/YYYY/MM/
│   └── videos/YYYY/MM/                    # اخبار ادمین
│
└── chat/{conversation_id}/
    ├── images/
    ├── voice/
    └── files/                             # چت خصوصی
```

نام‌های `coaches_*` برای سازگاری با URLهای قدیمی در دیتابیس نگه داشته شده‌اند.

## فایل‌های PHP که باید روی هاست باشند

| منبع پروژه | نام روی سرور |
|---|---|
| `lib/services/upload_config.php` | `upload_config.php` |
| `lib/services/upload_paths.php` | `upload_paths.php` **(جدید — اجباری)** |
| `lib/services/coach_cover_upload_standalone.php` | `upload-cover.php` |
| `lib/services/coach_music_upload_standalone.php` | `upload-music.php` |
| `lib/services/coach_video_upload_standalone.php` | `upload-video.php` |
| `lib/services/coach_exercise_image_upload_standalone.php` | `upload-exercise-image.php` |
| `lib/services/coach_chat_media_upload_standalone.php` | `upload-chat-media.php` **(جدید)** |

همه را در همان روت وب (`private_html`) با Upload فایل بگذار.

## context ها

| `upload_context` | مقصد |
|---|---|
| *(خالی)* | academy: music / covers / video |
| `trainer_channel` | `channel/{user}/...` |
| `custom_exercise` | `custom_exercises/{user}/...` |
| `announcements` | `announcements/.../YYYY/MM/` |
| `private_chat` | `chat/{conversation_id}/...` |

## چه چیزی روی Supabase می‌ماند؟

| باکت | محتوا | دلیل |
|---|---|---|
| `profile_images` | آواتار | کوچک، گره به پروفایل |
| `coach_certificates` | مدارک مربی | کم‌تعداد، حساس |
| `confidential_photos` | عکس پیشرفت محرمانه | خصوصی، کم‌حجم |

چت دیگر پیش‌فرض روی dl است (نه باکت `chat_media`).

## تست سریع بعد از دیپلوی

1. `https://dl.gymaipro.ir/ping.php` → `ok`
2. GET `upload-chat-media.php` → JSON 405
3. از اپ: آپلود عکس چت / کانال / تمرین و چک مسیر فایل در File Manager
