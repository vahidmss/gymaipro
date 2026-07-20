import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gymaipro/core/foreground_resume_coordinator.dart';
import 'package:gymaipro/core/app_navigator.dart';
import 'package:gymaipro/payment/services/payment_resume_tracker.dart';
import 'package:gymaipro/payment/services/coach_plan_payment_service.dart';
import 'package:gymaipro/payment/services/trainer_payment_service.dart';
import 'package:gymaipro/payment/services/wallet_service.dart';
import 'package:gymaipro/payment/utils/wallet_refresh_notifier.dart';
import 'package:gymaipro/payment/widgets/purchase_success_dialog.dart';
import 'package:gymaipro/utils/external_url_launcher.dart';

/// سرویس مدیریت deeplink های پرداخت
class PaymentDeeplinkService {
  factory PaymentDeeplinkService() => _instance;
  PaymentDeeplinkService._internal();
  static final PaymentDeeplinkService _instance =
      PaymentDeeplinkService._internal();

  final AppLinks _appLinks = AppLinks();

  StreamSubscription<Uri>? _linkSubscription;
  BuildContext? _context;
  String? _lastTopupDeeplinkKey;
  DateTime? _lastTopupHandledAt;

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
    uri = _normalizeDeeplinkUri(uri);
    if (kDebugMode) {
      print('Deeplink دریافت شد: $uri');
    }

    if (_isWebPaymentCallback(uri)) {
      _handleWebPaymentCallback(uri);
      return;
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
      case 'coach-plan':
      case 'coach_plan':
        _handleCoachPlanPayment(uri);
      default:
        if (kDebugMode) {
          print('مسیر پرداخت نامعتبر: ${pathSegments[0]}');
        }
    }
  }

  void _handleTrainerPayment(Uri uri) {
    uri = _normalizeDeeplinkUri(uri);
    ForegroundResumeCoordinator.markPaymentReturnHandling();

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
        _collapseTransientPaymentRoutes(ctx);
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
      _collapseTransientPaymentRoutes(ctx);
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
              _collapseTransientPaymentRoutes(ctx);
              try {
                openMainMyClub();
              } catch (_) {}
            },
          );
          if (ctx.mounted) {
            _collapseTransientPaymentRoutes(ctx);
          }
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

  void _handleCoachPlanPayment(Uri uri) {
    uri = _normalizeDeeplinkUri(uri);
    ForegroundResumeCoordinator.markPaymentReturnHandling();

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

    if (_context == null) {
      if (kDebugMode) {
        print('Context موجود نیست برای پردازش پرداخت پلن مربی');
      }
      return;
    }

    if (kDebugMode) {
      print(
        'نتیجه پرداخت پلن مربی: status=$status tx=$transactionId track=$trackId',
      );
    }

    if (status != 'success' || transactionId == null || trackId == null) {
      _withNavigatorContext((ctx) async {
        _collapseTransientPaymentRoutes(ctx);
        if (!ctx.mounted) return;
        await showDialog<void>(
          context: ctx,
          builder: (d) => AlertDialog(
            title: const Text('پرداخت ناموفق'),
            content: const Text(
              'پرداخت پلن مربی هوشمند ناموفق بود. لطفاً مجدد تلاش کنید.',
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

    _withNavigatorContext((ctx) async {
      _collapseTransientPaymentRoutes(ctx);
      try {
        final service = CoachPlanPaymentService();
        final result = await service.verifyDirectPayment(
          transactionId: transactionId,
          trackId: trackId,
        );

        final success = result['success'] == true;
        if (!ctx.mounted) return;

        if (success) {
          final planTitle =
              result['plan_title']?.toString() ?? 'پلن مربی هوشمند';
          await PurchaseSuccessDialog.show(
            ctx,
            serviceName: planTitle,
            trainerName: 'مربی هوشمند',
            onViewPrograms: () {
              _collapseTransientPaymentRoutes(ctx);
              try {
                Navigator.of(ctx).pushNamedAndRemoveUntil(
                  '/coach',
                  (route) => route.isFirst,
                );
              } catch (_) {}
            },
          );
          if (ctx.mounted) {
            _collapseTransientPaymentRoutes(ctx);
          }
        } else {
          await showDialog<void>(
            context: ctx,
            barrierDismissible: false,
            builder: (d) => AlertDialog(
              title: const Text('پرداخت ناموفق'),
              content: Text(
                result['error']?.toString() ?? 'تایید پرداخت ناموفق بود.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(d, rootNavigator: true).pop(),
                  child: const Text('باشه'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print('خطا در تایید پرداخت پلن مربی: $e');
        }
      }
    });
  }

  /// پردازش deeplink شارژ کیف پول
  void _handleTopupDeeplink(Uri uri) {
    final status = uri.queryParameters['status'];
    final dedupeKey = '${uri.host}${uri.path}?status=$status';
    final now = DateTime.now();
    if (_lastTopupDeeplinkKey == dedupeKey &&
        _lastTopupHandledAt != null &&
        now.difference(_lastTopupHandledAt!) <
            const Duration(seconds: 4)) {
      return;
    }
    _lastTopupDeeplinkKey = dedupeKey;
    _lastTopupHandledAt = now;
    ForegroundResumeCoordinator.markPaymentReturnHandling();

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
      await ExternalUrlLauncher.closePaymentBrowserIfOpen();
      // صبر تا route شیم app_links روی پشته قرار گیرد، بعد جمع‌آوری UI
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (!ctx.mounted) return;
      await _settleAfterTopup(ctx, status);
    });
  }

  Future<void> _settleAfterTopup(BuildContext ctx, String? status) async {
    if (!ctx.mounted) return;

    _collapseTransientWalletRoutes(ctx);

    if (status == 'success') {
      PaymentResumeTracker.instance.clear();
      try {
        await WalletService().refreshUserWallet();
        WalletRefreshNotifier.notifyRefresh(balanceAlreadyRefreshed: true);
      } catch (e) {
        if (kDebugMode) {
          print('Wallet refresh after topup failed: $e');
        }
        WalletRefreshNotifier.notifyRefresh();
      }
      if (!ctx.mounted) return;
      _showTopupSnack(ctx, 'شارژ موفق — موجودی به‌روز شد');
    } else if (status == 'failed') {
      _showTopupSnack(ctx, 'شارژ انجام نشد. دوباره تلاش کنید.');
    } else if (kDebugMode) {
      print('وضعیت نامعتبر شارژ: $status');
    }
  }

  void _collapseTransientWalletRoutes(BuildContext ctx) {
    _collapseTransientPaymentRoutes(ctx);
  }

  void _collapseTransientPaymentRoutes(BuildContext ctx) {
    final navigator = rootNavigator ?? Navigator.of(ctx);
    if (!navigator.canPop()) return;

    navigator.popUntil((route) {
      final name = route.settings.name ?? '';
      if (name == '/payment-deeplink-shim' ||
          name == '/topup-deeplink-shim' ||
          name == '/trainer' ||
          name == '/payment/trainer' ||
          name == '/payment/coach-plan' ||
          name == '/payment/coach_plan') {
        return false;
      }
      return true;
    });
  }

  static Uri _normalizeDeeplinkUri(Uri uri) {
    final raw = uri.toString();
    if (!raw.contains('&amp;')) return uri;
    return Uri.parse(raw.replaceAll('&amp;', '&'));
  }

  void _showTopupSnack(BuildContext ctx, String message) {
    ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(ctx);
    final rootCtx = appNavigatorKey.currentContext;
    if (messenger == null && rootCtx != null) {
      messenger = ScaffoldMessenger.maybeOf(rootCtx);
    }
    messenger?.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Callback پرداخت از مرورگر (https://gymaipro.ir/payment/callback?...)
  bool _isWebPaymentCallback(Uri uri) {
    if (uri.scheme != 'https' && uri.scheme != 'http') return false;
    const hosts = {'gymaipro.ir', 'www.gymaipro.ir', 'app.gymaipro.ir'};
    if (!hosts.contains(uri.host)) return false;
    return uri.path.contains('payment/callback');
  }

  /// پردازش URL فعلی مرورگر هنگام باز شدن PWA
  void handleWebLaunchUri(Uri uri) {
    if (!kIsWeb) return;
    if (!_isWebPaymentCallback(uri)) return;
    _handleWebPaymentCallback(uri);
  }

  void _handleWebPaymentCallback(Uri uri) {
    final params = uri.queryParameters;
    final type = params['type'];

    if (type == 'trainer') {
      _handleTrainerPayment(uri);
      return;
    }

    if (type == 'coach_plan' || type == 'coach-plan') {
      _handleCoachPlanPayment(uri);
      return;
    }

    final status = params['status'] ??
        (params['success'] == '1' ? 'success' : null) ??
        params['result'];

    if (uri.path.contains('wallet') || params.containsKey('topup')) {
      _handleTopupDeeplink(
        Uri(
          scheme: 'gymaipro',
          host: 'wallet',
          pathSegments: const ['topup'],
          queryParameters: {'status': status ?? 'unknown'},
        ),
      );
      return;
    }

    if (status != null) {
      _handleTopupDeeplink(
        Uri(
          scheme: 'gymaipro',
          host: 'wallet',
          pathSegments: const ['topup'],
          queryParameters: {'status': status},
        ),
      );
    }
  }

  /// بررسی و پردازش deeplink اولیه (در صورت وجود)
  Future<void> handleInitialLink() async {
    try {
      if (kIsWeb) {
        handleWebLaunchUri(Uri.base);
        return;
      }

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
