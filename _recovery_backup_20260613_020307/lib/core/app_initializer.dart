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
import 'package:gymaipro/services/backend_reachability_service.dart';
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
  /// Guards one-time core SDKs (Firebase, Supabase, timezone).
  static bool _coreInitialized = false;

  /// Whether Supabase.initialize() completed successfully.
  static bool _supabaseInitialized = false;

  /// Check if Supabase is ready before accessing Supabase.instance.
  static bool get isSupabaseReady => _supabaseInitialized;

  /// Maximum time the entire initialization is allowed to take.
  static const Duration _globalTimeout = Duration(seconds: 10);

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
      final route = await _determineInitialRoute().timeout(
        const Duration(seconds: 2),
        onTimeout: () => '/welcome',
      );
      return AppInitResult(
        success: true,
        initialRoute: route,
        supabaseService: SupabaseService(),
      );
    } catch (_) {
      return AppInitResult(
        success: false,
        initialRoute: '/welcome',
        supabaseService: SupabaseService(),
      );
    }
  }

  static Future<AppInitResult> _doInitialize() async {
    // ── Core SDK init (runs only once) ──
    if (!_coreInitialized) {
      await _loadEnvironmentVariables();
      _configureSystemUI();
      await _initializeFirebase();
      _initializeTimezone();
      await _initializeSupabase();
      _coreInitialized = true;
    }

    // ── Retriable services (safe to call again on retry) ──
    // Fire-and-forget for non-critical services
    _initializeAppServices();

    // Auth & routing (must complete before we can navigate)
    // If Supabase is unreachable, we still allow app startup in offline-safe mode.
    if (_supabaseInitialized) {
      await _setupAuth();
    }

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
    final Client? httpClient = kDebugMode
        ? () {
            final io = HttpClient();
            io.badCertificateCallback = (_, __, ___) => true;
            return IOClient(io);
          }()
        : null;

    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
        httpClient: httpClient,
        authOptions: const FlutterAuthClientOptions(
          autoRefreshToken: true,
        ),
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

    // Brief pause for Supabase to restore session from storage
    await Future<void>.delayed(const Duration(milliseconds: 150));

    // Non-blocking connection test
    try {
      await _testSupabaseConnection();
    } catch (e) {
      if (kDebugMode) debugPrint('Connection test error: $e');
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
      final isOnline = await ConnectivityService.instance.checkNow();

      if (kDebugMode) {
        debugPrint('Setting up auth - Online: $isOnline');
      }

      // Small delay to let Supabase finish session hydration from storage
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // تلاش برای بازیابی نشست (حتی در حالت آفلاین)
      final session = await authService.restoreSession();

      if (session != null) {
        if (kDebugMode) {
          debugPrint(
            'Session restored successfully for user: ${session.user.id}',
          );
        }

        // Subscribe to notifications (fire-and-forget with timeout)
        unawaited(
          NotificationService()
              .forceSubscribeToAll()
              .timeout(const Duration(seconds: 3))
              .then((_) {
            if (kDebugMode) {
              debugPrint('✅ Subscribed to topic "all" after session restore');
            }
          }).catchError((Object e) {
            if (kDebugMode) {
              debugPrint('⚠️ Error subscribing to topic "all": $e');
            }
          }),
        );

        // Verify profile if online (with timeout to avoid hanging)
        if (isOnline) {
          try {
            final hasProfile = await _verifyUserProfile(
              session.user.id,
              session.user,
            ).timeout(const Duration(seconds: 5), onTimeout: () => false);
            if (!hasProfile) {
              if (kDebugMode) {
                debugPrint(
                  '⚠️ User ${session.user.id} has no complete profile. Keeping session and redirecting to registration flow.',
                );
              }
              return;
            }
            unawaited(_refreshUserContextCache());
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

  static Future<String> _determineFallbackRouteWithoutSupabase() async {
    try {
      final isOnline = await ConnectivityService.instance.checkNow();
      if (!isOnline) return '/offline';
      final backendReachable = await BackendReachabilityService
          .isBackendReachable(timeout: const Duration(seconds: 3));
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
