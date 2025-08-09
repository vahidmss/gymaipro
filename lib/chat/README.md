# سیستم چت GymAI Pro

## 📋 فهرست مطالب
- [معرفی](#معرفی)
- [ویژگی‌ها](#ویژگیها)
- [ساختار فایل‌ها](#ساختار-فایلها)
- [نحوه استفاده](#نحوه-استفاده)
- [پیکربندی دیتابیس](#پیکربندی-دیتابیس)
- [API ها](#api-ها)
- [مثال‌های کد](#مثالهای-کد)

## 🎯 معرفی

سیستم چت GymAI Pro یک سیستم چت کامل و پیشرفته است که امکان ارتباط بین مربیان و شاگردان را فراهم می‌کند. این سیستم شامل چت خصوصی، چت عمومی و سیستم پیام‌رسانی گروهی است.

## ✨ ویژگی‌ها

### چت خصوصی
- ✅ چت یک به یک بین کاربران
- ✅ نمایش وضعیت آنلاین
- ✅ نشانگر پیام‌های نخوانده
- ✅ پشتیبانی از انواع پیام (متن، تصویر، فایل، صدا)
- ✅ ویرایش و حذف پیام‌ها
- ✅ جستجو در پیام‌ها
- ✅ بارگذاری تدریجی پیام‌ها

### چت عمومی
- ✅ چت عمومی برای همه کاربران
- ✅ پیام‌های عمومی مربیان
- ✅ سیستم اعلان‌ها

### مدیریت گفتگوها
- ✅ لیست گفتگوهای اخیر
- ✅ مرتب‌سازی بر اساس آخرین پیام
- ✅ فیلتر و جستجو
- ✅ آمار گفتگوها

### امنیت
- ✅ Row Level Security (RLS)
- ✅ احراز هویت کاربران
- ✅ کنترل دسترسی
- ✅ رمزگذاری پیام‌ها

## 📁 ساختار فایل‌ها

```
lib/chat/
├── screens/
│   ├── chat_main_screen.dart          # صفحه اصلی چت
│   ├── chat_screen.dart               # صفحه چت خصوصی
│   ├── chat_conversations_screen.dart # لیست گفتگوها
│   └── chat_trainer_selection_screen.dart # انتخاب مربی
├── services/
│   ├── chat_service.dart              # سرویس اصلی چت
│   └── broadcast_service.dart         # سرویس پیام‌های عمومی
├── widgets/
│   ├── chat_message_bubble.dart       # حباب پیام
│   ├── chat_search_bar.dart           # نوار جستجو
│   └── chat_stats_widget.dart         # آمار چت
└── README.md                          # این فایل
```

## 🚀 نحوه استفاده

### 1. راه‌اندازی اولیه

```dart
// در main.dart یا app initialization
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);
```

### 2. استفاده از ChatService

```dart
final chatService = ChatService(supabaseService: SupabaseService());

// ارسال پیام
await chatService.sendMessage(
  receiverId: 'user_id',
  message: 'سلام!',
);

// دریافت پیام‌ها
final messages = await chatService.getMessages('other_user_id');

// دریافت گفتگوها
final conversations = await chatService.getConversations();
```

### 3. استفاده از ChatScreen

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ChatScreen(
      otherUserId: 'user_id',
      otherUserName: 'نام کاربر',
    ),
  ),
);
```

### 4. استفاده از ChatMainScreen

```dart
// در navigation
Navigator.pushNamed(context, '/chat-main');
```

## 🗄️ پیکربندی دیتابیس

### جداول مورد نیاز

1. **chat_messages** - پیام‌های چت
2. **chat_conversations** - گفتگوها
3. **chat_rooms** - اتاق‌های چت (برای آینده)
4. **chat_room_members** - اعضای اتاق

### اجرای SQL

فایل `supabase/chat_system_complete_setup.sql` را در Supabase اجرا کنید:

```sql
-- اجرای کامل سیستم چت
\i supabase/chat_system_complete_setup.sql
```

### توابع مهم

- `mark_messages_as_read(p_sender_id UUID)` - علامت‌گذاری پیام‌ها
- `mark_conversation_as_read(p_other_user_id UUID)` - علامت‌گذاری گفتگو
- `get_unread_message_count()` - تعداد پیام‌های نخوانده
- `update_chat_conversation()` - به‌روزرسانی خودکار گفتگوها

## 🔌 API ها

### ChatService

```dart
class ChatService {
  // دریافت گفتگوها
  Future<List<ChatConversation>> getConversations();
  
  // دریافت پیام‌ها
  Future<List<ChatMessage>> getMessages(String otherUserId, {
    int limit = 50,
    int offset = 0,
  });
  
  // ارسال پیام
  Future<ChatMessage> sendMessage({
    required String receiverId,
    required String message,
    String messageType = 'text',
    String? attachmentUrl,
    String? attachmentType,
    String? attachmentName,
    int? attachmentSize,
  });
  
  // علامت‌گذاری پیام‌ها
  Future<void> markMessagesAsRead(String senderId);
  
  // علامت‌گذاری گفتگو
  Future<void> markConversationAsRead(String otherUserId);
  
  // دریافت تعداد پیام‌های نخوانده
  Future<int> getUnreadMessageCount();
  
  // حذف پیام
  Future<void> deleteMessage(String messageId);
  
  // ویرایش پیام
  Future<void> editMessage(String messageId, String newMessage);
  
  // اشتراک در پیام‌ها
  Stream<ChatMessage> subscribeToMessages(String otherUserId);
  
  // اشتراک در گفتگوها
  Stream<ChatConversation> subscribeToConversations();
}
```

### BroadcastService

```dart
class BroadcastService {
  // ارسال پیام عمومی
  Future<void> sendBroadcastMessage(String message);
  
  // دریافت پیام‌های عمومی
  Future<List<BroadcastMessage>> getBroadcastMessages();
  
  // اشتراک در پیام‌های عمومی
  Stream<BroadcastMessage> subscribeToBroadcastMessages();
}
```

## 💡 مثال‌های کد

### مثال 1: ارسال پیام

```dart
Future<void> sendMessage() async {
  try {
    await chatService.sendMessage(
      receiverId: 'user_id',
      message: 'سلام! چطوری؟',
      messageType: 'text',
    );
  } catch (e) {
    print('خطا در ارسال پیام: $e');
  }
}
```

### مثال 2: دریافت پیام‌ها

```dart
Future<void> loadMessages() async {
  try {
    final messages = await chatService.getMessages(
      'other_user_id',
      limit: 20,
      offset: 0,
    );
    setState(() {
      _messages = messages;
    });
  } catch (e) {
    print('خطا در بارگیری پیام‌ها: $e');
  }
}
```

### مثال 3: اشتراک در پیام‌ها

```dart
void subscribeToMessages() {
  chatService.subscribeToMessages('other_user_id').listen(
    (message) {
      setState(() {
        _messages.add(message);
      });
    },
    onError: (error) {
      print('خطا در اشتراک: $error');
    },
  );
}
```

### مثال 4: استفاده از ChatTrainerSelectionScreen

```dart
// برای مربیان - نمایش شاگردان
final clients = await trainerService.getTrainerClientsWithProfiles(trainerId);

// برای شاگردان - نمایش مربیان
final trainers = await trainerService.getClientTrainersWithProfiles(clientId);
```

## 🔧 تنظیمات

### متغیرهای محیطی

```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

### تنظیمات اعلان‌ها

```dart
// در app_config.dart
class ChatConfig {
  static const int messagesPerPage = 20;
  static const Duration messageTimeout = Duration(seconds: 30);
  static const bool enableVoiceMessages = true;
  static const bool enableFileSharing = true;
}
```

## 🐛 عیب‌یابی

### مشکلات رایج

1. **خطای اتصال به Supabase**
   - بررسی URL و کلید
   - بررسی اتصال اینترنت

2. **پیام‌ها نمایش داده نمی‌شوند**
   - بررسی RLS policies
   - بررسی authentication

3. **خطا در ارسال پیام**
   - بررسی دسترسی‌ها
   - بررسی validation

### لاگ‌ها

```dart
// فعال‌سازی لاگ‌های چت
if (kDebugMode) {
  chatService.enableLogging();
}
```

## 📱 ویژگی‌های آینده

- [ ] چت گروهی
- [ ] تماس صوتی و تصویری
- [ ] اشتراک‌گذاری موقعیت
- [ ] استیکر و ایموجی
- [ ] پیام‌های موقت
- [ ] رمزگذاری end-to-end
- [ ] پشتیبان‌گیری پیام‌ها

## 🤝 مشارکت

برای مشارکت در توسعه این سیستم:

1. Fork کنید
2. Branch جدید بسازید
3. تغییرات را commit کنید
4. Pull Request ارسال کنید

## 📄 لایسنس

این پروژه تحت لایسنس MIT منتشر شده است.

---

**نکته**: این سیستم برای استفاده در محیط production طراحی شده و تمام استانداردهای امنیتی را رعایت می‌کند. 