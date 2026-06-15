import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/config/app_config.dart';
import 'package:gymaipro/services/app_access_control_service.dart';
import 'package:gymaipro/services/app_update_service.dart';
import 'package:gymaipro/services/app_version_service.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/widgets/app_status_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

/// Maintenance / forced APK gate + optional sideload APK update prompts.
class AppUpdateCoordinator extends StatefulWidget {
  const AppUpdateCoordinator({required this.child, super.key});

  final Widget child;

  @override
  State<AppUpdateCoordinator> createState() => _AppUpdateCoordinatorState();
}

class _AppUpdateCoordinatorState extends State<AppUpdateCoordinator>
    with WidgetsBindingObserver {
  final AppAccessControlService _accessService =
      AppAccessControlService.instance;
  final AppUpdateService _updateService = AppUpdateService.instance;

  AppAccessConfig _config = AppAccessConfig.defaults();
  bool _isAdmin = false;
  String _userRole = 'athlete';
  Timer? _accessRefreshTimer;
  bool _softPromptVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateService.stateNotifier.addListener(_onUpdateStateChanged);
    unawaited(_bootstrap());
    _accessRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      unawaited(_refreshAccessState());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _accessRefreshTimer?.cancel();
    _updateService.stateNotifier.removeListener(_onUpdateStateChanged);
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await AppVersionService.instance.ensureLoaded();
    await _refreshAccessState();
    await _updateService.checkForUpdates(force: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshAccessState());
      unawaited(_updateService.checkForUpdates(force: true));
    }
  }

  void _onUpdateStateChanged() {
    if (!mounted) return;
    final kind = _updateService.stateNotifier.value.promptKind;
    if (kind == AppUpdatePromptKind.apkRequired) {
      setState(() {});
      return;
    }
    if (kind == AppUpdatePromptKind.none) {
      _softPromptVisible = false;
      setState(() {});
      return;
    }
    if (!_softPromptVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_showSoftUpdateDialog());
      });
    }
  }

  Future<void> _refreshAccessState() async {
    final config = await _accessService.getConfig(forceRefresh: true);
    var isAdmin = false;
    var userRole = 'athlete';
    try {
      final profile = await SimpleProfileService.getCurrentProfile();
      isAdmin = profile?['role'] == 'admin';
      userRole = (profile?['role'] as String?) ?? 'athlete';
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _config = config;
      _isAdmin = isAdmin;
      _userRole = userRole;
    });
  }

  bool _isMaintenanceApplicableForCurrentUser() {
    if (_isAdmin) return false;
    switch (_config.maintenanceScope) {
      case 'athlete_only':
        return _userRole == 'athlete';
      case 'trainer_only':
        return _userRole == 'trainer';
      case 'all_non_admin':
      default:
        return true;
    }
  }

  bool get _showMaintenance =>
      _config.maintenanceMode && _isMaintenanceApplicableForCurrentUser();

  bool get _showForceApkUpdate {
    if (_isAdmin) return false;
    return _updateService.stateNotifier.value.promptKind ==
        AppUpdatePromptKind.apkRequired;
  }

  Future<void> _openUpdateLinkExternally() async {
    final rawUrl = _config.updateUrl.trim();
    if (rawUrl.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لینک بروزرسانی تنظیم نشده است'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _handleForcedApkUpdate() async {
    final installed = await _updateService.downloadAndInstallApk();
    if (!mounted) return;
    if (installed) return;
    final error = _updateService.stateNotifier.value.lastError;
    if (error != null && error.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppTheme.errorColor),
      );
    }
    await _openUpdateLinkExternally();
  }

  Future<void> _showSoftUpdateDialog() async {
    if (!mounted || _softPromptVisible) return;
    final updateState = _updateService.stateNotifier.value;
    if (updateState.promptKind != AppUpdatePromptKind.apkOptional) {
      return;
    }

    _softPromptVisible = true;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: ValueListenableBuilder<AppUpdateState>(
            valueListenable: _updateService.stateNotifier,
            builder: (context, liveState, _) {
              return AlertDialog(
                backgroundColor:
                    isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18.r),
                  side: BorderSide(
                    color: AppTheme.goldColor.withValues(alpha: 0.25),
                  ),
                ),
                title: Row(
                  children: [
                    Icon(LucideIcons.download, color: AppTheme.goldColor, size: 22.sp),
                    SizedBox(width: 8.w),
                    const Expanded(
                      child: Text(
                        'نسخه جدید APK',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'نسخه ${liveState.latestRemoteVersion} منتشر شده. برای دریافت APK جدید دانلود و نصب کنید.',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 13.sp,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'نسخه فعلی: ${liveState.currentVersion.isNotEmpty ? liveState.currentVersion : AppConfig.appVersion}',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: AppTheme.goldColor,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (liveState.isApplying) ...[
                      SizedBox(height: 14.h),
                      LinearProgressIndicator(
                        minHeight: 3.h,
                        color: AppTheme.goldColor,
                        backgroundColor: AppTheme.goldColor.withValues(alpha: 0.15),
                        value: liveState.apkDownloadTotal != null &&
                                liveState.apkDownloadTotal! > 0
                            ? liveState.apkDownloadProgress /
                                liveState.apkDownloadTotal!
                            : null,
                      ),
                    ],
                    if (liveState.lastError != null &&
                        liveState.lastError!.isNotEmpty) ...[
                      SizedBox(height: 10.h),
                      Text(
                        liveState.lastError!,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: AppTheme.errorColor,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: liveState.isApplying
                        ? null
                        : () async {
                            await _updateService.dismissOptionalApkPrompt();
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                          },
                    child: const Text('بعداً'),
                  ),
                  FilledButton(
                    onPressed: liveState.isApplying
                        ? null
                        : () async {
                            await _updateService.downloadAndInstallApk();
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.goldColor,
                      foregroundColor: AppTheme.veryDarkBackground,
                    ),
                    child: const Text('دانلود و نصب'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    _softPromptVisible = false;
    if (!mounted) return;
    final remaining = _updateService.stateNotifier.value.promptKind;
    if (remaining == AppUpdatePromptKind.apkOptional) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_showSoftUpdateDialog());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppUpdateState>(
      valueListenable: _updateService.stateNotifier,
      builder: (context, updateState, _) {
        if (!_showMaintenance && !_showForceApkUpdate) {
          return widget.child;
        }

        final title =
            _showForceApkUpdate ? 'نیاز به بروزرسانی' : 'اپ موقتاً بسته است';
        final description = _showForceApkUpdate
            ? 'برای ادامه، نسخه جدید اپ را نصب کنید.'
            : _config.maintenanceMessage;
        final currentVersion = updateState.currentVersion.isNotEmpty
            ? updateState.currentVersion
            : AppVersionService.instance.version;

        return Stack(
          fit: StackFit.expand,
          children: [
            widget.child,
            AppStatusCard(
              overlay: true,
              icon:
                  _showForceApkUpdate ? LucideIcons.download : LucideIcons.wrench,
              title: title,
              description: description,
              badgeText: _showForceApkUpdate ? 'نسخه فعلی: $currentVersion' : null,
              showLoading: _showMaintenance || updateState.isApplying,
              actions: [
                if (_showForceApkUpdate)
                  AppStatusAction(
                    label: updateState.isApplying
                        ? 'در حال دانلود...'
                        : 'دانلود و نصب APK',
                    onPressed:
                        updateState.isApplying ? () {} : _handleForcedApkUpdate,
                    primary: true,
                  ),
                if (_showForceApkUpdate)
                  AppStatusAction(
                    label: 'باز کردن لینک',
                    onPressed: _openUpdateLinkExternally,
                  ),
                AppStatusAction(
                  label: 'بررسی مجدد',
                  onPressed: () {
                    unawaited(_refreshAccessState());
                    unawaited(_updateService.checkForUpdates(force: true));
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
