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
import 'package:gymaipro/trainer_ranking/services/trainer_ranking_service.dart';
import 'package:gymaipro/trainer_ranking/utils/dialog_helpers.dart';
import 'package:gymaipro/trainer_ranking/utils/format_utils.dart';
import 'package:gymaipro/trainer_ranking/widgets/certificate_carousel.dart';
import 'package:gymaipro/trainer_ranking/widgets/package_card_widget.dart';
import 'package:gymaipro/trainer_ranking/widgets/review_submission_widget.dart';
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

  List<TrainerReview> _reviews = [];
  bool _isLoadingReviews = true;

  // اطلاعات به‌روزرسانی شده مربی
  double _currentRating = 0;
  int _currentReviewCount = 0;
  int _currentStudentCount = 0;
  int _currentActiveStudentCount = 0;
  Map<String, int> _programStats = {};
  bool _isLoadingStats = true;

  // Pricing/Services state
  bool _isLoadingServices = true;
  num _trainingCost = 0;
  num _dietCost = 0;
  num _discountPct = 0;
  bool _serviceTrainingEnabled = true;
  bool _serviceDietEnabled = true;
  bool _serviceConsultEnabled = true;

  // Service selection state
  String? _selectedService;
  String? _processingServiceId; // برای نمایش loading در کارت خاص

  // Payment services
  final TrainerPaymentService _paymentService = TrainerPaymentService();
  final WalletService _walletService = WalletService();

  // Payment state
  bool _isProcessingPayment = false;
  String? _discountCode;
  int _walletBalance = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // مقداردهی اولیه
    _currentRating = widget.trainer.rating ?? 0.0;
    _currentReviewCount = widget.trainer.reviewCount ?? 0;
    _currentStudentCount = widget.trainer.studentCount ?? 0;
    _currentActiveStudentCount = 0; // در initState محاسبه می‌شود

    _loadReviews();
    _loadProgramStats();
    _loadServicesPricing();
    _loadWalletBalance();
    _refreshTrainerInfo(); // به‌روزرسانی اطلاعات مربی
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
    // بازخورد لمسی فوری
    HapticFeedback.mediumImpact();

    // نمایش فوری بازخورد بصری
    SafeSetState.call(this, () {
      _selectedService = serviceId;
      _processingServiceId = serviceId;
    });

    // نمایش دیالوگ بدون تأخیر
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        _showPaymentDialog(serviceId, cost);
      }
    });
  }

  void _showPaymentDialog(String serviceId, double cost) {
    String serviceName = '';
    switch (serviceId) {
      case 'training':
        serviceName = 'برنامه تمرینی';
      case 'diet':
        serviceName = 'برنامه رژیم غذایی';
      case 'consulting':
        serviceName = 'مشاوره و نظارت';
      case 'package':
        serviceName = 'بسته کامل';
    }

    // بازخورد لمسی برای باز شدن دیالوگ
    HapticFeedback.lightImpact();

    // به‌روزرسانی موجودی کیف پول قبل از نمایش دیالوگ
    _loadWalletBalance();

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return PopScope(
          canPop: !_isProcessingPayment,
          child: AlertDialog(
            backgroundColor: context.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
              side: BorderSide(
                color: AppTheme.goldColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            title: Text(
              'انتخاب روش پرداخت',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: context.textColor,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'خدمت: $serviceName',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: AppTheme.goldColor,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                Text(
                  'مبلغ: ${FormatUtils.formatAmount(cost)} تومان',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: context.textColor,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12.h),
                // نمایش موجودی کیف پول
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.wallet,
                        color: AppTheme.goldColor,
                        size: 18.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'موجودی کیف پول: ${PaymentConstants.formatAmount(_walletBalance)}',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: context.textColor,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                // ورودی کد تخفیف
                TextField(
                  onChanged: (value) {
                    _discountCode = value.trim().isEmpty ? null : value.trim();
                  },
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: context.textColor,
                    fontSize: 14.sp,
                  ),
                  decoration: InputDecoration(
                    hintText: 'کد تخفیف (اختیاری)',
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
                      borderSide: BorderSide(color: context.separatorColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: context.separatorColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color: AppTheme.goldColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'روش پرداخت خود را انتخاب کنید:',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: context.textSecondary,
                    fontSize: 14.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isProcessingPayment
                          ? null
                          : () {
                              Navigator.of(context).pop();
                              _processPayment('wallet', serviceId, cost);
                            },
                      icon: _isProcessingPayment
                          ? SizedBox(
                              width: 18.w,
                              height: 18.h,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(LucideIcons.wallet, size: 18),
                      label: Text(
                        _isProcessingPayment ? 'در حال پردازش...' : 'کیف پول',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isProcessingPayment
                            ? context.textSecondary
                            : AppTheme.goldColor,
                        foregroundColor: _isProcessingPayment
                            ? context.textColor
                            : (isDark ? AppTheme.onGoldColor : Colors.white),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: _isProcessingPayment ? 0 : 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isProcessingPayment
                          ? null
                          : () {
                              Navigator.of(context).pop();
                              _processPayment('direct', serviceId, cost);
                            },
                      icon: _isProcessingPayment
                          ? SizedBox(
                              width: 18.w,
                              height: 18.h,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.goldColor,
                                ),
                              ),
                            )
                          : const Icon(LucideIcons.creditCard, size: 18),
                      label: Text(
                        _isProcessingPayment
                            ? 'در حال پردازش...'
                            : 'پرداخت مستقیم',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 14,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _isProcessingPayment
                            ? context.textSecondary
                            : AppTheme.goldColor,
                        side: BorderSide(
                          color: _isProcessingPayment
                              ? context.separatorColor
                              : AppTheme.goldColor,
                          width: 2,
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
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
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _processPayment(
    String paymentMethod,
    String serviceId,
    double cost,
  ) async {
    if (_isProcessingPayment) return;

    SafeSetState.call(this, () {
      _isProcessingPayment = true;
      _processingServiceId = serviceId;
    });

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        DialogHelpers.showError(
          context,
          'لطفاً ابتدا وارد حساب کاربری خود شوید',
        );
        return;
      }

      // تبدیل serviceId به TrainerServiceType
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
          DialogHelpers.showError(context, 'نوع خدمات نامعتبر');
          return;
      }

      // پردازش خرید
      final result = await _paymentService.processTrainerSubscriptionPurchase(
        userId: currentUser.id,
        trainerId: widget.trainer.id!,
        serviceType: serviceType,
        originalAmount: (cost * 10).round(), // تبدیل به ریال
        discountCode: _discountCode,
        paymentMethod: paymentMethod,
        userPhone: widget.trainer.phoneNumber,
        userEmail: widget.trainer.emailPublic,
        metadata: {
          'trainer_name': widget.trainer.fullName,
          'service_name': _getServiceName(serviceId),
        },
      );

      if (result['success'] == true) {
        if (paymentMethod == 'wallet') {
          if (mounted) {
            DialogHelpers.showSuccess(
              context,
              'اشتراک شما فعال شده و می‌توانید از خدمات مربی استفاده کنید.',
              title: 'اشتراک با موفقیت خریداری شد',
            );
          }
          // به‌روزرسانی موجودی کیف پول
          if (mounted) {
            await _loadWalletBalance();
          }
        } else {
          // هدایت به درگاه پرداخت
          if (mounted) {
            _showPaymentRedirectDialog(
              result['payment_url']! as String,
              result['track_id']! as String,
            );
          }
        }
      } else {
        if (mounted) {
          DialogHelpers.showError(
            context,
            (result['error'] as String?) ?? 'خطا در پردازش پرداخت',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        DialogHelpers.showError(context, 'خطا در پردازش: $e');
      }
    } finally {
      SafeSetState.call(this, () {
        _isProcessingPayment = false;
        _processingServiceId = null;
      });
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
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 280.h,
            floating: false,
            pinned: true,
            backgroundColor: context.backgroundColor,
            elevation: 0,
            leading: Container(
              margin: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: context.cardColor.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8.r,
                    offset: Offset(0, 2.h),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  LucideIcons.arrowRight,
                  color: context.textColor,
                  size: 20.sp,
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(),
              centerTitle: false,
            ),
          ),
        ],
        body: Column(
          children: [
            _buildActionButtons(),
            Container(
              decoration: BoxDecoration(
                color: context.cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4.r,
                    offset: Offset(0, 2.h),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.goldColor,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: AppTheme.goldColor,
                unselectedLabelColor: context.textSecondary,
                labelStyle: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
                tabs: [
                  Tab(
                    child: Text(
                      'اطلاعات',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Tab(
                    child: Text(
                      'نظرات',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Tab(
                    child: Text(
                      'گواهینامه',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Tab(
                    child: Text(
                      'تعرفه‌ها',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: context.backgroundColor,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppTheme.goldColor.withValues(alpha: 0.12),
                  AppTheme.goldColor.withValues(alpha: 0.05),
                  context.backgroundColor,
                ]
              : [
                  AppTheme.lightGradientStart.withValues(alpha: 0.3),
                  AppTheme.lightGradientStart.withValues(alpha: 0.15),
                  context.backgroundColor,
                ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(top: 8.h, bottom: 16.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // آواتار مربی با طراحی مدرن
              Hero(
                tag: 'trainer_${widget.trainer.id}_${widget.trainer.username}',
                child: Container(
                  width: 110.w,
                  height: 110.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.goldColor,
                        AppTheme.goldColor.withValues(alpha: 0.7),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.goldColor.withValues(alpha: 0.4),
                        blurRadius: 24.r,
                        spreadRadius: 0,
                        offset: Offset(0, 8.h),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(4.w),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.cardColor,
                    ),
                    child: ClipOval(
                      child: widget.trainer.avatarUrl != null
                          ? Image.network(
                              widget.trainer.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildDefaultAvatar();
                              },
                            )
                          : _buildDefaultAvatar(),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // نام مربی
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Text(
                  widget.trainer.fullName.isNotEmpty
                      ? widget.trainer.fullName
                      : widget.trainer.username,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: isDark ? Colors.white : context.textColor,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              SizedBox(height: 10.h),

              // رتبه و آمار در یک ردیف
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // رتبه
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.goldColor,
                            AppTheme.goldColor.withValues(alpha: 0.9),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.goldColor.withValues(alpha: 0.3),
                            blurRadius: 8.r,
                            offset: Offset(0, 3.h),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.trophy,
                            color: isDark ? AppTheme.onGoldColor : Colors.white,
                            size: 14.sp,
                          ),
                          SizedBox(width: 5.w),
                          Text(
                            '#${widget.trainer.ranking ?? 999}',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color: isDark
                                  ? AppTheme.onGoldColor
                                  : Colors.white,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: context.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8.r,
            offset: Offset(0, -2.h),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.goldColor, AppTheme.darkGold],
            ),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: AppTheme.goldColor.withValues(alpha: 0.4),
                blurRadius: 12.r,
                offset: Offset(0, 4.h),
                spreadRadius: 0,
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: _messageTrainer,
            icon: Icon(LucideIcons.messageCircle, size: 20.sp),
            label: Text(
              'پیام خصوصی',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: AppTheme.onGoldColor,
              shadowColor: Colors.transparent,
              padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // بیوگرافی
          if (widget.trainer.bio != null && widget.trainer.bio!.isNotEmpty) ...[
            _buildSectionTitle('خود نوشته'),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: context.separatorColor, width: 1),
              ),
              child: Text(
                widget.trainer.bio!,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: context.textColor,
                  fontSize: 14.sp,
                  height: 1.6,
                ),
                textAlign: TextAlign.justify,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: 20.h),
          ],

          // تخصص‌ها
          _buildSectionTitle('تخصص‌ها'),
          SizedBox(height: 8.h),
          if ((widget.trainer.specializations ?? []).isEmpty)
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: context.separatorColor),
              ),
              child: Text(
                'تخصصی ثبت نشده',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: context.textSecondary,
                  fontSize: 14.sp,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: (widget.trainer.specializations ?? []).map((spec) {
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.goldColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: AppTheme.goldColor.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    spec,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: AppTheme.goldColor,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          SizedBox(height: 24.h),

          // آمار
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
              const SizedBox(width: 8),
              Expanded(
                child: _buildInfoCard(
                  icon: LucideIcons.userCheck,
                  title: 'شاگردان فعال',
                  value: _currentActiveStudentCount.toString(),
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
              const SizedBox(width: 8),
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
          const SizedBox(height: 12),

          // آمار برنامه‌ها
          _buildSectionTitle('برنامه‌های ارائه شده'),
          if (_isLoadingStats)
            const Center(
              child: CircularProgressIndicator(color: AppTheme.goldColor),
            )
          else
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    icon: LucideIcons.dumbbell,
                    title: 'برنامه ورزشی',
                    value: (_programStats['workout_programs'] ?? 0).toString(),
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoCard(
                    icon: LucideIcons.apple,
                    title: 'برنامه تغذیه',
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
        // دکمه افزودن نظر
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showReviewDialog,
              icon: const Icon(LucideIcons.star),
              label: Text(
                'نظر خود را ثبت کنید',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 4,
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
              padding: EdgeInsets.all(48.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.award,
                    size: 80.sp,
                    color: context.textSecondary,
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    'مدرکی ثبت نشده',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: context.textColor,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'مربی هنوز مدرکی ثبت نکرده یا مدارک در انتظار تایید هستند',
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

        return ListView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12),
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
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          color: context.textColor,
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
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
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8.r,
            offset: Offset(0.w, 2.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26.sp),
          ),
          SizedBox(height: 12.h),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: color,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6.h),
          Text(
            title,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: context.textSecondary,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
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
          isSelected: _selectedService == 'training',
          isProcessing:
              _processingServiceId == 'training' && _isProcessingPayment,
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
          isSelected: _selectedService == 'diet',
          isProcessing: _processingServiceId == 'diet' && _isProcessingPayment,
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
          isSelected: _selectedService == 'consulting',
          isProcessing:
              _processingServiceId == 'consulting' && _isProcessingPayment,
          onTap: () => _selectService('consulting', consultingCost.toDouble()),
        ),
        const SizedBox(height: 16),

        // بسته کامل
        PackageCardWidget(
          cost: packageFinal.toDouble(),
          packageRaw: _trainingCost + _dietCost + consultingCost,
          discountPct: _discountPct,
          isSelected: _selectedService == 'package',
          isProcessing:
              _processingServiceId == 'package' && _isProcessingPayment,
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
      child: Icon(LucideIcons.user, color: context.textSecondary, size: 60.sp),
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
