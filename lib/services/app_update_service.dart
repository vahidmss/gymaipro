import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/services/app_access_control_service.dart';
import 'package:gymaipro/services/app_version_service.dart';
import 'package:gymaipro/services/apk_install_service.dart';
import 'package:gymaipro/services/connectivity_service.dart';
import 'package:gymaipro/utils/version_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppUpdatePromptKind {
  none,
  apkOptional,
  apkRequired,
}

@immutable
class AppUpdateState {
  const AppUpdateState({
    required this.promptKind,
    required this.currentVersion,
    required this.latestRemoteVersion,
    required this.isChecking,
    required this.isApplying,
    required this.apkDownloadProgress,
    required this.apkDownloadTotal,
    required this.lastError,
  });

  factory AppUpdateState.initial() {
    return const AppUpdateState(
      promptKind: AppUpdatePromptKind.none,
      currentVersion: '',
      latestRemoteVersion: '',
      isChecking: false,
      isApplying: false,
      apkDownloadProgress: 0,
      apkDownloadTotal: null,
      lastError: null,
    );
  }

  final AppUpdatePromptKind promptKind;
  final String currentVersion;
  final String latestRemoteVersion;
  final bool isChecking;
  final bool isApplying;
  final int apkDownloadProgress;
  final int? apkDownloadTotal;
  final String? lastError;

  AppUpdateState copyWith({
    AppUpdatePromptKind? promptKind,
    String? currentVersion,
    String? latestRemoteVersion,
    bool? isChecking,
    bool? isApplying,
    int? apkDownloadProgress,
    int? apkDownloadTotal,
    String? lastError,
    bool clearError = false,
  }) {
    return AppUpdateState(
      promptKind: promptKind ?? this.promptKind,
      currentVersion: currentVersion ?? this.currentVersion,
      latestRemoteVersion: latestRemoteVersion ?? this.latestRemoteVersion,
      isChecking: isChecking ?? this.isChecking,
      isApplying: isApplying ?? this.isApplying,
      apkDownloadProgress: apkDownloadProgress ?? this.apkDownloadProgress,
      apkDownloadTotal: apkDownloadTotal ?? this.apkDownloadTotal,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}

/// Coordinates sideloaded APK updates from Supabase for gym distribution.
class AppUpdateService {
  AppUpdateService._();

  static final AppUpdateService instance = AppUpdateService._();

  static const _dismissedApkVersionKey = 'app_update_dismissed_apk_version';
  static const _minCheckInterval = Duration(minutes: 10);

  final ValueNotifier<AppUpdateState> stateNotifier = ValueNotifier(
    AppUpdateState.initial(),
  );

  final AppAccessControlService _accessService = AppAccessControlService.instance;

  DateTime? _lastCheckAt;
  bool _checkInFlight = false;

  Future<void> checkForUpdates({bool force = false}) async {
    if (_checkInFlight) return;
    if (!force &&
        _lastCheckAt != null &&
        DateTime.now().difference(_lastCheckAt!) < _minCheckInterval) {
      return;
    }

    _checkInFlight = true;
    stateNotifier.value = stateNotifier.value.copyWith(
      isChecking: true,
      clearError: true,
    );

    try {
      await AppVersionService.instance.ensureLoaded();
      final currentVersion = AppVersionService.instance.version;

      stateNotifier.value = stateNotifier.value.copyWith(
        currentVersion: currentVersion,
      );

      final online = await ConnectivityService.instance.canReachAppBackend();
      AppAccessConfig config = _accessService.configNotifier.value;
      if (online) {
        config = await _accessService.getConfig(forceRefresh: force);
      }

      final latestRemote = config.latestVersion.trim();
      stateNotifier.value = stateNotifier.value.copyWith(
        latestRemoteVersion: latestRemote,
      );

      if (_shouldForceApkUpdate(config, currentVersion)) {
        stateNotifier.value = stateNotifier.value.copyWith(
          promptKind: AppUpdatePromptKind.apkRequired,
        );
        return;
      }

      if (online && await _shouldSuggestApkUpdate(config, currentVersion)) {
        stateNotifier.value = stateNotifier.value.copyWith(
          promptKind: AppUpdatePromptKind.apkOptional,
        );
        return;
      }

      stateNotifier.value = stateNotifier.value.copyWith(
        promptKind: AppUpdatePromptKind.none,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AppUpdateService.checkForUpdates error: $e');
      }
      stateNotifier.value = stateNotifier.value.copyWith(
        lastError: 'خطا در بررسی بروزرسانی',
      );
    } finally {
      _lastCheckAt = DateTime.now();
      _checkInFlight = false;
      stateNotifier.value = stateNotifier.value.copyWith(isChecking: false);
    }
  }

  bool _shouldForceApkUpdate(AppAccessConfig config, String currentVersion) {
    if (!config.forceUpdate) return false;
    final minVersion = config.minSupportedVersion.trim();
    if (minVersion.isEmpty) return false;
    return VersionUtils.isLessThan(currentVersion, minVersion);
  }

  Future<bool> _shouldSuggestApkUpdate(
    AppAccessConfig config,
    String currentVersion,
  ) async {
    final latest = config.latestVersion.trim();
    final updateUrl = config.updateUrl.trim();
    if (latest.isEmpty || updateUrl.isEmpty) return false;
    if (!VersionUtils.isLessThan(currentVersion, latest)) return false;

    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getString(_dismissedApkVersionKey);
    return dismissed != latest;
  }

  Future<void> dismissOptionalApkPrompt() async {
    final latest = stateNotifier.value.latestRemoteVersion.trim();
    if (latest.isEmpty) {
      clearPrompt();
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dismissedApkVersionKey, latest);
    clearPrompt();
  }

  void clearPrompt() {
    stateNotifier.value = stateNotifier.value.copyWith(
      promptKind: AppUpdatePromptKind.none,
      clearError: true,
    );
  }

  Future<bool> downloadAndInstallApk({String? urlOverride}) async {
    final config = _accessService.configNotifier.value;
    final url = (urlOverride ?? config.updateUrl).trim();
    if (url.isEmpty) {
      stateNotifier.value = stateNotifier.value.copyWith(
        lastError: 'لینک بروزرسانی تنظیم نشده است.',
      );
      return false;
    }

    stateNotifier.value = stateNotifier.value.copyWith(
      isApplying: true,
      apkDownloadProgress: 0,
      apkDownloadTotal: null,
      clearError: true,
    );

    try {
      final filePath = await ApkInstallService.instance.downloadApk(
        url: url,
        onProgress: (received, total) {
          stateNotifier.value = stateNotifier.value.copyWith(
            apkDownloadProgress: received,
            apkDownloadTotal: total,
          );
        },
      );
      if (filePath == null) {
        stateNotifier.value = stateNotifier.value.copyWith(
          lastError: 'دانلود APK ناموفق بود. اتصال اینترنت را بررسی کنید.',
        );
        return false;
      }

      final installed = await ApkInstallService.instance.installApk(filePath);
      if (!installed) {
        stateNotifier.value = stateNotifier.value.copyWith(
          lastError:
              'نصب APK شروع نشد. «نصب از منابع ناشناس» را برای مرورگر/فایل‌منیجر فعال کنید.',
        );
      }
      return installed;
    } finally {
      stateNotifier.value = stateNotifier.value.copyWith(isApplying: false);
    }
  }
}
