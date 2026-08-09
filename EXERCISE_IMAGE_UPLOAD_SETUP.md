# آپلود تصویر تمرین اختصاصی روی dl.gymaipro.ir

روت واقعی سایت روی این هاست (طبق error.log):

```
/home/dlgymai1/domains/dl.gymaipro.ir/private_html/
```

اگر `public_html` و `private_html` لینک به هم هستند، هر کدام باز شود کافی است.
مهم: فایل‌ها جایی باشند که nginx از آن سرو می‌کند (`private_html`).

## فایل‌هایی که باید روی هاست باشند

| منبع در پروژه | نام روی هاست |
|---|---|
| `lib/services/coach_exercise_image_upload_standalone.php` | `upload-exercise-image.php` |
| `lib/services/coach_cover_upload_standalone.php` | `upload-cover.php` (نسخه با پشتیبانی `custom_exercise`) |
| `lib/services/upload_config.php` | `upload_config.php` (اگر از قبل سالم است دست نزن) |

آپلود را با **Upload فایل** انجام بده، نه Paste در ادیتور آنلاین.

## پوشه مقصد تصاویر

```
private_html/custom_exercises/
```

مجوز: `755`

ساختار بعد از آپلود موفق:

```
custom_exercises/{username}/images/exercise_img_....jpg
```

URL:

```
https://dl.gymaipro.ir/custom_exercises/{username}/images/...
```

## تست سریع

1. `https://dl.gymaipro.ir/ping.php` → باید `ok` باشد  
2. `https://dl.gymaipro.ir/upload-exercise-image.php` → JSON با `method_not_allowed` (405)  
3. از اپ: تمرین جدید → انتخاب تصویر → ذخیره

اپ به این endpoint می‌زند:

```
POST https://dl.gymaipro.ir/upload-exercise-image.php
field: image
```
