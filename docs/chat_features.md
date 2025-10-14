# ویژگی‌های چت GymAI Pro

## چکیده
سیستم چت GymAI Pro شامل دو نوع چت است:
1. **چت عمومی**: برای گفتگو بین تمام کاربران
2. **چت خصوصی**: برای گفتگو بین مربی و شاگرد

## ویژگی‌های اصلی

### 1. چت عمومی (Public Chat)
- **دسترسی**: تمام کاربران (مربی و شاگرد)
- **مکان**: تب اول در ChatTabsWidget
- **ویژگی‌ها**:
  - نمایش نام واقعی کاربران (نام و نام خانوادگی)
  - نمایش آواتار کاربران
  - نمایش نقش کاربر (مربی/شاگرد)
  - پیام‌های realtime
  - تاریخچه پیام‌ها

### 2. چت خصوصی (Private Chat)
- **دسترسی**: مربی‌ها و شاگردهای مرتبط
- **مکان**: تب دوم در ChatTabsWidget
- **ویژگی‌ها**:
  - نمایش لیست مربی‌ها برای شاگردها
  - نمایش لیست شاگردها برای مربی‌ها
  - چت یک به یک
  - نمایش وضعیت خوانده شدن پیام‌ها

## نمایش نام کاربران

### منطق نمایش نام:
1. **نام کامل**: اگر نام و نام خانوادگی موجود باشد
2. **نام**: اگر فقط نام موجود باشد
3. **نام خانوادگی**: اگر فقط نام خانوادگی موجود باشد
4. **شماره تلفن مخفی**: اگر هیچ نامی موجود نباشد (مثل: ***1234567)
5. **کاربر ناشناس**: در صورت خطا

### مثال‌ها:
- `علی احمدی` (نام و نام خانوادگی)
- `علی` (فقط نام)
- `احمدی` (فقط نام خانوادگی)
- `***1234567` (شماره تلفن مخفی)
- `کاربر ناشناس` (خطا)

## ساختار پایگاه داده

### جدول public_chat_messages:
```sql
- id (UUID)
- sender_id (UUID)
- message (TEXT)
- sender_name (TEXT) - نام نمایشی فرستنده
- sender_avatar (TEXT) - آواتار فرستنده
- sender_role (TEXT) - نقش فرستنده
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)
- is_deleted (BOOLEAN)
```

### جدول chat_conversations:
```sql
- id (UUID)
- user_id (UUID)
- other_user_id (UUID)
- other_user_name (TEXT) - نام نمایشی کاربر دیگر
- other_user_avatar (TEXT) - آواتار کاربر دیگر
- other_user_role (TEXT) - نقش کاربر دیگر
- last_message_at (TIMESTAMP)
- last_message_text (TEXT)
- last_message_type (TEXT)
- unread_count (INTEGER)
- is_sent_by_me (BOOLEAN)
```

## سرویس‌ها

### 1. PublicChatService
- `getMessages()`: دریافت پیام‌های عمومی
- `sendMessage()`: ارسال پیام عمومی
- `subscribeMessages()`: اشتراک realtime

### 2. ChatService
- `getConversations()`: دریافت مکالمات خصوصی
- `getMessages()`: دریافت پیام‌های خصوصی
- `sendMessage()`: ارسال پیام خصوصی
- `getTrainers()`: دریافت لیست مربی‌ها
- `getClients()`: دریافت لیست شاگردها

### 3. UserService
- `getDisplayName()`: دریافت نام نمایشی کاربر
- `getUserAvatar()`: دریافت آواتار کاربر
- `getUserRole()`: دریافت نقش کاربر

## UI Components

### 1. ChatTabsWidget
ویجت اصلی چت با دو تب:
- تب چت عمومی
- تب چت خصوصی

### 2. PublicChatWidget
ویجت چت عمومی با:
- لیست پیام‌ها
- فرم ارسال پیام
- نمایش نام کاربران

### 3. TrainersChatSection
ویجت چت خصوصی با:
- لیست مربی‌ها/شاگردها
- امکان شروع چت

## Triggers و Functions

### 1. populate_user_info_in_public_chat()
اتوماتیک اطلاعات کاربر را در پیام‌های عمومی پر می‌کند

### 2. update_conversation_names()
نام‌های مکالمات را هنگام تغییر پروفایل به‌روزرسانی می‌کند

### 3. create_conversation_with_names()
مکالمه جدید با نام‌های صحیح ایجاد می‌کند

## نحوه استفاده

### برای کاربران:
1. به تب Home در dashboard بروید
2. ChatTabsWidget را پیدا کنید
3. بین تب‌های "چت عمومی" و "چت خصوصی" سوییچ کنید
4. پیام ارسال کنید

### برای توسعه‌دهندگان:
```dart
// استفاده از ChatTabsWidget
ChatTabsWidget()

// استفاده از PublicChatWidget
PublicChatWidget()

// استفاده از TrainersChatSection
TrainersChatSection()
```

## نکات مهم

1. **امنیت**: تمام پیام‌ها با RLS محافظت می‌شوند
2. **Performance**: پیام‌ها با pagination بارگیری می‌شوند
3. **Realtime**: از Supabase Realtime برای پیام‌های زنده استفاده می‌شود
4. **Backup**: پیام‌ها soft delete می‌شوند
5. **Scalability**: ساختار برای مقیاس‌پذیری طراحی شده است 