import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymaipro/profile/models/user_profile.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_ranking/screens/trainer_detail_screen.dart';
import 'package:gymaipro/trainer_ranking/services/trainer_ranking_service.dart';
import 'package:gymaipro/trainer_ranking/widgets/shimmer.dart';
import 'package:gymaipro/trainer_ranking/widgets/trainer_card_widget.dart';
import 'package:lucide_icons/lucide_icons.dart';

class TrainerRankingScreen extends StatefulWidget {
  const TrainerRankingScreen({super.key});

  @override
  State<TrainerRankingScreen> createState() => _TrainerRankingScreenState();
}

class _TrainerRankingScreenState extends State<TrainerRankingScreen> {
  final TrainerRankingService _service = TrainerRankingService();
  List<UserProfile> _trainers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrainers();
  }

  @override
  void dispose() {
    super.dispose();
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
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا در بارگذاری مربیان: $e',
              style: GoogleFonts.vazirmatn(),
            ),
            backgroundColor: Colors.red,
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
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshTrainers,
        color: AppTheme.goldColor,
        backgroundColor: const Color(0xFF2A2A2A),
        child: Column(
          children: [
            // نوار افقی مربیان (استایل استوری)
            if (!_isLoading && _trainers.isNotEmpty)
              Container(
                margin: EdgeInsets.only(top: 16.h),
                child: SizedBox(
                  height: 140.h,
                  child: ListView.builder(
                    padding: const EdgeInsetsDirectional.only(
                      start: 12,
                      end: 12,
                    ),
                    scrollDirection: Axis.horizontal,
                    itemCount: _trainers.length.clamp(0, 12),
                    itemBuilder: (context, index) {
                      final t = _trainers[index];
                      return GestureDetector(
                        onTap: () => _onTrainerTap(t),
                        child: Container(
                          width: 90.w,
                          margin: EdgeInsets.symmetric(
                            horizontal: 4.w,
                            vertical: 8.h,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
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
                                      color: AppTheme.goldColor.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 6.r,
                                      offset: Offset(0.w, 2.h),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(2.w),
                                  child: Hero(
                                    tag: 'trainer_${t.id}_${t.username}',
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF2A2A2A),
                                        border: Border.all(
                                          color: const Color(0xFF1A1A1A),
                                          width: 1.5.w,
                                        ),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: t.avatarUrl != null
                                          ? Image.network(
                                              t.avatarUrl!,
                                              fit: BoxFit.cover,
                                            )
                                          : Icon(
                                              LucideIcons.user,
                                              color: Colors.white,
                                              size: 20.sp,
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                t.username,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.vazirmatn(
                                  color: Colors.white,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

            // Spotlight حذف شد برای خلوت‌تر شدن UI

            // لیست مربیان
            Expanded(
              child: _isLoading
                  ? ListView.builder(
                      padding: EdgeInsets.all(12.w),
                      itemCount: 6,
                      itemBuilder: (context, i) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
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
                                    Shimmer(width: 140.w, height: 12),
                                    SizedBox(height: 6.h),
                                    Shimmer(width: 100.w, height: 10),
                                    SizedBox(height: 6.h),
                                    Shimmer(width: 160.w, height: 8),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  : _trainers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.search,
                            size: 64.sp,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'مربی‌ای یافت نشد',
                            style: GoogleFonts.vazirmatn(
                              color: Colors.grey[600],
                              fontSize: 18.sp,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(12.w),
                      itemCount: _trainers.length,
                      itemBuilder: (context, index) {
                        final trainer = _trainers[index];
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
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // آمار کلی حذف شد
}
