import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymaipro/chat/screens/chat_screen.dart';
import 'package:gymaipro/payment/models/trainer_subscription.dart';
import 'package:gymaipro/payment/services/trainer_payment_service.dart';
import 'package:gymaipro/payment/services/wallet_service.dart';
import 'package:gymaipro/profile/models/user_profile.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_ranking/models/certificate.dart';
import 'package:gymaipro/trainer_ranking/models/trainer_ranking_model.dart'
    show TrainerReview;
import 'package:gymaipro/trainer_ranking/services/certificate_service.dart';
import 'package:gymaipro/trainer_ranking/services/trainer_ranking_service.dart';
import 'package:gymaipro/trainer_ranking/widgets/certificate_carousel.dart';
import 'package:gymaipro/trainer_ranking/widgets/review_submission_widget.dart';
import 'package:gymaipro/trainer_ranking/widgets/trainer_review_widget.dart';
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

  void _showNetworkErrorDialog() {
    if (mounted) {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('خطا در اتصال', style: GoogleFonts.vazirmatn()),
          content: Text(
            'لطفاً اتصال اینترنت خود را بررسی کنید و دوباره تلاش کنید.',
            style: GoogleFonts.vazirmatn(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('باشه', style: GoogleFonts.vazirmatn()),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _loadReviews() async {
    try {
      final hasConnection = await _checkConnectivity();
      if (!hasConnection) {
        if (mounted) {
          _showNetworkErrorDialog();
          setState(() {
            _isLoadingReviews = false;
          });
        }
        return;
      }

      final reviews = await _service.getTrainerReviews(widget.trainer.id!);

      if (mounted) {
        setState(() {
          _reviews = reviews;
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _showNetworkErrorDialog();
        setState(() {
          _isLoadingReviews = false;
        });
      }
    }
  }

  // به‌روزرسانی اطلاعات مربی از دیتابیس
  Future<void> _refreshTrainerInfo() async {
    try {
      print('🔄 به‌روزرسانی اطلاعات مربی...');
      final updatedTrainer = await _service.getTrainerDetails(
        widget.trainer.id!,
      );
      if (updatedTrainer != null && mounted) {
        setState(() {
          // به‌روزرسانی اطلاعات مربی در state
          _currentRating = updatedTrainer.rating ?? 0.0;
          _currentReviewCount = updatedTrainer.reviewCount ?? 0;
          _currentStudentCount = updatedTrainer.studentCount ?? 0;
          _currentActiveStudentCount = updatedTrainer.activeStudentCount ?? 0;
        });
        print(
          '🔄 اطلاعات مربی به‌روزرسانی شد - امتیاز: $_currentRating, نظرات: $_currentReviewCount, کل شاگردان: $_currentStudentCount, شاگردان فعال: $_currentActiveStudentCount',
        );
      }
    } catch (e) {
      print('🔄 خطا در به‌روزرسانی اطلاعات مربی: $e');
    }
  }

  Future<void> _loadProgramStats() async {
    try {
      final hasConnection = await _checkConnectivity();
      if (!hasConnection) {
        if (mounted) {
          setState(() {
            _isLoadingStats = false;
          });
        }
        return;
      }

      final stats = await _service.getTrainerProgramStats(widget.trainer.id!);
      if (mounted) {
        setState(() {
          _programStats = stats;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
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
          setState(() => _isLoadingServices = false);
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
        setState(() {
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
        setState(() => _isLoadingServices = false);
      }
    }
  }

  Future<void> _loadWalletBalance() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        final wallet = await _walletService.getUserWallet();
        if (wallet != null && mounted) {
          setState(() {
            _walletBalance = wallet.balance;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('خطا در دریافت موجودی کیف پول: $e');
      }
    }
  }

  String _toFa(String input) {
    const fa = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    final b = StringBuffer();
    for (final ch in input.split('')) {
      final d = int.tryParse(ch);
      b.write(d == null ? ch : fa[d]);
    }
    return b.toString();
  }

  String _formatAmountFa(num value) {
    final s = value.toStringAsFixed(0);
    final rev = s.split('').reversed.toList();
    final out = StringBuffer();
    for (int i = 0; i < rev.length; i++) {
      if (i != 0 && i % 3 == 0) out.write(',');
      out.write(rev[i]);
    }
    final withSep = out.toString().split('').reversed.join();
    return _toFa(withSep);
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
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: SingleChildScrollView(
          child: ReviewSubmissionWidget(
            trainerId: widget.trainer.id ?? '',
            onReviewSubmitted: _loadReviews,
          ),
        ),
      ),
    );
  }

  void _selectService(String serviceId, double cost) {
    if (mounted) {
      setState(() {
        _selectedService = serviceId;
      });
    }
    _showPaymentDialog(serviceId, cost);
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

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            'انتخاب روش پرداخت',
            style: GoogleFonts.vazirmatn(
              color: Colors.white,
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
                style: GoogleFonts.vazirmatn(
                  color: AppTheme.goldColor,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'مبلغ: ${_formatAmountFa(cost)} تومان',
                style: GoogleFonts.vazirmatn(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // نمایش موجودی کیف پول
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF3A3A3A),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.wallet,
                      color: AppTheme.goldColor,
                      size: 16.sp,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'موجودی کیف پول: ${_formatAmountFa(_walletBalance / 10)} تومان',
                      style: GoogleFonts.vazirmatn(
                        color: Colors.white,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // ورودی کد تخفیف
              TextField(
                onChanged: (value) {
                  _discountCode = value.trim().isEmpty ? null : value.trim();
                },
                style: GoogleFonts.vazirmatn(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'کد تخفیف (اختیاری)',
                  hintStyle: GoogleFonts.vazirmatn(color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFF3A3A3A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'روش پرداخت خود را انتخاب کنید:',
                style: GoogleFonts.vazirmatn(
                  color: Colors.grey[300],
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
                      style: GoogleFonts.vazirmatn(fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isProcessingPayment
                          ? Colors.grey[600]
                          : AppTheme.goldColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
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
                      style: GoogleFonts.vazirmatn(fontSize: 14),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _isProcessingPayment
                          ? Colors.grey[400]
                          : AppTheme.goldColor,
                      side: BorderSide(
                        color: _isProcessingPayment
                            ? Colors.grey[400]!
                            : AppTheme.goldColor,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
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
                  style: GoogleFonts.vazirmatn(
                    color: Colors.grey[400],
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
          ],
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

    if (mounted) {
      setState(() {
        _isProcessingPayment = true;
      });
    }

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        _showErrorDialog('لطفاً ابتدا وارد حساب کاربری خود شوید');
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
          _showErrorDialog('نوع خدمات نامعتبر');
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
          _showSuccessDialog(
            'اشتراک با موفقیت خریداری شد',
            'اشتراک شما فعال شده و می‌توانید از خدمات مربی استفاده کنید.',
          );
          // به‌روزرسانی موجودی کیف پول
          await _loadWalletBalance();
        } else {
          // هدایت به درگاه پرداخت
          _showPaymentRedirectDialog(
            result['payment_url']! as String,
            result['track_id']! as String,
          );
        }
      } else {
        _showErrorDialog(
          (result['error'] as String?) ?? 'خطا در پردازش پرداخت',
        );
      }
    } catch (e) {
      _showErrorDialog('خطا در پردازش: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
      }
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

  void _showErrorDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'خطا',
          style: GoogleFonts.vazirmatn(
            color: Colors.red,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.vazirmatn(color: Colors.white, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'باشه',
              style: GoogleFonts.vazirmatn(color: AppTheme.goldColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          title,
          style: GoogleFonts.vazirmatn(
            color: Colors.green,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.vazirmatn(color: Colors.white, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'باشه',
              style: GoogleFonts.vazirmatn(color: AppTheme.goldColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentRedirectDialog(String paymentUrl, String trackId) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'هدایت به درگاه پرداخت',
          style: GoogleFonts.vazirmatn(
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
              style: GoogleFonts.vazirmatn(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text(
              'کد پیگیری: $trackId',
              style: GoogleFonts.vazirmatn(
                color: Colors.grey[400],
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'انصراف',
              style: GoogleFonts.vazirmatn(color: Colors.grey[400]),
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
              foregroundColor: Colors.white,
            ),
            child: Text('ادامه پرداخت', style: GoogleFonts.vazirmatn()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: const Color(0xFF1A1A1A),
            flexibleSpace: FlexibleSpaceBar(background: _buildHeader()),
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(LucideIcons.arrowRight, color: Colors.white),
            ),
          ),
        ],
        body: Column(
          children: [
            _buildActionButtons(),
            ColoredBox(
              color: const Color(0xFF2A2A2A),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.goldColor,
                labelColor: AppTheme.goldColor,
                unselectedLabelColor: Colors.grey[400],
                tabs: [
                  Tab(child: Text('اطلاعات', style: GoogleFonts.vazirmatn())),
                  Tab(child: Text('نظرات', style: GoogleFonts.vazirmatn())),
                  Tab(
                    child: Text(' گواهینامه', style: GoogleFonts.vazirmatn()),
                  ),
                  Tab(child: Text('تعرفه ها', style: GoogleFonts.vazirmatn())),
                ],
              ),
            ),
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
      ),
    );
  }

  Widget _buildHeader() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.goldColor.withValues(alpha: 0.8),
            const Color(0xFF1A1A1A),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // تصویر مربی
              Stack(
                children: [
                  Hero(
                    tag:
                        'trainer_${widget.trainer.id}_${widget.trainer.username}',
                    child: Container(
                      width: 100.w,
                      height: 100.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
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
                  if (widget.trainer.isOnline ?? false)
                    Positioned(
                      bottom: 0.h,
                      right: 0.w,
                      child: Container(
                        width: 28.w,
                        height: 28.h,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          LucideIcons.wifi,
                          color: Colors.white,
                          size: 14.sp,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // نام و رتبه
              Flexible(
                child: Text(
                  widget.trainer.fullName.isNotEmpty
                      ? widget.trainer.fullName
                      : widget.trainer.username,
                  style: GoogleFonts.vazirmatn(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              Container(
                margin: const EdgeInsets.only(top: 6),
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppTheme.goldColor,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Text(
                  'رتبه #${widget.trainer.ranking ?? 999}',
                  style: GoogleFonts.vazirmatn(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // امتیاز و آمار
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(
                    icon: LucideIcons.star,
                    label: 'امتیاز',
                    value: _currentRating.toStringAsFixed(1),
                    color: Colors.amber,
                  ),
                  _buildStatItem(
                    icon: LucideIcons.messageCircle,
                    label: 'نظرات',
                    value: _currentReviewCount.toString(),
                    color: Colors.blue,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12),
      child: Center(
        child: SizedBox(
          width: 200.w,
          child: ElevatedButton.icon(
            onPressed: _messageTrainer,
            icon: const Icon(LucideIcons.messageCircle, size: 20),
            label: Text(
              'پیام خصوصی',
              style: GoogleFonts.vazirmatn(fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.goldColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 4,
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
            Text(
              'خود نوشته',
              style: GoogleFonts.vazirmatn(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.2),
                  width: 0.5,
                ),
              ),
              child: Text(
                widget.trainer.bio!,
                style: GoogleFonts.vazirmatn(
                  color: Colors.grey[300],
                  fontSize: 12.sp,
                  height: 1.4,
                ),
                textAlign: TextAlign.justify,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: 16.h),
          ],

          // تخصص‌ها
          _buildSectionTitle('تخصص‌ها'),
          if ((widget.trainer.specializations ?? []).isEmpty)
            Container(
              padding: const EdgeInsets.all(12.0 * 1.5),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                'تخصصی ثبت نشده',
                style: GoogleFonts.vazirmatn(
                  color: Colors.grey[400],
                  fontSize: 13.sp,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: (widget.trainer.specializations ?? []).map((spec) {
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.goldColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: AppTheme.goldColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    spec,
                    style: GoogleFonts.vazirmatn(
                      color: AppTheme.goldColor,
                      fontSize: 11.sp,
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 20),

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
        Container(
          width: double.infinity,
          margin: EdgeInsets.all(16.w),
          child: ElevatedButton.icon(
            onPressed: _showReviewDialog,
            icon: const Icon(LucideIcons.star),
            label: Text(
              'نظر خود را ثبت کنید',
              style: GoogleFonts.vazirmatn(
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
                      padding: EdgeInsets.all(32.w),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.messageCircle,
                            size: 64.sp,
                            color: Colors.grey[600],
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'هنوز نظری ثبت نشده',
                            style: GoogleFonts.vazirmatn(
                              color: Colors.grey[600],
                              fontSize: 18.sp,
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
                    print('🔄 نمایش نظر ${index + 1} از ${_reviews.length}');
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
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.alertCircle, size: 64.sp, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'خطا در بارگذاری مدارک',
                  style: GoogleFonts.vazirmatn(
                    color: Colors.red,
                    fontSize: 18.sp,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: GoogleFonts.vazirmatn(
                    color: Colors.grey[500],
                    fontSize: 14.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final certificates = snapshot.data ?? [];
        final approvedCertificates = certificates
            .where((c) => c.status == CertificateStatus.approved)
            .toList();

        if (approvedCertificates.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.award, size: 64.sp, color: Colors.grey[600]),
                const SizedBox(height: 16),
                Text(
                  'مدرکی ثبت نشده',
                  style: GoogleFonts.vazirmatn(
                    color: Colors.grey[600],
                    fontSize: 18.sp,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'مربی هنوز مدرکی ثبت نکرده یا مدارک در انتظار تایید هستند',
                  style: GoogleFonts.vazirmatn(
                    color: Colors.grey[500],
                    fontSize: 14.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
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
      padding: EdgeInsets.only(bottom: 6.h),
      child: Text(
        title,
        style: GoogleFonts.vazirmatn(
          color: Colors.white,
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.vazirmatn(
            color: color,
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.vazirmatn(color: Colors.white, fontSize: 10),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.vazirmatn(
              color: color,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.vazirmatn(color: Colors.grey[400], fontSize: 10),
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
        _buildServiceCard(
          icon: LucideIcons.dumbbell,
          title: 'برنامه تمرینی',
          description: 'برنامه تمرینی شخصی‌سازی شده براساس اهداف شما',
          price: _serviceTrainingEnabled
              ? _formatAmountFa(_trainingCost)
              : _toFa('۰'),
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
        _buildServiceCard(
          icon: LucideIcons.apple,
          title: 'برنامه رژیم غذایی',
          description: 'رژیم غذایی متعادل متناسب با اهداف و شرایط شما',
          price: _serviceDietEnabled ? _formatAmountFa(_dietCost) : _toFa('۰'),
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
        _buildServiceCard(
          icon: LucideIcons.headphones,
          title: 'مشاوره و نظارت',
          description: 'مشاوره تخصصی و نظارت مداوم بر روند پیشرفت شما',
          price: _serviceConsultEnabled && _serviceTrainingEnabled
              ? _formatAmountFa(consultingCost)
              : _toFa('۰'),
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
        GestureDetector(
          onTap: () => _selectService('package', packageFinal.toDouble()),
          child: Container(
            padding: const EdgeInsets.all(12.0 * 1.5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.goldColor.withValues(alpha: 0.2),
                  AppTheme.goldColor.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: _selectedService == 'package'
                    ? AppTheme.goldColor
                    : AppTheme.goldColor.withValues(alpha: 0.5),
                width: _selectedService == 'package' ? 3 : 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        color: AppTheme.goldColor,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Icon(
                        LucideIcons.crown,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'بسته کامل',
                            style: GoogleFonts.vazirmatn(
                              color: AppTheme.goldColor,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'همه خدمات با تخفیف ویژه',
                            style: GoogleFonts.vazirmatn(
                              color: Colors.grey[300],
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Price (dynamic later)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'تومان ',
                              style: GoogleFonts.vazirmatn(
                                color: Colors.grey[300],
                                fontSize: 10.sp,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                _formatAmountFa(packageFinal),
                                style: GoogleFonts.vazirmatn(
                                  color: AppTheme.goldColor,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'ماهانه',
                          style: GoogleFonts.vazirmatn(
                            color: Colors.grey[400],
                            fontSize: 10.sp,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'شامل: برنامه تمرینی + برنامه رژیم غذایی + مشاوره و نظارت',
                  style: GoogleFonts.vazirmatn(
                    color: Colors.white,
                    fontSize: 12.sp,
                    height: 1.4.h,
                  ),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (packageRaw > 0 && _discountPct > 0)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          'تخفیف ${_toFa(_discountPct.toStringAsFixed(0))}٪',
                          style: GoogleFonts.vazirmatn(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceCard({
    required IconData icon,
    required String title,
    required String description,
    required String price,
    required String period,
    required List<String> features,
    required Color color,
    bool isPopular = false,
    bool disabled = false,
    String? serviceId,
    VoidCallback? onTap,
  }) {
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: _selectedService == serviceId
                  ? AppTheme.goldColor
                  : (isPopular
                        ? AppTheme.goldColor
                        : color.withValues(alpha: 0.3)),
              width: _selectedService == serviceId ? 3 : (isPopular ? 2 : 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 6.r,
                offset: Offset(0.w, 2.h),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                style: GoogleFonts.vazirmatn(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isPopular) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6.w,
                                  vertical: 2.h,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.goldColor,
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Text(
                                  'محبوب',
                                  style: GoogleFonts.vazirmatn(
                                    color: Colors.white,
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                            if (_selectedService == serviceId) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6.w,
                                  vertical: 2.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Text(
                                  'انتخاب شده',
                                  style: GoogleFonts.vazirmatn(
                                    color: Colors.white,
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: GoogleFonts.vazirmatn(
                            color: Colors.grey[400],
                            fontSize: 11.sp,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'تومان ',
                            style: GoogleFonts.vazirmatn(
                              color: Colors.grey[300],
                              fontSize: 10.sp,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              price,
                              style: GoogleFonts.vazirmatn(
                                color: color,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        period,
                        style: GoogleFonts.vazirmatn(
                          color: Colors.grey[400],
                          fontSize: 10.sp,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'شامل:',
                style: GoogleFonts.vazirmatn(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              ...features.map(
                (feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    children: [
                      Icon(LucideIcons.check, color: color, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          feature,
                          style: GoogleFonts.vazirmatn(
                            color: Colors.grey[300],
                            fontSize: 11.sp,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return const ColoredBox(
      color: Color(0xFF3A3A3A),
      child: Icon(LucideIcons.user, color: Colors.white, size: 60),
    );
  }

  // Load certificates from database
  Future<List<Certificate>> _loadCertificates() async {
    try {
      return await CertificateService.getPublicCertificates(widget.trainer.id!);
    } catch (e) {
      throw Exception('خطا در بارگذاری مدارک: $e');
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
                        padding: EdgeInsets.all(32.w),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported,
                                color: Colors.grey[400],
                                size: 64.sp,
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                'خطا در بارگذاری تصویر',
                                style: GoogleFonts.vazirmatn(
                                  color: Colors.grey[400],
                                  fontSize: 16.sp,
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
