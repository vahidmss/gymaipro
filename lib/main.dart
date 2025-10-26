import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/auth/services/auth_state_service.dart';
import 'package:gymaipro/chat/services/chat_unread_notifier.dart';
import 'package:gymaipro/config/app_config.dart';
import 'package:gymaipro/core/lifecycle_observer.dart';
import 'package:gymaipro/debug/global_key_debugger.dart';
import 'package:gymaipro/notification/notification_service.dart';
import 'package:gymaipro/notification/services/private_message_notification_service.dart';
import 'package:gymaipro/payment/services/payment_deeplink_service.dart';
import 'package:gymaipro/services/connectivity_service.dart';
import 'package:gymaipro/services/database_migration_service.dart';
import 'package:gymaipro/services/exercise_service.dart';
import 'package:gymaipro/services/food_service.dart';
import 'package:gymaipro/services/notification_navigation_service.dart';
import 'package:gymaipro/services/route_service.dart';
import 'package:gymaipro/services/supabase_service.dart';
import 'package:gymaipro/services/video_cache_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/widgets/offline_banner.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // بهینه‌سازی عملکردyes

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  // محدود کردن جهت صفحه برای بهبود تجربه کاربری
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  if (kDebugMode) print('Starting application...');

  // Initialize Firebase early to avoid [core/no-app] errors
  try {
    if (kIsWeb) {
      // For web, Firebase needs to be initialized with options
      // Skip Firebase initialization for web to avoid errors
      if (kDebugMode) print('Skipping Firebase initialization for web');
    } else {
      await Firebase.initializeApp();
      if (kDebugMode) print('Firebase initialized in main.dart');
    }
  } catch (e) {
    if (kDebugMode) print('Error initializing Firebase in main.dart: $e');
  }

  // Initialize timezone
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Tehran'));
  if (kDebugMode) print('Timezone initialized for Tehran');

  // Initialize Supabase
  try {
    if (kDebugMode) {
      print('Initializing Supabase with URL: ${AppConfig.supabaseUrl}');
    }
    if (kDebugMode) {
      print('Anon Key is set: ${AppConfig.supabaseAnonKey.isNotEmpty}');
    }

    // Check connectivity before initializing Supabase
    final isOnline = await ConnectivityService.instance.checkNow();
    if (isOnline) {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
      );
      if (kDebugMode) print('Supabase initialized successfully');
    } else {
      if (kDebugMode) print('Offline mode: Skipping Supabase initialization');
      // Initialize Supabase in offline mode with minimal config
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
      );
      if (kDebugMode) print('Supabase initialized in offline mode');
    }

    // Persist session via auth state change listener (redundant with SDK storage but explicit)
    try {
      Supabase.instance.client.auth.onAuthStateChange.listen((event) async {
        final session = event.session;
        if (kDebugMode) {
          print(
            '=== AUTH LISTENER: event=${event.event} session=${session != null} ===',
          );
        }
        // SDK خودش session را ذخیره می‌کند؛ اینجا فقط لاگ می‌زنیم
      });
    } catch (e) {
      if (kDebugMode) print('Auth listener setup failed (offline mode): $e');
    }

    // Test connection (only if we appear online)
    try {
      final isOnline = await ConnectivityService.instance.checkNow();
      if (isOnline) {
        // Retry mechanism for network failures
        bool connectionSuccessful = false;
        int retryCount = 0;
        const maxRetries = 3;

        while (!connectionSuccessful && retryCount < maxRetries) {
          try {
            await Supabase.instance.client
                .from('profiles')
                .select('id')
                .limit(1);
            connectionSuccessful = true;
            if (kDebugMode) print('Supabase connection test successful');
          } catch (e) {
            retryCount++;
            if (kDebugMode) {
              print(
                'Supabase connection test failed (attempt $retryCount): $e',
              );
            }
            if (retryCount < maxRetries) {
              await Future<void>.delayed(Duration(seconds: retryCount * 2));
            }
          }
        }

        if (!connectionSuccessful) {
          if (kDebugMode) {
            print('Supabase connection failed after $maxRetries attempts');
          }
        }
      } else {
        if (kDebugMode) print('Offline mode: Skipping connection test');
      }
    } catch (e) {
      if (kDebugMode) print('Supabase connection test failed: $e');
    }

    // اولیه‌سازی سرویس‌های اپلیکیشن - به صورت موازی
    unawaited(
      Future.wait([
            _initExerciseService(),
            _initFoodService(),
            _initVideoCacheService(),
            // Only run migrations if online; otherwise skip silently
            () async {
              final isOnline = await ConnectivityService.instance.checkNow();
              if (!isOnline) {
                if (kDebugMode) {
                  print('Skipping database migrations: offline');
                }
                return;
              }
              await _runDatabaseMigrations();
            }(),
            _initNotificationService(),
          ])
          .then((_) {
            if (kDebugMode) print('All initialization services completed');
          })
          .catchError((Object error) {
            if (kDebugMode) print('Error in initialization services: $error');
          }),
    );
  } catch (e) {
    if (kDebugMode) print('Error initializing Supabase: $e');
    if (kDebugMode) print('Error details: $e');
  }

  // Auth service setup
  final authService = AuthStateService();
  try {
    // Check connectivity before auth operations
    final isOnline = await ConnectivityService.instance.checkNow();

    // Check current authentication state
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (kDebugMode) {
      print('Current user at startup: ${currentUser?.id ?? "None"}');
    }

    final session = await authService.restoreSession();
    if (kDebugMode) print('Session restored: ${session != null}');

    if (session != null) {
      if (kDebugMode) print('User is logged in: ${session.user.id}');

      // Only verify profile if online
      if (isOnline) {
        try {
          final profile = await Supabase.instance.client
              .from('profiles')
              .select()
              .eq('id', session.user.id)
              .maybeSingle();

          if (profile != null) {
            if (kDebugMode) print('User profile found: ${profile['username']}');
          } else {
            if (kDebugMode) {
              print(
                'Warning: No profile found for authenticated user, creating one...',
              );
            }

            // تلاش برای ایجاد پروفایل مفقود
            try {
              final tempSupabaseService = SupabaseService();
              final created = await tempSupabaseService.ensureProfileExists(
                session.user.id,
              );
              if (created) {
                if (kDebugMode) {
                  print('Profile created successfully for existing user');
                }
              } else {
                if (kDebugMode) {
                  print('Failed to create profile for existing user');
                }
              }
            } catch (profileCreationError) {
              if (kDebugMode) {
                print('Error creating missing profile: $profileCreationError');
              }
            }
          }
        } catch (e) {
          if (kDebugMode) print('Error checking user profile: $e');
        }
      } else {
        if (kDebugMode) print('Offline mode: Skipping profile verification');
      }
    } else {
      if (kDebugMode) print('No active session found');
    }
  } catch (e) {
    if (kDebugMode) print('Error restoring session: $e');
  }

  // Determine initial route
  String initialRoute = '/welcome'; // Default to welcome screen
  try {
    if (kDebugMode) print('=== MAIN: About to call getInitialRoute() ===');

    // Check connectivity before determining route
    final isOnline = await ConnectivityService.instance.checkNow();
    if (isOnline) {
      initialRoute = await RouteService.getInitialRoute();
    } else {
      if (kDebugMode) print('=== MAIN: Offline mode, using cached route ===');
      // In offline mode, try to get route from cache or use default
      try {
        initialRoute = await RouteService.getInitialRoute();
      } catch (e) {
        if (kDebugMode) print('=== MAIN: Error getting cached route: $e ===');
        initialRoute = '/welcome';
      }
    }

    if (kDebugMode) {
      print('=== MAIN: Initial route determined: $initialRoute ===');
    }

    // بررسی نهایی وضعیت احراز هویت
    if (kDebugMode) {
      final authService = AuthStateService();
      final isLoggedIn = await authService.isLoggedIn();
      print('=== MAIN: Final login status check: $isLoggedIn ===');

      final currentUser = Supabase.instance.client.auth.currentUser;
      print('=== MAIN: Final current user: ${currentUser?.id ?? "null"} ===');
    }
  } catch (e) {
    if (kDebugMode) print('=== MAIN: Error determining initial route: $e ===');
    if (kDebugMode) print('=== MAIN: Using default route: /welcome ===');
  }

  // ساخت یک نمونه از SupabaseService
  final supabaseService = SupabaseService();

  runApp(
    LifecycleObserver(
      child: MyApp(
        initialRoute: initialRoute,
        supabaseService: supabaseService,
      ),
    ),
  );
}

// اولیه‌سازی سرویس تمرین‌ها به صورت جداگانه
Future<void> _initExerciseService() async {
  try {
    await ExerciseService.initAll();
    if (kDebugMode) print('Exercise service initialized successfully');
  } catch (e) {
    if (kDebugMode) print('Error initializing exercise service: $e');
  }
}

// اولیه‌سازی سرویس خوراکی‌ها به صورت جداگانه
Future<void> _initFoodService() async {
  try {
    await FoodService.initAll();
    if (kDebugMode) print('Food service initialized successfully');
  } catch (e) {
    if (kDebugMode) print('Error initializing food service: $e');
  }
}

// اولیه‌سازی سرویس کش ویدیو به صورت جداگانه
Future<void> _initVideoCacheService() async {
  try {
    await VideoCacheService().initialize();
    if (kDebugMode) print('Video cache service initialized successfully');
  } catch (e) {
    if (kDebugMode) print('Error initializing video cache service: $e');
  }
}

// اجرای مهاجرت‌های پایگاه داده به صورت جداگانه
Future<void> _runDatabaseMigrations() async {
  try {
    await DatabaseMigrationService.runMigrations();
    if (kDebugMode) print('Database migrations completed');
  } catch (e) {
    if (kDebugMode) print('Error running database migrations: $e');
  }
}

// اولیه‌سازی سرویس نوتیفیکیشن به صورت جداگانه
Future<void> _initNotificationService() async {
  try {
    final notificationService = NotificationService();
    await notificationService.initialize();
    if (kDebugMode) print('Notification service initialized successfully');

    // مقداردهی سرویس نوتیفیکیشن پیام‌های شخصی
    final privateMessageNotificationService =
        PrivateMessageNotificationService();
    await privateMessageNotificationService.initialize();
    if (kDebugMode) {
      print('Private message notification service initialized successfully');
    }
  } catch (e) {
    if (kDebugMode) print('Error initializing notification service: $e');
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
    debugPrint('=== MAIN: initState called ===');
    GlobalKeyDebugger.logNavigationAttempt('main_initState');

    // ایجاد ChatUnreadNotifier فقط یک بار
    _chatUnreadNotifier = ChatUnreadNotifier();
    debugPrint('=== MAIN: ChatUnreadNotifier created ===');
    GlobalKeyDebugger.logChatUnreadNotifierCall('main_initState');

    // تنظیم سرویس‌ها بعد از ساخت MaterialApp
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('=== MAIN: PostFrameCallback executing ===');
      GlobalKeyDebugger.logNavigationAttempt('main_postFrameCallback');

      // کانتکست امن داخل MaterialApp
      final innerContext = MyApp.navigatorKey.currentContext;

      if (innerContext != null && mounted) {
        // مقداردهی PaymentDeeplinkService با کانتکستِ داخل MaterialApp
        _deeplinkService.initialize(innerContext);
        _deeplinkService.handleInitialLink();
        debugPrint('=== MAIN: PaymentDeeplinkService initialized ===');

        // مقداردهی ChatUnreadNotifier
        _chatUnreadNotifier.initialize(widget.supabaseService);
        debugPrint('=== MAIN: ChatUnreadNotifier initialized ===');
        GlobalKeyDebugger.logChatUnreadNotifierCall('main_postFrameCallback');
      } else {
        // اگر هنوز Navigator آماده نیست، کمی بعد تلاش مجدد
        Future.delayed(const Duration(milliseconds: 100), () {
          final retryContext = MyApp.navigatorKey.currentContext;
          if (retryContext != null && mounted) {
            _deeplinkService.initialize(retryContext);
            _deeplinkService.handleInitialLink();
            _chatUnreadNotifier.initialize(widget.supabaseService);
            debugPrint('=== MAIN: Initialized services after retry ===');
          } else {
            debugPrint(
              '=== MAIN: Navigator context still null; skipping init ===',
            );
          }
        });
      }

      // بررسی pending navigation با تأخیر کمتر و retry mechanism
      Future.delayed(const Duration(milliseconds: 300), () async {
        try {
          debugPrint('=== MAIN: Checking pending navigation ===');
          GlobalKeyDebugger.logNavigationAttempt('main_pendingNavigation');
          final navContext = MyApp.navigatorKey.currentContext ?? context;
          await NotificationNavigationService.checkPendingNavigation(
            navContext,
          );
          debugPrint('=== MAIN: Pending navigation checked ===');
        } catch (e) {
          debugPrint('Error in pending navigation: $e');
          // تلاش مجدد بعد از 1 ثانیه
          Future.delayed(const Duration(seconds: 1), () async {
            try {
              debugPrint('=== MAIN: Retrying pending navigation ===');
              final retryNavContext =
                  MyApp.navigatorKey.currentContext ?? context;
              await NotificationNavigationService.checkPendingNavigation(
                retryNavContext,
              );
            } catch (retryError) {
              debugPrint('Error in retry pending navigation: $retryError');
            }
          });
        }
      });

      // چک کردن وضعیت GlobalKey
      if (GlobalKeyDebugger.hasGlobalKeyIssue()) {
        debugPrint('=== MAIN: ⚠️ GlobalKey issue detected! ===');
        GlobalKeyDebugger.printStatus();
      }
    });
  }

  @override
  void dispose() {
    _deeplinkService.dispose();
    _chatUnreadNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Initialize connectivity monitoring once the app builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ConnectivityService.instance.initialize();

      // اطمینان از آماده بودن GlobalKey
      Future.delayed(const Duration(milliseconds: 500), () {
        if (MyApp.navigatorKey.currentState != null) {
          debugPrint('=== MAIN: NavigatorKey is ready ===');
        } else {
          debugPrint('=== MAIN: NavigatorKey is not ready yet ===');
        }
      });
    });
    return MultiProvider(
      providers: [
        Provider<SupabaseService>(create: (_) => widget.supabaseService),
        ChangeNotifierProvider<ChatUnreadNotifier>(
          create: (_) => _chatUnreadNotifier,
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812), // iPhone X design size
        minTextAdapt: true,
        splitScreenMode: true,
        useInheritedMediaQuery: true,
        builder: (context, child) {
          return MaterialApp(
            title: 'GymAI Pro',
            debugShowCheckedModeBanner: false,
            navigatorKey: MyApp.navigatorKey,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('fa'), Locale('en')],
            locale: const Locale('fa'),
            theme: ThemeData(
              scaffoldBackgroundColor: AppTheme.backgroundColor,
              appBarTheme: AppBarTheme(
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: const IconThemeData(color: AppTheme.goldColor),
                titleTextStyle: AppTheme.headingStyle,
              ),
              textTheme: TextTheme(
                bodyLarge: AppTheme.bodyStyle,
                bodyMedium: AppTheme.bodyStyle,
              ),
              colorScheme: const ColorScheme.dark(
                primary: AppTheme.goldColor,
                secondary: AppTheme.darkGold,
                surface: AppTheme.cardColor,
              ),
            ),
            // تنظیم RTL برای تمام اپلیکیشن
            builder: (context, child) {
              return ResponsiveBreakpoints.builder(
                breakpoints: [
                  const Breakpoint(start: 0, end: 450, name: MOBILE),
                  const Breakpoint(start: 451, end: 800, name: TABLET),
                  const Breakpoint(start: 801, end: 1200, name: DESKTOP),
                  const Breakpoint(
                    start: 1201,
                    end: double.infinity,
                    name: '4K',
                  ),
                ],
                child: Stack(
                  children: [
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: child!,
                    ),
                    const OfflineBanner(),
                  ],
                ),
              );
            },
            onGenerateRoute: RouteService.generateRoute,
            initialRoute: widget.initialRoute,
          );
        },
      ),
    );
  }
}
