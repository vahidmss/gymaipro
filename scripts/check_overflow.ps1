# اسکریپت PowerShell برای بررسی overflow در کل پروژه
# این اسکریپت تمام تست‌های overflow را اجرا می‌کند

Write-Host "🔍 شروع بررسی overflow در پروژه..." -ForegroundColor Cyan

# اجرای تست‌های overflow
Write-Host "📝 اجرای تست‌های overflow..." -ForegroundColor Yellow
flutter test test/overflow_test.dart

# اجرای تست‌های integration
Write-Host "📝 اجرای تست‌های integration overflow..." -ForegroundColor Yellow
flutter test test/overflow_integration_test.dart

# اجرای flutter analyze برای بررسی مشکلات
Write-Host "🔍 اجرای flutter analyze..." -ForegroundColor Yellow
flutter analyze --no-fatal-infos | Select-String -Pattern "overflow|RenderFlex" | ForEach-Object {
    Write-Host $_ -ForegroundColor Red
}
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ هیچ مشکل overflow پیدا نشد" -ForegroundColor Green
}

# بررسی فایل‌های مشکوک
Write-Host "🔍 بررسی فایل‌های مشکوک..." -ForegroundColor Yellow

Write-Host "جستجوی Row بدون Flexible/Expanded..." -ForegroundColor Yellow
Get-ChildItem -Path lib -Recurse -Filter "*.dart" | Select-String -Pattern "Row\(" | Where-Object { 
    $_.Line -notmatch "Flexible|Expanded" 
} | Select-Object -First 20 | ForEach-Object {
    Write-Host "$($_.Filename):$($_.LineNumber) - $($_.Line)" -ForegroundColor Yellow
}

Write-Host "جستجوی Text بدون maxLines..." -ForegroundColor Yellow
Get-ChildItem -Path lib -Recurse -Filter "*.dart" | Select-String -Pattern "Text\(" | Where-Object { 
    $_.Line -notmatch "maxLines" 
} | Select-Object -First 20 | ForEach-Object {
    Write-Host "$($_.Filename):$($_.LineNumber) - $($_.Line)" -ForegroundColor Yellow
}

Write-Host "✅ بررسی overflow کامل شد!" -ForegroundColor Green
