import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/profile/models/user_profile.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/widgets/gymai_network_image.dart';
import 'package:gymaipro/trainer_ranking/screens/trainer_detail_screen.dart';
import 'package:gymaipro/trainer_ranking/services/trainer_ranking_service.dart';
import 'package:gymaipro/trainer_ranking/widgets/shimmer.dart';
import 'package:gymaipro/trainer_ranking/widgets/trainer_card_widget.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class TrainerRankingScreen extends StatefulWidget {
  const TrainerRankingScreen({super.key});

  @override
  State<TrainerRankingScreen> createState() => _TrainerRankingScreenState();
}

class _TrainerRankingScreenState extends State<TrainerRankingScreen> {
  final TrainerRankingService _service = TrainerRankingService();
  List<UserProfile> _trainers = [];
  List<UserProfile> _filteredTrainers = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadTrainers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredTrainers = _trainers;
      } else {
        _filteredTrainers = _trainers.where((trainer) {
          final name =
              (trainer.fullName.isNotEmpty
                      ? trainer.fullName
                      : trainer.username)
                  .toLowerCase();
          return name.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _loadTrainers({bool forceRefresh = false}) async {
    if (!mounted) return;

    // Don't show loading if we have cached data and not forcing refresh
    if (!forceRefresh && _trainers.isNotEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final trainers = await _service.getTrainerRankings(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _trainers = trainers;
        _filteredTrainers = trainers;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا در بارگذاری مربیان: $e',
              style: TextStyle(
                color: context.textColor,
                fontWeight: FontWeight.w600,
                fontFamily: AppTheme.fontFamily,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            backgroundColor: isDark
                ? AppTheme.errorColor.withValues(alpha: 0.2)
                : AppTheme.errorColor.withValues(alpha: 0.15),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
              side: BorderSide(
                color: AppTheme.errorColor.withValues(alpha: 0.5),
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> _refreshTrainers() async {
    await _loadTrainers(forceRefresh: true);
  }

  void _onTrainerTap(UserProfile trainer) {
    Navigator.of(context).push(_buildDetailRoute(trainer));
  }

  PageRoute<void> _buildDetailRoute(UserProfile trainer) {
    return PageRouteBuilder<void>(
      pageBuilder: (_, __, ___) => TrainerDetailScreen(trainer: trainer),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        final scale = Tween<double>(begin: 0.94, end: 1).animate(curved);
        final fade = Tween<double>(begin: 0, end: 1).animate(curved);
        return FadeTransition(
          opacity: fade,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // AppBar حرفه‌ای
            _buildAppBar(isDark),

            // نوار افقی مربیان (استایل استوری)
            if (!_isLoading && _trainers.isNotEmpty && !_isSearching)
              _buildHorizontalTrainerList(isDark),

            // لیست مربیان
            Expanded(child: _buildTrainerList(isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border(
          bottom: BorderSide(color: context.separatorColor),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        children: [
          // عنوان
          Expanded(
            child: Text(
              'لیست مربیان',
              style: TextStyle(
                color: context.textColor,
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                fontFamily: AppTheme.fontFamily,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // دکمه جستجو
          GestureDetector(
            onTap: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                }
              });
            },
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppTheme.goldColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: AppTheme.goldColor.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(
                _isSearching ? LucideIcons.x : LucideIcons.search,
                color: AppTheme.goldColor,
                size: 20.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    if (!_isSearching) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldColor.withValues(alpha: 0.1),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        style: TextStyle(
          color: context.textColor,
          fontSize: 14.sp,
          fontFamily: AppTheme.fontFamily,
        ),
        decoration: InputDecoration(
          hintText: 'جستجوی مربی...',
          hintStyle: TextStyle(
            color: context.textSecondary,
            fontSize: 14.sp,
            fontFamily: AppTheme.fontFamily,
          ),
          border: InputBorder.none,
          prefixIcon: Icon(
            LucideIcons.search,
            color: AppTheme.goldColor,
            size: 20.sp,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? GestureDetector(
                  onTap: _searchController.clear,
                  child: Icon(
                    LucideIcons.x,
                    color: context.textSecondary,
                    size: 18.sp,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildHorizontalTrainerList(bool isDark) {
    return Container(
      margin: EdgeInsets.only(top: 8.h, bottom: 8.h),
      height: 140.h,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        scrollDirection: Axis.horizontal,
        itemCount: _trainers.length.clamp(0, 12),
        itemBuilder: (context, index) {
          final trainer = _trainers[index];
          return GestureDetector(
            onTap: () => _onTrainerTap(trainer),
            child: Container(
              width: 90.w,
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // تصویر مربی با border طلایی
                  Container(
                    width: 70.w,
                    height: 70.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.goldColor,
                          AppTheme.goldColor.withValues(alpha: 0.7),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.goldColor.withValues(alpha: 0.3),
                          blurRadius: 8.r,
                          offset: Offset(0, 2.h),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(2.5.w),
                      child: Hero(
                        tag: 'trainer_${trainer.id}_${trainer.username}',
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: context.cardColor,
                            border: Border.all(
                              color: context.backgroundColor,
                              width: 1.5.w,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: trainer.avatarUrl != null
                              ? GymaiNetworkImage(
                                  imageUrl: trainer.avatarUrl!,
                                  errorWidget: _buildDefaultAvatar(),
                                )
                              : _buildDefaultAvatar(),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  // نام مربی
                  Text(
                    trainer.fullName.isNotEmpty
                        ? trainer.fullName
                        : trainer.username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.textColor,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  // رتبه
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.goldColor,
                          AppTheme.goldColor.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.trophy,
                          color: Colors.white,
                          size: 10.sp,
                        ),
                        SizedBox(width: 3.w),
                        Text(
                          '${trainer.ranking ?? 999}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.bold,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrainerList(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minHeight = constraints.maxHeight + 1.0;
        return RefreshIndicator(
          onRefresh: _refreshTrainers,
          color: AppTheme.goldColor,
          backgroundColor: context.cardColor,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // نوار جستجو
              SliverToBoxAdapter(child: _buildSearchBar(isDark)),

              // لیست یا حالت لودینگ/خالی
              if (_isLoading)
                SliverPadding(
                  padding: EdgeInsets.all(16.w),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: Row(
                          children: [
                            Shimmer(
                              width: 60.w,
                              height: 60.h,
                              borderRadius: BorderRadius.all(
                                Radius.circular(30.r),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Shimmer(width: 140.w, height: 14.h),
                                  SizedBox(height: 8.h),
                                  Shimmer(width: 100.w, height: 12.h),
                                  SizedBox(height: 8.h),
                                  Shimmer(width: 160.w, height: 10.h),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      childCount: 6,
                    ),
                  ),
                )
              else if (_filteredTrainers.isEmpty)
                SliverToBoxAdapter(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: minHeight),
                    child: _buildEmptyState(isDark),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final trainer = _filteredTrainers[index];
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.94, end: 1),
                        duration: Duration(
                          milliseconds: 220 + (index % 6) * 20,
                        ),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Opacity(
                              opacity: (value - 0.9) / 0.1.clamp(0, 1),
                              child: child,
                            ),
                          );
                        },
                        child: TrainerCardWidget(
                          trainer: trainer,
                          onTap: () => _onTrainerTap(trainer),
                        ),
                      );
                    }, childCount: _filteredTrainers.length),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: context.cardColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.goldColor.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: Icon(
              _isSearching ? LucideIcons.search : LucideIcons.users,
              size: 64.sp,
              color: AppTheme.goldColor.withValues(alpha: 0.6),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            _isSearching ? 'مربی‌ای یافت نشد' : 'مربی‌ای وجود ندارد',
            style: TextStyle(
              color: context.textColor,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            _isSearching
                ? 'لطفاً عبارت جستجوی دیگری را امتحان کنید'
                : 'در حال حاضر هیچ مربی‌ای ثبت نشده است',
            style: TextStyle(
              color: context.textSecondary,
              fontSize: 14.sp,
              fontFamily: AppTheme.fontFamily,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return ColoredBox(
      color: context.separatorColor,
      child: Icon(LucideIcons.user, color: context.textSecondary, size: 30.sp),
    );
  }
}
