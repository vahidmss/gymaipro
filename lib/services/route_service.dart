import 'package:flutter/material.dart';
import '../screens/welcome_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/workout_program_builder_screen.dart';
import '../screens/workout_log_screen.dart';
import '../screens/trainers_list_screen.dart';
import '../screens/trainer_profile_screen.dart';
import '../screens/web_login_screen.dart';
import '../screens/exercise_list_screen.dart';
import '../screens/food_list_screen.dart';
import '../screens/food_detail_screen.dart';
import '../screens/conversations_screen.dart';
import '../screens/chat_screen.dart';
import '../models/food.dart';
import '../models/chat_message.dart';
import '../services/auth_state_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RouteService {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          builder: (_) => const WelcomeScreen(),
        );
      case '/login':
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        );
      case '/register':
        return MaterialPageRoute(
          builder: (_) => const RegisterScreen(),
        );
      case '/dashboard':
        return MaterialPageRoute(
          builder: (_) => const DashboardScreen(),
        );
      case '/profile':
        return MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
        );
      case '/welcome':
        return MaterialPageRoute(
          builder: (_) => const WelcomeScreen(),
        );
      case '/workout-program-builder':
        final String? programId = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => WorkoutProgramBuilderScreen(programId: programId),
        );
      case '/workout-log':
        return MaterialPageRoute(
          builder: (_) => const WorkoutLogScreen(),
        );
      case '/trainers':
        return MaterialPageRoute(
          builder: (_) => const TrainersListScreen(),
        );
      case '/trainer-profile':
        final String trainerId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => TrainerProfileScreen(trainerId: trainerId),
        );
      case '/web_login':
        final args = settings.arguments as Map<String, dynamic>?;
        final phoneNumber = args?['phone_number'] as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => WebLoginScreen(phoneNumber: phoneNumber),
        );
      case '/exercise-list':
        return MaterialPageRoute(
          builder: (_) => const ExerciseListScreen(),
        );
      case '/food-list':
        return MaterialPageRoute(
          builder: (_) => const FoodListScreen(),
        );
      case '/food-detail':
        final Food food = settings.arguments as Food;
        return MaterialPageRoute(
          builder: (_) => FoodDetailScreen(food: food),
        );
      case '/conversations':
        return MaterialPageRoute(
          builder: (_) => const ConversationsScreen(),
        );
      case '/chat':
        final Map<String, dynamic> args =
            settings.arguments as Map<String, dynamic>;
        final String otherUserId = args['otherUserId'] as String;
        final String otherUserName = args['otherUserName'] as String;
        return MaterialPageRoute(
          builder: (_) => ChatScreen(
            otherUserId: otherUserId,
            otherUserName: otherUserName,
          ),
        );

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
      final authService = AuthStateService();
      print('Checking login state for initial route...');

      final isLoggedIn = await authService.isLoggedIn();
      print('Login state: $isLoggedIn');

      // اگر کاربر لاگین است، بررسی کنیم که آیا کاربر فعلی در کلاینت وجود دارد
      if (isLoggedIn) {
        final currentUser = Supabase.instance.client.auth.currentUser;
        if (currentUser != null) {
          print('User is logged in with ID: ${currentUser.id}');
          return '/dashboard';
        } else {
          print(
              'Warning: isLoggedIn is true but currentUser is null. Defaulting to welcome screen.');
          return '/welcome';
        }
      }

      return '/welcome';
    } catch (e) {
      print('Error in getInitialRoute: $e');
      // در صورت خطا به صفحه خوش‌آمدگویی هدایت می‌کنیم
      return '/welcome';
    }
  }
}
