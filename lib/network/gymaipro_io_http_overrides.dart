import 'dart:io' show HttpClient;

import 'package:gymaipro/network/gymaipro_io_http_overrides_stub.dart'
    if (dart.library.io) 'gymaipro_io_http_overrides_io.dart' as impl;

/// روی IO (موبایل/دسکتاپ) برای `Image`، `CachedNetworkImage` و `http` با میزبان gymaipro
/// در صورت انقضای SSL، [HttpClient] گواهی را نپذیرد مگر برای دامنه‌های مجاز.
void installGymaiproIoHttpOverridesForMedia() =>
    impl.installGymaiproIoHttpOverridesForMedia();
