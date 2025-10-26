import 'package:flutter/material.dart';
import 'package:gymaipro/academy/models/article.dart';
import 'package:gymaipro/academy/screens/article_detail_screen.dart';
import 'package:gymaipro/academy/screens/articles_list_screen.dart';
import 'package:gymaipro/admin/broadcast_center_screen.dart';
import 'package:gymaipro/ai/screens/ai_programs_screen.dart';
import 'package:gymaipro/auth/screens/login_screen.dart';
import 'package:gymaipro/auth/screens/register_screen.dart';
import 'package:gymaipro/auth/services/auth_state_service.dart';
import 'package:gymaipro/chat/screens/chat_conversations_screen.dart';
import 'package:gymaipro/chat/screens/chat_main_screen.dart';
import 'package:gymaipro/chat/screens/chat_screen.dart';
import 'package:gymaipro/dashboard/screens/dashboard_screen.dart';
import 'package:gymaipro/meal_plan/meal_log/screens/meal_log_screen.dart';
import 'package:gymaipro/meal_plan/meal_plan_builder/screens/meal_plan_builder_screen.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/models/food.dart';
import 'package:gymaipro/my_club/index.dart';
import 'package:gymaipro/navigation/navigation.dart';
import 'package:gymaipro/navigation/navigation_guard.dart';
import 'package:gymaipro/notification/screens/notification_settings_screen.dart';
import 'package:gymaipro/notification/screens/notifications_screen.dart';
import 'package:gymaipro/notification/screens/private_message_notification_settings_screen.dart';
import 'package:gymaipro/payment/index.dart';
import 'package:gymaipro/payment/screens/wallet_charge_screen.dart';
import 'package:gymaipro/profile/screens/profile_screen.dart';
import 'package:gymaipro/screens/exercise_detail_screen.dart';
import 'package:gymaipro/screens/exercise_list_screen.dart';
import 'package:gymaipro/screens/favorite_foods_screen.dart';
import 'package:gymaipro/screens/food_detail_screen.dart';
import 'package:gymaipro/screens/food_list_screen.dart';
import 'package:gymaipro/screens/help_screen.dart';
import 'package:gymaipro/screens/offline_screen.dart';
import 'package:gymaipro/screens/settings_screen.dart';
import 'package:gymaipro/screens/trainers_list_screen.dart';
import 'package:gymaipro/screens/welcome_screen.dart';
import 'package:gymaipro/services/connectivity_service.dart';
import 'package:gymaipro/trainer_dashboard/screens/client_management/client_management_screen.dart';
import 'package:gymaipro/user_profile/screens/user_profile_screen.dart';
import 'package:gymaipro/workout_plan/workout_log/screens/workout_log_screen.dart';
import 'package:gymaipro/workout_plan/workout_plan_builder/screens/workout_program_builder_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RouteService {
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
      case '/':
        return MaterialPageRoute(
          builder: (_) => _buildProtectedRoute(const WelcomeScreen(), '/'),
        );
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
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case '/main':
        return MaterialPageRoute(builder: (_) => const MainNavigationScreen());
      case '/profile':
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case '/welcome':
        return MaterialPageRoute(
          builder: (_) =>
              _buildProtectedRoute(const WelcomeScreen(), '/welcome'),
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
        final mpArgs = settings.arguments;
        if (mpArgs is String?) {
          planId = mpArgs;
        } else if (mpArgs is Map<String, dynamic>) {
          planId = mpArgs['planId'] as String?;
          targetUserIdMp = mpArgs['targetUserId'] as String?;
          targetUserNameMp = mpArgs['targetUserName'] as String?;
        }
        return MaterialPageRoute(
          builder: (_) => MealPlanBuilderScreen(
            planId: planId,
            targetUserId: targetUserIdMp,
            targetUserName: targetUserNameMp,
          ),
        );
      case '/meal-log':
        return MaterialPageRoute(builder: (_) => const FoodLogScreen());
      case '/trainers':
        return MaterialPageRoute(builder: (_) => const TrainersListScreen());
      case '/trainer-profile':
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
      case '/my-programs':
        return MaterialPageRoute(builder: (_) => const MyProgramsScreen());
      case '/my-club':
        return MaterialPageRoute(builder: (_) => const MyClubMainScreen());
      case '/food-list':
        return MaterialPageRoute(builder: (_) => const FoodListScreen());
      case '/favorite-foods':
        return MaterialPageRoute(builder: (_) => const FavoriteFoodsScreen());
      case '/food-detail':
        final Food food = settings.arguments! as Food;
        return MaterialPageRoute(builder: (_) => FoodDetailScreen(food: food));
      case '/articles':
        return MaterialPageRoute(builder: (_) => const ArticlesListScreen());
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
        return MaterialPageRoute(builder: (_) => const ChatMainScreen());

      case '/admin-broadcast-center':
        return MaterialPageRoute(builder: (_) => const BroadcastCenterScreen());
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
      // Global offline gate
      final isOnline = await ConnectivityService.instance.checkNow();
      if (!isOnline) {
        print('=== ROUTE SERVICE: Offline detected, returning /offline ===');
        return '/offline';
      }
      final authService = AuthStateService();
      print('=== ROUTE SERVICE: Checking login state for initial route... ===');

      final isLoggedIn = await authService.isLoggedIn();
      print('=== ROUTE SERVICE: Login state: $isLoggedIn ===');

      // اگر کاربر لاگین است، بررسی کنیم که آیا کاربر فعلی در کلاینت وجود دارد
      if (isLoggedIn) {
        final currentUser = Supabase.instance.client.auth.currentUser;
        print(
          '=== ROUTE SERVICE: Current user: ${currentUser?.id ?? "null"} ===',
        );

        if (currentUser != null) {
          print(
            '=== ROUTE SERVICE: User is logged in with ID: ${currentUser.id} ===',
          );
          print('=== ROUTE SERVICE: Returning /main ===');
          return '/main'; // تغییر به صفحه اصلی جدید
        } else {
          print(
            '=== ROUTE SERVICE: Warning: isLoggedIn is true but currentUser is null. Defaulting to welcome screen. ===',
          );
          return '/welcome';
        }
      }

      print('=== ROUTE SERVICE: User not logged in, returning /welcome ===');
      return '/welcome';
    } catch (e) {
      print('=== ROUTE SERVICE: Error in getInitialRoute: $e ===');
      // در صورت خطا به صفحه خوش‌آمدگویی هدایت می‌کنیم
      return '/welcome';
    }
  }

  /// Build protected route that redirects logged in users
  static Widget _buildProtectedRoute(Widget child, String routeName) {
    return FutureBuilder<bool>(
      future: _checkIfUserIsLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final isLoggedIn = snapshot.data ?? false;

        if (isLoggedIn &&
            !NavigationGuard.isRouteAllowedForLoggedInUser(routeName)) {
          // Redirect to main screen
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              Navigator.pushNamedAndRemoveUntil(
                context,
                NavigationGuard.getRedirectRouteForLoggedInUser(),
                (route) => false,
              );
            } catch (e) {
              debugPrint('Error in route redirect: $e');
            }
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return child;
      },
    );
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
