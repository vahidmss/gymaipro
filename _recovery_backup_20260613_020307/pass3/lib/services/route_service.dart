import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gymaipro/academy/models/article.dart';
import 'package:gymaipro/academy/screens/article_detail_screen.dart';
import 'package:gymaipro/ai/screens/ai_programs_screen.dart';
import 'package:gymaipro/auth/screens/login_screen.dart';
import 'package:gymaipro/auth/screens/register_screen.dart';
import 'package:gymaipro/auth/services/auth_state_service.dart';
import 'package:gymaipro/chat/screens/chat_conversations_screen.dart';
import 'package:gymaipro/chat/screens/chat_main_screen.dart';
import 'package:gymaipro/chat/screens/chat_screen.dart';
import 'package:gymaipro/dashboard/screens/dashboard_screen.dart';
import 'package:gymaipro/dashboard/screens/program_type_selection_screen.dart';
import 'package:gymaipro/meal_log/screens/meal_log_screen.dart';
import 'package:gymaipro/meal_plan_builder/screens/meal_plan_builder_screen.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/models/food.dart';
import 'package:gymaipro/my_club/index.dart';
import 'package:gymaipro/navigation/constants/navigation_constants.dart';
import 'package:gymaipro/navigation/navigation.dart';
import 'package:gymaipro/navigation/navigation_guard.dart';
import 'package:gymaipro/navigation/screens/main_navigation_screen.dart';
import 'package:gymaipro/notification/screens/notification_settings_screen.dart';
import 'package:gymaipro/notification/screens/notifications_screen.dart';
import 'package:gymaipro/notification/screens/private_message_notification_settings_screen.dart';
import 'package:gymaipro/payment/index.dart';
import 'package:gymaipro/payment/screens/wallet_charge_screen.dart';
import 'package:gymaipro/profile/screens/profile_screen.dart';
import 'package:gymaipro/screens/exercise_detail_screen.dart';
import 'package:gymaipro/screens/exercise_list_screen.dart';
import 'package:gymaipro/academy/screens/music_favorites_screen.dart';
import 'package:gymaipro/screens/favorite_foods_screen.dart';
import 'package:gymaipro/screens/food_detail_screen.dart';
import 'package:gymaipro/screens/food_list_screen.dart';
import 'package:gymaipro/referral/screens/referral_guide_screen.dart';
import 'package:gymaipro/screens/help_screen.dart';
import 'package:gymaipro/screens/offline_screen.dart';
import 'package:gymaipro/screens/settings_screen.dart';
import 'package:gymaipro/screens/welcome_screen.dart';
import 'package:gymaipro/services/connectivity_service.dart';
import 'package:gymaipro/services/backend_reachability_service.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/trainer_dashboard/screens/client_management/client_management_screen.dart';
import 'package:gymaipro/trainer_dashboard/screens/trainer_dashboard_screen.dart';
import 'package:gymaipro/profile/models/user_profile.dart';
import 'package:gymaipro/ranking/screens/leaderboard_screen.dart';
import 'package:gymaipro/trainer_ranking/screens/trainer_detail_screen.dart';
import 'package:gymaipro/trainer_ranking/screens/trainer_ranking_screen.dart';
import 'package:gymaipro/trainer_ranking/services/trainer_ranking_service.dart';
import 'package:gymaipro/user_profile/screens/user_profile_screen.dart';
import 'package:gymaipro/workout_log/screens/workout_log_screen.dart';
import 'package:gymaipro/workout_plan_builder/screens/workout_program_builder_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RouteService {
  static bool _isProfileUsernameValid(String? username) {
    if (username == null) return false;
    if (username.isEmpty) return false;
    if (username.startsWith('user_')) return false;
    return true;
  }

  static Future<bool> _isProfileCompleteForCurrentUser() async {
    try {
      final profile = await SimpleProfileService.getCurrentProfile();
      if (profile == null) return false;
      final username = profile['username'] as String?;
      return _isProfileUsernameValid(username);
    } catch (_) {
      return false;
    }
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final originalName = settings.name ?? '';
    print('=== ROUTE SERVICE: Generating route for: $originalName ===');

    // sanitize query string
    final sanitizedName = originalName.contains('?')
        ? originalName.split('?').first
        : originalName;

    // هندل لینک‌های دیپلینک که ممکن است به صورت route وارد شوند
    if (sanitizedName == '/topup' || sanitizedName == '/wallet/topup') {
      // مسیر دیپلینک را شفاف و بدون UI باز و سریعاً pop کن تا صفحه سیاه نشود
      return PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        pageBuilder: (ctx, __, ___) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.of(ctx, rootNavigator: true).canPop()) {
              Navigator.of(ctx, rootNavigator: true).pop();
            }
          });
          return const SizedBox.shrink();
        },
        transitionDuration: const Duration(),
        reverseTransitionDuration: const Duration(),
      );
    }

    // For now, just build the route directly
    // TODO: Implement async route interception
    return _buildRoute(
      RouteSettings(name: sanitizedName, arguments: settings.arguments),
    );
  }

  static Route<dynamic> _buildRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/login':
        return MaterialPageRoute(
          builder: (_) => _buildProtectedRoute(const LoginScreen(), '/login'),
        );
      case '/register':
        return MaterialPageRoute(
          builder: (_) =>
              _buildProtectedRoute(const RegisterScreen(), '/register'),
        );
      case '/dashboard':
        return MaterialPageRoute(
          builder: (_) => _buildAuthRequiredRoute(const DashboardScreen()),
        );
      case '/main':
        return MaterialPageRoute(
          builder: (_) =>
              _buildAuthRequiredRoute(const MainNavigationScreen()),
        );
      case '/profile':
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case '/welcome':
        // بررسی arguments برای jumpToLastPage
        final args = settings.arguments;
        final jumpToLastPage = args is Map<String, dynamic>
            ? args['jumpToLastPage'] as bool? ?? false
            : false;
        return MaterialPageRoute(
          builder: (_) => _buildProtectedRoute(
            WelcomeScreen(jumpToLastPage: jumpToLastPage),
            '/welcome',
          ),
        );
      case '/offline':
        return MaterialPageRoute(builder: (_) => const OfflineScreen());
      case '/workout-program-builder':
        String? programId;
        String? targetUserId;
        String? targetUserName;
        final args = settings.arguments;
        if (args is String?) {
          programId = args;
        } else if (args is Map<String, dynamic>) {
          programId = args['programId'] as String?;
          targetUserId = args['targetUserId'] as String?;
          targetUserName = args['targetUserName'] as String?;
        }
        return MaterialPageRoute(
          builder: (_) => WorkoutProgramBuilderScreen(
            programId: programId,
            targetUserId: targetUserId,
            targetUserName: targetUserName,
          ),
        );
      case '/workout-log':
        return MaterialPageRoute(builder: (_) => const WorkoutLogScreen());
      case '/meal-plan-builder':
        String? planId;
        String? targetUserIdMp;
        String? targetUserNameMp;
        String? subscriptionIdMp;
        String? paymentTransactionIdMp;
        final mpArgs = settings.arguments;
        if (mpArgs is String?) {
          planId = mpArgs;
        } else if (mpArgs is Map<String, dynamic>) {
          planId = mpArgs['planId'] as String?;
          targetUserIdMp = mpArgs['targetUserId'] as String?;
          targetUserNameMp = mpArgs['targetUserName'] as String?;
          subscriptionIdMp = mpArgs['subscriptionId'] as String?;
          paymentTransactionIdMp = mpArgs['paymentTransactionId'] as String?;
        }
        return MaterialPageRoute(
          builder: (_) => MealPlanBuilderScreen(
            planId: planId,
            targetUserId: targetUserIdMp,
            targetUserName: targetUserNameMp,
            subscriptionId: subscriptionIdMp,
            paymentTransactionId: paymentTransactionIdMp,
          ),
        );
      case '/meal-log':
        final mealPlanId = settings.arguments as String?;
        // اگر mealPlanId از arguments نیامده، از active meal plan service بگیر
        return MaterialPageRoute(
          builder: (_) => FoodLogScreen(mealPlanId: mealPlanId),
        );

      case '/trainer-profile':
        final String userId = settings.arguments! as String;
        return MaterialPageRoute(
          builder: (_) => UserProfileScreen(userId: userId),
        );
      case '/user-profile':
        final String userId = settings.arguments! as String;
        return MaterialPageRoute(
          builder: (_) => UserProfileScreen(userId: userId),
        );
      case '/exercise-list':
        return MaterialPageRoute(builder: (_) => const ExerciseListScreen());
      case '/exercise-detail':
        final Map<String, dynamic> args =
            settings.arguments! as Map<String, dynamic>;
        final Exercise exercise = args['exercise'] as Exercise;
        return MaterialPageRoute(
          builder: (_) => ExerciseDetailScreen(exercise: exercise),
        );
      case '/ai-programs':
        return MaterialPageRoute(builder: (_) => const AIProgramsScreen());
      case '/program-type-selection':
        return MaterialPageRoute(
          builder: (_) => const ProgramTypeSelectionScreen(),
        );
      case '/my-programs':
        return MaterialPageRoute(builder: (_) => const MyProgramsScreen());
      case '/my-club':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => const MyClubMainScreen(),
          settings: RouteSettings(arguments: args),
        );
      case '/food-list':
        return MaterialPageRoute(builder: (_) => const FoodListScreen());
      case '/favorite-foods':
        return MaterialPageRoute(builder: (_) => const FavoriteFoodsScreen());
      case '/music-favorites':
        return MaterialPageRoute(builder: (_) => const MusicFavoritesScreen());
      case '/food-detail':
        final Food food = settings.arguments! as Food;
        return MaterialPageRoute(builder: (_) => FoodDetailScreen(food: food));
      case '/articles':
        // Navigate to academy tab in main navigation
        // Pop back to main navigation first
        WidgetsBinding.instance.addPostFrameCallback((_) {
          MainNavigationScreen.navigateToTab(NavigationConstants.academyIndex);
        });
        // Return empty container as placeholder (will navigate to tab instead)
        return MaterialPageRoute(builder: (_) => const SizedBox.shrink());
      case '/trainer-ranking':
        return MaterialPageRoute(builder: (_) => const TrainerRankingScreen());
      case '/leaderboard':
      case '/ranking':
        return MaterialPageRoute(builder: (_) => const LeaderboardScreen());
      case '/trainer-detail':
        final args = settings.arguments as Map<String, dynamic>?;
        final trainerId = args?['trainerId'] as String?;
        if (trainerId == null) {
          // اگر trainerId نبود، به صفحه لیست مربیان برگرد
          return MaterialPageRoute(builder: (_) => const TrainerRankingScreen());
        }
        // لود کردن trainer و نمایش صفحه
        return MaterialPageRoute(
          builder: (_) => _TrainerDetailRouteBuilder(trainerId: trainerId),
        );
      case '/article-detail':
        final Article article = settings.arguments! as Article;
        return MaterialPageRoute(
          builder: (_) => ArticleDetailScreen(article: article),
        );
      case '/conversations':
        return MaterialPageRoute(
          builder: (_) => const ChatConversationsScreen(),
        );
      case '/chat-main':
        final initialTabIndex = settings.arguments is int
            ? settings.arguments as int
            : (settings.arguments is Map<String, dynamic>
                      ? (settings.arguments
                                as Map<String, dynamic>)['initialTabIndex']
                            as int?
                      : null) ??
                  0;
        return MaterialPageRoute(
          builder: (_) =>
              ChatMainScreen(initialTabIndex: initialTabIndex.clamp(0, 2)),
        );

      case '/chat':
        try {
          final Map<String, dynamic> args =
              settings.arguments! as Map<String, dynamic>;
          final String otherUserId = args['otherUserId'] as String;
          final String otherUserName = args['otherUserName'] as String;

          debugPrint(
            '=== CHAT ROUTE: Opening chat with $otherUserName (ID: $otherUserId) ===',
          );

          // بررسی صحت داده‌ها
          if (otherUserId.isEmpty) {
            throw Exception('otherUserId is empty');
          }

          return MaterialPageRoute(
            builder: (_) => ChatScreen(
              otherUserId: otherUserId,
              otherUserName: otherUserName,
            ),
          );
        } catch (e) {
          debugPrint('=== ROUTE SERVICE: Error in /chat route: $e ===');
          // بازگشت به صفحه اصلی در صورت خطا
          return MaterialPageRoute(
            builder: (_) => const MainNavigationScreen(),
          );
        }
      case '/client-management':
        return MaterialPageRoute(
          builder: (_) => const ClientManagementScreen(),
        );
      case '/trainer-dashboard':
        final initialTabIndex = settings.arguments is int
            ? settings.arguments as int
            : (settings.arguments is Map<String, dynamic>
                    ? (settings.arguments
                            as Map<String, dynamic>)['initialTabIndex']
                        as int?
                    : null) ??
                0;
        return MaterialPageRoute(
          builder: (_) => TrainerDashboardScreen(
            initialTabIndex: initialTabIndex.clamp(0, 8),
          ),
        );
      case '/notifications':
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());
      case '/notification-settings':
        return MaterialPageRoute(
          builder: (_) => const NotificationSettingsScreen(),
        );
      case '/private-message-notification-settings':
        return MaterialPageRoute(
          builder: (_) => const PrivateMessageNotificationSettingsScreen(),
        );
      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case '/referral':
      case '/invite-friends':
        return MaterialPageRoute(builder: (_) => const ReferralGuideScreen());
      case '/help':
        return MaterialPageRoute(builder: (_) => const HelpScreen());

      // Payment routes
      case '/payment':
        final PaymentPlan plan = settings.arguments! as PaymentPlan;
        return MaterialPageRoute(builder: (_) => PaymentScreen(plan: plan));
      case '/wallet':
        return MaterialPageRoute(builder: (_) => const WalletScreen());
      case '/wallet-charge':
        return MaterialPageRoute(builder: (_) => const WalletChargeScreen());
      case '/subscriptions':
        return MaterialPageRoute(builder: (_) => const SubscriptionScreen());
      case '/payment-history':
        return MaterialPageRoute(builder: (_) => const PaymentHistoryScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('صفحه مورد نظر یافت نشد')),
          ),
        );
    }
  }

  static Future<String> getInitialRoute() async {
    try {
      print('=== ROUTE SERVICE: Starting getInitialRoute ===');
      final gate = await _offlineGateRoute();
      if (gate != null) return gate;
      return _resolveAppEntryRoute();
    } catch (e) {
      print('=== ROUTE SERVICE: Error in getInitialRoute: $e ===');
      return '/welcome';
    }
  }

  /// Where to go after the user explicitly retries from [/offline].
  /// Never bypasses login — same rules as cold start.
  static Future<String> resolveRouteAfterReconnect() async {
    try {
      final gate = await _offlineGateRoute();
      if (gate != null) return gate;
      return _resolveAppEntryRoute();
    } catch (e) {
      print('=== ROUTE SERVICE: Error in resolveRouteAfterReconnect: $e ===');
      return '/welcome';
    }
  }

  static Future<String?> _offlineGateRoute() async {
    final isOnline = await ConnectivityService.instance.checkNow();
    if (!isOnline) {
      print('=== ROUTE SERVICE: Offline detected, returning /offline ===');
      return '/offline';
    }
    final backendReachable = await BackendReachabilityService.isBackendReachable(
      timeout: const Duration(seconds: 5),
    );
    if (!backendReachable) {
      print(
        '=== ROUTE SERVICE: Network is available but backend is unreachable. Returning /offline ===',
      );
      return '/offline';
    }
    return null;
  }

  static Future<String> _resolveAppEntryRoute() async {
    final authService = AuthStateService();
    print('=== ROUTE SERVICE: Checking login state for entry route... ===');

    final isLoggedIn = await authService.isLoggedIn();
    print('=== ROUTE SERVICE: Login state: $isLoggedIn ===');

    if (!isLoggedIn) {
      print('=== ROUTE SERVICE: User not logged in, returning /welcome ===');
      return '/welcome';
    }

    final currentUser = Supabase.instance.client.auth.currentUser;
    print(
      '=== ROUTE SERVICE: Current user: ${currentUser?.id ?? "null"} ===',
    );
    if (currentUser == null) {
      print(
        '=== ROUTE SERVICE: Session flag set but no user — returning /welcome ===',
      );
      return '/welcome';
    }

    final complete = await _isProfileCompleteForCurrentUser();
    if (complete) {
      print('=== ROUTE SERVICE: Profile complete. Returning /main ===');
      return '/main';
    }

    print(
      '=== ROUTE SERVICE: Profile incomplete. Returning /register ===',
    );
    return '/register';
  }

  /// Build protected route that redirects logged in users
  /// Uses a StatefulWidget to cache the auth check result and prevent rebuilds
  static Widget _buildProtectedRoute(Widget child, String routeName) {
    return _ProtectedRouteWrapper(child: child, routeName: routeName);
  }

  /// Routes that require an authenticated user (e.g. /main, /dashboard).
  static Widget _buildAuthRequiredRoute(Widget child) {
    return _AuthRequiredRouteWrapper(child: child);
  }

  /// Check if user is logged in
  static Future<bool> _checkIfUserIsLoggedIn() async {
    try {
      final authService = AuthStateService();
      return await authService.isLoggedIn();
    } catch (e) {
      print('=== ROUTE SERVICE: Error checking login status: $e ===');
      return false;
    }
  }
}

/// Blocks unauthenticated access to app shell routes (/main, /dashboard).
class _AuthRequiredRouteWrapper extends StatefulWidget {
  const _AuthRequiredRouteWrapper({required this.child});

  final Widget child;

  @override
  State<_AuthRequiredRouteWrapper> createState() =>
      _AuthRequiredRouteWrapperState();
}

class _AuthRequiredRouteWrapperState extends State<_AuthRequiredRouteWrapper> {
  bool _hasRedirected = false;

  Future<void> _redirectTo(String route) async {
    if (_hasRedirected || !mounted) return;
    _hasRedirected = true;
    await Navigator.pushNamedAndRemoveUntil(context, route, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: RouteService._resolveAppEntryRoute(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final route = snapshot.data ?? '/welcome';
        if (route == '/main') {
          return widget.child;
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          unawaited(_redirectTo(route));
        });
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

/// Wrapper widget that caches the auth check result to prevent rebuild loops
class _ProtectedRouteWrapper extends StatefulWidget {
  const _ProtectedRouteWrapper({required this.child, required this.routeName});

  final Widget child;
  final String routeName;

  @override
  State<_ProtectedRouteWrapper> createState() => _ProtectedRouteWrapperState();
}

class _ProtectedRouteWrapperState extends State<_ProtectedRouteWrapper> {
  Future<bool>? _authCheckFuture;
  bool? _cachedAuthResult;
  Future<bool>? _profileCompleteFuture;
  bool? _cachedProfileComplete;
  bool _hasRedirected = false;

  @override
  void initState() {
    super.initState();
    // Cache the future on first build only
    _authCheckFuture = RouteService._checkIfUserIsLoggedIn();
    _authCheckFuture!.then((result) {
      if (mounted) {
        setState(() {
          _cachedAuthResult = result;
        });
      }
    });

    // Also cache profile completeness for professional routing behavior
    _profileCompleteFuture = RouteService._isProfileCompleteForCurrentUser();
    _profileCompleteFuture!.then((result) {
      if (mounted) {
        setState(() {
          _cachedProfileComplete = result;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // If we have a cached result, use it immediately
    if (_cachedAuthResult != null) {
      final isLoggedIn = _cachedAuthResult!;

      // If user is logged in and on a restricted route, only redirect if profile is complete.
      // If profile is incomplete, allow user to stay on /register to finish setup.
      if (isLoggedIn &&
          !NavigationGuard.isRouteAllowedForLoggedInUser(widget.routeName) &&
          !_hasRedirected) {
        if (_cachedProfileComplete == null) {
          return FutureBuilder<bool>(
            future: _profileCompleteFuture,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              final complete = snap.data ?? false;
              // cache
              _cachedProfileComplete = complete;
              if (complete) {
                _hasRedirected = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      NavigationGuard.getRedirectRouteForLoggedInUser(),
                      (route) => false,
                    );
                  }
                });
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              return widget.child;
            },
          );
        } else {
          final complete = _cachedProfileComplete!;
          if (complete) {
            _hasRedirected = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  NavigationGuard.getRedirectRouteForLoggedInUser(),
                  (route) => false,
                );
              }
            });
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
        }
      }

      return widget.child;
    }

    // While waiting for auth check, show loading
    return FutureBuilder<bool>(
      future: _authCheckFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final isLoggedIn = snapshot.data ?? false;

        if (isLoggedIn &&
            !NavigationGuard.isRouteAllowedForLoggedInUser(widget.routeName) &&
            !_hasRedirected) {
          // Redirect only once
          _hasRedirected = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              try {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  NavigationGuard.getRedirectRouteForLoggedInUser(),
                  (route) => false,
                );
              } catch (e) {
                debugPrint('Error in route redirect: $e');
              }
            }
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return widget.child;
      },
    );
  }
}

/// Widget builder برای صفحه trainer detail که trainer را از ID لود می‌کند
class _TrainerDetailRouteBuilder extends StatefulWidget {
  const _TrainerDetailRouteBuilder({required this.trainerId});
  final String trainerId;

  @override
  State<_TrainerDetailRouteBuilder> createState() => _TrainerDetailRouteBuilderState();
}

class _TrainerDetailRouteBuilderState extends State<_TrainerDetailRouteBuilder> {
  final TrainerRankingService _service = TrainerRankingService();
  bool _isLoading = true;
  UserProfile? _trainer;

  @override
  void initState() {
    super.initState();
    _loadTrainer();
  }

  Future<void> _loadTrainer() async {
    try {
      final trainer = await _service.getTrainerDetails(widget.trainerId);
      if (mounted) {
        setState(() {
          _trainer = trainer;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading trainer: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_trainer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('مربی یافت نشد')),
        body: const Center(child: Text('مربی یافت نشد')),
      );
    }

    return TrainerDetailScreen(trainer: _trainer!);
  }
}
