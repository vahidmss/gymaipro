import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/my_club/my_programs_screen.dart';
import 'package:gymaipro/my_club/screens/confidential_user_info_screen.dart';
import 'package:gymaipro/my_club/screens/friendship_search_screen.dart';
import 'package:gymaipro/my_club/screens/my_friends_screen.dart';
import 'package:gymaipro/my_club/screens/my_points_screen.dart';
import 'package:gymaipro/my_club/screens/my_wallet_screen.dart';
import 'package:gymaipro/my_club/widgets/my_club_trainer_card.dart';
import 'package:gymaipro/my_club/widgets/unified_empty_state.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_dashboard/services/trainer_client_service.dart';
import 'package:gymaipro/utils/auth_helper.dart';
import 'package:gymaipro/utils/cache_service.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MyClubMainScreen extends StatefulWidget {
  const MyClubMainScreen({super.key, this.initialTabIndex});

  /// ۰=برنامه‌ها، ۱=مربی‌ها، ۲=دوستان، ۳=امتیازات، ۴=مالی، ۵=اطلاعات محرمانه
  final int? initialTabIndex;

  @override
  State<MyClubMainScreen> createState() => _MyClubMainScreenState();
}

class _MyClubMainScreenState extends State<MyClubMainScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    final initialIndex = (widget.initialTabIndex ?? 0).clamp(0, 5);
    _tabController = TabController(
      length: 6,
      vsync: this,
      initialIndex: initialIndex,
    );
    _tabController.addListener(() {
      SafeSetState.call(this, () {});
    });
  }

  @override
  void didUpdateWidget(covariant MyClubMainScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTabIndex != oldWidget.initialTabIndex) {
      _applyInitialTab(widget.initialTabIndex);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final initialTab = widget.initialTabIndex ??
          args?['initialTab'] as int? ??
          args?['initialTabIndex'] as int?;
      _applyInitialTab(initialTab);
      _isInitialized = true;
    }
  }

  void _applyInitialTab(int? tabIndex) {
    if (tabIndex == null) return;
    final index = tabIndex.clamp(0, _tabController.length - 1);
    if (_tabController.index == index) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _tabController.index != index) {
        _tabController.animateTo(index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: context.backgroundColor,
        appBarTheme: AppBarTheme(
          backgroundColor: isDark
              ? context.backgroundColor
              : Colors.transparent,
          elevation: 0,
        ),
      ),
      child: DecoratedBox(
        decoration: isDark
            ? const BoxDecoration()
            : BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.lightGradientStart.withValues(alpha: 0.15),
                    AppTheme.lightCardColor,
                    AppTheme.lightGradientEnd.withValues(alpha: 0.1),
                  ],
                ),
              ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: isDark
                ? context.backgroundColor
                : Colors.transparent,
            elevation: 0,
            title: Text(
              'باشگاه من',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
                color: isDark ? AppTheme.goldColor : context.textColor,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(60.h),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: isDark
                      ? context.backgroundColor
                      : AppTheme.darkTextColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24.r),
                    topRight: Radius.circular(24.r),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? AppTheme.veryDarkBackground.withValues(alpha: 0.2)
                          : AppTheme.goldColor.withValues(alpha: 0.08),
                      blurRadius: 12.r,
                      offset: Offset(0, -2.h),
                    ),
                  ],
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? Colors.transparent
                          : AppTheme.goldColor.withValues(alpha: 0.15),
                    ),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(14.r),
                    gradient: isDark
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.goldColor.withValues(alpha: 0.25),
                              AppTheme.goldColor.withValues(alpha: 0.15),
                            ],
                          )
                        : null,
                    color: isDark
                        ? null
                        : context.textColor.withValues(alpha: 0.1),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? AppTheme.goldColor.withValues(alpha: 0.2)
                            : context.textColor.withValues(alpha: 0.1),
                        blurRadius: 8.r,
                        offset: Offset(0, 2.h),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: EdgeInsets.symmetric(
                    horizontal: 6.w,
                    vertical: 6.h,
                  ),
                  dividerColor: Colors.transparent,
                  labelColor: isDark ? AppTheme.goldColor : context.textColor,
                  unselectedLabelColor: context.textSecondary,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 8.sp,
                    letterSpacing: 0.1,
                    fontFamily: AppTheme.fontFamily,
                    height: 1.4,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 8.sp,
                    letterSpacing: 0.05,
                    fontFamily: AppTheme.fontFamily,
                    height: 1.4,
                  ),
                  tabAlignment: TabAlignment.fill,
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
                  tabs: [
                    Tab(
                      icon: Icon(LucideIcons.dumbbell, size: 15.sp),
                      text: 'برنامه‌ها',
                      height: 44.h,
                    ),
                    Tab(
                      icon: Icon(LucideIcons.userCheck, size: 15.sp),
                      text: 'مربی‌ها',
                      height: 44.h,
                    ),
                    Tab(
                      icon: Icon(LucideIcons.users, size: 15.sp),
                      text: 'دوستان',
                      height: 44.h,
                    ),
                    Tab(
                      icon: Icon(LucideIcons.sparkles, size: 15.sp),
                      text: 'امتیازات',
                      height: 44.h,
                    ),
                    Tab(
                      icon: Icon(LucideIcons.wallet, size: 15.sp),
                      text: 'مالی',
                      height: 44.h,
                    ),
                    Tab(
                      icon: Icon(LucideIcons.shield, size: 15.sp),
                      text: 'اطلاعات محرمانه',
                      height: 44.h,
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: const [
              MyProgramsScreen(),
              _MyTrainersTab(),
              MyFriendsScreen(),
              MyPointsScreen(),
              MyWalletScreen(),
              ConfidentialUserInfoScreen(embedded: true),
            ],
          ),
          floatingActionButton: _tabController.index == 2
              ? FloatingActionButton(
                  onPressed: () {
                    WidgetSafetyUtils.safeNavigate(
                      context,
                      () => const FriendshipSearchScreen(),
                    );
                  },
                  backgroundColor: AppTheme.goldColor,
                  child: const Icon(LucideIcons.search, color: AppTheme.onGoldColor),
                )
              : null,
        ),
      ),
    );
  }
}

class _MyTrainersTab extends StatefulWidget {
  const _MyTrainersTab();

  @override
  State<_MyTrainersTab> createState() => _MyTrainersTabState();
}

class _MyTrainersTabState extends State<_MyTrainersTab> {
  final TrainerClientService _trainerClientService = TrainerClientService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _trainers = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _loadTrainers();
  }

  int _statusSortOrder(String? status) => switch (status) {
        'active' => 0,
        'pending' => 1,
        _ => 2,
      };

  List<Map<String, dynamic>> _sortedTrainers(List<Map<String, dynamic>> raw) {
    final list = raw.map(Map<String, dynamic>.from).toList();
    list.sort((a, b) {
      final sa = _statusSortOrder(a['status'] as String?);
      final sb = _statusSortOrder(b['status'] as String?);
      if (sa != sb) return sa.compareTo(sb);
      final ca = DateTime.tryParse(a['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final cb = DateTime.tryParse(b['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return cb.compareTo(ca);
    });
    return list;
  }

  Future<void> _loadTrainers() async {
    final cached = await CacheService.getJsonList('trainers_screen_cache');
    if (cached != null && mounted) {
      setState(() {
        _trainers = _sortedTrainers(
          cached.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
        );
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final userId = await AuthHelper.getCurrentUserId();
      if (userId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final trainers = await _trainerClientService.getClientTrainers(userId);
      final sorted = _sortedTrainers(trainers);
      await CacheService.setJson('trainers_screen_cache', sorted);
      if (mounted) {
        setState(() {
          _trainers = sorted;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openChat(Map<String, dynamic> trainer) {
    final profile = trainer['trainer'] as Map<String, dynamic>?;
    final trainerId = profile?['id'] as String?;
    if (trainerId == null || trainerId.isEmpty) return;
    Navigator.pushNamed(
      context,
      '/chat',
      arguments: <String, dynamic>{
        'otherUserId': trainerId,
        'otherUserName': MyClubTrainerCard.displayNameFor(trainer),
      },
    );
  }

  void _openProfile(Map<String, dynamic> trainer) {
    final trainerId =
        trainer['trainer_id'] as String? ??
        (trainer['trainer'] as Map<String, dynamic>?)?['id'] as String?;
    if (trainerId == null || trainerId.isEmpty) return;
    Navigator.pushNamed(context, '/trainer-profile', arguments: trainerId);
  }

  Future<void> _endRelationship(Map<String, dynamic> trainer) async {
    final name = MyClubTrainerCard.displayNameFor(trainer);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardColor,
        title: Text(
          'پایان رابطه',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: context.textColor,
          ),
        ),
        content: Text(
          'رابطه با «$name» پایان می‌یابد. برنامه‌های قبلی در «برنامه‌های من» باقی می‌مانند.',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: context.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'پایان رابطه',
              style: TextStyle(
                color: AppTheme.errorColor,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _trainerClientService.endRelationship(
        trainerId: trainer['trainer_id'] as String,
        clientId: trainer['client_id'] as String,
      );
      await _loadTrainers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'رابطه با $name پایان یافت',
              style: const TextStyle(fontFamily: AppTheme.fontFamily),
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _trainers.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.goldColor),
      );
    }

    if (_trainers.isEmpty) {
      return UnifiedEmptyState(
        icon: LucideIcons.users,
        title: 'هنوز مربی‌ای ندارید',
        subtitle: 'مربی حرفه‌ای انتخاب کنید یا برنامهٔ شروع باشگاه را فعال کنید',
        actionText: 'جستجوی مربی',
        actionIcon: LucideIcons.search,
        onAction: () => Navigator.pushNamed(context, '/trainer-ranking'),
      );
    }

    final activeCount =
        _trainers.where((t) => t['status'] == 'active').length;

    return RefreshIndicator(
      onRefresh: _loadTrainers,
      color: AppTheme.goldColor,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مربی‌های من',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w800,
                        color: context.textColor,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '$activeCount مربی فعال از ${_trainers.length}',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12.sp,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, '/trainer-ranking'),
                icon: Icon(LucideIcons.plus, size: 16.sp, color: AppTheme.goldColor),
                label: Text(
                  'مربی جدید',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.goldColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ..._trainers.map(
            (trainer) => MyClubTrainerCard(
              trainer: trainer,
              onChat: () => _openChat(trainer),
              onViewProfile: () => _openProfile(trainer),
              onEndRelationship: () => _endRelationship(trainer),
            ),
          ),
        ],
      ),
    );
  }
}
