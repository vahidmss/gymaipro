import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' show Client;
import 'package:http/io_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gymaipro/ai/services/user_context_cache_service.dart';
import 'package:gymaipro/auth/services/auth_state_service.dart';
import 'package:gymaipro/config/app_config.dart';
import 'package:gymaipro/services/connectivity_service.dart';
import 'package:gymaipro/services/database_migration_service.dart';
import 'package:gymaipro/services/exercise_service.dart';
import 'package:gymaipro/services/food_service.dart';
import 'package:gymaipro/services/route_service.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/services/supabase_service.dart';
import 'package:gymaipro/services/video_cache_service.dart';
import 'package:gymaipro/services/ai_exercise_read_service.dart';
import 'package:gymaipro/notification/notification_service.dart';
import 'package:gymaipro/notification/services/private_message_notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Handles all application initialization logic
class AppInitializer {
  /// Initialize all app services and dependencies
  static Future<AppInitResult> initialize() async {
    try {
      // Load environment variables
      await _loadEnvironmentVariables();

      // Configure system UI
      _configureSystemUI();

      // Initialize Firebase
      await _initializeFirebase();

      // Initialize timezone
      _initializeTimezone();

      // Initialize Supabase
      await _initializeSupabase();

      // Initialize app services
      await _initializeAppServices();

      // Setup auth
      await _setupAuth();

      // Determine initial route
      final initialRoute = await _determineInitialRoute();

      return AppInitResult(
        success: true,
        initialRoute: initialRoute,
        supabaseService: SupabaseService(),
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error during app initialization: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      return AppInitResult(
        success: false,
        initialRoute: '/welcome',
        supabaseService: SupabaseService(),
      );
    }
  }

  static Future<void> _loadEnvironmentVariables() async {
    try {
      await dotenv.load(fileName: '.env');
      if (kDebugMode) {
        debugPrint('✅ Environment variables loaded successfully');
        final openaiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
        if (openaiKey.isEmpty) {
          debugPrint(
            '⚠️ OPENAI_API_KEY is empty in .env – add OPENAI_API_KEY=sk-... to your .env file and restart the app',
          );
        } else {
          debugPrint('✅ OPENAI_API_KEY found (length: ${openaiKey.length})');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Could not load .env file: $e');
        debugPrint(
          '   Ensure .env exists in project root (copy from .env.example) and contains OPENAI_API_KEY=sk-...',
        );
        debugPrint(
          '   Or run with: flutter run --dart-define=OPENAI_API_KEY=sk-...',
        );
      }
    }
  }

  static void _configureSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
    );
  }

  static Future<void> _initializeFirebase() async {
    try {
      if (kIsWeb) {
        if (kDebugMode) {
          debugPrint('Skipping Firebase initialization for web');
        }
      } else {
        await Firebase.initializeApp();
        if (kDebugMode) {
          debugPrint('Firebase initialized successfully');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error initializing Firebase: $e');
      }
    }
  }

  static void _initializeTimezone() {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Tehran'));
    if (kDebugMode) {
      debugPrint('Timezone initialized for Tehran');
    }
  }

  static Future<void> _initializeSupabase() async {
    try {
      // در حالت Debug، اگر Hostname mismatch (امولاتور/پروکسی/شبکه) رخ دهد، یک کلاینت که گواهی را نادیده می‌گیرد استفاده می‌شود.
      // فقط برای توسعه؛ در Release این کار انجام نمی‌شود.
      final Client? httpClient = kDebugMode
          ? () {
              final io = HttpClient();
              io.badCertificateCallback = (_, __, ___) => true;
              return IOClient(io);
            }()
          : null;

      // فعال‌سازی autoRefreshToken برای مدیریت خودکار نشست
      // این باعث می‌شود نشست‌ها به صورت خودکار refresh شوند و کاربر نیازی به لاگین مجدد نداشته باشد
      // persistSession به صورت پیش‌فرض فعال است در Supabase Flutter SDK
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
        httpClient: httpClient,
        authOptions: const FlutterAuthClientOptions(
          autoRefreshToken: true, // فعال‌سازی رفرش خودکار توکن
        ),
      );

      if (kDebugMode) {
        debugPrint(
          'Supabase initialized successfully with auto-refresh enabled',
        );
      }

      // Setup auth state listener
      _setupAuthStateListener();

      // منتظر بمان تا Supabase session را از storage بازیابی کند
      // این مهم است چون session restoration به صورت asynchronous انجام می‌شود
      await Future<void>.delayed(const Duration(milliseconds: 300));

      // Test connection if online
      await _testSupabaseConnection();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error initializing Supabase: $e');
      }
    }
  }

  static void _setupAuthStateListener() {
    try {
      Supabase.instance.client.auth.onAuthStateChange.listen(
        (event) {
          try {
            final session = event.session;
            if (kDebugMode) {
              if (session != null) {
                debugPrint('Auth state changed: ${event.event}');
                debugPrint('Session user ID: ${session.user.id}');
                debugPrint('Session expired: ${session.isExpired}');
                if (session.isExpired) {
                  debugPrint(
                    'Session expired - auto-refresh will attempt to restore',
                  );
                }
              } else {
                debugPrint(
                  'Auth state changed: ${event.event} - Session cleared',
                );
              }
            }
          } catch (e, stackTrace) {
            if (kDebugMode) {
              debugPrint('Auth listener callback error: $e');
              debugPrint('Stack trace: $stackTrace');
            }
          }
        },
        onError: (Object error, [StackTrace? stackTrace]) {
          if (kDebugMode) {
            final errorString = error.toString();
            if (_isNetworkError(errorString)) {
              debugPrint(
                'Network error detected in auth listener - continuing in offline mode',
              );
            } else {
              debugPrint('Auth listener error: $error');
            }
          }
        },
        cancelOnError: false,
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Auth listener setup failed: $e');
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }

  static bool _isNetworkError(String errorString) {
    return errorString.contains('SocketException') ||
        errorString.contains('Failed host lookup') ||
        errorString.contains('AuthRetryableFetchException') ||
        errorString.contains('ClientException') ||
        errorString.contains('No address associated with hostname');
  }

  static Future<void> _testSupabaseConnection() async {
    try {
      final isOnline = await ConnectivityService.instance.checkNow();
      if (!isOnline) {
        if (kDebugMode) {
          debugPrint('Offline mode: Skipping connection test');
        }
        return;
      }

      bool connectionSuccessful = false;
      int retryCount = 0;
      const maxRetries = 3;

      while (!connectionSuccessful && retryCount < maxRetries) {
        try {
          await Supabase.instance.client.from('profiles').select('id').limit(1);
          connectionSuccessful = true;
          if (kDebugMode) {
            debugPrint('Supabase connection test successful');
          }
        } catch (e) {
          retryCount++;
          if (kDebugMode) {
            debugPrint(
              'Supabase connection test failed (attempt $retryCount): $e',
            );
          }
          if (retryCount < maxRetries) {
            await Future<void>.delayed(Duration(seconds: retryCount * 2));
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Supabase connection test failed: $e');
      }
    }
  }

  static Future<void> _initializeAppServices() async {
    unawaited(
      Future.wait([
            _initExerciseService(),
            _initFoodService(),
            _initVideoCacheService(),
            _initDatabaseMigrations(),
            _initNotificationService(),
            _preloadAIExercises(),
          ])
          .then((_) {
            if (kDebugMode) {
              debugPrint('All initialization services completed');
            }
          })
          .catchError((Object error) {
            if (kDebugMode) {
              debugPrint('Error in initialization services: $error');
            }
          }),
    );
  }

  /// پیش‌بارگذاری تمرینات AI از دیتابیس برای استفاده در تولید برنامه
  static Future<void> _preloadAIExercises() async {
    try {
      final isOnline = await ConnectivityService.instance.checkNow();
      if (!isOnline) {
        if (kDebugMode) {
          debugPrint('Skipping AI exercises preload: offline');
        }
        return;
      }

      // بارگذاری تمرینات از دیتابیس برای استفاده در AI
      final exercises = await AIExerciseReadService().getExercisesForAI();
      if (kDebugMode) {
        debugPrint('AI exercises preloaded: ${exercises.length} exercises');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error preloading AI exercises: $e');
      }
    }
  }

  static Future<void> _initExerciseService() async {
    try {
      await ExerciseService.initAll();
      if (kDebugMode) {
        debugPrint('Exercise service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error initializing exercise service: $e');
      }
    }
  }

  static Future<void> _initFoodService() async {
    try {
      await FoodService.initAll();
      if (kDebugMode) {
        debugPrint('Food service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error initializing food service: $e');
      }
    }
  }

  static Future<void> _initVideoCacheService() async {
    try {
      await VideoCacheService().initialize();
      if (kDebugMode) {
        debugPrint('Video cache service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error initializing video cache service: $e');
      }
    }
  }

  static Future<void> _initDatabaseMigrations() async {
    try {
      final isOnline = await ConnectivityService.instance.checkNow();
      if (!isOnline) {
        if (kDebugMode) {
          debugPrint('Skipping database migrations: offline');
        }
        return;
      }
      await DatabaseMigrationService.runMigrations();
      if (kDebugMode) {
        debugPrint('Database migrations completed');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error running database migrations: $e');
      }
    }
  }

  static Future<void> _initNotificationService() async {
    try {
      final notificationService = NotificationService();
      await notificationService.initialize();
      if (kDebugMode) {
        debugPrint('Notification service initialized');
      }

      final privateMessageNotificationService =
          PrivateMessageNotificationService();
      await privateMessageNotificationService.initialize();
      if (kDebugMode) {
        debugPrint('Private message notification service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error initializing notification service: $e');
      }
    }
  }

  static Future<void> _setupAuth() async {
    try {
      final authService = AuthStateService();
      final isOnline = await ConnectivityService.instance.checkNow();

      if (kDebugMode) {
        debugPrint('Setting up auth - Online: $isOnline');
      }

      // منتظر بمان تا Supabase session را از storage بازیابی کند
      // این اطمینان می‌دهد که session قبل از بررسی، به طور کامل بازیابی شده است
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // تلاش برای بازیابی نشست (حتی در حالت آفلاین)
      final session = await authService.restoreSession();

      if (session != null) {
        if (kDebugMode) {
          debugPrint(
            'Session restored successfully for user: ${session.user.id}',
          );
        }

        // Subscribe to 'all' topic after session restore to ensure broadcast notifications work
        try {
          await NotificationService().forceSubscribeToAll();
          if (kDebugMode) {
            debugPrint('✅ Subscribed to topic "all" after session restore');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
              '⚠️ Error subscribing to topic "all" after session restore: $e',
            );
          }
        }

        // اگر آنلاین هستیم، پروفایل و کش را به‌روزرسانی کن
        if (isOnline) {
          try {
            final hasProfile = await _verifyUserProfile(
              session.user.id,
              session.user,
            );
            if (!hasProfile) {
              if (kDebugMode) {
                debugPrint(
                  '⚠️ User ${session.user.id} has no complete profile. Keeping session and redirecting to registration flow.',
                );
              }
              // IMPORTANT: Do NOT sign out here. Professional apps keep the session and
              // route the user to a profile completion/registration flow instead.
              return;
            }
            await _refreshUserContextCache();
            if (kDebugMode) {
              debugPrint('User profile and cache refreshed successfully');
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('Error refreshing profile/cache: $e');
            }
            // IMPORTANT: Do NOT sign out on transient errors. Keep session and let routing handle it.
          }
        } else {
          if (kDebugMode) {
            debugPrint(
              'Offline mode - skipping profile verification and cache refresh',
            );
          }
        }
      } else {
        if (kDebugMode) {
          debugPrint('No valid session found - user needs to login');
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error setting up auth: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      // در صورت خطا، به کاربر اجازه می‌دهیم به صفحه welcome برود
    }
  }

  /// بررسی وجود پروفایل کاربر
  /// برمی‌گرداند: true اگر پروفایل وجود دارد، false اگر وجود ندارد
  /// هیچ پروفایلی خودکار ساخته نمی‌شود - کاربر باید ثبت‌نام کند
  static Future<bool> _verifyUserProfile(String userId, User user) async {
    try {
      // First, try the direct lookup by auth.user.id (newer schema expectation)
      Map<String, dynamic>? profile = await Supabase.instance.client
          .from('profiles')
          .select('id, username')
          .eq('id', userId)
          .maybeSingle();

      // If not found, fallback to our unified profile resolver (supports phone fallback)
      profile ??= await SimpleProfileService.getCurrentProfile();

      if (profile == null) {
        if (kDebugMode) {
          debugPrint(
            '⚠️ No profile found for user: $userId (anonymous: ${user.isAnonymous}). '
            'User must complete registration.',
          );
        }
        return false;
      }

      // بررسی اینکه username وجود دارد یا نه
      final username = profile['username'] as String?;
      if (username == null ||
          username.isEmpty ||
          username.startsWith('user_')) {
        if (kDebugMode) {
          debugPrint(
            '⚠️ User $userId has invalid or default username: "$username". '
            'User must complete registration.',
          );
        }
        return false;
      }

      if (kDebugMode) {
        debugPrint(
          '✅ Profile verified for user: $userId (username: $username)',
        );
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error verifying user profile: $e');
      }
      return false;
    }
  }

  static Future<void> _refreshUserContextCache() async {
    try {
      await UserContextCacheService.refreshUserContextCache();
      if (kDebugMode) {
        debugPrint('AI Context Cache refreshed');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error refreshing AI Context Cache: $e');
      }
    }
  }

  static Future<String> _determineInitialRoute() async {
    try {
      return await RouteService.getInitialRoute();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error determining initial route: $e');
      }
      return '/welcome';
    }
  }
}

/// Result of app initialization
class AppInitResult {
  const AppInitResult({
    required this.success,
    required this.initialRoute,
    required this.supabaseService,
  });

  final bool success;
  final String initialRoute;
  final SupabaseService supabaseService;
}
