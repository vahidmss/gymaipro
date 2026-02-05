# شروع سریع - سیستم دستاوردها

## 🚀 استفاده در 3 مرحله ساده

### مرحله 1: اضافه کردن به Dashboard

در فایل `lib/dashboard/screens/dashboard_screen.dart`:

```dart
import 'package:gymaipro/achievements/widgets/achievements_dashboard_card.dart';

// در بدنه Widget
AchievementsDashboardCard(),
```

یا اگر GridView دارید:

```dart
AchievementsCompactCard(),
```

### مرحله 2: تست کردن

الان می‌تونی روی کارت دستاوردها کلیک کنی و صفحه کامل دستاوردها رو ببینی!

### مرحله 3: بروزرسانی پیشرفت

هر جایی که کاربر کاری انجام میده، پیشرفت رو بروزرسانی کن:

```dart
import 'package:provider/provider.dart';
import 'package:gymaipro/achievements/services/achievement_service.dart';

// مثلاً بعد از تکمیل تمرین
final achievementService = Provider.of<AchievementService>(context, listen: false);
await achievementService.incrementProgress('first_workout', 1);
```

---

## 🎯 مثال‌های عملی

### 1. تکمیل تمرین

```dart
// در workout_completion_screen.dart
void onWorkoutComplete() async {
  final service = context.read<AchievementService>();
  
  await service.incrementProgress('first_workout', 1);
  await service.incrementProgress('workout_beginner', 1);
  await service.incrementProgress('workout_intermediate', 1);
  
  // بررسی زمان تمرین
  if (DateTime.now().hour < 7) {
    await service.incrementProgress('early_bird', 1);
  }
}
```

### 2. ثبت وعده غذایی

```dart
// در meal_logging_screen.dart
void onMealLogged() async {
  final service = context.read<AchievementService>();
  
  await service.incrementProgress('first_meal_log', 1);
  await service.incrementProgress('healthy_eater', 1);
}
```

### 3. دعوت دوست

```dart
// در invite_friends_screen.dart
void onFriendInvited() async {
  final service = context.read<AchievementService>();
  
  await service.incrementProgress('invite_1', 1);
  await service.incrementProgress('invite_5', 1);
  await service.incrementProgress('invite_10', 1);
}
```

### 4. تکمیل پروفایل

```dart
// در profile_completion_check.dart
void checkProfileCompletion() async {
  final service = context.read<AchievementService>();
  
  // محاسبه درصد تکمیل
  int completionPercentage = calculateProfileCompletion();
  
  await service.updateProgress('profile_complete', completionPercentage);
}
```

---

## 🔥 مدیریت Streak (روزهای متوالی)

```dart
// در app startup یا daily check
void updateWorkoutStreak() async {
  final service = context.read<AchievementService>();
  
  // محاسبه streak (از SharedPreferences یا database)
  int currentStreak = await calculateCurrentStreak();
  
  await service.updateProgress('streak_3', currentStreak);
  await service.updateProgress('streak_7', currentStreak);
  await service.updateProgress('streak_30', currentStreak);
}

// مثال محاسبه streak
Future<int> calculateCurrentStreak() async {
  // بگیر آخرین روزی که تمرین کرده
  DateTime? lastWorkoutDate = await getLastWorkoutDate();
  if (lastWorkoutDate == null) return 0;
  
  DateTime today = DateTime.now();
  int daysDiff = today.difference(lastWorkoutDate).inDays;
  
  if (daysDiff <= 1) {
    // Streak ادامه دارد
    int streak = await getCurrentStreakCount();
    return streak;
  } else {
    // Streak شکسته شده
    return 0;
  }
}
```

---

## 💡 نکات مهم

### ✅ چه موقع باید updateProgress استفاده کنیم؟

زمانی که می‌خوایم مقدار دقیق رو set کنیم:

```dart
await service.updateProgress('streak_7', currentStreak);
await service.updateProgress('profile_complete', 85); // 85%
```

### ✅ چه موقع باید incrementProgress استفاده کنیم?

زمانی که فقط می‌خوایم +1 یا +n کنیم:

```dart
await service.incrementProgress('first_workout', 1); // +1
await service.incrementProgress('invite_5', 1); // +1
```

---

## 🎨 سفارشی‌سازی سریع

### تغییر رنگ اصلی

در فایل `achievements_dashboard_card.dart`:

```dart
// از این رنگ طلایی:
Color(0xFFFFD700)

// به رنگ دلخواه تغییر بده:
Theme.of(context).primaryColor
```

### اضافه کردن دستاورد جدید

در `achievement_service.dart` در متد `_initializeAchievements`:

```dart
Achievement(
  id: 'my_new_achievement',
  title: 'عنوان جدید',
  description: 'توضیحات',
  icon: '🎉',
  category: AchievementCategory.workout,
  targetValue: 20,
  currentValue: 0,
  unit: 'بار',
  points: 150,
  tier: AchievementTier.silver,
),
```

---

## 🐛 مشکلات رایج

### مشکل: دستاوردها reset میشن

**راه حل**: باید دستاوردها رو در database یا SharedPreferences ذخیره کنی.

```dart
// در app startup
void loadAchievements() async {
  final prefs = await SharedPreferences.getInstance();
  final data = prefs.getString('achievements');
  
  if (data != null) {
    // بارگذاری از storage
  }
}

// بعد از هر تغییر
void saveAchievements() async {
  final service = context.read<AchievementService>();
  final prefs = await SharedPreferences.getInstance();
  
  // ذخیره‌سازی
  await prefs.setString('achievements', jsonEncode(service.achievements));
}
```

### مشکل: Provider error

**راه حل**: مطمئن شو که `AchievementService` رو در سطح بالای app در `Provider` گذاشتی:

```dart
// در main.dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AchievementService()),
    // سایر providers...
  ],
  child: MaterialApp(...),
)
```

---

## 📱 مثال کامل Integration

```dart
// main.dart
import 'package:provider/provider.dart';
import 'package:gymaipro/achievements/services/achievement_service.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AchievementService()),
      ],
      child: MyApp(),
    ),
  );
}

// dashboard_screen.dart
import 'package:gymaipro/achievements/widgets/achievements_dashboard_card.dart';

Widget build(BuildContext context) {
  return ListView(
    children: [
      // کارت های دیگه...
      AchievementsDashboardCard(),
      // کارت های دیگه...
    ],
  );
}

// workout_screen.dart
import 'package:provider/provider.dart';
import 'package:gymaipro/achievements/services/achievement_service.dart';

void completeWorkout() async {
  final service = context.read<AchievementService>();
  await service.incrementProgress('first_workout', 1);
  
  // نمایش پیام موفقیت
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('تمرین با موفقیت ثبت شد!')),
  );
}
```

---

**تمام! 🎉 حالا یه سیستم دستاورد حرفه‌ای داری!**

هر سوالی داشتی، README.md کامل رو بخون یا بپرس! 😊

