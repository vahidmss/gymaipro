import 'package:flutter/material.dart';
import '../screens/welcome_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/profile_screen.dart';
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
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('مسیر ${settings.name} پیدا نشد'),
            ),
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
