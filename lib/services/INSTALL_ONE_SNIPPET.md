# یک snippet — همین

## حذف کن
- کد قدیمی متاباکس (همان که HTML شکسته داشت)
- همه snippetهای GymAI Seed / REST جدا

## فقط این را بگذار
فایل: **`CODE_SNIPPET_FINAL.php`**
- عنوان: `GymAI Exercise Meta`
- محل اجرا: **همه جا**
- **بدون** `<?php` در اول فایل

## تست
1. ویرایش حرکت 3857 در وردپرس
2. پر کردن: توضیح کوتاه، MET، هیت‌مپ → **به‌روزرسانی**
3. باز کردن:  
   `https://gymaipro.ir/wp-json/wp/v2/exercises/3857`
4. در `meta` باید ببینی: `short_description`, `met`, `muscle_targets_json`

## چرا کد قدیمی ذخیره نمی‌کرد؟
| باگ | اثر |
|-----|-----|
| `</div>` و `?>` وسط فرم | فیلدها خارج `<form>` وردپرس |
| `select` بدون `selected()` | بعد از ذخیره خالی می‌ماند |
| `register_rest_field` | فیلد در `meta` API نمی‌آید |
| `short_description` با `sanitize_text_field` | متن بریده می‌شد |
| `save_post` روی همه پست‌ها | تداخل |

## Seed
اگر قبلاً Seed زدی (Updated: 10) کافی است. فقط متاباکس جدید + یک بار Update روی هر حرکت برای فیلدهای خالی.
