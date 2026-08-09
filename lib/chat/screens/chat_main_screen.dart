import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/chat/screens/chat_conversations_screen.dart';
import 'package:gymaipro/chat/widgets/public_chat_widget.dart';
import 'package:gymaipro/core/web_interaction.dart';
import 'package:gymaipro/navigation/screens/main_navigation_screen.dart';
import 'package:gymaipro/services/app_feedback_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatMainScreen extends StatefulWidget {
  const ChatMainScreen({
    super.key,
    this.initialTabIndex = 0,
    this.isActiveTab = true,
  });

  final int initialTabIndex;

  /// When embedded in [MainNavigationScreen], only the visible tab handles back.
  final bool isActiveTab;

  @override
  State<ChatMainScreen> createState() => _ChatMainScreenState();
}

class _ChatMainScreenState extends State<ChatMainScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: context.backgroundColor,
        appBarTheme: AppBarTheme(
          backgroundColor: context.cardColor,
          elevation: 0,
          foregroundColor: context.textColor,
        ),
      ),
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: AppBar(
          backgroundColor: context.cardColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(LucideIcons.arrowRight, color: context.textColor),
            tooltip: 'بازگشت به منو',
            onPressed: _handleLeaveChatHub,
          ),
          title: Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: context.goldGradientColors
                        .map((c) => c.withValues(alpha: 0.2))
                        .toList(),
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  LucideIcons.messageCircle,
                  color: AppTheme.goldColor,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'گفتگو',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.bold,
                        fontSize: 18.sp,
                        color: context.textColor,
                      ),
                    ),
                    Text(
                      'پیام‌های خصوصی و چت همگانی',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12.sp,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(LucideIcons.settings, color: context.textColor),
              onPressed: _showChatSettings,
            ),
          ],
        ),
        body: Column(
          children: [
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: _buildTabBar(),
            ),
            SizedBox(height: 10.h),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: WebInteraction.tabBarViewPhysics,
                children: const [ChatConversationsScreen(), PublicChatWidget()],
              ),
            ),
          ],
        ),
      ),
    );

    if (!widget.isActiveTab) {
      return scaffold;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleLeaveChatHub();
      },
      child: scaffold,
    );
  }

  void _handleLeaveChatHub() {
    if (_tabController.index > 0) {
      _tabController.animateTo(0);
      return;
    }
    if (MainNavigationScreen.isShellActive) {
      MainNavigationScreen.leaveSocialTab();
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Widget _buildTabBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 46.h,
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: isDark ? 0.28 : 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldColor.withValues(alpha: isDark ? 0.04 : 0.08),
            blurRadius: 10,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(colors: context.goldGradientColors),
          borderRadius: BorderRadius.circular(12.r),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: EdgeInsets.all(4.w),
        labelPadding: EdgeInsets.symmetric(horizontal: 8.w),
        labelColor: AppTheme.onGoldColor,
        unselectedLabelColor: context.textSecondary,
        labelStyle: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontWeight: FontWeight.bold,
          fontSize: 13.5.sp,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontWeight: FontWeight.w500,
          fontSize: 13.5.sp,
        ),
        dividerColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        tabs: [
          Tab(
            child: Row(
              textDirection: TextDirection.rtl,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.messageSquare, size: 16.sp),
                SizedBox(width: 6.w),
                const Text('گفتگوها'),
              ],
            ),
          ),
          Tab(
            child: Row(
              textDirection: TextDirection.rtl,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.users, size: 16.sp),
                SizedBox(width: 6.w),
                const Text('همگانی'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showChatSettings() {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: context.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        builder: (context) => const _ChatSettingsSheet(),
      ),
    );
  }
}

class _ChatSettingsSheet extends StatefulWidget {
  const _ChatSettingsSheet();

  @override
  State<_ChatSettingsSheet> createState() => _ChatSettingsSheetState();
}

class _ChatSettingsSheetState extends State<_ChatSettingsSheet> {
  bool _loading = true;
  bool _chatSoundsEnabled = true;
  bool _hapticsEnabled = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final sounds = await AppFeedbackService.instance.isChatInAppSoundsEnabled();
    final haptics = await AppFeedbackService.instance.isVibrationEnabled();
    if (!mounted) return;
    setState(() {
      _chatSoundsEnabled = sounds;
      _hapticsEnabled = haptics;
      _loading = false;
    });
  }

  Future<void> _setChatSounds(bool value) async {
    setState(() => _chatSoundsEnabled = value);
    await AppFeedbackService.instance.setChatInAppSoundsEnabled(enabled: value);
    unawaited(AppFeedbackService.instance.selection());
  }

  Future<void> _setHaptics(bool value) async {
    setState(() => _hapticsEnabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppFeedbackService.vibrationEnabledKey, value);
    if (value) {
      unawaited(AppFeedbackService.instance.selection());
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: context.separatorColor,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'تنظیمات چت',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
                color: context.textColor,
              ),
            ),
            SizedBox(height: 12.h),
            if (_loading)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 24.h),
                child: const CircularProgressIndicator(
                  color: AppTheme.goldColor,
                ),
              )
            else ...[
              Directionality(
                textDirection: TextDirection.rtl,
                child: SwitchListTile(
                  secondary: const Icon(
                    LucideIcons.volume2,
                    color: AppTheme.goldColor,
                  ),
                  title: Text(
                    'صداهای گفتگو',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: context.textColor,
                    ),
                  ),
                  subtitle: Text(
                    'صدای نرم ارسال و دریافت داخل چت',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: context.textSecondary,
                      fontSize: 12.sp,
                    ),
                  ),
                  value: _chatSoundsEnabled,
                  activeThumbColor: AppTheme.goldColor,
                  onChanged: _setChatSounds,
                ),
              ),
              Directionality(
                textDirection: TextDirection.rtl,
                child: SwitchListTile(
                  secondary: const Icon(
                    LucideIcons.vibrate,
                    color: AppTheme.goldColor,
                  ),
                  title: Text(
                    'لرزش لمسی',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: context.textColor,
                    ),
                  ),
                  subtitle: Text(
                    'فیدبک لمسی برای اکشن‌های چت',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: context.textSecondary,
                      fontSize: 12.sp,
                    ),
                  ),
                  value: _hapticsEnabled,
                  activeThumbColor: AppTheme.goldColor,
                  onChanged: _setHaptics,
                ),
              ),
              Directionality(
                textDirection: TextDirection.rtl,
                child: ListTile(
                  leading: const Icon(
                    LucideIcons.bell,
                    color: AppTheme.goldColor,
                  ),
                  title: Text(
                    'اعلان‌های پیام',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: context.textColor,
                    ),
                  ),
                  subtitle: Text(
                    'نوتیفیکیشن، پیش‌نمایش و صدای سیستم',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: context.textSecondary,
                      fontSize: 12.sp,
                    ),
                  ),
                  trailing: Icon(
                    LucideIcons.chevronLeft,
                    color: context.textSecondary,
                  ),
                  onTap: () {
                    unawaited(AppFeedbackService.instance.selection());
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed(
                      '/private-message-notification-settings',
                    );
                  },
                ),
              ),
            ],
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }
}
