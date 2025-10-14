# راهنمای راه‌اندازی سیستم اعلان‌ها

## مراحل راه‌اندازی

### 1. اجرای SQL در Supabase

فایل `sql/create_notifications_table.sql` را در Supabase SQL Editor اجرا کنید:

```sql
-- این فایل شامل:
-- - جدول notifications
-- - ایندکس‌های بهینه‌سازی
-- - RLS policies
-- - توابع کمکی
-- - داده‌های نمونه
```

### 2. ویژگی‌های سیستم اعلان‌ها

#### ✅ فایل‌های ایجاد شده:

1. **`lib/notification/services/notification_data_service.dart`**
   - سرویس اصلی برای مدیریت اعلان‌ها
   - متدهای CRUD کامل
   - پشتیبانی از Real-time updates

2. **`lib/notification/screens/notifications_screen.dart`**
   - صفحه نمایش اعلان‌ها با داده‌های واقعی
   - Pull-to-refresh
   - Loading و Error states

3. **`lib/widgets/notification_icon.dart`**
   - آیکون اعلان با شمارشگر واقعی
   - انیمیشن‌های زیبا
   - نمایش تعداد اعلان‌های خوانده نشده

#### 🎯 ویژگی‌های کلیدی:

- **Real-time Updates**: اعلان‌ها به صورت زنده به‌روزرسانی می‌شوند
- **انواع اعلان‌ها**: welcome, workout, reminder, achievement, message, payment, system
- **اولویت‌بندی**: 5 سطح اولویت (1=کم، 5=زیاد)
- **انقضا**: امکان تعیین تاریخ انقضا
- **Action URL**: لینک‌های قابل کلیک
- **JSON Data**: داده‌های اضافی برای هر اعلان

#### 🔧 متدهای سرویس:

```dart
// دریافت اعلان‌ها
await NotificationDataService.getUserNotifications()

// تعداد اعلان‌های خوانده نشده
await NotificationDataService.getUnreadCount()

// بررسی وجود اعلان‌های خوانده نشده
await NotificationDataService.hasUnreadNotifications()

// علامت‌گذاری به عنوان خوانده شده
await NotificationDataService.markAsRead(notificationId)

// علامت‌گذاری همه به عنوان خوانده شده
await NotificationDataService.markAllAsRead()

// ایجاد اعلان جدید
await NotificationDataService.createNotification(...)

// Real-time listening
NotificationDataService.listenToNotifications()
```

### 3. نحوه استفاده

#### ایجاد اعلان جدید:

```dart
await NotificationDataService.createNotification(
  userId: 'user-id',
  title: 'عنوان اعلان',
  message: 'متن اعلان',
  type: NotificationType.workout,
  priority: 3,
  data: {'workout_id': '123'},
  actionUrl: '/workout/123',
);
```

#### دریافت اعلان‌ها:

```dart
final notifications = await NotificationDataService.getUserNotifications();
final unreadCount = await NotificationDataService.getUnreadCount();
```

### 4. تست سیستم

1. **اجرای SQL**: فایل SQL را در Supabase اجرا کنید
2. **اجرای اپ**: اپلیکیشن را اجرا کنید
3. **بررسی آیکون**: آیکون اعلان باید تعداد واقعی را نمایش دهد
4. **کلیک روی آیکون**: باید به صفحه اعلان‌ها برود
5. **تست خواندن**: کلیک روی اعلان باید آن را به عنوان خوانده شده علامت‌گذاری کند

### 5. سفارشی‌سازی

#### اضافه کردن نوع اعلان جدید:

1. در `NotificationType` enum اضافه کنید
2. در `_getNotificationColor` و `_getNotificationIcon` case جدید اضافه کنید
3. در SQL constraint نوع جدید را اضافه کنید

#### تغییر ظاهر:

- رنگ‌ها در `_getNotificationColor`
- آیکون‌ها در `_getNotificationIcon`
- استایل‌ها در `_buildNotificationCard`

### 6. نکات مهم

- **RLS فعال است**: هر کاربر فقط اعلان‌های خودش را می‌بیند
- **Real-time**: تغییرات فوری در UI نمایش داده می‌شود
- **Performance**: ایندکس‌های بهینه برای سرعت بالا
- **Security**: تمام عملیات با احراز هویت کاربر

## 🎉 سیستم اعلان‌ها آماده است!

حالا می‌توانید از سیستم اعلان‌های کامل و قدرتمند استفاده کنید.
