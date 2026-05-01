<?php
/**
 * تنظیمات اتصال به Supabase برای اسکریپت‌های آپلود
 * 
 * سرور dl.gymaipro.ir نمی‌تواند به IP:8000 وصل شود (فایروال/محدودیت).
 * باید Supabase از طریق دامنه عمومی روی HTTPS (پورت ۴۴۳) در دسترس باشد.
 * 
 * این فایل را روی dl کنار upload-cover.php قرار بده و URL دامنه خودت را بگذار.
 */
return [
    // آدرس دسترسی به Supabase از دید هاست دانلود
    // از IP روی پورت 80 استفاده می‌کنیم و Host را جداگانه تنظیم می‌کنیم
    'supabase_url' => 'http://87.248.156.175',
    'supabase_host' => 'api.gymaipro.ir',
    'supabase_anon_key' => 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyAgCiAgICAicm9sZSI6ICJhbm9uIiwKICAgICJpc3MiOiAic3VwYWJhc2UtZGVtbyIsCiAgICAiaWF0IjogMTY0MTc2OTIwMCwKICAgICJleHAiOiAxNzk5NTM1NjAwCn0.dc_X5iR_VP_qT0zsiyj_I_OZ2T9FtRU2BBNWN8Bu4GE',
];
