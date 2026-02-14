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
    _loadKpis();
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
            expandedHeight: 240.h,
            floating: false,
            pinned: true,
            backgroundColor: context.backgroundColor,
            elevation: 0,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                LucideIcons.arrowRight,
                color: context.textColor,
                size: 22.sp,
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
            SizedBox(height: 16.h),
            _buildActionButtons(),
            Container(
              decoration: BoxDecoration(
                color: context.cardColor,
                border: Border(
                  bottom: BorderSide(
                    color: context.separatorColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.goldColor,
                indicatorWeight: 2,
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: AppTheme.goldColor,
                unselectedLabelColor: context.textSecondary,
                labelStyle: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12.sp,
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
        color: isDark
            ? context.backgroundColor
            : AppTheme.lightGradientStart.withValues(alpha: 0.12),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(top: 6.h, bottom: 12.h),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Hero(
                  tag:
                      'trainer_${widget.trainer.id}_${widget.trainer.username}',
                  child: Container(
                    width: 72.w,
                    height: 72.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.goldColor, width: 2.w),
                      color: context.cardColor,
                    ),
                    child: ClipOval(
                      child: widget.trainer.avatarUrl != null
                          ? Image.network(
                              widget.trainer.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildDefaultAvatar(),
                            )
                          : _buildDefaultAvatar(),
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        widget.trainer.fullName.isNotEmpty
                            ? widget.trainer.fullName
                            : widget.trainer.username,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: context.textColor,
                          fontSize: 17.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.trainer.ranking != null &&
                        widget.trainer.ranking! > 0) ...[
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 3.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.goldColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.trophy,
                              size: 14.sp,
                              color: AppTheme.onGoldColor,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              '${widget.trainer.ranking}',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.onGoldColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 12.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: _miniKpiChip(
                          context,
                          icon: LucideIcons.userCheck,
                          label: 'شاگرد',
                          value: _currentActiveStudentCount.toString(),
                          color: const Color(0xFF4CAF50),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: _miniKpiChip(
                          context,
                          icon: LucideIcons.dumbbell,
                          label: 'برنامه',
                          value: (_programStats['workout_programs'] ?? 0)
                              .toString(),
                          color: const Color(0xFF2196F3),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 6.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: _miniKpiChip(
                          context,
                          icon: LucideIcons.music,
                          label: 'موزیک',
                          value: _isLoadingKpis
                              ? '—'
                              : (_kpis?.totalCustomMusics ?? 0).toString(),
                          color: const Color(0xFF9C27B0),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: _miniKpiChip(
                          context,
                          icon: LucideIcons.thumbsUp,
                          label: 'رضایت',
                          value: _isLoadingKpis
                              ? '—'
                              : '${_kpis?.satisfactionPercent ?? 0}%',
                          color: const Color(0xFFFF9800),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniKpiChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: context.separatorColor.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14.sp, color: color),
          SizedBox(width: 6.w),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: context.textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 10.sp,
                    color: context.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _messageTrainer,
          borderRadius: BorderRadius.circular(14.r),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
            decoration: BoxDecoration(
              color: AppTheme.goldColor,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.messageCircle,
                  size: 18.sp,
                  color: AppTheme.onGoldColor,
                ),
                SizedBox(width: 8.w),
                Text(
                  'پیام',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onGoldColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
