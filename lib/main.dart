import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/achievements/services/achievement_service.dart';
import 'package:gymaipro/chat/services/chat_unread_notifier.dart';
import 'package:gymaipro/core/app_error_handler.dart';
import 'package:gymaipro/core/app_initializer.dart';
import 'package:gymaipro/core/lifecycle_observer.dart';
import 'package:gymaipro/debug/global_key_debugger.dart';
import 'package:gymaipro/guide/guide.dart';
import 'package:gymaipro/payment/services/payment_deeplink_service.dart';
import 'package:gymaipro/services/connectivity_service.dart';
import 'package:gymaipro/services/notification_navigation_service.dart';
import 'package:gymaipro/notification/providers/notification_provider.dart';
import 'package:gymaipro/services/route_service.dart';
import 'package:gymaipro/academy/services/music_player_service.dart';
import 'package:gymaipro/services/score_service.dart';
import 'package:gymaipro/services/supabase_service.dart';
import 'package:gymaipro/services/video_download_manager.dart';
import 'package:gymaipro/screens/offline_screen.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/theme/theme_provider.dart';
import 'package:gymaipro/widgets/offline_banner.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize global error handler
  AppErrorHandler.initialize();

  // Professional startup:
  // Don't block first frame by awaiting heavy initialization before runApp.
  // Show a lightweight splash immediately and run initialization in background.
  runApp(
    DevicePreview(
      // DevicePreview enabled in debug mode for testing different screen sizes
      enabled: kDebugMode,
      builder: (context) => const BootstrapApp(),
    ),
  );
}

class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  late Future<AppInitResult> _initFuture;
  late Future<bool> _onlineFuture;

  void _restartInit() {
    setState(() {
      _onlineFuture = ConnectivityService.instance.checkNow();
      _initFuture = AppInitializer.initialize();
    });
  }

  @override
  void initState() {
    super.initState();
    _initFuture = AppInitializer.initialize();
    // Quick connectivity check to show a proper offline UI while heavy init runs.
    _onlineFuture = ConnectivityService.instance.checkNow();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _onlineFuture,
      builder: (context, onlineSnap) {
        // While we're still checking connectivity, keep the splash look (avoid white screen).
        if (onlineSnap.connectionState != ConnectionState.done) {
          return const _BootstrapSplashApp();
        }

        final online = onlineSnap.data;

        // If offline, show offline screen immediately instead of a "white loading".
        if (online == false) {
          return ScreenUtilInit(
            designSize: const Size(375, 812),
            minTextAdapt: true,
            splitScreenMode: true,
            useInheritedMediaQuery: true,
            builder: (context, child) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                home: OfflineScreen(onReconnect: _restartInit),
              );
            },
          );
        }

        return FutureBuilder<AppInitResult>(
          future: _initFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              // Splash while initializing (match native splash to avoid a white flash)
              return const _BootstrapSplashApp();
            }

            final initResult = snapshot.data;
            if (initResult == null || initResult.success != true) {
              // Fail-safe: still boot to offline UI, but don't crash.
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                home: OfflineScreen(onReconnect: _restartInit),
              );
            }

            // Only start lifecycle observers after core services are initialized
            return LifecycleObserver(
              child: MyApp(
                initialRoute: initResult.initialRoute,
                supabaseService: initResult.supabaseService,
              ),
            );
          },
        );
      },
    );
  }
}

class _BootstrapSplashApp extends StatelessWidget {
  const _BootstrapSplashApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _BootstrapSplashScreen(),
    );
  }
}

class _BootstrapSplashScreen extends StatelessWidget {
  const _BootstrapSplashScreen();

  static const Color _bg = Color(0xFF0A0A0A);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: _bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image(image: AssetImage('images/mainlogo_no_bg.png'), width: 160),
            SizedBox(height: 24),
            SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({
    required this.initialRoute,
    required this.supabaseService,
    super.key,
  });

  final String initialRoute;
  final SupabaseService supabaseService;
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // One-time initialization (avoid doing this in build, it can repeat)
      ConnectivityService.instance.initialize();
      _initializeServices();
      _checkPendingNavigation();
      _checkGlobalKeyStatus();
      _initializeGuideServices();
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

    final scoreService = ScoreService();
    scoreService.init().catchError((Object e) {
      debugPrint('Error initializing ScoreService: $e');
    });
  }

  void _checkPendingNavigation() {
    Future<void>.delayed(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      final navContext = MyApp.navigatorKey.currentContext ?? context;
      if (navContext == null) return;

      try {
        await NotificationNavigationService.checkPendingNavigation(navContext);
      } catch (e) {
        debugPrint('Error in pending navigation: $e');
        Future<void>.delayed(const Duration(seconds: 1), () async {
          if (!mounted) return;
          final retryNavContext = MyApp.navigatorKey.currentContext ?? context;
          if (retryNavContext == null) return;
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
    if (GlobalKeyDebugger.hasGlobalKeyIssue()) {
      debugPrint('⚠️ GlobalKey issue detected!');
      GlobalKeyDebugger.printStatus();
    }
  }

  @override
  void dispose() {
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
            // Initialize asynchronously to avoid blocking UI thread
            // The service will initialize when first accessed
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
                navigatorKey: MyApp.navigatorKey,
                // Device Preview settings
                useInheritedMediaQuery: true,
                locale: DevicePreview.locale(context),
                builder: (context, child) {
                  // First apply DevicePreview builder
                  final devicePreviewChild = DevicePreview.appBuilder(
                    context,
                    child,
                  );

                  // Then apply our custom builder
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  return ResponsiveBreakpoints.builder(
                    breakpoints: const [
                      Breakpoint(start: 0, end: 450, name: MOBILE),
                      Breakpoint(start: 451, end: 800, name: TABLET),
                      Breakpoint(start: 801, end: 1200, name: DESKTOP),
                      Breakpoint(start: 1201, end: double.infinity, name: '4K'),
                    ],
                    child: Container(
                      color: isDark ? AppTheme.darkBackgroundColor : null,
                      decoration: isDark
                          ? null
                          : BoxDecoration(
                              // گرادیانت عمودی: بالا پررنگ‌تر (نوار ساعت خوانا) → پایین روشن
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  const Color(
                                    0xFFDDD0B8,
                                  ), // نوار بالا: کرم طلایی پررنگ
                                  const Color(0xFFEDE4D4), // نرم
                                  AppTheme.lightCardColor,
                                  AppTheme.lightGradientEnd.withValues(
                                    alpha: 0.12,
                                  ),
                                ],
                                stops: const [0.0, 0.08, 0.22, 1.0],
                              ),
                            ),
                      child: Stack(
                        children: [
                          SafeArea(
                            top: false,
                            child: Directionality(
                              textDirection: TextDirection.rtl,
                              child: devicePreviewChild,
                            ),
                          ),
                          const OfflineBanner(),
                        ],
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
                initialRoute: widget.initialRoute,
              );
            },
          );
        },
      ),
    );
  }
}
