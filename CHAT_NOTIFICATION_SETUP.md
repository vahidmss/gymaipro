# راهنمای تنظیم نوتیفیکیشن چت

## 📋 مراحل تنظیم

### 1. Deploy Edge Function

```bash
# در terminal، در پوشه پروژه
supabase functions deploy send-chat-notification
```

### 2. بررسی Environment Variables

اطمینان حاصل کنید که این متغیرها در Supabase تنظیم شده‌اند:

```bash
# در Supabase Dashboard > Settings > Edge Functions
FIREBASE_SERVICE_ACCOUNT_KEY={"type":"service_account",...}
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_anon_key
```

### 3. تست Edge Function

```bash
# تست مستقیم Edge Function
curl -X POST 'https://your-project.supabase.co/functions/v1/send-chat-notification' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "receiver_id": "user-id-here",
    "sender_id": "sender-id-here", 
    "sender_name": "نام فرستنده",
    "message": "متن پیام",
    "message_id": "message-id-here",
    "message_type": "text"
  }'
```

### 4. بررسی Device Tokens

```sql
-- بررسی device tokens موجود
SELECT user_id, token, platform, is_push_enabled, last_seen 
FROM device_tokens 
WHERE is_push_enabled = true;
```

### 5. تست در Flutter

```dart
// استفاده از ChatService
final chatService = ChatService(supabaseService: SupabaseService());
await chatService.sendMessage(
  receiverId: 'user-id',
  message: 'سلام!',
);
```

## 🔧 عیب‌یابی

### مشکل: نوتیفیکیشن ارسال نمی‌شود

1. **بررسی Device Tokens**:
   ```sql
   SELECT COUNT(*) FROM device_tokens WHERE user_id = 'receiver-id';
   ```

2. **بررسی Edge Function Logs**:
   - برو به Supabase Dashboard > Edge Functions > send-chat-notification > Logs

3. **بررسی FCM Token**:
   ```dart
   final token = await FirebaseMessaging.instance.getToken();
   print('FCM Token: $token');
   ```

### مشکل: Edge Function خطا می‌دهد

1. **بررسی Environment Variables**
2. **بررسی Firebase Service Account Key**
3. **بررسی Network Access**

## 📱 ویژگی‌های نوتیفیکیشن

- **عنوان**: "پیام جدید از [نام فرستنده]"
- **متن**: محتوای پیام
- **صدا**: default
- **آیکون**: ic_notification
- **رنگ**: طلایی (#FFD700)
- **Data**: شامل sender_id, message_id, message_type

## 🎯 نحوه کار

1. کاربر پیام می‌فرستد
2. `ChatService.sendMessage()` فراخوانی می‌شود
3. پیام در دیتابیس ذخیره می‌شود
4. `_sendChatNotification()` فراخوانی می‌شود
5. Edge Function `send-chat-notification` اجرا می‌شود
6. Device tokens کاربر گیرنده دریافت می‌شود
7. نوتیفیکیشن از طریق FCM ارسال می‌شود

## ✅ تست نهایی

1. دو کاربر مختلف در دو دستگاه
2. یکی پیام بفرستد
3. دیگری نوتیفیکیشن دریافت کند
4. روی نوتیفیکیشن کلیک کند
5. به صفحه چت منتقل شود
