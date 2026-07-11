import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/achievements/services/achievement_service.dart';
import 'package:gymaipro/chat/services/chat_unread_notifier.dart';
import 'package:gymaipro/config/app_config.dart';
import 'package:gymaipro/core/app_error_handler.dart';
import 'package:gymaipro/core/app_initializer.dart';
import 'package:gymaipro/core/app_navigator.dart';
import 'package:gymaipro/core/lifecycle_observer.dart';
import 'package:gymaipro/core/performance_monitor.dart';
import 'package:gymaipro/core/web_interaction.dart';
import 'package:gymaipro/debug/global_key_debugger.dart';
import 'package:gymaipro/guide/guide.dart';
import 'package:gymaipro/payment/services/payment_deeplink_service.dart';
import 'package:gymaipro/services/connectivity_service.dart';
import 'package:gymaipro/services/backend_reachability_service.dart';
import 'package:gymaipro/services/notification_navigation_service.dart';
import 'package:gymaipro/notification/providers/notification_provider.dart';
import 'package:gymaipro/services/route_service.dart';
import 'package:gymaipro/academy/services/music_player_service.dart';
import 'package:gymaipro/services/score_service.dart';
import 'package:gymaipro/services/supabase_service.dart';
import 'package:gymaipro/services/video_download_manager.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/theme/theme_provider.dart';
import 'package:gymaipro/widgets/app_update_coordinator.dart';
import 'package:gymaipro/widgets/offline_banner.dart';
import 'package:gymaipro/widgets/vpn_warning_banner.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    usePathUrlStrategy();
  }
  AppErrorHandler.initialize();
  runApp(const BootstrapApp());
}

// ─────────────────────────────────────────────────────────────────────────────
// Bootstrap — Handles initialization with timeout, auto-retry & connectivity
// ─────────────────────────────────────────────────────────────────────────────

class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

enum _BootPhase { loading, done, failed }

enum _BootFailureReason {
  noNetwork,
  serverUnreachable,
  initError,
  missingConfig,
}

class _BootstrapAppState extends State<BootstrapApp> {
  _BootPhase _phase = _BootPhase.loading;
  AppInitResult? _result;

  bool _isInitializing = false;
  bool _showSlowHint = false;
  _BootFailureReason _failureReason = _BootFailureReason.noNetwork;
  Timer? _slowTimer;
  StreamSubscription<bool>? _connectivitySub;

  @override
  void initState() {
    super.initState();
    _startInit();
    _listenConnectivity();
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    _connectivitySub?.cancel();
    super.dispose();
  }

  Future<void> _startInit() async {
    if (_phase == _BootPhase.done) return;
    if (_isInitializing) return;

    _isInitializing = true;
    _slowTimer?.cancel();
    setState(() {
      _phase = _BootPhase.loading;
      _showSlowHint = false;
    });

    // After 6s show a subtle hint — user is never left wondering
    _slowTimer = Timer(const Duration(seconds: 6), () {
      if (mounted && _phase == _BootPhase.loading) {
        setState(() => _showSlowHint = true);
      }
    });

    try {
      final online = await ConnectivityService.instance.checkNow();
      if (!online) {
        _slowTimer?.cancel();
        if (!mounted) return;
        setState(() {
          _phase = _BootPhase.failed;
          _failureReason = _BootFailureReason.noNetwork;
        });
        return;
      }

      final result = await AppInitializer.initialize();
      _slowTimer?.cancel();
      if (!mounted) return;

      if (result.success) {
        if (kDebugMode &&
            !AppInitializer.isSupabaseReady &&
            AppConfig.supabaseAnonKey.isEmpty) {
          setState(() {
            _phase = _BootPhase.failed;
            _failureReason = _BootFailureReason.missingConfig;
          });
          return;
        }
        setState(() {
          _phase = _BootPhase.done;
          _result = result;
        });
      } else {
        final backendReachable =
            await BackendReachabilityService.isBackendReachable();
        setState(() {
          _phase = _BootPhase.failed;
          _failureReason = backendReachable
              ? _BootFailureReason.initError
              : _BootFailureReason.serverUnreachable;
        });
      }
    } catch (e) {
      _slowTimer?.cancel();
      if (kDebugMode) debugPrint('Bootstrap init error: $e');
      if (!mounted) return;
      setState(() {
        _phase = _BootPhase.failed;
        _failureReason = _BootFailureReason.initError;
      });
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _retryInit() async {
    final online = await ConnectivityService.instance.checkNow();
    if (!online) {
      if (!mounted) return;
      setState(() {
        _phase = _BootPhase.failed;
        _failureReason = _BootFailureReason.noNetwork;
      });
      return;
    }
    await _startInit();
  }

  void _listenConnectivity() {
    ConnectivityService.instance.ensureListening();
    ConnectivityService.instance.checkNow();

    _connectivitySub = ConnectivityService.instance.isConnectedStream.listen((
      online,
    ) {
      if (online && _phase != _BootPhase.done && !_isInitializing) {
        _startInit();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == _BootPhase.done && _result != null) {
      return LifecycleObserver(
        child: MyApp(
          initialRoute: _result!.initialRoute,
          supabaseService: _result!.supabaseService,
        ),
      );
    }

    return _SplashMaterialApp(
      phase: _phase,
      showSlowHint: _showSlowHint,
      failureReason: _failureReason,
      onRetry: _retryInit,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Splash screen — shown during initialization
// ─────────────────────────────────────────────────────────────────────────────

class _SplashMaterialApp extends StatelessWidget {
  const _SplashMaterialApp({
    required this.phase,
    required this.showSlowHint,
    required this.failureReason,
    required this.onRetry,
  });

  final _BootPhase phase;
  final bool showSlowHint;
  final _BootFailureReason failureReason;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _SplashScreen(
        phase: phase,
        showSlowHint: showSlowHint,
        failureReason: failureReason,
        onRetry: onRetry,
      ),
    );
  }
}

class _SplashScreen extends StatefulWidget {
  const _SplashScreen({
    required this.phase,
    required this.showSlowHint,
    required this.failureReason,
    required this.onRetry,
  });

  final _BootPhase phase;
  final bool showSlowHint;
  final _BootFailureReason failureReason;
  final VoidCallback onRetry;

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Subtle breathing opacity on the logo — not a spinner, just life
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.7, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFailed = widget.phase == _BootPhase.failed;
    final failure = widget.failureReason;

    final String title;
    final String subtitle;
    final IconData failureIcon;

    switch (failure) {
      case _BootFailureReason.serverUnreachable:
        title = 'سرور در دسترس نیست';
        subtitle = 'اینترنت وصل است ولی به سرور نمی‌رسیم';
        failureIcon = Icons.cloud_off_rounded;
      case _BootFailureReason.initError:
        title = 'خطا در راه‌اندازی';
        subtitle = 'لطفاً دوباره تلاش کنید';
        failureIcon = Icons.error_outline_rounded;
      case _BootFailureReason.noNetwork:
        title = 'اتصال اینترنت نیست';
        subtitle = 'اینترنت را روشن کنید و دوباره تلاش کنید';
        failureIcon = Icons.wifi_off_rounded;
      case _BootFailureReason.missingConfig:
        title = 'تنظیمات env لود نشده';
        subtitle =
            'فایل .env را بسازید و با --dart-define-from-file=.env اجرا کنید\n'
            '(Run → GymAI Pro Android / iOS)';
        failureIcon = Icons.settings_outlined;
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeTransition(
                    opacity: isFailed
                        ? const AlwaysStoppedAnimation(1)
                        : _fadeAnimation,
                    child: const Image(
                      image: AssetImage('images/mainlogo_no_bg.png'),
                      width: 130,
                    ),
                  ),
                  const SizedBox(height: 48),
                  AnimatedOpacity(
                    opacity: isFailed ? 0 : 1,
                    duration: const Duration(milliseconds: 300),
                    child: SizedBox(
                      width: 56,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          minHeight: 2,
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          color: AppTheme.goldColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                  if (isFailed) ...[
                    const SizedBox(height: 28),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.goldColor.withValues(alpha: 0.06),
                        border: Border.all(
                          color: AppTheme.goldColor.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Icon(
                        failureIcon,
                        size: 32,
                        color: AppTheme.goldColor.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.45),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: widget.onRetry,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.goldColor,
                          foregroundColor: AppTheme.onGoldColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        child: const Text(
                          'تلاش مجدد',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (!isFailed)
                    AnimatedOpacity(
                      opacity: widget.showSlowHint ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 500),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 28),
                        child: Column(
                          children: [
                            Text(
                              'در حال اتصال...',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.55),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'وی‌پی‌ان روشن است؟ خاموشش کنید.',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withValues(alpha: 0.45),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MyApp — The real application after successful initialization
// ─────────────────────────────────────────────────────────────────────────────

class MyApp extends StatefulWidget {
  const MyApp({
    required this.initialRoute,
    required this.supabaseService,
    super.key,
  });

  final String initialRoute;
  final SupabaseService supabaseService;
  static GlobalKey<NavigatorState> get navigatorKey => appNavigatorKey;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final PaymentDeeplinkService _deeplinkService = PaymentDeeplinkService();
  late final ChatUnreadNotifier _chatUnreadNotifier;

  @override
  void initState() {
    super.initState();
    _chatUnreadNotifier = ChatUnreadNotifier();
    PerformanceMonitor.instance.start();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ConnectivityService.instance.initialize();
      _checkGlobalKeyStatus();
      _initializeGuideServices();
      _initializeServices();
      _checkPendingNavigation();
    });
  }

  void _initializeGuideServices() {
    try {
      final guideService = GuideService();
      guideService.initialize();

      final onboardingService = OnboardingService();
      onboardingService.initialize();
    } catch (e) {
      debugPrint('Error initializing guide services: $e');
    }
  }

  void _initializeServices() {
    final context = MyApp.navigatorKey.currentContext;
    if (context == null || !mounted) {
      Future<void>.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _initializeServices();
      });
      return;
    }

    _deeplinkService.initialize(context);
    _deeplinkService.handleInitialLink();

    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _chatUnreadNotifier.initialize(widget.supabaseService);
    });

    Future<void>.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        final scoreService = ScoreService();
        scoreService.init().catchError((Object e) {
          debugPrint('Error initializing ScoreService: $e');
        });
      }
    });
  }

  void _checkPendingNavigation() {
    Future<void>.delayed(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      final navContext = MyApp.navigatorKey.currentContext ?? context;
      if (!navContext.mounted) return;

      try {
        await NotificationNavigationService.checkPendingNavigation(navContext);
      } catch (e) {
        debugPrint('Error in pending navigation: $e');
        Future<void>.delayed(const Duration(seconds: 1), () async {
          if (!mounted) return;
          final retryNavContext = MyApp.navigatorKey.currentContext ?? context;
          if (!retryNavContext.mounted) return;
          try {
            await NotificationNavigationService.checkPendingNavigation(
              retryNavContext,
            );
          } catch (retryError) {
            debugPrint('Error in retry pending navigation: $retryError');
          }
        });
      }
    });
  }

  void _checkGlobalKeyStatus() {
    if (!kDebugMode) return;
    if (GlobalKeyDebugger.hasGlobalKeyIssue()) {
      debugPrint('⚠️ GlobalKey issue detected!');
      GlobalKeyDebugger.printStatus();
    }
  }

  @override
  void dispose() {
    PerformanceMonitor.instance.stop();
    _deeplinkService.dispose();
    _chatUnreadNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SupabaseService>(create: (_) => widget.supabaseService),
        ChangeNotifierProvider<ChatUnreadNotifier>(
          create: (_) => _chatUnreadNotifier,
        ),
        ChangeNotifierProvider<ScoreService>(create: (_) => ScoreService()),
        ChangeNotifierProvider<AchievementService>(
          create: (_) => AchievementService.instance,
        ),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<MusicPlayerService>(
          create: (_) {
            final service = MusicPlayerService();
            service.init().catchError((Object error) {
              debugPrint('Error initializing MusicPlayerService: $error');
            });
            return service;
          },
        ),
        ChangeNotifierProvider<VideoDownloadManager>(
          create: (_) => VideoDownloadManager(),
        ),
        ChangeNotifierProvider<GuideService>(create: (_) => GuideService()),
        ChangeNotifierProvider<OnboardingService>(
          create: (_) => OnboardingService(),
        ),
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => NotificationProvider(),
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        useInheritedMediaQuery: true,
        builder: (context, child) {
          return Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return MaterialApp(
                title: 'GymAI Pro',
                debugShowCheckedModeBanner: false,
                scrollBehavior: WebInteraction.scrollBehavior,
                navigatorKey: appNavigatorKey,
                locale: const Locale('fa'),
                builder: (context, child) {
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  // Cap system text scaling to 1.2 so huge device fonts don't
                  // break fixed-height layouts or clip text silently.
                  final mq = MediaQuery.of(context);
                  final cappedScaler = mq.textScaler.clamp(maxScaleFactor: 1.2);
                  return MediaQuery(
                    data: mq.copyWith(textScaler: cappedScaler),
                    child: ResponsiveBreakpoints.builder(
                      breakpoints: const [
                        Breakpoint(start: 0, end: 450, name: MOBILE),
                        Breakpoint(start: 451, end: 800, name: TABLET),
                        Breakpoint(start: 801, end: 1200, name: DESKTOP),
                        Breakpoint(
                          start: 1201,
                          end: double.infinity,
                          name: '4K',
                        ),
                      ],
                      child: Container(
                        color: isDark ? AppTheme.darkBackgroundColor : null,
                        decoration: isDark
                            ? null
                            : BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    const Color(0xFFDDD0B8),
                                    const Color(0xFFEDE4D4),
                                    AppTheme.lightCardColor,
                                    AppTheme.lightGradientEnd.withValues(
                                      alpha: 0.12,
                                    ),
                                  ],
                                  stops: const [0.0, 0.08, 0.22, 1.0],
                                ),
                              ),
                        child: AppUpdateCoordinator(
                          child: Stack(
                            children: [
                              SafeArea(
                                top: false,
                                child: Directionality(
                                  textDirection: TextDirection.rtl,
                                  child: child ?? const SizedBox.shrink(),
                                ),
                              ),
                              const OfflineBanner(),
                              const VpnWarningBanner(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [Locale('fa'), Locale('en')],
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeProvider.themeMode,
                onGenerateRoute: RouteService.generateRoute,
                // فقط یک مسیر اولیه بساز (نه استکِ پیش‌فرضِ «/»+«/main»)؛
                // در غیر این‌صورت MainNavigationScreen دوبار ساخته می‌شود و همهٔ
                // درخواست‌های شبکه (موزیک، تمرین، مربی، ویدیو) دوبار اجرا می‌شوند.
                onGenerateInitialRoutes: (initialRouteName) => <Route<dynamic>>[
                  RouteService.generateRoute(
                    RouteSettings(name: initialRouteName),
                  ),
                ],
                initialRoute: widget.initialRoute,
              );
            },
          );
        },
      ),
    );
  }
}
