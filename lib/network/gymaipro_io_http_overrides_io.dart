import 'dart:io';

import 'package:gymaipro/config/app_config.dart';
import 'package:gymaipro/network/gymaipro_insecure_tls_hosts.dart';

void installGymaiproIoHttpOverridesForMedia() {
  if (!AppConfig.allowInsecureTlsFallback) {
    return;
  }
  HttpOverrides.global = _GymaiproMediaHttpOverrides();
}

class _GymaiproMediaHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) =>
          GymaiproInsecureTlsHosts.allowInsecureConnectionTo(host);
    return client;
  }
}
