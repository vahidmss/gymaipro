# راهنمای نصب Supabase روی سرور خودت (ایران)

این راهنما برای این است که Supabase را روی سرور لینوکس خودت (مثلاً `87.248.156.175`) اجرا کنی تا وقتی سایت‌های خارجی فیلترند، اپ با نت داخلی به دیتابیس وصل شود.

---

## خلاصه: چطور به استودیو وصل شوم؟

بعد از اجرای اسکریپت نصب روی سرور:

1. در مرورگر باز کن: **`http://87.248.156.175:8000`** (به‌جای این IP، آدرس سرور خودت را بگذار.)
2. وقتی از تو **نام کاربری و پسورد** خواست:
   - **Username:** معمولاً `supabase` (یا مقدار `DASHBOARD_USERNAME` در فایل `.env` روی سرور).
   - **Password:** مقدار `DASHBOARD_PASSWORD` در فایل `~/supabase-project/.env` روی سرور.
3. برای دیدن پسورد روی سرور این را بزن:  
   `grep DASHBOARD_PASSWORD ~/supabase-project/.env`

جزئیات کامل و نصب دستی در ادامه همین راهنماست.

---

## پیش‌نیاز

- یک سرور لینوکس (Ubuntu 20.04+ یا مشابه) با دسترسی SSH
- حداقل ۴ گیگ RAM، ۲ هسته CPU، ۵۰ گیگ فضای دیسک
- Docker و Docker Compose نصب باشد (اسکریپت می‌تواند نصب را انجام دهد)

---

## روش ۱: اجرای اسکریپت خودکار (پیشنهادی)

### مرحله ۱: وصل شدن به سرور

با SSH به سرور وصل شو (آدرس و کاربر را با اطلاعات خودت عوض کن):

```bash
ssh root@87.248.156.175
```

یا اگر کاربر دیگری داری:

```bash
ssh karbar@87.248.156.175
```

### مرحله ۲: کپی کردن و اجرای اسکریپت

اسکریپت `scripts/setup_supabase_server.sh` را از پروژه GymAI Pro به سرور برسان (با SCP، یا محتوایش را کپی کن و روی سرور یک فایل بساز).

**روی ویندوز (PowerShell) از همین پوشه پروژه:**

```powershell
scp scripts/setup_supabase_server.sh root@87.248.156.175:~/
```

بعد روی **سرور لینوکس**:

```bash
chmod +x ~/setup_supabase_server.sh
~/setup_supabase_server.sh 87.248.156.175
```

به‌جای `87.248.156.175` آدرس IP یا دامنه واقعی سرور خودت را بگذار.

اسکریپت این کارها را انجام می‌دهد:

- نصب Docker و Docker Compose در صورت نبود
- کلون کردن مخزن Supabase
- کپی فایل‌های Docker و ساختن `.env`
- ساخت کلیدها و پسوردها
- تنظیم آدرس‌ها روی IP سرور
- اجرای `docker compose up -d`

در پایان، آدرس Studio و راهنمای ورود را چاپ می‌کند.

### مرحله ۳: پسورد استودیو

پسورد ورود به Studio در فایل `.env` روی سرور است:

- مسیر: `~/supabase-project/.env`
- متغیرها: `DASHBOARD_USERNAME` و `DASHBOARD_PASSWORD`

برای دیدن پسورد (روی سرور):

```bash
grep DASHBOARD_PASSWORD ~/supabase-project/.env
```

حتماً این پسورد را عوض کن و یک پسورد قوی بذار (حداقل یک حرف و عدد؛ طبق مستندات Supabase از کاراکتر خاص استفاده نکن).

---

## چطور به استودیو وصل شوم؟

1. در مرورگر باز کن:  
   **`http://87.248.156.175:8000`**  
   (اگر IP سرورت فرق دارد، همان را بگذار.)

2. وقتی صفحه باز شد، از تو **نام کاربری و پسورد** خواسته می‌شود:
   - **Username:** مقدار `DASHBOARD_USERNAME` در فایل `.env` (پیش‌فرض اغلب `supabase` است).
   - **Password:** مقدار `DASHBOARD_PASSWORD` در همان `.env`.

3. بعد از ورود، داشبورد Supabase Studio را می‌بینی و می‌توانی دیتابیس، Auth، Storage و غیره را مدیریت کنی.

اگر صفحه لود نشد:

- فایروال سرور را چک کن که پورت **8000** باز باشد.
- روی سرور اجرا کن: `docker compose -f ~/supabase-project/docker-compose.yml ps` و مطمئن شو سرویس‌ها Up و healthy هستند.

---

## وصل کردن اپ GymAI Pro به Supabase خودت

وقتی Supabase روی سرور بالا آمد و Studio را دیدی:

1. در فایل **`.env` روی سرور** (مسیر `~/supabase-project/.env`) مقدار **`ANON_KEY`** را پیدا کن و کپی کن.

2. در **پروژه GymAI Pro** (روی کامپیوتر خودت) فایل **`.env`** را باز کن و این دو خط را طوری تنظیم کن که به سرور خودت اشاره کنند:

```env
SUPABASE_URL=http://87.248.156.175:8000
SUPABASE_ANON_KEY=همان_ANON_KEY_کپی_شده_از_سرور
```

به‌جای `87.248.156.175` اگر دامنه داری (مثلاً `supabase.gymaipro.ir`) بگذار و در صورت استفاده از HTTPS بنویس:

```env
SUPABASE_URL=https://supabase.gymaipro.ir
SUPABASE_ANON_KEY=...
```

3. اپ را دوباره اجرا کن (Run/Debug). از این به بعد اپ به Supabase روی سرور خودت وصل می‌شود.

---

## روش ۲: نصب دستی (اگر اسکریپت اجرا نشد)

روی سرور این دستورات را به ترتیب بزن:

```bash
# نصب Docker (Ubuntu/Debian)
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
# خروج و ورود مجدد به SSH برای اعمال گروه docker

# کلون و راه‌اندازی
git clone --depth 1 https://github.com/supabase/supabase
mkdir -p supabase-project
cp -rf supabase/docker/* supabase-project/
cp supabase/docker/.env.example supabase-project/.env
cd supabase-project

# ساخت کلیدها (فایل .env را به‌روز می‌کند)
sh ./utils/generate-keys.sh

# ویرایش .env و تنظیم آدرس سرور (با nano یا vim)
# این خطوط را پیدا کن و با IP خودت عوض کن:
# SUPABASE_PUBLIC_URL=http://87.248.156.175:8000
# API_EXTERNAL_URL=http://87.248.156.175:8000
# SITE_URL=http://87.248.156.175:8000
# DASHBOARD_PASSWORD=یک_پسورد_قوی_با_حرف_و_عدد

nano .env

# پسورد دیتابیس (POSTGRES_PASSWORD) را هم حتماً عوض کن

# اجرا
docker compose pull
docker compose up -d
```

بعد از چند دقیقه Studio از آدرس **`http://IPسرور:8000`** در دسترس است.

---

## امنیت

- پسورد سرور و پسورد Studio و `POSTGRES_PASSWORD` را قوی بگذار و هیچ‌وقت در چت یا Git قرار نده.
- در production حتماً برای دامنه خودت **HTTPS** (مثلاً با Nginx + Let's Encrypt) بگیر و به جای `http://IP:8000` از `https://دامنه` استفاده کن.
- در فایروال فقط پورت‌های لازم (مثلاً 22، 80، 443، 8000) را باز کن.
- در اپ فقط **ANON_KEY** استفاده کن؛ **SERVICE_ROLE_KEY** را هرگز در اپ یا فرانت قرار نده.

---

## مایگریشن دیتابیس (جداول پروژه GymAI)

اگر الان روی Supabase ابری جداول و مایگریشن داری، باید همان اسکریپت‌های SQL را روی Supabase خودت هم اجرا کنی:

1. از پروژه ابری یا از پوشه `sql/` و `supabase/migrations/` فایل‌های `.sql` را بردار.
2. در Studio روی سرور خودت برو به **SQL Editor** و آن فایل‌ها را به ترتیب اجرا کن، یا با `psql` از طریق connection string Supavisor وصل شو و اسکریپت را اجرا کن.

بعد از این، اپ با همان ساختار جداول روی سرور خودت کار می‌کند.

---

## عیب‌یابی

| مشکل | کار پیشنهادی |
|------|----------------|
| Studio باز نمی‌شود | چک کن پورت 8000 در فایروال باز باشد و `docker compose ps` همه سرویس‌ها را Up نشان دهد. |
| خطای ۵۰۰ یا ۵۰۲ | لاگ بگیر: `docker compose logs studio` و `docker compose logs kong`. |
| اپ وصل نمی‌شود | در `.env` اپ مطمئن شو `SUPABASE_URL` و `SUPABASE_ANON_KEY` درست و مطابق سرور است. |
| پسورد Studio یادم نیست | روی سرور: `grep DASHBOARD ~/supabase-project/.env` یا پسورد را در `.env` عوض کن و سرویس را ریستارت کن: `docker compose restart`. |

اگر خواستی برای یک سرور یا IP مشخص (مثلاً همان 87.248.156.175) مرحله‌به‌مرحله را با دستور دقیق بنویسم، بگو روی چه سیستمی (Ubuntu/CentOS و با چه کاربری) کار می‌کنی.
