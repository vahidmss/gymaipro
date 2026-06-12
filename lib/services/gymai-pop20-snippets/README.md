# GymAI Exercises — 200 حرکت (Code Snippets)

## روش deploy

### 1) اسنیپت CORE (آپدیت لازم)
- `CODE_SNIPPET_POP20_CORE.php` — Run everywhere
- اگر قبلاً CORE قدیمی داری، **محتوای جدید** را جایگزین کن (batch 7–11 اضافه شده)

### 2) فایل‌های batch در `wp-content/gymai-seed/`
```
pop20-batch1.php … pop20-batch11.php
```

### 3) اجرا
**ابزارها → GymAI Exercises** — batch 7 تا 11 = **100 حرکت جدید** (101 تا 200)

---

## Batch 7 (101–120) — پا و هیپ‌هینج
اسکات جعبه، بلغاری هالتر، کوزاک، لندماین اسکات، لگ پرس تک‌پا، نوردیک، پشت پا خوابیده/نشسته، هیپ تراست هالتر، لانج جانبی/اسکی، تراپ بار، بلوک/رک پول، RDL تک‌پا، پرش جعبه

## Batch 8 (121–140) — پشت و کشش
مدوز رو، رویینگ سینه‌تکیه، دست صاف، بارفیکس دست باز/آرچر/استرالیایی، inverted row، لندماین رو، پول‌اور دمبل، RDL هالتر، GHR، bird dog

## Batch 9 (141–160) — سینه و شانه
پرس دمبل شیب، فلای زمین/اینکلاین، پرس سوندر، شنا کلاپ، پرس پین، OHP اسمیت/نشسته، نشر کج، پرس لندماین، HSPU، wall walk

## Batch 10 (161–180) — بازو
پریچر، EZ bar، concentration/spider curl، پشت بازو نشسته/تک‌بازو، ساعد، 21s، tricep push-up

## Batch 11 (181–200) — Core و فانکشنال
Shoulder tap plank، V-up، hollow body، woodchopper، battle ropes، box jump، kettlebell clean/snatch، push press، thruster، jump rope، farmer walk

---

## Batch 1–6 (100 حرکت قبلی)
همان README قبلی — batch 5 و 6 = 61–100

---

## تصاویر
- batch 1–6: `uploads/2026/06/exercise-batchN-XX.jpg`
- batch 7–11: `uploads/2026/07/exercise-batchN-XX.jpg`

---

## Rank Math
بعد از هر batch از لیست پست‌ها «بروزرسانی» بزن.

## v3.6 Classification
حرکات با «هالتر» در نام، `main_muscle` صریح در meta دارند (بدون باگ لت/هالتر).
اسنیپت **v3.6 Output Patch** را فعال نگه دار.

## تولید مجدد batch 7–11
```bash
cd lib/services/gymai-pop20-snippets
python generate_batch7_11.py
```
