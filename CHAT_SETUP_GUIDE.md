# راهنمای نصب و راه‌اندازی سیستم چت GymAI Pro

## 📋 فهرست مطالب
- [پیش‌نیازها](#پیشنیازها)
- [مراحل نصب](#مراحل-نصب)
- [پیکربندی دیتابیس](#پیکربندی-دیتابیس)
- [تست سیستم](#تست-سیستم)
- [عیب‌یابی](#عیبیابی)

## 🔧 پیش‌نیازها

### 1. Supabase Project
- پروژه Supabase فعال
- دسترسی به SQL Editor
- Real-time enabled

### 2. Flutter Project
- Flutter SDK نصب شده
- Supabase Flutter package
- Lucide Icons package

### 3. جداول موجود
- جدول `profiles` با ستون‌های زیر:
  - `id` (UUID, Primary Key)
  - `username` (VARCHAR)
  - `first_name` (VARCHAR)
  - `last_name` (VARCHAR)
  - `avatar_url` (TEXT)
  - `role` (VARCHAR) - 'trainer', 'athlete', 'admin'

## 🚀 مراحل نصب

### مرحله 1: نصب Dependencies

در فایل `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^1.10.25
  lucide_icons: ^0.263.1
  intl: ^0.18.1
```

سپس اجرا کنید:
```bash
flutter pub get
```

### مرحله 2: پیکربندی Supabase

در فایل `lib/config/supabase_config.dart`:

```dart
class SupabaseConfig {
  static const String url = 'YOUR_SUPABASE_URL';
  static const String anonKey = 'YOUR_SUPABASE_ANON_KEY';
}
```

### مرحله 3: راه‌اندازی دیتابیس

#### گزینه A: نصب کامل (توصیه شده)
1. در Supabase Dashboard بروید به SQL Editor
2. فایل `supabase/chat_system_complete_setup.sql` را کپی کنید
3. اجرا کنید

#### گزینه B: نصب ساده (برای تست)
1. فایل `supabase/chat_system_simple_setup.sql` را اجرا کنید

### مرحله 4: اضافه کردن Routes

در فایل `lib/services/route_service.dart`:

```dart
case '/chat-main':
  return MaterialPageRoute(
    builder: (_) => const ChatMainScreen(),
  );
case '/chat':
  final Map<String, dynamic> args = settings.arguments as Map<String, dynamic>;
  return MaterialPageRoute(
    builder: (_) => ChatScreen(
      otherUserId: args['otherUserId'],
      otherUserName: args['otherUserName'],
    ),
  );
```

### مرحله 5: اضافه کردن Navigation

در منوی اصلی یا dashboard:

```dart
ListTile(
  leading: const Icon(LucideIcons.messageCircle),
  title: const Text('چت'),
  onTap: () => Navigator.pushNamed(context, '/chat-main'),
),
```

## 🗄️ پیکربندی دیتابیس

### بررسی جداول ایجاد شده

```sql
-- بررسی جداول
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name LIKE 'chat_%';

-- بررسی توابع
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name LIKE '%chat%';
```

### بررسی RLS Policies

```sql
-- بررسی سیاست‌های chat_messages
SELECT * FROM pg_policies WHERE tablename = 'chat_messages';

-- بررسی سیاست‌های chat_conversations
SELECT * FROM pg_policies WHERE tablename = 'chat_conversations';
```

### فعال‌سازی Real-time

در Supabase Dashboard:
1. بروید به Database > Replication
2. Real-time را برای جداول زیر فعال کنید:
   - `chat_messages`
   - `chat_conversations`

## 🧪 تست سیستم

### تست 1: بررسی اتصال

```dart
// در main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  
  runApp(MyApp());
}
```

### تست 2: تست ChatService

```dart
void testChatService() async {
  final chatService = ChatService(supabaseService: SupabaseService());
  
  try {
    // تست دریافت گفتگوها
    final conversations = await chatService.getConversations();
    print('تعداد گفتگوها: ${conversations.length}');
    
    // تست تعداد پیام‌های نخوانده
    final unreadCount = await chatService.getUnreadMessageCount();
    print('پیام‌های نخوانده: $unreadCount');
    
  } catch (e) {
    print('خطا: $e');
  }
}
```

### تست 3: تست ارسال پیام

```dart
void testSendMessage() async {
  final chatService = ChatService(supabaseService: SupabaseService());
  
  try {
    await chatService.sendMessage(
      receiverId: 'test-user-id',
      message: 'پیام تست',
    );
    print('پیام ارسال شد');
  } catch (e) {
    print('خطا در ارسال: $e');
  }
}
```

### تست 4: تست Real-time

```dart
void testRealTime() {
  final chatService = ChatService(supabaseService: SupabaseService());
  
  chatService.subscribeToConversations().listen(
    (conversation) {
      print('گفتگوی جدید: ${conversation.otherUserName}');
    },
    onError: (error) {
      print('خطا در real-time: $error');
    },
  );
}
```

## 🐛 عیب‌یابی

### مشکل 1: خطای اتصال به Supabase

**علائم:**
```
Error: Failed to connect to Supabase
```

**راه‌حل:**
1. بررسی URL و کلید در `supabase_config.dart`
2. بررسی اتصال اینترنت
3. بررسی وضعیت Supabase project

### مشکل 2: خطای RLS

**علائم:**
```
Error: new row violates row-level security policy
```

**راه‌حل:**
1. بررسی سیاست‌های RLS
2. اطمینان از احراز هویت کاربر
3. بررسی دسترسی‌های کاربر

### مشکل 3: پیام‌ها نمایش داده نمی‌شوند

**علائم:**
- لیست پیام‌ها خالی است
- خطای "No messages found"

**راه‌حل:**
1. بررسی جدول `chat_messages`
2. بررسی RLS policies
3. بررسی authentication

### مشکل 4: Real-time کار نمی‌کند

**علائم:**
- پیام‌های جدید نمایش داده نمی‌شوند
- گفتگوها به‌روزرسانی نمی‌شوند

**راه‌حل:**
1. بررسی Real-time در Supabase
2. بررسی subscription ها
3. بررسی network connection

### مشکل 5: خطای Foreign Key

**علائم:**
```
Error: insert or update on table "chat_messages" violates foreign key constraint
```

**راه‌حل:**
1. بررسی وجود کاربران در جدول `profiles`
2. بررسی صحت `sender_id` و `receiver_id`
3. بررسی cascade delete settings

## 📊 مانیتورینگ

### لاگ‌های مهم

```dart
// فعال‌سازی لاگ‌های چت
if (kDebugMode) {
  chatService.enableLogging();
}
```

### متریک‌های مهم

1. **تعداد پیام‌های ارسالی**
2. **تعداد کاربران فعال**
3. **زمان پاسخ‌دهی**
4. **خطاهای اتصال**

### کوئری‌های مفید

```sql
-- تعداد پیام‌های امروز
SELECT COUNT(*) FROM chat_messages 
WHERE DATE(created_at) = CURRENT_DATE;

-- کاربران فعال
SELECT sender_id, COUNT(*) as message_count 
FROM chat_messages 
WHERE created_at > NOW() - INTERVAL '24 hours'
GROUP BY sender_id 
ORDER BY message_count DESC;

-- گفتگوهای فعال
SELECT other_user_name, last_message_at 
FROM chat_conversations 
WHERE last_message_at > NOW() - INTERVAL '7 days'
ORDER BY last_message_at DESC;
```

## 🔒 امنیت

### بررسی‌های امنیتی

1. **RLS Policies** - اطمینان از فعال بودن
2. **Authentication** - بررسی احراز هویت
3. **Input Validation** - بررسی ورودی‌ها
4. **Rate Limiting** - محدودیت ارسال پیام

### بهترین شیوه‌ها

1. همیشه از `auth.uid()` استفاده کنید
2. ورودی‌ها را validate کنید
3. از prepared statements استفاده کنید
4. لاگ‌های امنیتی نگه دارید

## 📞 پشتیبانی

در صورت بروز مشکل:

1. لاگ‌ها را بررسی کنید
2. مستندات را مطالعه کنید
3. در GitHub Issues مطرح کنید
4. با تیم توسعه تماس بگیرید

---

**نکته مهم**: این راهنما برای نسخه فعلی سیستم چت است. برای به‌روزرسانی‌های آینده، این فایل را بررسی کنید. 