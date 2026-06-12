import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/config/app_config.dart';
import 'package:gymaipro/services/app_access_control_service.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/widgets/app_status_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class AppAccessControlGate extends StatefulWidget {
  const AppAccessControlGate({required this.child, super.key});

  final Widget child;

  @override
  State<AppAccessControlGate> createState() => _AppAccessControlGateState();
}

class _AppAccessControlGateState extends State<AppAccessControlGate> {
  AppAccessConfig _config = AppAccessConfig.defaults();
  bool _isAdmin = false;
  String _userRole = 'athlete';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _refreshAccessState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      _refreshAccessState();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refreshAccessState() async {
    final config = await AppAccessControlService.instance.getConfig(
      forceRefresh: true,
    );
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

  Future<void> _openUpdateLink() async {
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

  @override
  Widget build(BuildContext context) {
    final showMaintenance =
        _config.maintenanceMode && _isMaintenanceApplicableForCurrentUser();
    final showForceUpdate = _config.shouldForceUpdate && !_isAdmin;

    if (!showMaintenance && !showForceUpdate) {
      return widget.child;
    }

    final title = showForceUpdate ? 'نیاز به بروزرسانی' : 'اپ موقتاً بسته است';
    final description = showForceUpdate
        ? 'برای ادامه، اپ را به نسخه جدید ارتقا دهید.'
        : _config.maintenanceMessage;

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        AppStatusCard(
          overlay: true,
          icon: showForceUpdate ? LucideIcons.download : LucideIcons.wrench,
          title: title,
          description: description,
          badgeText: showForceUpdate ? 'نسخه فعلی: ${AppConfig.appVersion}' : null,
          showLoading: showMaintenance,
          actions: [
            if (showForceUpdate)
              AppStatusAction(
                label: 'بروزرسانی اپ',
                onPressed: _openUpdateLink,
                primary: true,
              ),
            AppStatusAction(label: 'بررسی مجدد', onPressed: _refreshAccessState),
          ],
        ),
      ],
    );
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
}
