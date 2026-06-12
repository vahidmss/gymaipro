import 'package:flutter/foundation.dart';
import 'package:gymaipro/config/app_config.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Runtime app version from the installed package (pubspec / build metadata).
class AppVersionService {
  AppVersionService._();

  static final AppVersionService instance = AppVersionService._();

  PackageInfo? _info;
  Future<void>? _loadFuture;

  Future<void> ensureLoaded() {
    _loadFuture ??= _load();
    return _loadFuture!;
  }

  Future<void> _load() async {
    try {
      _info = await PackageInfo.fromPlatform();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AppVersionService: failed to read package info: $e');
      }
    }
  }

  String get version {
    final info = _info;
    if (info != null && info.version.trim().isNotEmpty) {
      return info.version.trim();
    }
    return AppConfig.appVersion;
  }

  String get buildNumber {
    final info = _info;
    if (info != null && info.buildNumber.trim().isNotEmpty) {
      return info.buildNumber.trim();
    }
    return '0';
  }

  String get fullVersionLabel => '$version+$buildNumber';
}
