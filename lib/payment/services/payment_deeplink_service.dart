import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gymaipro/payment/services/trainer_payment_service.dart';
import 'package:gymaipro/payment/widgets/purchase_success_dialog.dart';
import 'package:gymaipro/widgets/responsive_dialog.dart';

/// سرویس مدیریت deeplink های پرداخت
class PaymentDeeplinkService {
  factory PaymentDeeplinkService() => _instance;
  PaymentDeeplinkService._internal();
  static final PaymentDeeplinkService _instance =
      PaymentDeeplinkService._internal();

  final AppLinks _appLinks = AppLinks();

  StreamSubscription<Uri>? _linkSubscription;
  BuildContext? _context;
  bool _isShowingDialog = false;

  BuildContext? _getNavigatorContext() {
    // استفاده از context محلی
    return _context;
  }

  // /// دریافت NavigatorState از GlobalKey
  // NavigatorState? _getNavigatorState() {
  //   // استفاده از context محلی برای یافتن NavigatorState
  //   if (_context != null) {
  //     return Navigator.of(_context!);
  //   }
  //   return null;
  // }

  Future<void> _withNavigatorContext(
    Future<void> Function(BuildContext) action, {
    int retries = 10,
  }) async {
    BuildContext? ctx = _getNavigatorContext();
    int attempts = 0;
    while (ctx == null && attempts < retries) {
      await Future<void>.delayed(const Duration(milliseconds: 80));
      ctx = _getNavigatorContext();
      attempts++;
    }
    if (ctx != null && ctx.mounted) {
      await action(ctx);
    } else if (kDebugMode) {
      print('Navigator context still unavailable after retries.');
    }
  }

  /// شروع گوش دادن به deeplink ها
  void initialize(BuildContext context) {
    _context = context;
    _startListening();
  }

  /// توقف گوش دادن به deeplink ها
  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
  }

  void _startListening() {
    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleDeeplink,
      onError: (Object err) {
        if (kDebugMode) {
          print('خطا در پردازش deeplink: $err');
        }
      },
    );
  }

  /// پردازش deeplink دریافتی
  void _handleDeeplink(Uri uri) {
    if (kDebugMode) {
      print('Deeplink دریافت شد: $uri');
    }

    // بررسی scheme و host
    if (uri.scheme != 'gymaipro') {
      if (kDebugMode) {
        print('Scheme نامعتبر: ${uri.scheme}');
      }
      return;
    }

    // پردازش مسیرهای مختلف
    switch (uri.host) {
      case 'wallet':
        _handleWalletDeeplink(uri);
      case 'payment':
        _handlePaymentDeeplink(uri);
      default:
        if (kDebugMode) {
          print('Host نامعتبر: ${uri.host}');
        }
    }
  }

  /// پردازش deeplink های کیف پول
  void _handleWalletDeeplink(Uri uri) {
    final pathSegments = uri.pathSegments;
    if (pathSegments.isEmpty) return;

    switch (pathSegments[0]) {
      case 'topup':
        _handleTopupDeeplink(uri);
      default:
        if (kDebugMode) {
          print('مسیر کیف پول نامعتبر: ${pathSegments[0]}');
        }
    }
  }

  /// پردازش deeplink های پرداخت‌های مستقیم (اشتراک مربی و ...)
  void _handlePaymentDeeplink(Uri uri) {
    final pathSegments = uri.pathSegments;
    if (pathSegments.isEmpty) return;

    switch (pathSegments[0]) {
      case 'trainer':
        _handleTrainerPayment(uri);
      default:
        if (kDebugMode) {
          print('مسیر پرداخت نامعتبر: ${pathSegments[0]}');
        }
    }
  }

  void _handleTrainerPayment(Uri uri) {
    // برخی وب‌سرورها کاراکتر & را به &amp; تبدیل می‌کنند؛ نرمال‌سازی
    final String raw = uri.toString();
    if (raw.contains('&amp;')) {
      final normalized = Uri.parse(raw.replaceAll('&amp;', '&'));
      uri = normalized;
    }

    // خواندن پارامترها با نام‌های ممکن مختلف
    final status = uri.queryParameters['status'];
    final transactionId =
        uri.queryParameters['transactionId'] ??
        uri.queryParameters['orderId'] ??
        uri.queryParameters['tx'] ??
        uri.queryParameters['oid'];
    final trackId =
        uri.queryParameters['trackId'] ??
        uri.queryParameters['track_id'] ??
        uri.queryParameters['tid'];
    final trainerId = uri.queryParameters['trainerId'];

    if (_context == null) {
      if (kDebugMode) {
        print('Context موجود نیست برای پردازش پرداخت');
      }
      return;
    }

    if (kDebugMode) {
      print(
        'نتیجه پرداخت مربی: status=$status tx=$transactionId track=$trackId trainer=$trainerId',
      );
    }

    if (status != 'success' || transactionId == null || trackId == null) {
      _withNavigatorContext((ctx) async {
        // هدایت به صفحه مربی در صورت وجود trainerId
        if (trainerId != null && trainerId.isNotEmpty) {
          try {
            Navigator.of(ctx).pushNamedAndRemoveUntil(
              '/trainer-detail',
              (route) => route.isFirst,
              arguments: {'trainerId': trainerId},
            );
            await Future<void>.delayed(const Duration(milliseconds: 300));
          } catch (_) {}
        }

        if (!ctx.mounted) return;
        await showDialog<void>(
          context: ctx,
          builder: (d) => AlertDialog(
            title: const Text('پرداخت ناموفق'),
            content: const Text(
              'پرداخت ناموفق بود. لطفاً مجدد تلاش کنید.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(d, rootNavigator: true).pop(),
                child: const Text('باشه'),
              ),
            ],
          ),
        );
      });
      return;
    }

    // تایید پرداخت و نمایش نتیجه
    _withNavigatorContext((ctx) async {
      try {
        final service = TrainerPaymentService();
        final result = await service.verifyDirectPayment(
          transactionId: transactionId,
          trackId: trackId,
        );

        final success = result['success'] == true;

        if (!ctx.mounted) return;
        if (success) {
          // نمایش دیالوگ موفقیت خرید
          String serviceName = 'برنامه';
          String trainerNameStr = 'مربی';

          // دریافت نام سرویس از metadata تراکنش
          try {
            final txStatus = await service.getTransactionStatus(transactionId);
            final txData = txStatus?['transaction'] as Map<String, dynamic>?;
            final meta = txData?['metadata'] as Map<String, dynamic>?;
            serviceName = (meta?['service_name'] as String?) ?? serviceName;
            trainerNameStr = (meta?['trainer_name'] as String?) ?? trainerNameStr;
          } catch (_) {}

          if (!ctx.mounted) return;
          await PurchaseSuccessDialog.show(
            ctx,
            serviceName: serviceName,
            trainerName: trainerNameStr,
            onViewPrograms: () {
              try {
                Navigator.of(ctx).pushNamedAndRemoveUntil(
                  '/my-club',
                  (route) => route.isFirst,
                  arguments: {'initialTab': 0},
                );
              } catch (_) {}
            },
          );
        } else {
          await showDialog<void>(
            context: ctx,
            barrierDismissible: false,
            builder: (d) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.error, color: Colors.red, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'پرداخت ناموفق',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: Text(
                result['error']?.toString() ?? 'تایید پرداخت ناموفق بود.',
                style: const TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(d, rootNavigator: true).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text(
                    'باشه',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print('خطا در تایید پرداخت مربی: $e');
        }
      }
    });
  }

  /// پردازش deeplink شارژ کیف پول
  void _handleTopupDeeplink(Uri uri) {
    final status = uri.queryParameters['status'];

    if (kDebugMode) {
      print('نتیجه شارژ کیف پول: $status');
    }

    if (_context == null) {
      if (kDebugMode) {
        print('Context موجود نیست');
      }
      return;
    }

    _withNavigatorContext((ctx) async {
      await _navigateToWallet(ctx);
      // بعد از ناوبری به کیف پول، دیالوگ نتیجه را نمایش بده
      Future.delayed(const Duration(milliseconds: 120), () {
        switch (status) {
          case 'success':
            _showTopupSuccessDialog();
          case 'failed':
            _showTopupFailedDialog();
          default:
            if (kDebugMode) {
              print('وضعیت نامعتبر: $status');
            }
        }
      });
    });
  }

  /// ناوبری به صفحه کیف پول و بستن هر دیالوگ باز قبلی
  Future<void> _navigateToWallet(BuildContext ctx) async {
    // تلاش برای بستن هر دیالوگ باز (مثل دیالوگ ادامه پرداخت)
    try {
      Navigator.of(ctx, rootNavigator: true).pop();
    } catch (_) {
      // نادیده بگیر
    }
    await Future<void>.delayed(const Duration(milliseconds: 60));
    if (kDebugMode) {
      print('Navigating to /wallet after payment result');
    }

    if (!ctx.mounted) return;
    // استفاده از NavigatorState از context
    try {
      Navigator.of(ctx).pushNamedAndRemoveUntil('/wallet', (route) {
        final name = route.settings.name ?? '';
        return name == '/main' || route.isFirst;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error navigating to wallet: $e');
      }
    }
  }

  /// نمایش دیالوگ موفقیت شارژ
  void _showTopupSuccessDialog() {
    if (_isShowingDialog) return;
    _isShowingDialog = true;
    _withNavigatorContext((ctx) async {
      await ResponsiveDialog.showAlert<void>(
        context: ctx,
        title: 'شارژ موفق',
        content: 'کیف پول شما با موفقیت شارژ شد. موجودی شما به‌روزرسانی خواهد شد.',
        confirmText: 'باشه',
        barrierDismissible: false,
        onConfirm: () {
          Navigator.of(ctx, rootNavigator: true).pop();
        },
      );
      _isShowingDialog = false;
    });
  }

  /// نمایش دیالوگ عدم موفقیت شارژ
  void _showTopupFailedDialog() {
    if (_isShowingDialog) return;
    _isShowingDialog = true;
    _withNavigatorContext((ctx) async {
      await ResponsiveDialog.showAlert<void>(
        context: ctx,
        title: 'شارژ ناموفق',
        content: 'متأسفانه شارژ کیف پول شما ناموفق بود. لطفاً مجدد تلاش کنید.',
        confirmText: 'باشه',
        barrierDismissible: false,
        onConfirm: () {
          Navigator.of(ctx, rootNavigator: true).pop();
        },
      );
      _isShowingDialog = false;
    });
  }

  /// بررسی و پردازش deeplink اولیه (در صورت وجود)
  Future<void> handleInitialLink() async {
    try {
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        if (kDebugMode) {
          print('Initial deeplink: $initialUri');
        }
        _handleDeeplink(initialUri);
      }
    } catch (e) {
      if (kDebugMode) {
        print('خطا در پردازش initial deeplink: $e');
      }
    }
  }
}
