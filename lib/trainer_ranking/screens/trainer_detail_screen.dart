import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/chat/screens/chat_screen.dart';
import 'package:gymaipro/payment/models/trainer_subscription.dart';
import 'package:gymaipro/payment/services/trainer_payment_service.dart';
import 'package:gymaipro/payment/services/wallet_service.dart';
import 'package:gymaipro/payment/utils/payment_constants.dart';
import 'package:gymaipro/profile/models/user_profile.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_ranking/models/certificate.dart';
import 'package:gymaipro/trainer_ranking/models/trainer_ranking_model.dart'
    show TrainerReview;
import 'package:gymaipro/trainer_ranking/services/certificate_service.dart';
import 'package:gymaipro/trainer_ranking/services/trainer_kpi_service.dart';
import 'package:gymaipro/trainer_ranking/services/trainer_ranking_service.dart';
import 'package:gymaipro/payment/widgets/purchase_success_dialog.dart';
import 'package:gymaipro/trainer_ranking/utils/dialog_helpers.dart';
import 'package:gymaipro/trainer_ranking/utils/format_utils.dart';
import 'package:gymaipro/trainer_ranking/widgets/certificate_carousel.dart';
import 'package:gymaipro/trainer_ranking/widgets/package_card_widget.dart';
import 'package:gymaipro/trainer_ranking/widgets/review_submission_widget.dart';
import 'package:gymaipro/trainer_ranking/widgets/shimmer.dart';
import 'package:gymaipro/trainer_ranking/widgets/service_card_widget.dart';
import 'package:gymaipro/trainer_ranking/widgets/trainer_review_widget.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
    ]);
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

      final kpis = await _kpiService.getTrainerKpis(widget.trainer.id!);
      if (mounted) {
        SafeSetState.call(this, () {
          _kpis = kpis;
          _isLoadingKpis = false;
        });
      }
    } catch (_) {
      if (mounted) {
        SafeSetState.call(this, () => _isLoadingKpis = false);
      }
    }
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

      final json = await Supabase.instance.client
          .from('profiles')
          .select(
            'monthly_training_cost, monthly_diet_cost, package_discount_pct, service_training_enabled, service_diet_enabled, service_consulting_enabled',
          )
          .eq('id', widget.trainer.id!)
          .maybeSingle();
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
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: keyboardHeight > 0 ? 8.h : 24.h,
          ),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ReviewSubmissionWidget(
              trainerId: widget.trainer.id ?? '',
              onReviewSubmitted: _loadReviews,
            ),
          ),
        );
      },
    );
  }

  void _selectService(String serviceId, double cost) {
    HapticFeedback.mediumImpact();
    _loadWalletBalance();
    _showPaymentBottomSheet(serviceId, cost);
  }

  void _showPaymentBottomSheet(String serviceId, double cost) {
    HapticFeedback.lightImpact();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
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
                      : AppTheme.lightButtonBackground,
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
                foregroundColor: isDark ? AppTheme.onGoldColor : Colors.white,
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
        backgroundColor: context.backgroundColor,
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
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: context.textColor,
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
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
          Container(
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

  /// هدر پروفایل مربی: آواتار، رتبه، امتیاز، آمار (مشابه اپ‌های حرفه‌ای)
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
            crossAxisAlignment: CrossAxisAlignment.center,
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
                    child: ClipOval(
                      child: t.avatarUrl != null
                          ? Image.network(t.avatarUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildDefaultAvatar())
                          : _buildDefaultAvatar(),
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
                          Icon(LucideIcons.star, size: 12.sp, color: const Color(0xFFFF9800)),
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
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF4CAF50)),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'آنلاین',
                            style: TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 10.sp, color: const Color(0xFF4CAF50), fontWeight: FontWeight.w600),
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
        ],
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
                  width: 1,
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
                      width: 1,
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
                  color: Colors.green,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildInfoCard(
                  icon: LucideIcons.userCheck,
                  title: 'شاگرد فعال',
                  value: _currentActiveStudentCount.toString(),
                  color: Colors.blue,
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
                  color: Colors.orange,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildInfoCard(
                  icon: LucideIcons.star,
                  title: 'امتیاز',
                  value: _currentRating.toStringAsFixed(1),
                  color: Colors.amber,
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
                  child: CircularProgressIndicator(
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
                    color: Colors.orange,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _buildInfoCard(
                    icon: LucideIcons.apple,
                    title: 'تغذیه',
                    value: (_programStats['nutrition_programs'] ?? 0)
                        .toString(),
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: InkWell(
            onTap: _showReviewDialog,
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 10.h),
              decoration: BoxDecoration(
                color: AppTheme.goldColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppTheme.goldColor.withValues(alpha: 0.4),
                  width: 1,
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
                    'ثبت نظر',
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
        ),

        // لیست نظرات
        Expanded(
          child: _isLoadingReviews
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.goldColor),
                )
              : _reviews.isEmpty
              ? SingleChildScrollView(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(48.w),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.messageCircle,
                            size: 80.sp,
                            color: context.textSecondary,
                          ),
                          SizedBox(height: 24.h),
                          Text(
                            'هنوز نظری ثبت نشده',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color: context.textColor,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'اولین کسی باشید که نظر می‌دهد',
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
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12),
                  itemCount: _reviews.length,
                  itemBuilder: (BuildContext context, int index) {
                    if (kDebugMode) {
                      print('🔄 نمایش نظر ${index + 1} از ${_reviews.length}');
                    }
                    return TrainerReviewWidget(review: _reviews[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCertificatesTab() {
    return FutureBuilder<List<Certificate>>(
      future: _loadCertificates(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
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
          width: 1,
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

  Widget _buildServicesTab() {
    if (_isLoadingServices) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.goldColor),
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

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12),
      children: [
        // عنوان بخش
        _buildSectionTitle('خدمات ارائه شده'),

        // برنامه تمرینی
        ServiceCardWidget(
          icon: LucideIcons.dumbbell,
          title: 'برنامه تمرینی',
          description: 'برنامه تمرینی شخصی‌سازی شده براساس اهداف شما',
          price: _serviceTrainingEnabled
              ? FormatUtils.formatAmount(_trainingCost)
              : FormatUtils.toPersianDigits('۰'),
          period: 'ماهانه',
          features: [
            'برنامه ی تمرینی روزانه',
            'شامل 4 هفته تمرین',
            'راهنمایی تکنیک ها و حرکات',
            'پشتیبانی آنلاین',
            'بررسی پیشرفت شما',
            'چت نامحدود با مربی',
          ],
          color: Colors.orange,
          disabled: !_serviceTrainingEnabled,
          serviceId: 'training',
          onTap: () => _selectService('training', _trainingCost.toDouble()),
        ),
        const SizedBox(height: 12),

        // برنامه رژیم غذایی
        ServiceCardWidget(
          icon: LucideIcons.apple,
          title: 'برنامه رژیم غذایی',
          description: 'رژیم غذایی متعادل متناسب با اهداف و شرایط شما',
          price: _serviceDietEnabled
              ? FormatUtils.formatAmount(_dietCost)
              : FormatUtils.toPersianDigits('۰'),
          period: 'ماهانه',
          features: [
            'برنامه ی غذایی روزانه',
            'شامل 4 هفته رژیم',
            'محاسبه ی کالری و درشت‌مغذی‌ها',
            'پشتیبانی آنلاین',
            'بررسی پیشرفت شما',
            'چت نامحدود با مربی',
          ],
          color: Colors.purple,
          disabled: !_serviceDietEnabled,
          serviceId: 'diet',
          onTap: () => _selectService('diet', _dietCost.toDouble()),
        ),
        const SizedBox(height: 12),

        // مشاوره و نظارت
        ServiceCardWidget(
          icon: LucideIcons.headphones,
          title: 'مشاوره و نظارت',
          description: 'مشاوره تخصصی و نظارت مداوم بر روند پیشرفت شما',
          price: _serviceConsultEnabled && _serviceTrainingEnabled
              ? FormatUtils.formatAmount(consultingCost)
              : FormatUtils.toPersianDigits('۰'),
          period: 'ماهانه',
          features: [
            'چت نامحدود با مربی',
            'بررسی روزانه پیشرفت',
            'مشاوره تخصصی',
            'تنظیم برنامه بر اساس نتایج',
            'پشتیبانی 24/7',
          ],
          color: Colors.blue,
          disabled: !_serviceConsultEnabled || !_serviceTrainingEnabled,
          serviceId: 'consulting',
          onTap: () => _selectService('consulting', consultingCost.toDouble()),
        ),
        const SizedBox(height: 16),

        // بسته کامل
        PackageCardWidget(
          cost: packageFinal.toDouble(),
          packageRaw: _trainingCost + _dietCost + consultingCost,
          discountPct: _discountPct,
          onTap: () => _selectService('package', packageFinal.toDouble()),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ColoredBox(
      color: isDark
          ? context.veryDarkBackground
          : AppTheme.lightButtonBackground,
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
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
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
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
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
      child: Container(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
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
          color: Colors.grey.withValues(alpha: 0.3),
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
            : AppTheme.lightButtonBackground,
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
                      ? const Color(0xFF4CAF50)
                      : Colors.orange,
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
            : AppTheme.lightButtonBackground,
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
          borderSide: BorderSide(color: AppTheme.goldColor, width: 2),
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
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.alertCircle, color: Colors.red, size: 18.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: Colors.red,
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
              foregroundColor: isDark ? AppTheme.onGoldColor : Colors.white,
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
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
                color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.checkCircle2,
                color: const Color(0xFF4CAF50),
                size: 48.sp,
              ),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'پرداخت موفق',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: const Color(0xFF4CAF50),
              fontSize: 20.sp,
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
