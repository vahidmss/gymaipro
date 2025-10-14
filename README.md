# GymAI Pro - Flutter Application

یک اپلیکیشن Flutter مدرن برای مدیریت تمرینات و تناسب اندام با استفاده از هوش مصنوعی.

## ویژگی‌های کلیدی

- 🎯 **طراحی ریسپانسیو**: استفاده از `flutter_screenutil` برای ابعاد و فونت‌های ریسپانسیو
- 🎨 **تم‌های تاریک و روشن**: پشتیبانی کامل از حالت تاریک و روشن
- 🌍 **چندزبانه**: پشتیبانی از فارسی و انگلیسی
- 🔐 **احراز هویت**: سیستم کامل ورود و ثبت نام با Supabase
- 📱 **اعلان‌ها**: سیستم اعلان‌های محلی و Firebase
- 🏗️ **معماری تمیز**: استفاده از Provider برای مدیریت state
- 📊 **داشبورد**: نمایش آمار و پیشرفت کاربر

## ساختار پروژه

```
lib/
├── core/                    # کدهای اصلی و مشترک
│   ├── config/             # تنظیمات اپلیکیشن
│   ├── providers/          # مدیریت state با Provider
│   ├── routes/             # مدیریت navigation
│   ├── services/           # سرویس‌های مختلف
│   ├── theme/              # تم‌ها و استایل‌ها
│   └── utils/              # ابزارهای کمکی
├── features/               # ویژگی‌های مختلف اپلیکیشن
│   ├── auth/              # احراز هویت
│   ├── home/              # صفحه اصلی
│   ├── profile/           # پروفایل کاربر
│   ├── settings/          # تنظیمات
│   └── splash/            # صفحه splash
└── main.dart              # نقطه ورود اپلیکیشن
```

## تکنولوژی‌های استفاده شده

### Core Dependencies
- **Flutter**: فریمورک اصلی
- **Dart**: زبان برنامه‌نویسی
- **Provider**: مدیریت state
- **GoRouter**: مدیریت navigation

### UI/UX
- **flutter_screenutil**: طراحی ریسپانسیو
- **google_fonts**: فونت‌های گوگل
- **Material Design 3**: طراحی متریال

### Backend & Services
- **Supabase**: پایگاه داده و احراز هویت
- **Firebase**: اعلان‌ها و analytics
- **SharedPreferences**: ذخیره‌سازی محلی

### Additional Features
- **Connectivity Plus**: بررسی اتصال اینترنت
- **Permission Handler**: مدیریت مجوزها
- **Image Picker**: انتخاب تصاویر
- **URL Launcher**: باز کردن لینک‌ها

## تنظیمات اولیه

### 1. نصب وابستگی‌ها
```bash
flutter pub get
```

### 2. تنظیم Supabase
در فایل `lib/core/config/app_config.dart`:
```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

### 3. تنظیم Firebase
فایل `google-services.json` را در پوشه `android/app/` قرار دهید.

### 4. اجرای اپلیکیشن
```bash
flutter run
```

## سیستم طراحی ریسپانسیو

### استفاده از ابعاد ریسپانسیو

```dart
// عرض
Container(
  width: 100.w,  // 100 pixels responsive width
  height: 50.h,  // 50 pixels responsive height
  child: Text(
    'Hello',
    style: TextStyle(fontSize: 16.sp), // 16 responsive font size
  ),
)
```

### ثابت‌های از پیش تعریف شده

```dart
// استفاده از ثابت‌های تعریف شده
Container(
  width: AppConstants.width100,
  height: AppConstants.height50,
  padding: AppConstants.padding16,
  margin: AppConstants.margin8,
  child: Text(
    'Hello',
    style: AppConstants.body1,
  ),
)
```

## مدیریت State

### AuthProvider
```dart
final authProvider = Provider.of<AuthProvider>(context);
await authProvider.signIn(email: email, password: password);
```

### ThemeProvider
```dart
final themeProvider = Provider.of<ThemeProvider>(context);
themeProvider.toggleTheme(); // تغییر تم
```

### LanguageProvider
```dart
final languageProvider = Provider.of<LanguageProvider>(context);
languageProvider.toggleLanguage(); // تغییر زبان
```

## Navigation

### استفاده از GoRouter
```dart
// Navigate to a page
context.go('/home');

// Navigate with parameters
context.go('/profile?id=123');

// Pop current page
context.pop();
```

## تم‌ها و استایل‌ها

### استفاده از تم‌ها
```dart
Theme.of(context).primaryColor
Theme.of(context).textTheme.headlineLarge
```

### استایل‌های سفارشی
```dart
Text(
  'Custom Text',
  style: AppConstants.heading1.copyWith(
    color: Colors.blue,
  ),
)
```

## تست و کیفیت کد

### اجرای تحلیل کد
```bash
flutter analyze
```

### اجرای تست‌ها
```bash
flutter test
```

### فرمت کردن کد
```bash
dart format .
```

## قوانین کدنویسی

1. **استفاده از ابعاد ریسپانسیو**: همیشه از `.w`, `.h`, `.sp` استفاده کنید
2. **نام‌گذاری**: از camelCase برای متغیرها و PascalCase برای کلاس‌ها
3. **Import ها**: مرتب کردن import ها طبق قوانین
4. **Documentation**: مستندسازی کدهای پیچیده
5. **Error Handling**: مدیریت مناسب خطاها

## نمونه کد

### ایجاد یک صفحه جدید
```dart
class NewPage extends StatelessWidget {
  const NewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('صفحه جدید'),
      ),
      body: Padding(
        padding: AppConstants.padding16,
        child: Column(
          children: [
            Text(
              'متن نمونه',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: AppConstants.spacing16),
            ElevatedButton(
              onPressed: () {},
              child: const Text('دکمه'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## مشارکت

1. Fork کنید
2. یک branch جدید ایجاد کنید
3. تغییرات خود را commit کنید
4. Pull request ارسال کنید

## لایسنس

این پروژه تحت لایسنس MIT منتشر شده است.