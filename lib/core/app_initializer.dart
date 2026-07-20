import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gymaipro/ai/config/ai_engine_config.dart';
import 'package:gymaipro/ai/services/user_context_cache_service.dart';
import 'package:gymaipro/auth/services/auth_state_service.dart';
import 'package:gymaipro/config/app_config.dart';
import 'package:gymaipro/notification/notification_service.dart';
import 'package:gymaipro/notification/services/private_message_notification_service.dart';
import 'package:gymaipro/profile/repositories/profile_repository.dart';
import 'package:gymaipro/services/ai_exercise_read_service.dart';
import 'package:gymaipro/services/backend_reachability_service.dart';
import 'package:gymaipro/services/connectivity_service.dart';
import 'package:gymaipro/services/database_migration_service.dart';
import 'package:gymaipro/services/exercise_service.dart';
import 'package:gymaipro/services/food_service.dart';
import 'package:gymaipro/services/route_service.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/services/supabase_service.dart';
import 'package:gymaipro/services/video_cache_service.dart';
import 'package:http/http.dart' show Client;
import 'package:http/io_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Handles all application initialization logic
class AppInitializer {
  /// Guards one-time core SDKs (Firebase, Supabase, timezone).
  static bool _coreInitialized = false;

  /// Whether Supabase.initialize() completed successfully.
  static bool _supabaseInitialized = false;
  static bool _backgroundServicesStarted = false;
  static bool _networkHeavyServicesStarted = false;

  /// Check if Supabase is ready before accessing Supabase.instance.
  static bool get isSupabaseReady => _supabaseInitialized;

  /// Maximum time the entire initialization is allowed to take.
  static const Duration _globalTimeout = Duration(seconds: 25);

  /// Initialize all app services and dependencies.
  ///
  /// Safe to call multiple times (idempotent for core SDKs).
  /// Wraps the whole process in a [_globalTimeout] to prevent infinite hangs.
  static Future<AppInitResult> initialize() async {
    try {
      return await _doInitialize().timeout(
        _globalTimeout,
        onTimeout: () {
          if (kDebugMode) {
            debugPrint(
              '⚠️ App initialization timed out after ${_globalTimeout.inSeconds}s — proceeding with best-effort result',
            );
          }
          // Timed out, but core SDKs might be ready.
          // Try to determine route from whatever state we have.
          return _buildBestEffortResult();
        },
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

  /// Build the best possible result when init times out or partially fails.
  static Future<AppInitResult> _buildBestEffortResult() async {
    if (!_supabaseInitialized) {
      final fallbackRoute = await _determineFallbackRouteWithoutSupabase();
      return AppInitResult(
        success: true,
        initialRoute: fallbackRoute,
        supabaseService: SupabaseService(),
      );
    }

    try {
      final authService = AuthStateService();
      final restored = await authService
          .restoreSession()
          .timeout(const Duration(seconds: 10), onTimeout: () => null);
      if (restored != null && !restored.isExpired) {
        if (kDebugMode) {
          debugPrint('Bootstrap best-effort: valid session → /main');
        }
        return AppInitResult(
          success: true,
          initialRoute: '/main',
          supabaseService: SupabaseService(),
        );
      }
    } catch (_) {}

    // Never open /main with an expired/unusable session (broken "کاربر عزیز" UI).
    if (kDebugMode) {
      debugPrint('Bootstrap best-effort: no usable session → /offline');
    }
    return AppInitResult(
      success: true,
      initialRoute: '/offline',
      supabaseService: SupabaseService(),
    );
  }

  static Future<AppInitResult> _doInitialize() async {
    // ── Core SDK init (runs only once) ──
    if (!_coreInitialized) {
      // dotenv must load first (Supabase needs the anon key from it).
      await _loadEnvironmentVariables();
      _configureSystemUI();
      _initializeTimezone();
      // Firebase and Supabase are independent SDKs — initialize concurrently
      // so the Firebase channel setup does not sit on the critical path.
      await Future.wait([
        _initializeFirebase(),
        _initializeSupabase(),
      ]);
      _coreInitialized = true;
    } else {
      // Retry path: first launch may have failed while offline.
      if (!dotenv.isInitialized) {
        await _loadEnvironmentVariables();
      }
      if (!_supabaseInitialized && AppConfig.supabaseAnonKey.isNotEmpty) {
        await _initializeSupabase();
      }
    }

    // Auth first so an expired token is refreshed once before background DB work.
    if (_supabaseInitialized) {
      await _setupAuth();
    }

    // ── Retriable services (safe to call again on retry) ──
    unawaited(_initializeAppServices());

    final initialRoute = _supabaseInitialized
        ? await _determineInitialRoute()
        : await _determineFallbackRouteWithoutSupabase();

    return AppInitResult(
      success: true,
      initialRoute: initialRoute,
      supabaseService: SupabaseService(),
    );
  }

  static Future<void> _loadEnvironmentVariables() async {
    // Release و Web: فقط --dart-define (امنیت).
    if (kReleaseMode || kIsWeb) return;
    if (dotenv.isInitialized) return;

    // اولویت: --dart-define-from-file=.env (بدون نیاز به asset در APK)
    if (AppConfig.supabaseAnonKey.isNotEmpty) {
      debugPrint('✅ Config loaded (--dart-define-from-file)');
      final engine = AiEngineConfig.mode.name;
      final route = AiEngineConfig.usesServerProxyRoute
          ? 'server-proxy'
          : (AppConfig.openaiApiKey.isNotEmpty ? 'direct' : 'none');
      debugPrint('✅ AI engine: $engine (route=$route)');
      return;
    }

    // fallback قدیمی: asset .env (اگر دوباره به pubspec اضافه شود)
    try {
      await dotenv.load();
      debugPrint('✅ Environment variables loaded from .env asset');
      if (AppConfig.supabaseAnonKey.isEmpty) {
        debugPrint('⚠️ SUPABASE_ANON_KEY خالی است');
      }
    } catch (e) {
      debugPrint('❌ Config not loaded: $e');
      debugPrint(
        '   Android/iOS debug: flutter run --dart-define-from-file=.env',
      );
      debugPrint(
        '   یا از Cursor: Run → GymAI Pro (Android / iOS)',
      );
      debugPrint(
        '   یا: .\\scripts\\run-android-debug.ps1',
      );
      debugPrint(
        '   فایل .env: copy .env.example .env و SUPABASE_ANON_KEY را پر کنید',
      );
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
    final Client? httpClient = (!kIsWeb && kDebugMode)
        ? () {
            final io = HttpClient();
            io.badCertificateCallback = (_, __, ___) => true;
            return IOClient(io);
          }()
        : null;

    final anonKey = AppConfig.supabaseAnonKey;
    if (anonKey.isEmpty) {
      _supabaseInitialized = false;
      if (kDebugMode) {
        debugPrint(
          '❌ SUPABASE_ANON_KEY خالی است — درخواست‌ها با 401 (No API key) رد می‌شوند. '
          '.env را لود کنید یا flutter run --dart-define-from-file=.env',
        );
      }
      return;
    }

    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: anonKey,
        httpClient: httpClient,
      ).timeout(const Duration(seconds: 6));
      _supabaseInitialized = true;
    } catch (e) {
      _supabaseInitialized = false;
      if (kDebugMode) {
        debugPrint(
          'Supabase initialization failed/unreachable. Continuing in offline-safe mode: $e',
        );
      }
      return;
    }

    if (kDebugMode) {
      debugPrint('Supabase initialized successfully');
    }

    // Non-critical post-init (safe to fail)
    try {
      _setupAuthStateListener();
    } catch (e) {
      if (kDebugMode) debugPrint('Auth listener setup error: $e');
    }

    // Brief pause for Supabase to restore session from storage (web needs more time).
    await Future<void>.delayed(
      const Duration(milliseconds: kIsWeb ? 350 : 150),
    );

    // Connection warm-up — its result is only used for debug logging, so run it
    // off the critical path. Awaiting it here previously blocked the splash for
    // a full network round-trip (reachability + a profiles SELECT, up to ~5s).
    unawaited(
      _testSupabaseConnection().catchError((Object e) {
        if (kDebugMode) debugPrint('Connection test error: $e');
      }),
    );
  }

  static void _setupAuthStateListener() {
    try {
      Supabase.instance.client.auth.onAuthStateChange.listen(
        (event) {
          try {
            final session = event.session;
            if (kDebugMode) {
              if (session != null) {
                // Intentionally silent for non-null sessions to avoid noisy
                // logs from frequent auth token refresh events.
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
      final canBackend = await ConnectivityService.instance.canReachAppBackend();
      if (!canBackend) {
        if (kDebugMode) {
          debugPrint(
            'Skipping Supabase connection test: no usable network/DNS for backend',
          );
        }
        return;
      }

      // Single attempt with a strict timeout — don't block startup.
      try {
        await Supabase.instance.client
            .from('profiles')
            .select('id')
            .limit(1)
            .timeout(const Duration(seconds: 5));
        if (kDebugMode) {
          debugPrint('Supabase connection test successful');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Supabase connection test failed (non-blocking): $e');
        }
        // Don't retry — auth auto-refresh will recover in the background.
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Supabase connection test error: $e');
      }
    }
  }

  static Future<void> _initializeAppServices() async {
    final canBackend = await ConnectivityService.instance.canReachAppBackend();

    if (!_backgroundServicesStarted) {
      _backgroundServicesStarted = true;

      // Stage background services to reduce startup contention/jank.
      if (!kIsWeb) {
        unawaited(_initVideoCacheService());
        unawaited(
          Future<void>.delayed(const Duration(milliseconds: 1800), () async {
            await _initNotificationService();
          }),
        );
      }
    }

    // Network-heavy services may have been skipped on first offline launch.
    if (canBackend && !_networkHeavyServicesStarted) {
      _networkHeavyServicesStarted = true;
      unawaited(
        Future<void>.delayed(const Duration(milliseconds: 600), () async {
          await _initDatabaseMigrations();
        }),
      );
      unawaited(
        Future<void>.delayed(const Duration(milliseconds: 1400), () async {
          await _initExerciseService();
        }),
      );
      unawaited(
        Future<void>.delayed(const Duration(milliseconds: 2000), () async {
          await _initFoodService();
        }),
      );
      unawaited(
        Future<void>.delayed(const Duration(milliseconds: 2600), () async {
          await _preloadAIExercises();
        }),
      );
    } else if (!canBackend && kDebugMode) {
      debugPrint(
        'Skipping startup network-heavy services (exercise/food/AI preload) due to offline DNS state',
      );
    }
  }

  /// پیش‌بارگذاری تمرینات AI از دیتابیس برای استفاده در تولید برنامه
  static Future<void> _preloadAIExercises() async {
    try {
      final canBackend = await ConnectivityService.instance.canReachAppBackend();
      if (!canBackend) {
        if (kDebugMode) {
          debugPrint(
            'Skipping AI exercises preload: no usable network/DNS for backend',
          );
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
      final canBackend = await ConnectivityService.instance.canReachAppBackend();
      if (!canBackend) {
        if (kDebugMode) {
          debugPrint(
            'Skipping database migrations: no usable network/DNS for backend',
          );
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
      await notificationService.initialize().timeout(
        const Duration(seconds: 4),
        onTimeout: () {
          if (kDebugMode) {
            debugPrint('NotificationService init timed out; continuing startup');
          }
        },
      );
      if (kDebugMode) {
        debugPrint('Notification service initialized');
      }

      final privateMessageNotificationService =
          PrivateMessageNotificationService();
      await privateMessageNotificationService.initialize().timeout(
        const Duration(seconds: 4),
        onTimeout: () {
          if (kDebugMode) {
            debugPrint(
              'PrivateMessageNotificationService init timed out; continuing startup',
            );
          }
        },
      );
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
    if (!_supabaseInitialized) {
      if (kDebugMode) {
        debugPrint('Skipping auth setup: Supabase is not initialized');
      }
      return;
    }
    try {
      final authService = AuthStateService();
      final canUseBackend = await ConnectivityService.instance.canReachAppBackend();

      if (kDebugMode) {
        debugPrint('Setting up auth - Backend reachable (DNS): $canUseBackend');
      }

      // Small delay to let Supabase finish session hydration from storage
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // بازیابی نشست usable (رفرش شکست → null)
      final session = await authService.restoreSession();

      if (session != null) {
        if (kDebugMode) {
          debugPrint(
            'Session restored successfully for user: ${session.user.id}',
          );
        }

        // Heavy profile/cache checks should not block startup route resolution.
        if (canUseBackend) {
          unawaited(_verifyAndRefreshProfileInBackground(session));
        } else if (kDebugMode) {
          debugPrint(
            'No backend DNS/network - skipping profile verification and cache refresh',
          );
        }
      } else {
        if (kDebugMode) {
          debugPrint('No valid session found - user needs offline/login');
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

  static Future<void> _verifyAndRefreshProfileInBackground(Session session) async {
    try {
      final hasProfile = await _verifyUserProfile(session.user.id, session.user)
          .timeout(const Duration(seconds: 5), onTimeout: () => true);
      if (!hasProfile) {
        if (kDebugMode) {
          debugPrint(
            '⚠️ User ${session.user.id} has no complete profile. Keeping session and deferring to route guards.',
          );
        }
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
    }
  }

  /// بررسی وجود پروفایل کاربر
  /// برمی‌گرداند: true اگر پروفایل وجود دارد، false اگر وجود ندارد
  /// هیچ پروفایلی خودکار ساخته نمی‌شود - کاربر باید ثبت‌نام کند
  static Future<bool> _verifyUserProfile(String userId, User user) async {
    try {
      // Unified lookup (profiles.id or auth_user_id), then phone fallback.
      Map<String, dynamic>? profile =
          await ProfileRepository.instance.fetchProfile(userId);
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

  static Future<String> _determineFallbackRouteWithoutSupabase() async {
    try {
      if (kIsWeb) return '/welcome';
      final isOnline = await ConnectivityService.instance.checkNow();
      if (!isOnline) return '/offline';
      final backendReachable = await BackendReachabilityService
          .isBackendReachable();
      return backendReachable ? '/welcome' : '/offline';
    } catch (_) {
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
