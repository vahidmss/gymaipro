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
  const ChatMainScreen({super.key});

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
    _tabController = TabController(length: 3, vsync: this);
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
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.cardColor,
          elevation: 0,
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppTheme.goldColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  LucideIcons.messageCircle,
                  color: AppTheme.goldColor,
                  size: 20.sp,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'گفتگو',
                    style: AppTheme.headingStyle.copyWith(fontSize: 18.sp),
                  ),
                  Text(
                    'با مربیان و کاربران چت کنید',
                    style: AppTheme.bodyStyle.copyWith(fontSize: 12.sp),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.settings, color: AppTheme.textColor),
              onPressed: _showChatSettings,
            ),
          ],
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.goldColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.cardColor,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppTheme.goldColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                LucideIcons.messageCircle,
                color: AppTheme.goldColor,
                size: 20.sp,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'گفتگو',
                  style: AppTheme.headingStyle.copyWith(fontSize: 18.sp),
                ),
                Text(
                  'با مربیان و کاربران چت کنید',
                  style: AppTheme.bodyStyle.copyWith(fontSize: 12.sp),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings, color: AppTheme.textColor),
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
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: const PublicChatWidget(),
                ),
                // تب انتخاب مربی
                const ChatTrainerSelectionScreen(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppTheme.goldColor.withValues(alpha: 0.2)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.goldColor,
          borderRadius: BorderRadius.circular(10.r),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AppTheme.textColor,
        unselectedLabelColor: AppTheme.bodyStyle.color,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 14.sp,
        ),
        dividerColor: AppTheme.backgroundColor,
        tabs: [
          const Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.messageSquare, size: 16),
                SizedBox(width: 6),
                Text('گفتگوها'),
              ],
            ),
          ),
          const Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.users, size: 16),
                SizedBox(width: 6),
                Text('همگانی'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.userPlus, size: 16),
                const SizedBox(width: 6),
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
      return FloatingActionButton(
        onPressed: _showTrainerSearch,
        backgroundColor: AppTheme.goldColor,
        child: const Icon(LucideIcons.search, color: AppTheme.textColor),
      );
    }

    return const SizedBox.shrink();
  }

  void _showChatSettings() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'تنظیمات چت',
              style: AppTheme.headingStyle.copyWith(fontSize: 18.sp),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(LucideIcons.bell, color: AppTheme.goldColor),
              title: const Text(
                'اعلان‌ها',
                style: TextStyle(color: AppTheme.textColor),
              ),
              onTap: () {
                Navigator.pop(context);
                // Notification settings not implemented yet
              },
            ),
            ListTile(
              leading: const Icon(
                LucideIcons.shield,
                color: AppTheme.goldColor,
              ),
              title: const Text(
                'حریم خصوصی',
                style: TextStyle(color: AppTheme.textColor),
              ),
              onTap: () {
                Navigator.pop(context);
                // Privacy settings not implemented yet
              },
            ),
            ListTile(
              leading: const Icon(
                LucideIcons.download,
                color: AppTheme.goldColor,
              ),
              title: const Text(
                'پشتیبان‌گیری',
                style: TextStyle(color: AppTheme.textColor),
              ),
              onTap: () {
                Navigator.pop(context);
                // Backup feature not implemented yet
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTrainerSearch() {
    // Trainer search not implemented yet
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('جستجوی مربی به زودی اضافه می‌شود')),
    );
  }
}
