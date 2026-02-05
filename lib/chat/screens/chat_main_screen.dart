import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/chat/screens/chat_conversations_screen.dart';
import 'package:gymaipro/chat/screens/chat_trainer_selection_screen.dart';
import 'package:gymaipro/chat/widgets/public_chat_widget.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatMainScreen extends StatefulWidget {
  const ChatMainScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  final int initialTabIndex;

  @override
  State<ChatMainScreen> createState() => _ChatMainScreenState();
}

class _ChatMainScreenState extends State<ChatMainScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  String? _userRole;
  bool _roleResolved = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
    _currentIndex = widget.initialTabIndex.clamp(0, 2);
    _loadCachedRole();
    _loadUserInfo();

    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
      });
    });
  }

  Future<void> _loadCachedRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('cached_user_role');
      if (cached != null && mounted) {
        setState(() {
          _userRole = cached;
          _roleResolved = true;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadUserInfo() async {
    try {
      final profileMap = await SimpleProfileService.getCurrentProfile();
      if (profileMap != null) {
        setState(() {
          _userRole = profileMap['role'] as String?;
          _roleResolved = true;
        });
        // cache to avoid flicker on next open
        try {
          final prefs = await SharedPreferences.getInstance();
          if (_userRole != null) {
            await prefs.setString('cached_user_role', _userRole!);
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Error loading user info: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_roleResolved) {
      // نمایش یک حالت سبک تا نقش آماده شود تا از فلیکر جلوگیری شود
      return Theme(
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
            title: Row(
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: context.goldGradientColors.map((c) => c.withValues(alpha: 0.2)).toList(),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'گفتگو',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.bold,
                        fontSize: 18.sp,
                        color: context.textColor,
                      ),
                    ),
                    Text(
                      'با مربیان و کاربران چت کنید',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12.sp,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
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
          body: Center(
            child: CircularProgressIndicator(color: AppTheme.goldColor),
          ),
        ),
      );
    }

    return Theme(
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
          title: Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: context.goldGradientColors.map((c) => c.withValues(alpha: 0.2)).toList(),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'گفتگو',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.bold,
                      fontSize: 18.sp,
                      color: context.textColor,
                    ),
                  ),
                  Text(
                    'با مربیان و کاربران چت کنید',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 12.sp,
                      color: context.textSecondary,
                    ),
                  ),
                ],
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
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // تب گفتگوها
                const ChatConversationsScreen(),
                // تب چت عمومی - مستقیماً PublicChatWidget
                const PublicChatWidget(),
                // تب انتخاب مربی
                const ChatTrainerSelectionScreen(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  Widget _buildTabBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: isDark ? 0.3 : 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldColor.withValues(alpha: isDark ? 0.05 : 0.1),
            blurRadius: 8,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: context.goldGradientColors,
          ),
          borderRadius: BorderRadius.circular(10.r),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AppTheme.onGoldColor,
        unselectedLabelColor: context.textSecondary,
        labelStyle: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontWeight: FontWeight.bold,
          fontSize: 14.sp,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontWeight: FontWeight.normal,
          fontSize: 14.sp,
        ),
        dividerColor: Colors.transparent,
        tabs: [
          Tab(
            child: Row(
              textDirection: TextDirection.rtl,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.messageSquare, size: 16.sp),
                SizedBox(width: 6.w),
                Text('گفتگوها'),
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
                Text('همگانی'),
              ],
            ),
          ),
          Tab(
            child: Row(
              textDirection: TextDirection.rtl,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.userPlus, size: 16.sp),
                SizedBox(width: 6.w),
                Text(_userRole == 'trainer' ? 'شاگردها' : 'مربی‌ها'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    if (_currentIndex == 1) {
      // برای تب چت عمومی - هیچ دکمه‌ای نیاز نیست
      return const SizedBox.shrink();
    } else if (_currentIndex == 2) {
      // برای تب مربی‌ها - جستجوی مربی
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: context.goldGradientColors,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.goldColor.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _showTrainerSearch,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Icon(LucideIcons.search, color: AppTheme.onGoldColor),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _showChatSettings() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
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
            SizedBox(height: 20.h),
            Directionality(
              textDirection: TextDirection.rtl,
              child: ListTile(
                leading: Icon(LucideIcons.bell, color: AppTheme.goldColor),
                title: Text(
                  'اعلان‌ها',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: context.textColor,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Notification settings not implemented yet
                },
              ),
            ),
            Directionality(
              textDirection: TextDirection.rtl,
              child: ListTile(
                leading: Icon(
                  LucideIcons.shield,
                  color: AppTheme.goldColor,
                ),
                title: Text(
                  'حریم خصوصی',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: context.textColor,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Privacy settings not implemented yet
                },
              ),
            ),
            Directionality(
              textDirection: TextDirection.rtl,
              child: ListTile(
                leading: Icon(
                  LucideIcons.download,
                  color: AppTheme.goldColor,
                ),
                title: Text(
                  'پشتیبان‌گیری',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: context.textColor,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Backup feature not implemented yet
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTrainerSearch() {
    // Trainer search not implemented yet
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'جستجوی مربی به زودی اضافه می‌شود',
          style: TextStyle(fontFamily: AppTheme.fontFamily),
        ),
        backgroundColor: context.cardColor,
      ),
    );
  }
}
