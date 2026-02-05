#!/bin/bash

# اسکریپت برای بررسی overflow در کل پروژه
# این اسکریپت تمام تست‌های overflow را اجرا می‌کند

echo "🔍 شروع بررسی overflow در پروژه..."

# اجرای تست‌های overflow
echo "📝 اجرای تست‌های overflow..."
flutter test test/overflow_test.dart

# اجرای تست‌های integration
echo "📝 اجرای تست‌های integration overflow..."
flutter test test/overflow_integration_test.dart

# اجرای flutter analyze برای بررسی مشکلات
echo "🔍 اجرای flutter analyze..."
flutter analyze --no-fatal-infos | grep -i "overflow\|RenderFlex" || echo "✅ هیچ مشکل overflow پیدا نشد"

# بررسی فایل‌های مشکوک
echo "🔍 بررسی فایل‌های مشکوک..."
echo "جستجوی Row بدون Flexible/Expanded..."
grep -r "Row(" lib/ --include="*.dart" | grep -v "Flexible\|Expanded" | head -20 || echo "✅ همه Row ها امن هستند"

echo "جستجوی Text بدون maxLines..."
grep -r "Text(" lib/ --include="*.dart" | grep -v "maxLines" | head -20 || echo "✅ همه Text ها امن هستند"

echo "✅ بررسی overflow کامل شد!"
