<?php
/**
 * تنظیمات اتصال به Supabase برای اسکریپت‌های آپلود روی dl.gymaipro.ir
 *
 * مهم: از HTTPS استفاده کن. اگر http://IP بزنی و سرور 301 به HTTPS بدهد،
 * اسکریپت‌ها 401 با debug_http=301 می‌گیرند.
 */
return [
    // دامنه عمومی Supabase روی پورت 443
    'supabase_url' => 'https://api.gymaipro.ir',
    // اگر از IP استفاده می‌کنی، حتماً https و supabase_host را بگذار
    'supabase_host' => 'api.gymaipro.ir',
    'supabase_anon_key' => 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyAgCiAgICAicm9sZSI6ICJhbm9uIiwKICAgICJpc3MiOiAic3VwYWJhc2UtZGVtbyIsCiAgICAiaWF0IjogMTY0MTc2OTIwMCwKICAgICJleHAiOiAxNzk5NTM1NjAwCn0.dc_X5iR_VP_qT0zsiyj_I_OZ2T9FtRU2BBNWN8Bu4GE',
];
