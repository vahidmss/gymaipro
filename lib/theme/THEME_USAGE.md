# راهنمای استفاده از تم روشن/تاریک

## نحوه استفاده از Extension Methods

برای استفاده از رنگ‌های سازگار با تم، از extension methods استفاده کنید:

```dart
// به جای:
Container(
  color: AppTheme.backgroundColor, // فقط dark mode
)

// استفاده کنید:
Container(
  color: context.backgroundColor, // خودکار بر اساس تم
)
```

## رنگ‌های موجود در Extension

- `context.backgroundColor` - پس‌زمینه اصلی
- `context.cardColor` - رنگ کارت‌ها
- `context.textColor` - رنگ متن اصلی
- `context.textSecondary` - رنگ متن ثانویه
- `context.separatorColor` - رنگ جداکننده
- `context.gradientStartColor` - رنگ شروع gradient
- `context.veryDarkBackground` - پس‌زمینه خیلی تیره/روشن

## مثال استفاده

```dart
Widget build(BuildContext context) {
  return Container(
    color: context.backgroundColor,
    child: Card(
      color: context.cardColor,
      child: Text(
        'متن نمونه',
        style: TextStyle(color: context.textColor),
      ),
    ),
  );
}
```

## سوییچ تم

تم از طریق `ThemeProvider` مدیریت می‌شود:

```dart
// در settings_screen
Consumer<ThemeProvider>(
  builder: (context, themeProvider, _) {
    return Switch(
      value: themeProvider.isDarkMode,
      onChanged: (value) => themeProvider.setTheme(value),
    );
  },
)
```

## رنگ‌های ثابت (مشترک بین light/dark)

این رنگ‌ها در هر دو تم یکسان هستند:
- `AppTheme.goldColor`
- `AppTheme.darkGold`
- `AppTheme.accentColor`
- `AppTheme.successColor`
- `AppTheme.errorColor`
- و سایر رنگ‌های معنایی

