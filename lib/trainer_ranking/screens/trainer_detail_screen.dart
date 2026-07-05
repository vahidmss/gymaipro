import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/chat/screens/chat_screen.dart';
import 'package:gymaipro/payment/models/trainer_subscription.dart';
import 'package:gymaipro/payment/services/trainer_payment_service.dart';
import 'package:gymaipro/payment/services/wallet_service.dart';
import 'package:gymaipro/payment/utils/payment_constants.dart';
import 'package:gymaipro/payment/widgets/purchase_success_dialog.dart';
import 'package:gymaipro/profile/models/user_profile.dart';
import 'package:gymaipro/profile/repositories/profile_repository.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_ranking/models/certificate.dart';
import 'package:gymaipro/trainer_ranking/models/trainer_ranking_model.dart'
    show TrainerReview;
import 'package:gymaipro/trainer_ranking/services/certificate_service.dart';
import 'package:gymaipro/trainer_ranking/services/trainer_kpi_service.dart';
import 'package:gymaipro/trainer_ranking/services/trainer_league_bonus_policy.dart';
import 'package:gymaipro/trainer_ranking/services/trainer_league_points.dart';
import 'package:gymaipro/trainer_ranking/services/trainer_ranking_service.dart';
import 'package:gymaipro/trainer_ranking/utils/dialog_helpers.dart';
import 'package:gymaipro/trainer_ranking/utils/format_utils.dart';
import 'package:gymaipro/trainer_ranking/widgets/certificate_carousel.dart';
import 'package:gymaipro/widgets/gymai_network_image.dart';
import 'package:gymaipro/widgets/gymai_trainer_avatar.dart';
import 'package:gymaipro/trainer_ranking/widgets/package_card_widget.dart';
import 'package:gymaipro/trainer_ranking/widgets/review_submission_widget.dart';
import 'package:gymaipro/trainer_ranking/widgets/service_card_widget.dart';
import 'package:gymaipro/trainer_ranking/widgets/shimmer.dart';
import 'package:gymaipro/trainer_channel/screens/trainer_channel_screen.dart';
import 'package:gymaipro/trainer_channel/services/trainer_channel_service.dart';
import 'package:gymaipro/trainer_ranking/widgets/trainer_review_widget.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class TrainerDetailScreen extends StatefulWidget {
  const TrainerDetailScreen({required this.trainer, super.key});
  final UserProfile trainer;

  @override
  State<TrainerDetailScreen> createState() => _TrainerDetailScreenState();
}

class _TrainerDetailScreenState extends State<TrainerDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TrainerRankingService _service = TrainerRankingService();
  final TrainerKpiService _kpiService = TrainerKpiService();

  List<TrainerReview> _reviews = [];
  bool _isLoadingReviews = true;

  // اطلاعات به‌روزرسانی شده مربی
  double _currentRating = 0;
  int _currentReviewCount = 0;
  int _currentStudentCount = 0;
  int _currentActiveStudentCount = 0;
  Map<String, int> _programStats = {};
  bool _isLoadingStats = true;

  TrainerKpis? _kpis;
  bool _isLoadingKpis = true;
  TrainerProgramDeliveryStats? _deliveryStats;
  int _approvedCertCount = 0;
  TrainerLeaguePointsBreakdown? _leaguePoints;
  int _reviewStarsSum = 0;
  int _privateExerciseCount = 0;
  int _publicExerciseCount = 0;
  int _eventBonusPoints = 0;

  // Pricing/Services state
  bool _isLoadingServices = true;
  num _trainingCost = 0;
  num _dietCost = 0;
  num _discountPct = 0;
  bool _serviceTrainingEnabled = true;
  bool _serviceDietEnabled = true;
  bool _serviceConsultEnabled = true;

  // Payment services
  final TrainerPaymentService _paymentService = TrainerPaymentService();
  final WalletService _walletService = WalletService();

  String? _discountCode;
  int _walletBalance = 0;
  bool _hasVisibleChannel = false;
  final TrainerChannelService _channelService = TrainerChannelService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // مقداردهی اولیه از همان trainer تا بلافاصله در هدر نمایش داده شود (بدون انتظار لود)
    _currentRating = widget.trainer.rating ?? 0.0;
    _currentReviewCount = widget.trainer.reviewCount ?? 0;
    _currentStudentCount = widget.trainer.studentCount ?? 0;
    _currentActiveStudentCount = widget.trainer.activeStudentCount ??
        widget.trainer.studentCount ??
        0;

    // لود KPI و آمار به صورت موازی برای سرعت بیشتر
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// لود موازی همهٔ داده‌ها برای سریع‌ترین نمایش
  Future<void> _loadAllData() async {
    await Future.wait([
      _loadKpis(),
      _loadProgramStats(),
      _loadReviews(),
      _loadServicesPricing(),
      _loadWalletBalance(),
      _refreshTrainerInfo(),
      _loadChannelVisibility(),
    ]);
  }

  Future<void> _loadChannelVisibility() async {
    try {
      final visible = await _channelService.isChannelVisibleToPublic(
        widget.trainer.id!,
      );
      if (mounted) {
        SafeSetState.call(this, () => _hasVisibleChannel = visible);
      }
    } catch (_) {}
  }

  void _openTrainerChannel() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TrainerChannelScreen(trainer: widget.trainer),
      ),
    );
  }

  Future<bool> _checkConnectivity() async {
    try {
      final connectivityResults = await Connectivity().checkConnectivity();
      return !connectivityResults.contains(ConnectivityResult.none);
    } catch (e) {
      return false;
    }
  }

  Future<void> _loadReviews() async {
    try {
      final hasConnection = await _checkConnectivity();
      if (!hasConnection) {
        if (mounted) {
          SafeSetState.call(this, () {
            _isLoadingReviews = false;
          });
          // نمایش dialog بعد از build
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              DialogHelpers.showNetworkError(context);
            }
          });
        }
        return;
      }

      final reviews = await _service.getTrainerReviews(widget.trainer.id!);

      if (mounted) {
        SafeSetState.call(this, () {
          _reviews = reviews;
          _isLoadingReviews = false;
        });
        _recomputeLeaguePoints();
      }
    } catch (e) {
      if (mounted) {
        SafeSetState.call(this, () {
          _isLoadingReviews = false;
        });
        // نمایش dialog بعد از build
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            DialogHelpers.showNetworkError(context);
          }
        });
      }
    }
  }

  // به‌روزرسانی اطلاعات مربی از دیتابیس
  Future<void> _refreshTrainerInfo() async {
    try {
      if (kDebugMode) {
        print('🔄 به‌روزرسانی اطلاعات مربی...');
      }
      final updatedTrainer = await _service.getTrainerDetails(
        widget.trainer.id!,
      );
      if (updatedTrainer != null && mounted) {
        // استفاده از post-frame callback برای جلوگیری از خطای build
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            SafeSetState.call(this, () {
              // به‌روزرسانی اطلاعات مربی در state
              _currentRating = updatedTrainer.rating ?? 0.0;
              _currentReviewCount = updatedTrainer.reviewCount ?? 0;
              _currentStudentCount = updatedTrainer.studentCount ?? 0;
              _currentActiveStudentCount =
                  updatedTrainer.activeStudentCount ?? 0;
            });
            _recomputeLeaguePoints();
            if (kDebugMode) {
              print(
                '🔄 اطلاعات مربی به‌روزرسانی شد - امتیاز: $_currentRating, نظرات: $_currentReviewCount, کل شاگردان: $_currentStudentCount, شاگردان فعال: $_currentActiveStudentCount',
              );
            }
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔄 خطا در به‌روزرسانی اطلاعات مربی: $e');
      }
    }
  }

  Future<void> _loadProgramStats() async {
    try {
      final hasConnection = await _checkConnectivity();
      if (!hasConnection) {
        if (mounted) {
          SafeSetState.call(this, () {
            _isLoadingStats = false;
          });
        }
        return;
      }

      final stats = await _service.getTrainerProgramStats(widget.trainer.id!);
      if (mounted) {
        SafeSetState.call(this, () {
          _programStats = stats;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        SafeSetState.call(this, () {
          _isLoadingStats = false;
        });
      }
    }
  }

  Future<void> _loadKpis() async {
    try {
      final hasConnection = await _checkConnectivity();
      if (!hasConnection) {
        if (mounted) {
          SafeSetState.call(this, () => _isLoadingKpis = false);
        }
        return;
      }

      final trainerId = widget.trainer.id!;
      final kpis = await _kpiService.getTrainerKpis(trainerId);
      final delivery = await _kpiService.getProgramDeliveryStats(trainerId);
      final certN =
          await CertificateService.countApprovedTrainerCertificates(trainerId);
      final starSum = await _kpiService.sumReviewStarPoints(trainerId);
      final exVis =
          await _kpiService.countCustomExercisesByVisibility(trainerId);
      final eventBonus =
          await TrainerLeagueBonusRegistry.eventBonusFor(trainerId);
      final league = TrainerLeaguePoints.compute(
        TrainerLeaguePointsInput(
          totalStudents: kpis.totalStudents,
          sentWorkoutPrograms: kpis.activeWorkoutPrograms,
          sumReviewStars: starSum,
          medianDeliveryHours: delivery.medianHours,
          deliverySampleCount: delivery.sampleCount,
          privateCustomExercises: exVis.privateCount,
          publicCustomExercises: exVis.publicCount,
          customMusicCount: kpis.totalCustomMusics,
          approvedCertificateCount: certN,
          eventBonusPoints: eventBonus,
        ),
      );
      if (mounted) {
        SafeSetState.call(this, () {
          _kpis = kpis;
          _deliveryStats = delivery;
          _approvedCertCount = certN;
          _reviewStarsSum = starSum;
          _privateExerciseCount = exVis.privateCount;
          _publicExerciseCount = exVis.publicCount;
          _eventBonusPoints = eventBonus;
          _leaguePoints = league;
          _isLoadingKpis = false;
        });
      }
    } catch (_) {
      if (mounted) {
        SafeSetState.call(this, () => _isLoadingKpis = false);
      }
    }
  }

  void _recomputeLeaguePoints() {
    final kpis = _kpis;
    final delivery = _deliveryStats;
    if (kpis == null || delivery == null || !mounted) return;
    final starSum = _reviews.isNotEmpty
        ? _reviews.fold<int>(
            0,
            (s, r) => s + r.rating.round().clamp(1, 5),
          )
        : _reviewStarsSum;
    final league = TrainerLeaguePoints.compute(
      TrainerLeaguePointsInput(
        totalStudents: kpis.totalStudents,
        sentWorkoutPrograms: kpis.activeWorkoutPrograms,
        sumReviewStars: starSum,
        medianDeliveryHours: delivery.medianHours,
        deliverySampleCount: delivery.sampleCount,
        privateCustomExercises: _privateExerciseCount,
        publicCustomExercises: _publicExerciseCount,
        customMusicCount: kpis.totalCustomMusics,
        approvedCertificateCount: _approvedCertCount,
        eventBonusPoints: _eventBonusPoints,
      ),
    );
    SafeSetState.call(this, () {
      _leaguePoints = league;
      if (_reviews.isNotEmpty) {
        _reviewStarsSum = starSum;
      }
    });
  }

  Future<void> _loadServicesPricing() async {
    try {
      final hasConnection = await _checkConnectivity();
      if (!hasConnection) {
        if (mounted) {
          SafeSetState.call(this, () => _isLoadingServices = false);
        }
        return;
      }

      final json =
          await ProfileRepository.instance.fetchProfile(widget.trainer.id!);
      if (mounted) {
        SafeSetState.call(this, () {
          _trainingCost = (json?['monthly_training_cost'] as num?) ?? 0;
          _dietCost = (json?['monthly_diet_cost'] as num?) ?? 0;
          _discountPct = (json?['package_discount_pct'] as num?) ?? 0;
          _serviceTrainingEnabled =
              (json?['service_training_enabled'] ?? true) == true;
          _serviceDietEnabled = (json?['service_diet_enabled'] ?? true) == true;
          _serviceConsultEnabled =
              (json?['service_consulting_enabled'] ?? true) == true;
          _isLoadingServices = false;
        });
      }
    } catch (_) {
      if (mounted) {
        SafeSetState.call(this, () => _isLoadingServices = false);
      }
    }
  }

  Future<void> _loadWalletBalance() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        final wallet = await _walletService.getUserWallet();
        if (wallet != null && mounted) {
          SafeSetState.call(this, () {
            // استفاده از availableBalance به جای balance (مثل dashboard)
            _walletBalance = wallet.availableBalance;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('خطا در دریافت موجودی کیف پول: $e');
      }
    }
  }

  void _messageTrainer() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => ChatScreen(
          otherUserId: widget.trainer.id ?? '',
          otherUserName: widget.trainer.fullName.isNotEmpty
              ? widget.trainer.fullName
              : widget.trainer.username,
        ),
      ),
    );
  }

  void _showReviewDialog() {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
        final maxH = MediaQuery.of(sheetContext).size.height * 0.92;

        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxH),
              child: Material(
                color: sheetContext.cardColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    SizedBox(height: 10.h),
                    Container(
                      width: 44.w,
                      height: 5.h,
                      decoration: BoxDecoration(
                        color: sheetContext.separatorColor
                            .withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(3.r),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        child: ReviewSubmissionWidget(
                          trainerId: widget.trainer.id ?? '',
                          onReviewSubmitted: _loadReviews,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _selectService(String serviceId, double cost) {
    if (cost <= 0) {
      return;
    }
    HapticFeedback.mediumImpact();
    _loadWalletBalance();
    _showPaymentBottomSheet(serviceId, cost);
  }

  void _showPaymentBottomSheet(String serviceId, double cost) {
    if (cost <= 0) {
      return;
    }
    HapticFeedback.lightImpact();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return _PaymentBottomSheet(
          serviceName: _getServiceName(serviceId),
          cost: cost,
          walletBalance: _walletBalance,
          initialDiscountCode: _discountCode,
          onDiscountChanged: (v) => _discountCode = v,
          processRequest: _processPaymentRequest,
          serviceId: serviceId,
          trainerName: widget.trainer.fullName.isNotEmpty
              ? widget.trainer.fullName
              : widget.trainer.username,
          onWalletSuccess: (String serviceName) async {
            if (!mounted) return;
            await _loadWalletBalance();
            if (!mounted) return;
            await PurchaseSuccessDialog.show(
              context,
              serviceName: serviceName,
              trainerName: widget.trainer.fullName.isNotEmpty
                  ? widget.trainer.fullName
                  : widget.trainer.username,
              onViewPrograms: () {
                Navigator.of(context).pushNamed(
                  '/my-club',
                  arguments: {'initialTab': 0},
                );
              },
            );
          },
          onDirectRedirect: _showPaymentRedirectDialog,
        );
      },
    );
  }

  /// فقط درخواست پرداخت را اجرا می‌کند و نتیجه را برمی‌گرداند (بدون تغییر state).
  /// برای استفاده داخل دیالوگ پرداخت تا وضعیت دکمه‌ها داخل همان دیالوگ مدیریت شود.
  Future<Map<String, dynamic>> _processPaymentRequest(
    String paymentMethod,
    String serviceId,
    double cost,
  ) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      return {'success': false, 'error': 'لطفاً ابتدا وارد حساب کاربری خود شوید'};
    }

    if (_isOwnTrainerProfile) {
      return {
        'success': false,
        'error': 'نمی‌توانید از خودتان برنامه بخرید',
      };
    }

    TrainerServiceType serviceType;
    switch (serviceId) {
      case 'training':
        serviceType = TrainerServiceType.training;
      case 'diet':
        serviceType = TrainerServiceType.diet;
      case 'consulting':
        serviceType = TrainerServiceType.consulting;
      case 'package':
        serviceType = TrainerServiceType.package;
      default:
        return {'success': false, 'error': 'نوع خدمات نامعتبر'};
    }

    try {
      final result = await _paymentService.processTrainerSubscriptionPurchase(
        userId: currentUser.id,
        trainerId: widget.trainer.id!,
        serviceType: serviceType,
        originalAmount: (cost * 10).round(),
        discountCode: _discountCode,
        paymentMethod: paymentMethod,
        userPhone: widget.trainer.phoneNumber,
        userEmail: widget.trainer.emailPublic,
        metadata: {
          'trainer_name': widget.trainer.fullName,
          'service_name': _getServiceName(serviceId),
        },
      );
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return {'success': false, 'error': 'خطا در پردازش: $e'};
    }
  }

  String _getServiceName(String serviceId) {
    switch (serviceId) {
      case 'training':
        return 'برنامه تمرینی';
      case 'diet':
        return 'برنامه رژیم غذایی';
      case 'consulting':
        return 'مشاوره و نظارت';
      case 'package':
        return 'بسته کامل';
      default:
        return 'خدمات مربی';
    }
  }

  void _showPaymentRedirectDialog(String paymentUrl, String trackId) {
    showDialog<void>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: context.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
            side: BorderSide(
              color: AppTheme.goldColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          title: Text(
            'هدایت به درگاه پرداخت',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: AppTheme.goldColor,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'برای تکمیل پرداخت، به درگاه پرداخت هدایت می‌شوید.',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: context.textColor,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: isDark
                      ? context.veryDarkBackground
                      : AppTheme.lightCardColor,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppTheme.goldColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.hash,
                      color: AppTheme.goldColor,
                      size: 18.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'کد پیگیری: $trackId',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: context.textColor,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'انصراف',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: context.textSecondary,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final uri = Uri.parse(paymentUrl);
                final can = await canLaunchUrl(uri);
                if (can) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  // fallback try without canLaunch
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldColor,
                foregroundColor: AppTheme.onGoldColor,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 4,
              ),
              child: Text(
                'ادامه پرداخت',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.headerBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(LucideIcons.arrowRight, color: context.textColor, size: 20.sp),
        ),
        centerTitle: true,
        title: Text(
          widget.trainer.fullName.isNotEmpty
              ? widget.trainer.fullName
              : widget.trainer.username,
          style: context.headerTitleStyle(
            fontSize: 15.sp,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_hasVisibleChannel)
            IconButton(
              onPressed: _openTrainerChannel,
              icon: Icon(LucideIcons.radio, color: AppTheme.goldColor, size: 20.sp),
              tooltip: 'کانال',
            ),
          IconButton(
            onPressed: _messageTrainer,
            icon: Icon(LucideIcons.messageCircle, color: AppTheme.goldColor, size: 20.sp),
            tooltip: 'پیام',
          ),
        ],
      ),
      body: Column(
        children: [
          // هدر ثابت: آواتار + آمار (بلافاصله پر)
          _buildProfileHeader(),
          // تب‌بار
          DecoratedBox(
            decoration: BoxDecoration(
              color: context.cardColor,
              border: Border(
                bottom: BorderSide(color: context.separatorColor.withValues(alpha: 0.5)),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.goldColor,
              indicatorWeight: 2.5,
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: AppTheme.goldColor,
              unselectedLabelColor: context.textSecondary,
              labelStyle: TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w700),
              unselectedLabelStyle: TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w500),
              tabs: const [
                Tab(text: 'اطلاعات'),
                Tab(text: 'نظرات'),
                Tab(text: 'گواهینامه'),
                Tab(text: 'تعرفه‌ها'),
              ],
            ),
          ),
          // محتوای تب‌ها
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInfoTab(),
                _buildReviewsTab(),
                _buildCertificatesTab(),
                _buildServicesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// هدر پروفایل مربی: آواتار، رتبه، امتیاز، آمار
  Widget _buildProfileHeader() {
    final t = widget.trainer;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // داده‌ها: از KPI (بعد لود) یا از trainer (بلافاصله)
    final exercises = _kpis?.totalCustomExercises ?? 0;
    final musics = _kpis?.publicCustomMusics ?? _kpis?.totalCustomMusics ?? 0;
    final rating = _currentRating;

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 12.h),
      decoration: BoxDecoration(
        color: isDark ? context.cardColor.withValues(alpha: 0.4) : context.cardColor,
        border: Border(bottom: BorderSide(color: context.separatorColor.withValues(alpha: 0.3))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ردیف اول: آواتار + اطلاعات اصلی
          Row(
            children: [
              // آواتار
              Hero(
                tag: 'trainer_${t.id}_${t.username}',
                child: Container(
                  width: 56.w,
                  height: 56.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppTheme.goldColor, AppTheme.goldColor.withValues(alpha: 0.6)],
                    ),
                    boxShadow: [
                      BoxShadow(color: AppTheme.goldColor.withValues(alpha: 0.25), blurRadius: 8.r, offset: Offset(0, 2.h)),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(2.w),
                    child: GymaiTrainerAvatar(
                      avatarUrl: t.avatarUrl,
                      userId: t.id,
                      username: t.username,
                      size: 52.w,
                      fallback: _buildDefaultAvatar(),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              // نام + رتبه + ستاره
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        if (t.ranking != null && t.ranking! > 0) ...[
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.5.h),
                            decoration: BoxDecoration(
                              color: AppTheme.goldColor.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              '#${t.ranking}',
                              style: TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w800, color: AppTheme.goldColor),
                            ),
                          ),
                          SizedBox(width: 6.w),
                        ],
                        if (rating > 0) ...[
                          Icon(
                            LucideIcons.star,
                            size: 12.sp,
                            color: AppTheme.goldColor,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            rating.toStringAsFixed(1),
                            style: TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w600, color: context.textSecondary),
                          ),
                          Text(
                            ' ($_currentReviewCount)',
                            style: TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 10.sp, color: context.textSecondary.withValues(alpha: 0.7)),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 6.h),
                    // آنلاین / آفلاین
                    if (t.isOnline ?? false)
                      Row(
                        children: [
                          Container(
                            width: 7.w,
                            height: 7.w,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.successColor,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'آنلاین',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 10.sp,
                              color: AppTheme.successColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          // ردیف آمار: تمرین اختصاصی | موزیک | رضایت (با شیمر هنگام لود)
          Row(
            children: [
              _statItem(
                value: _isLoadingKpis ? null : exercises.toString(),
                label: 'تمرین اختصاصی',
                isLoading: _isLoadingKpis,
              ),
              _statDivider(),
              _statItem(
                value: _isLoadingKpis ? null : musics.toString(),
                label: 'موزیک',
                isLoading: _isLoadingKpis,
              ),
              _statDivider(),
              _statItem(
                value: _isLoadingKpis
                    ? (rating > 0 ? rating.toStringAsFixed(1) : null)
                    : (_kpis != null ? '${_kpis!.satisfactionPercent}%' : '—'),
                label: _isLoadingKpis ? 'امتیاز' : 'رضایت',
                isLoading: _isLoadingKpis && rating <= 0,
              ),
            ],
          ),
          if (_hasVisibleChannel) ...[
            SizedBox(height: 10.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openTrainerChannel,
                icon: Icon(LucideIcons.radio, size: 16.sp, color: AppTheme.goldColor),
                label: Text(
                  'مشاهده کانال',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.goldColor,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.goldColor.withValues(alpha: 0.5)),
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
            ),
          ],
          if (!_isLoadingKpis && _leaguePoints != null) ...[
            SizedBox(height: 10.h),
            GestureDetector(
              onTap: () => _showLeaguePointsBreakdown(context),
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.award, size: 14.sp, color: AppTheme.goldColor),
                  SizedBox(width: 6.w),
                  Text(
                    '${_leaguePoints!.totalPoints}',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.goldColor,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    'امتیاز',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: context.textSecondary,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    LucideIcons.chevronDown,
                    size: 14.sp,
                    color: context.textSecondary.withValues(alpha: 0.55),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showLeaguePointsBreakdown(BuildContext context) {
    final b = _leaguePoints;
    if (b == null) return;
    final d = _deliveryStats;
    final kpis = _kpis;

    String deliverySubtitle() {
      if (b.deliverySkippedInsufficientData) {
        return 'بعد از چند بار ارسال برنامه به شاگرد، این بخش هم فعال می‌شود.';
      }
      if (d != null && d.sampleCount > 0 && !d.medianHours.isNaN) {
        final h = d.medianHours;
        if (h < 1) {
          return 'معمولاً کمتر از یک ساعت تا رسیدن برنامه به شاگرد.';
        }
        if (h < 24) {
          return 'معمولاً حدود ${h.round()} ساعت طول می‌کشه تا برنامه به شاگرد برسه.';
        }
        final days = (h / 24).round();
        return 'معمولاً حدود $days روز طول می‌کشه تا برنامه به شاگرد برسه.';
      }
      return '';
    }

    String deliveryTitle() {
      if (b.deliverySkippedInsufficientData) {
        return 'سرعت رسیدن برنامه';
      }
      const labels = <int, String>{
        5: 'خیلی سریع',
        4: 'سریع',
        3: 'معمولی',
        2: 'کمی طولانی',
        1: 'نیاز به سرعت بیشتر',
      };
      final label = labels[b.deliveryPoints.clamp(1, 5)] ?? '';
      return label.isEmpty ? 'سرعت رسیدن برنامه' : 'سرعت رسیدن برنامه · $label';
    }

    final reviewCount = kpis?.totalReviews ?? _currentReviewCount;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      enableDrag: false,
      useSafeArea: true,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final card = isDark ? const Color(0xFF1A1D24) : const Color(0xFFFFFBF5);
        final muted = ctx.textSecondary;
        final padBottom = MediaQuery.paddingOf(ctx).bottom;
        final dragHandle = Center(
          child: Container(
            width: 44.w,
            height: 5.h,
            decoration: BoxDecoration(
              color: muted.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        );

        final tiles = <Widget>[
          if (kpis != null) ...[
            _leagueBreakdownTile(
              ctx,
              icon: LucideIcons.send,
              title: 'برنامه به شاگرد',
              statLine:
                  'تعداد برنامه‌های ارسال‌شده: ${kpis.activeWorkoutPrograms}',
              hintLine: kpis.activeWorkoutPrograms == 0
                  ? 'هنوز برنامه‌ای به شاگرد نرسیده.'
                  : null,
              points: b.sentProgramPoints,
            ),
            _leagueBreakdownTile(
              ctx,
              icon: LucideIcons.users,
              title: 'شاگردان',
              statLine: 'تعداد شاگردان ثبت‌شده: ${kpis.totalStudents}',
              hintLine: kpis.totalStudents == 0
                  ? 'هنوز شاگردی ثبت نشده.'
                  : null,
              points: b.studentPoints,
            ),
          ],
          _leagueBreakdownTile(
            ctx,
            icon: LucideIcons.star,
            title: 'نظر و ستاره',
            statLine:
                'تعداد نظر: $reviewCount — جمع ستاره‌ها: ${b.reviewStarPoints}',
            hintLine: reviewCount == 0
                ? 'با ثبت نظر، امتیاز این بخش هم زیاد می‌شه.'
                : null,
            points: b.reviewStarPoints,
          ),
          _leagueBreakdownTile(
            ctx,
            icon: LucideIcons.timer,
            title: deliveryTitle(),
            statLine: b.deliverySkippedInsufficientData
                ? 'سرعت تحویل: هنوز محاسبه نشده'
                : (d != null &&
                        d.sampleCount > 0 &&
                        !d.medianHours.isNaN
                    ? 'بر اساس ${d.sampleCount} ارسال اخیر'
                    : 'سرعت تحویل برنامه'),
            hintLine: deliverySubtitle().isEmpty
                ? (b.deliverySkippedInsufficientData
                    ? 'بعد از چند ارسال، این بخش پر می‌شه.'
                    : null)
                : deliverySubtitle(),
            points: b.deliveryPoints,
            chipText: b.deliverySkippedInsufficientData
                ? 'به‌زودی'
                : '+${b.deliveryPoints}',
          ),
          _leagueBreakdownTile(
            ctx,
            icon: LucideIcons.music,
            title: 'موسیقی',
            statLine:
                'تعداد موزیک ثبت‌شده: ${kpis?.totalCustomMusics ?? 0}',
            hintLine: (kpis?.totalCustomMusics ?? 0) == 0
                ? 'هنوز موزیکی ثبت نشده.'
                : null,
            points: b.musicPoints,
          ),
          if (_privateExerciseCount > 0)
            _leagueBreakdownTile(
              ctx,
              icon: LucideIcons.lock,
              title: 'تمرین شخصی',
              statLine: 'تعداد: $_privateExerciseCount',
              points: b.privateExercisePoints,
            ),
          if (_publicExerciseCount > 0)
            _leagueBreakdownTile(
              ctx,
              icon: LucideIcons.globe,
              title: 'تمرین عمومی',
              statLine: 'تعداد: $_publicExerciseCount',
              points: b.publicExercisePoints,
            ),
          if (_privateExerciseCount == 0 && _publicExerciseCount == 0)
            _leagueBreakdownTile(
              ctx,
              icon: LucideIcons.dumbbell,
              title: 'تمرین اختصاصی',
              statLine: 'تمرین شخصی: ۰ — تمرین عمومی: ۰',
              hintLine: 'با ساخت تمرین، امتیاز می‌گیری.',
              points: b.privateExercisePoints + b.publicExercisePoints,
            ),
          _leagueBreakdownTile(
            ctx,
            icon: LucideIcons.badgeCheck,
            title: 'مدارک معتبر',
            statLine: 'تعداد مدرک تأییدشده: $_approvedCertCount',
            hintLine: b.certificatePoints == 0
                ? 'با ${TrainerLeaguePoints.kCertificateMinApproved} مدرک به بالا، ${TrainerLeaguePoints.kCertificateBonusPoints} امتیاز هدیه.'
                : 'با ${TrainerLeaguePoints.kCertificateMinApproved} مدرک به بالا فعال شده.',
            points: b.certificatePoints,
          ),
          if (b.eventBonusPoints > 0)
            _leagueBreakdownTile(
              ctx,
              icon: LucideIcons.gift,
              title: 'هدیه ویژه',
              statLine: 'مربوط به کمپین یا چالش',
              points: b.eventBonusPoints,
            ),
          SizedBox(height: 8.h + padBottom),
        ];

        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          snap: true,
          snapSizes: const <double>[0.55, 0.9],
          expand: false,
          builder: (ctx, scrollController) {
            return ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              child: Material(
                color: card,
                elevation: 8,
                shadowColor: Colors.black.withValues(alpha: 0.2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(6.w, 8.h, 6.w, 0),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: 4.h),
                            child: dragHandle,
                          ),
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () => Navigator.of(ctx).maybePop(),
                              icon: Icon(
                                LucideIcons.x,
                                size: 20.sp,
                                color: muted.withValues(alpha: 0.85),
                              ),
                              tooltip: 'بستن',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Text(
                        'امتیاز از چه‌چیزهاییه؟',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14.w),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 14.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.goldColor.withValues(alpha: 0.12),
                              AppTheme.goldColor.withValues(alpha: 0.03),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(
                            color: AppTheme.goldColor.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'جمع امتیاز',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: muted,
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Text(
                              '${b.totalPoints}',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.goldColor,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 0),
                        children: tiles,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _leagueBreakdownTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String statLine,
    required int points,
    String? hintLine,
    String? chipText,
  }) {
    final muted = context.textSecondary;
    final chipLabel = chipText ?? (points > 0 ? '+$points' : '$points');
    final isPendingChip = chipText == 'به‌زودی';

    return Padding(
      padding: EdgeInsets.only(bottom: 7.h),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.04)
              : const Color(0xFF1A1A12).withValues(alpha: 0.035),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: muted.withValues(alpha: 0.1)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.goldColor.withValues(alpha: 0.11),
                ),
                child: Icon(icon, size: 16.sp, color: AppTheme.goldColor),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      statLine,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w600,
                        color: muted.withValues(alpha: 0.95),
                        height: 1.3,
                      ),
                    ),
                    if (hintLine != null && hintLine.isNotEmpty) ...[
                      SizedBox(height: 2.h),
                      Text(
                        hintLine,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 9.5.sp,
                          color: muted.withValues(alpha: 0.78),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 6.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: AppTheme.goldColor.withValues(
                    alpha: isPendingChip ? 0.06 : (points > 0 ? 0.14 : 0.07),
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Text(
                  chipLabel,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                    color: isPendingChip
                        ? muted
                        : (points > 0 ? AppTheme.goldColor : muted),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// آیتم آمار (مشابه Instagram: عدد بالا، لیبل پایین). هنگام لود با شیمر طلایی نمایش داده می‌شود.
  Widget _statItem({
    required String? value,
    required String label,
    bool isLoading = false,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: isLoading || value == null
                  ? Center(
                      key: const ValueKey('stat_loading'),
                      child: Shimmer(
                        width: 36.w,
                        height: 18.h,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                    )
                  : Text(
                      key: ValueKey('stat_$value'),
                      value,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        color: context.textColor,
                      ),
                    ),
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 10.sp,
              color: context.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1,
      height: 24.h,
      color: context.separatorColor.withValues(alpha: 0.4),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.trainer.bio != null && widget.trainer.bio!.isNotEmpty) ...[
            _buildSectionTitle('خود نوشته'),
            SizedBox(height: 6.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: context.separatorColor.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                widget.trainer.bio!,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: context.textColor,
                  fontSize: 13.sp,
                  height: 1.5,
                ),
                textAlign: TextAlign.justify,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: 16.h),
          ],

          _buildSectionTitle('تخصص‌ها'),
          SizedBox(height: 6.h),
          if ((widget.trainer.specializations ?? []).isEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: context.separatorColor.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                'تخصصی ثبت نشده',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: context.textSecondary,
                  fontSize: 12.sp,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: (widget.trainer.specializations ?? []).map((spec) {
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 5.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.goldColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: AppTheme.goldColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    spec,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: AppTheme.goldColor,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          SizedBox(height: 16.h),

          _buildSectionTitle('آمار'),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  icon: LucideIcons.users,
                  title: 'کل شاگردان',
                  value: _currentStudentCount.toString(),
                  color: AppTheme.successColor,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildInfoCard(
                  icon: LucideIcons.userCheck,
                  title: 'شاگرد فعال',
                  value: _currentActiveStudentCount.toString(),
                  color: AppTheme.carbsColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  icon: LucideIcons.clock,
                  title: 'سال تجربه',
                  value: (widget.trainer.experienceYears ?? 0).toString(),
                  color: AppTheme.fatColor,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildInfoCard(
                  icon: LucideIcons.star,
                  title: 'امتیاز',
                  value: _currentRating.toStringAsFixed(1),
                  color: AppTheme.goldColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildSectionTitle('برنامه‌های ارائه شده'),
          if (_isLoadingStats)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: Center(
                child: SizedBox(
                  width: 24.w,
                  height: 24.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.goldColor,
                  ),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    icon: LucideIcons.dumbbell,
                    title: 'ورزشی',
                    value: (_programStats['workout_programs'] ?? 0).toString(),
                    color: AppTheme.fatColor,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _buildInfoCard(
                    icon: LucideIcons.apple,
                    title: 'تغذیه',
                    value: (_programStats['nutrition_programs'] ?? 0)
                        .toString(),
                    color: AppTheme.proteinColor,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    final reviewCount =
        _reviews.isNotEmpty ? _reviews.length : _currentReviewCount;
    final avg = _currentRating;
    final scoreText = avg <= 0
        ? '—'
        : ((avg * 10).round() % 10 == 0)
            ? avg.toStringAsFixed(0)
            : avg.toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _reviewsTabStarRow(avg),
                  SizedBox(width: 8.w),
                  Text(
                    scoreText,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.goldColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$reviewCount نظر',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              InkWell(
                onTap: _showReviewDialog,
                borderRadius: BorderRadius.circular(12.r),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  decoration: BoxDecoration(
                    color: AppTheme.goldColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppTheme.goldColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.star,
                        size: 16.sp,
                        color: AppTheme.goldColor,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'تجربه‌ات را بنویس',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.goldColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        Expanded(
          child: _isLoadingReviews
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.goldColor),
                )
              : _reviews.isEmpty
                  ? _buildReviewsEmptyState()
                  : ListView.builder(
                      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
                      itemCount: _reviews.length,
                      itemBuilder: (BuildContext context, int index) {
                        return TrainerReviewWidget(review: _reviews[index]);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _reviewsTabStarRow(double rating) {
    final r = rating.clamp(0.0, 5.0);
    final inactive = context.textSecondary.withValues(alpha: 0.28);
    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.ltr,
      children: List.generate(5, (i) {
        final idx = i + 1.0;
        if (r >= idx - 0.001) {
          return Icon(Icons.star_rounded, size: 16.sp, color: AppTheme.goldColor);
        }
        if (r >= idx - 0.5) {
          return Icon(
            Icons.star_half_rounded,
            size: 16.sp,
            color: AppTheme.goldColor,
          );
        }
        return Icon(
          Icons.star_outline_rounded,
          size: 16.sp,
          color: inactive,
        );
      }),
    );
  }

  Widget _buildReviewsEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.messageCircle,
                  size: 56.sp,
                  color: context.textSecondary,
                ),
                SizedBox(height: 16.h),
                Text(
                  'هنوز نظری ثبت نشده',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: context.textColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                Text(
                  'از دکمهٔ «تجربه‌ات را بنویس» در بالا استفاده کن.',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: context.textSecondary,
                    fontSize: 13.sp,
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCertificatesTab() {
    return FutureBuilder<List<Certificate>>(
      future: _loadCertificates(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.goldColor),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(32.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.alertCircle,
                    size: 80.sp,
                    color: AppTheme.errorColor,
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    'خطا در بارگذاری مدارک',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: AppTheme.errorColor,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: context.textSecondary,
                      fontSize: 14.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final certificates = snapshot.data ?? [];
        final approvedCertificates = certificates
            .where((c) => c.status == CertificateStatus.approved)
            .toList();

        if (approvedCertificates.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(32.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.award,
                    size: 48.sp,
                    color: context.textSecondary,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'مدرکی ثبت نشده',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: context.textColor,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'مربی هنوز مدرکی ثبت نکرده است',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: context.textSecondary,
                      fontSize: 12.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          children: [
            // Coaching Certificates
            CertificateCarousel(
              title: 'گواهینامه‌های مربیگری',
              certificates: approvedCertificates
                  .where((c) => c.type == CertificateType.coaching)
                  .toList(),
              onCertificateTap: (certificate) =>
                  _showImageDialog(certificate.certificateUrl!),
            ),

            // Championship Certificates
            CertificateCarousel(
              title: 'قهرمانی‌ها و مدال‌ها',
              certificates: approvedCertificates
                  .where((c) => c.type == CertificateType.championship)
                  .toList(),
              onCertificateTap: (certificate) =>
                  _showImageDialog(certificate.certificateUrl!),
            ),

            // Education Certificates
            CertificateCarousel(
              title: 'تحصیلات و مدارک علمی',
              certificates: approvedCertificates
                  .where((c) => c.type == CertificateType.education)
                  .toList(),
              onCertificateTap: (certificate) =>
                  _showImageDialog(certificate.certificateUrl!),
            ),

            // Specialization Certificates
            CertificateCarousel(
              title: 'تخصص‌ها و مهارت‌ها',
              certificates: approvedCertificates
                  .where((c) => c.type == CertificateType.specialization)
                  .toList(),
              onCertificateTap: (certificate) =>
                  _showImageDialog(certificate.certificateUrl!),
            ),

            // Achievement Certificates
            CertificateCarousel(
              title: 'دستاوردها',
              certificates: approvedCertificates
                  .where((c) => c.type == CertificateType.achievement)
                  .toList(),
              onCertificateTap: (certificate) =>
                  _showImageDialog(certificate.certificateUrl!),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          color: context.textColor,
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: context.separatorColor.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(height: 6.h),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: context.textColor,
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: context.textSecondary,
              fontSize: 10.sp,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  bool get _isOwnTrainerProfile {
    final trainerId = widget.trainer.id;
    if (trainerId == null || trainerId.isEmpty) return false;
    final authId = Supabase.instance.client.auth.currentUser?.id;
    return authId != null && authId == trainerId;
  }

  Widget _buildServicesTab() {
    if (_isLoadingServices) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.goldColor),
      );
    }

    if (_isOwnTrainerProfile) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Text(
            'این پروفایل مربی خودتان است. برای خرید برنامه از مربی دیگر، از بخش رتبه‌بندی مربیان اقدام کنید.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13.sp,
              height: 1.55,
              color: context.textSecondary,
            ),
          ),
        ),
      );
    }

    final consultingCost = _serviceConsultEnabled && _serviceTrainingEnabled
        ? (_trainingCost / 2)
        : 0;
    // Full package excludes consulting
    final packageRaw =
        (_serviceTrainingEnabled ? _trainingCost : 0) +
        (_serviceDietEnabled ? _dietCost : 0);
    final packageFinal = (packageRaw * (1 - (_discountPct.clamp(0, 100) / 100)))
        .floor();

    final trainingPurchasable =
        _serviceTrainingEnabled && _trainingCost > 0;
    final dietPurchasable = _serviceDietEnabled && _dietCost > 0;
    final consultPurchasable = _serviceConsultEnabled &&
        _serviceTrainingEnabled &&
        _trainingCost > 0 &&
        consultingCost > 0;
    final packagePurchasable = packageFinal > 0;

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
      children: [
        _buildSectionTitle('تعرفه‌ها'),
        Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: Text(
            'مبالغ به تومان، دورهٔ یک ماهه. خدمتی که قیمت ندارد یا غیرفعال است قابل خرید نیست.',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 11.sp,
              height: 1.45,
              color: context.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // برنامه تمرینی
        ServiceCardWidget(
          icon: LucideIcons.dumbbell,
          title: 'برنامه تمرینی',
          description: 'برنامه تمرینی شخصی‌سازی‌شده بر اساس اهداف شما',
          price: _serviceTrainingEnabled
              ? FormatUtils.formatAmount(_trainingCost)
              : FormatUtils.toPersianDigits('۰'),
          period: 'ماهانه',
          features: const [
            'برنامه ی تمرینی روزانه',
            'شامل 4 هفته تمرین',
            'راهنمایی تکنیک ها و حرکات',
            'پشتیبانی آنلاین',
            'بررسی پیشرفت شما',
            'چت نامحدود با مربی',
          ],
          color: AppTheme.fatColor,
          disabled: !trainingPurchasable,
          serviceId: 'training',
          onTap: trainingPurchasable
              ? () => _selectService('training', _trainingCost.toDouble())
              : null,
        ),
        SizedBox(height: 12.h),

        // برنامه رژیم غذایی
        ServiceCardWidget(
          icon: LucideIcons.apple,
          title: 'برنامه رژیم غذایی',
          description: 'رژیم غذایی متعادل متناسب با اهداف و شرایط شما',
          price: _serviceDietEnabled
              ? FormatUtils.formatAmount(_dietCost)
              : FormatUtils.toPersianDigits('۰'),
          period: 'ماهانه',
          features: const [
            'برنامه ی غذایی روزانه',
            'شامل 4 هفته رژیم',
            'محاسبه ی کالری و درشت‌مغذی‌ها',
            'پشتیبانی آنلاین',
            'بررسی پیشرفت شما',
            'چت نامحدود با مربی',
          ],
          color: AppTheme.proteinColor,
          disabled: !dietPurchasable,
          serviceId: 'diet',
          onTap: dietPurchasable
              ? () => _selectService('diet', _dietCost.toDouble())
              : null,
        ),
        SizedBox(height: 12.h),

        // مشاوره و نظارت
        ServiceCardWidget(
          icon: LucideIcons.headphones,
          title: 'مشاوره و نظارت',
          description: 'مشاوره تخصصی و نظارت مداوم بر روند پیشرفت شما',
          price: _serviceConsultEnabled && _serviceTrainingEnabled
              ? FormatUtils.formatAmount(consultingCost)
              : FormatUtils.toPersianDigits('۰'),
          period: 'ماهانه',
          features: const [
            'چت نامحدود با مربی',
            'بررسی روزانه پیشرفت',
            'مشاوره تخصصی',
            'تنظیم برنامه بر اساس نتایج',
            'پشتیبانی 24/7',
          ],
          color: AppTheme.carbsColor,
          disabled: !consultPurchasable,
          serviceId: 'consulting',
          onTap: consultPurchasable
              ? () =>
                  _selectService('consulting', consultingCost.toDouble())
              : null,
        ),
        SizedBox(height: 16.h),

        // بسته کامل
        PackageCardWidget(
          cost: packageFinal.toDouble(),
          packageRaw: packageRaw,
          discountPct: _discountPct,
          disabled: !packagePurchasable,
          onTap: packagePurchasable
              ? () => _selectService('package', packageFinal.toDouble())
              : null,
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ColoredBox(
      color: isDark
          ? context.veryDarkBackground
          : AppTheme.lightCardColor,
      child: Icon(LucideIcons.user, color: context.textSecondary, size: 36.sp),
    );
  }

  // Load certificates from database
  Future<List<Certificate>> _loadCertificates() async {
    try {
      return await CertificateService.getPublicCertificates(widget.trainer.id!);
    } catch (e) {
      // به جای throw کردن، لیست خالی برمی‌گردانیم تا برنامه کرش نکند
      debugPrint('_loadCertificates error: $e');
      return [];
    }
  }

  // Helper method to show image dialog
  void _showImageDialog(String imageUrl) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.transparent,
            child: Center(
              child: GestureDetector(
                onTap: () {}, // Prevent closing when tapping on image
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.9,
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  child: GymaiNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                    errorWidget: Container(
                      padding: EdgeInsets.all(48.w),
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: context.separatorColor),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_not_supported,
                              color: context.textSecondary,
                              size: 64.sp,
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'خطا در بارگذاری تصویر',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color: context.textColor,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// حالت‌های مختلف جریان پرداخت
enum _PaymentPhase { idle, processing, success, error }

/// باتم‌شیت حرفه‌ای پرداخت با انیمیشن و بازخورد بصری کامل
class _PaymentBottomSheet extends StatefulWidget {
  const _PaymentBottomSheet({
    required this.serviceName,
    required this.cost,
    required this.walletBalance,
    required this.initialDiscountCode,
    required this.onDiscountChanged,
    required this.processRequest,
    required this.serviceId,
    required this.trainerName,
    required this.onWalletSuccess,
    required this.onDirectRedirect,
  });

  final String serviceName;
  final double cost;
  final int walletBalance;
  final String? initialDiscountCode;
  final void Function(String?) onDiscountChanged;
  final Future<Map<String, dynamic>> Function(String, String, double) processRequest;
  final String serviceId;
  final String trainerName;
  final Future<void> Function(String serviceName) onWalletSuccess;
  final void Function(String paymentUrl, String trackId) onDirectRedirect;

  @override
  State<_PaymentBottomSheet> createState() => _PaymentBottomSheetState();
}

class _PaymentBottomSheetState extends State<_PaymentBottomSheet>
    with SingleTickerProviderStateMixin {
  _PaymentPhase _phase = _PaymentPhase.idle;
  String? _tappedMethod;
  String? _errorMessage;
  late final TextEditingController _discountController;
  late final AnimationController _successAnimController;
  late final Animation<double> _successScale;

  @override
  void initState() {
    super.initState();
    _discountController = TextEditingController(text: widget.initialDiscountCode ?? '');
    _successAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successScale = CurvedAnimation(
      parent: _successAnimController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _discountController.dispose();
    _successAnimController.dispose();
    super.dispose();
  }

  Future<void> _pay(String paymentMethod) async {
    if (_phase == _PaymentPhase.processing) return;
    setState(() {
      _phase = _PaymentPhase.processing;
      _tappedMethod = paymentMethod;
      _errorMessage = null;
    });

    HapticFeedback.lightImpact();

    final result = await widget.processRequest(
      paymentMethod,
      widget.serviceId,
      widget.cost,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      if (paymentMethod == 'wallet') {
        HapticFeedback.heavyImpact();
        setState(() => _phase = _PaymentPhase.success);
        _successAnimController.forward();
        await Future<void>.delayed(const Duration(milliseconds: 800));
        if (!mounted) return;
        Navigator.of(context).pop();
        await widget.onWalletSuccess(widget.serviceName);
      } else {
        Navigator.of(context).pop();
        widget.onDirectRedirect(
          result['payment_url']! as String,
          result['track_id']! as String,
        );
      }
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _phase = _PaymentPhase.error;
        _errorMessage = (result['error'] as String?) ?? 'خطا در پردازش پرداخت';
      });
      await Future<void>.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      setState(() {
        _phase = _PaymentPhase.idle;
        _errorMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isProcessing = _phase == _PaymentPhase.processing;
    final isSuccess = _phase == _PaymentPhase.success;
    final isError = _phase == _PaymentPhase.error;

    return PopScope(
      canPop: !isProcessing,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.veryDarkBackground.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 16.h),
              child: isSuccess
                  ? _buildSuccessView()
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHandle(),
                        SizedBox(height: 16.h),
                        _buildTitle(context),
                        SizedBox(height: 20.h),
                        _buildOrderSummary(context, isDark),
                        SizedBox(height: 16.h),
                        _buildDiscountField(context, isDark),
                        SizedBox(height: 20.h),
                        if (isError && _errorMessage != null) ...[
                          _buildErrorBanner(context),
                          SizedBox(height: 12.h),
                        ],
                        _buildPaymentButtons(context, isDark),
                        SizedBox(height: 12.h),
                        _buildCancelButton(context, isProcessing),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 40.w,
        height: 4.h,
        decoration: BoxDecoration(
          color: AppTheme.darkGreySeparator.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(2.r),
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(LucideIcons.shieldCheck, color: AppTheme.goldColor, size: 22.sp),
        SizedBox(width: 8.w),
        Text(
          'پرداخت امن',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: context.textColor,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSummary(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark
            ? context.veryDarkBackground
            : AppTheme.lightCardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppTheme.goldColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            context,
            'خدمت',
            widget.serviceName,
            valueColor: AppTheme.goldColor,
          ),
          Divider(height: 20.h, color: context.separatorColor),
          _buildSummaryRow(
            context,
            'مبلغ',
            '${FormatUtils.formatAmount(widget.cost)} تومان',
            valueBold: true,
          ),
          Divider(height: 20.h, color: context.separatorColor),
          Row(
            children: [
              Icon(LucideIcons.wallet, color: AppTheme.goldColor, size: 16.sp),
              SizedBox(width: 6.w),
              Text(
                'موجودی کیف پول',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: context.textSecondary,
                  fontSize: 13.sp,
                ),
              ),
              const Spacer(),
              Text(
                '${PaymentConstants.formatAmount(widget.walletBalance)} تومان',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: widget.walletBalance >= (widget.cost * 10).round()
                      ? AppTheme.successColor
                      : AppTheme.fatColor,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
    bool valueBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: context.textSecondary,
            fontSize: 13.sp,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: valueColor ?? context.textColor,
            fontSize: 14.sp,
            fontWeight: valueBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDiscountField(BuildContext context, bool isDark) {
    return TextField(
      controller: _discountController,
      onChanged: (value) =>
          widget.onDiscountChanged(value.trim().isEmpty ? null : value.trim()),
      style: TextStyle(
        fontFamily: AppTheme.fontFamily,
        color: context.textColor,
        fontSize: 14.sp,
      ),
      decoration: InputDecoration(
        hintText: 'کد تخفیف (اختیاری)',
        prefixIcon: Icon(LucideIcons.tag, color: context.textSecondary, size: 18.sp),
        hintStyle: TextStyle(
          fontFamily: AppTheme.fontFamily,
          color: context.textSecondary,
          fontSize: 14.sp,
        ),
        filled: true,
        fillColor: isDark
            ? context.veryDarkBackground
            : AppTheme.lightCardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: context.separatorColor.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppTheme.goldColor, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.alertCircle, color: AppTheme.errorColor, size: 18.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: AppTheme.errorColor,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentButtons(BuildContext context, bool isDark) {
    final isProcessing = _phase == _PaymentPhase.processing;
    final isWalletProcessing = isProcessing && _tappedMethod == 'wallet';
    final isDirectProcessing = isProcessing && _tappedMethod == 'direct';

    return Column(
      children: [
        // دکمه کیف پول (اصلی)
        SizedBox(
          width: double.infinity,
          height: 52.h,
          child: ElevatedButton(
            onPressed: isProcessing ? null : () => _pay('wallet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isWalletProcessing
                  ? AppTheme.goldColor.withValues(alpha: 0.7)
                  : AppTheme.goldColor,
              foregroundColor: AppTheme.onGoldColor,
              elevation: isProcessing ? 0 : 6,
              shadowColor: AppTheme.goldColor.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: isWalletProcessing
                  ? Row(
                      key: const ValueKey('wallet_loading'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20.w,
                          height: 20.h,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(AppTheme.darkTextColor),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          'در حال پرداخت...',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      key: const ValueKey('wallet_idle'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.wallet, size: 20.sp),
                        SizedBox(width: 10.w),
                        Text(
                          'پرداخت از کیف پول',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        SizedBox(height: 10.h),
        // دکمه پرداخت مستقیم (ثانویه)
        SizedBox(
          width: double.infinity,
          height: 48.h,
          child: OutlinedButton(
            onPressed: isProcessing ? null : () => _pay('direct'),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDirectProcessing
                  ? context.textSecondary
                  : AppTheme.goldColor,
              side: BorderSide(
                color: isDirectProcessing
                    ? context.separatorColor
                    : AppTheme.goldColor,
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: isDirectProcessing
                  ? Row(
                      key: const ValueKey('direct_loading'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18.w,
                          height: 18.h,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(context.textSecondary),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          'در حال اتصال به درگاه...',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      key: const ValueKey('direct_idle'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.creditCard, size: 18.sp),
                        SizedBox(width: 10.w),
                        Text(
                          'پرداخت آنلاین',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCancelButton(BuildContext context, bool isProcessing) {
    return TextButton(
      onPressed: isProcessing ? null : () => Navigator.of(context).pop(),
      child: Text(
        'انصراف',
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          color: isProcessing
              ? context.textSecondary.withValues(alpha: 0.5)
              : context.textSecondary,
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _successScale,
            child: Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.checkCircle2,
                color: AppTheme.successColor,
                size: 48.sp,
              ),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'پرداخت موفق',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: AppTheme.successColor,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'اشتراک ${widget.serviceName} فعال شد',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: context.textSecondary,
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }
}
