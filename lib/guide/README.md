# 🎯 سیستم راهنمای جامع (Guide System)

سیستم راهنمای حرفه‌ای با قابلیت‌های Onboarding و Feature Tour برای اپلیکیشن GymAI Pro

## ✨ امکانات

### 1. Onboarding (معرفی اولیه)
- صفحات زیبا و جذاب برای کاربران جدید
- انیمیشن‌های smooth و حرفه‌ای
- امکان رد کردن (Skip)
- ذخیره وضعیت تا فقط یکبار نمایش داده شود
- گرادیانت‌های رنگارنگ برای هر صفحه

### 2. Feature Tour (تور قابلیت‌ها)
- Spotlight روی المنت‌های هدف
- Tooltip‌های توضیحی با موقعیت‌های مختلف
- انیمیشن Pulse برای جلب توجه
- امکان رفت و برگشت بین مراحل
- Progress indicator
- Blur effect روی پس‌زمینه

### 3. Dashboard Guide
- راهنمای کامل داشبورد با ۱۰ مرحله
- Highlight کردن بخش‌های مختلف
- توضیحات فارسی و جامع
- آیکون‌های زیبا و رنگ‌بندی متنوع

## 📁 ساختار فایل‌ها

```
lib/guide/
├── data/                           # محتوای راهنماها
│   ├── onboarding_data.dart       # محتوای صفحات onboarding
│   └── dashboard_guide_data.dart  # محتوای راهنمای داشبورد
├── models/                         # مدل‌های داده
│   ├── guide_step.dart            # مدل یک مرحله راهنما
│   ├── guide_sequence.dart        # مدل دنباله‌ای از مراحل
│   └── onboarding_page.dart       # مدل صفحه onboarding
├── services/                       # سرویس‌های مدیریت
│   ├── guide_service.dart         # مدیریت feature tours
│   └── onboarding_service.dart    # مدیریت onboarding
├── widgets/                        # ویجت‌های UI
│   ├── feature_showcase_overlay.dart  # Overlay برای نمایش spotlight
│   ├── feature_tour_widget.dart       # ویجت اصلی tour
│   ├── onboarding_page_widget.dart    # ویجت صفحه onboarding
│   └── onboarding_screen.dart         # صفحه کامل onboarding
├── screens/                        # صفحات
│   ├── welcome_with_onboarding.dart   # Wrapper برای welcome screen
│   └── guide_screens.dart             # Index file
├── guide.dart                      # Index file اصلی
└── README.md                       # این فایل
```

## 🚀 نحوه استفاده

### 1. اضافه کردن Providers (در main.dart)

```dart
ChangeNotifierProvider<GuideService>(
  create: (_) => GuideService(),
),
ChangeNotifierProvider<OnboardingService>(
  create: (_) => OnboardingService(),
),
```

### 2. ثبت یک راهنما

```dart
// در initState صفحه
void _registerGuides() {
  registerGuide(context, DashboardGuideData.getDashboardGuide());
}
```

### 3. اضافه کردن GlobalKey به ویجت‌ها

```dart
// تعریف key در data file
static final Map<String, GlobalKey> keys = {
  'my_widget': GlobalKey(),
};

// استفاده در ویجت
MyWidget(
  key: DashboardGuideData.keys['my_widget'],
)
```

### 4. شروع راهنما

```dart
await startGuide(context, 'dashboard_main_tour');
```

### 5. Wrap کردن صفحه با FeatureTourWidget

```dart
@override
Widget build(BuildContext context) {
  return FeatureTourWidget(
    child: Scaffold(
      // محتوای صفحه
    ),
  );
}
```

## 🎨 ایجاد راهنمای جدید

### مثال: ایجاد راهنما برای صفحه پروفایل

```dart
// 1. تعریف GlobalKeys
static final Map<String, GlobalKey> profileKeys = {
  'avatar': GlobalKey(),
  'edit_button': GlobalKey(),
  'stats': GlobalKey(),
};

// 2. ساخت GuideSequence
GuideSequence getProfileGuide() {
  return GuideSequence(
    id: 'profile_tour',
    name: 'راهنمای پروفایل',
    showOnce: true,
    steps: [
      GuideStep(
        id: 'avatar_step',
        title: '🖼️ تصویر پروفایل',
        description: 'روی تصویر کلیک کنید تا تغییر دهید.',
        icon: Icons.account_circle,
        primaryColor: AppTheme.goldColor,
        targetKey: profileKeys['avatar'],
        tooltipPosition: TooltipPosition.bottom,
      ),
      // مراحل بعدی...
    ],
  );
}
```

## 🎯 ویژگی‌های پیشرفته

### موقعیت Tooltip
- `TooltipPosition.top` - بالای المنت
- `TooltipPosition.bottom` - پایین المنت
- `TooltipPosition.left` - سمت چپ
- `TooltipPosition.right` - سمت راست
- `TooltipPosition.center` - وسط صفحه

### پیش‌نیازها (Prerequisites)
```dart
GuideSequence(
  id: 'advanced_tour',
  prerequisiteId: 'basic_tour', // باید اول basic_tour نشون داده بشه
  // ...
)
```

### دکمه عمل اختیاری
```dart
GuideStep(
  // ...
  action: GuideStepAction(
    label: 'باز کردن',
    onTap: () {
      // عملیات دلخواه
    },
  ),
)
```

## 🎨 سفارشی‌سازی ظاهر

### رنگ‌ها
هر مرحله می‌تواند رنگ مخصوص خود را داشته باشد:

```dart
GuideStep(
  primaryColor: const Color(0xFF6C63FF), // بنفش
  // یا
  primaryColor: AppTheme.goldColor,      // طلایی
)
```

### انیمیشن‌ها
```dart
GuideStep(
  usePulseAnimation: true, // برای جلب توجه بیشتر
)
```

## 📊 مدیریت State

### بررسی وضعیت
```dart
final guideService = Provider.of<GuideService>(context, listen: false);

// آیا باید نمایش داده شود؟
if (guideService.shouldShowGuide('my_tour')) {
  // ...
}

// آیا تکمیل شده؟
if (guideService.isGuideCompleted('my_tour')) {
  // ...
}
```

### ریست کردن
```dart
// ریست یک راهنما
await guideService.resetGuide('my_tour');

// ریست همه راهنماها
await guideService.resetAllGuides();
```

## 🛠️ نکات فنی

### 1. تاخیر برای Render
همیشه قبل از شروع tour، کمی تاخیر بدهید:
```dart
await Future<void>.delayed(const Duration(milliseconds: 800));
await startGuide(context, 'my_tour');
```

### 2. بررسی mounted
همیشه قبل از setState بررسی کنید:
```dart
if (mounted) {
  setState(() {
    // ...
  });
}
```

### 3. GlobalKey Uniqueness
هر GlobalKey باید یکتا باشد و فقط به یک ویجت اختصاص یابد.

## 🎨 طراحی و UX

### اصول طراحی
- ✅ انیمیشن‌های light و سریع
- ✅ رنگ‌های متنوع برای هر بخش
- ✅ متن‌های فارسی و واضح
- ✅ آیکون‌های گویا
- ✅ امکان رد کردن همیشه وجود دارد

### نکات UX
- همیشه امکان Skip/رد کردن فراهم کنید
- مراحل را کوتاه و مفید نگه دارید (حداکثر ۱۰ مرحله)
- از رنگ‌های متنوع برای جلوگیری از یکنواختی استفاده کنید
- توضیحات را ساده و کاربردی بنویسید

## 📝 To-Do و بهبودهای آینده

- [ ] اضافه کردن راهنما برای صفحات دیگر (پروفایل، تنظیمات، ...)
- [ ] پشتیبانی از ویدیو در مراحل راهنما
- [ ] آمار و Analytics برای دیدن اینکه کدام مراحل بیشتر رد می‌شوند
- [ ] امکان نمایش مجدد راهنما از منو
- [ ] پشتیبانی از چند زبان

## 🤝 مشارکت

برای اضافه کردن راهنمای جدید:
1. فایل data جدید در `lib/guide/data/` بسازید
2. GlobalKeys را تعریف کنید
3. GuideSequence را بسازید
4. به ویجت‌های مقصد key اضافه کنید
5. راهنما را register کنید
6. صفحه را با FeatureTourWidget wrap کنید

---

**نکته:** این سیستم کاملا modular و قابل توسعه است. می‌توانید برای هر بخش جدید اپ، راهنمای مخصوص خودش را بسازید! 🚀

