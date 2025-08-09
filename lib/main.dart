import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'services/route_service.dart';
import 'theme/app_theme.dart';
import 'services/auth_state_service.dart';
import 'services/exercise_service.dart';
import 'services/food_service.dart';
import 'services/database_migration_service.dart';
import 'services/supabase_service.dart';
import 'config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // بهینه‌سازی عملکرد
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ),
  );

  // محدود کردن جهت صفحه برای بهبود تجربه کاربری
  await SystemChrome.setPreferredOrientations(
    [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ],
  );

  if (kDebugMode) print('Starting application...');

  // Initialize Supabase
  try {
    if (kDebugMode) {
      print('Initializing Supabase with URL: ${AppConfig.supabaseUrl}');
    }
    if (kDebugMode) {
      print('Anon Key is set: ${AppConfig.supabaseAnonKey.isNotEmpty}');
    }

    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
    if (kDebugMode) print('Supabase initialized successfully');

    // Test connection
    try {
      await Supabase.instance.client.from('profiles').select('id').limit(1);
      if (kDebugMode) print('Supabase connection test successful');
    } catch (e) {
      if (kDebugMode) print('Supabase connection test failed: $e');
    }

    // اولیه‌سازی سرویس‌های اپلیکیشن - به صورت موازی
    unawaited(Future.wait([
      _initExerciseService(),
      _initFoodService(),
      _runDatabaseMigrations(),
    ]).then((_) {
      if (kDebugMode) print('All initialization services completed');
    }).catchError((error) {
      if (kDebugMode) print('Error in initialization services: $error');
    }));
  } catch (e) {
    if (kDebugMode) print('Error initializing Supabase: $e');
    if (kDebugMode) print('Error details: ${e.toString()}');
  }

  // Auth service setup
  final authService = AuthStateService();
  try {
    // Check current authentication state
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (kDebugMode) {
      print('Current user at startup: ${currentUser?.id ?? "None"}');
    }

    final session = await authService.restoreSession();
    if (kDebugMode) print('Session restored: ${session != null}');

    if (session != null) {
      if (kDebugMode) print('User is logged in: ${session.user.id}');

      // Verify the user has a profile
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
            print('Warning: No profile found for authenticated user');
          }
        }
      } catch (e) {
        if (kDebugMode) print('Error checking user profile: $e');
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
    initialRoute = await RouteService.getInitialRoute();
    if (kDebugMode) {
      print('=== MAIN: Initial route determined: $initialRoute ===');
    }
  } catch (e) {
    if (kDebugMode) print('=== MAIN: Error determining initial route: $e ===');
    if (kDebugMode) print('=== MAIN: Using default route: /welcome ===');
  }

  // ساخت یک نمونه از SupabaseService
  final supabaseService = SupabaseService();

  runApp(
    // افزودن Provider برای SupabaseService
    Provider<SupabaseService>(
      create: (_) => supabaseService,
      child: MyApp(initialRoute: initialRoute),
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

// اجرای مهاجرت‌های پایگاه داده به صورت جداگانه
Future<void> _runDatabaseMigrations() async {
  try {
    await DatabaseMigrationService.runMigrations();
    if (kDebugMode) print('Database migrations completed');
  } catch (e) {
    if (kDebugMode) print('Error running database migrations: $e');
  }
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({Key? key, required this.initialRoute}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'GymAI Pro',
        theme: ThemeData(
          scaffoldBackgroundColor: AppTheme.backgroundColor,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: AppTheme.goldColor),
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
          // بهینه‌سازی انیمیشن‌ها
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            },
          ),
        ),
        debugShowCheckedModeBanner: false,
        onGenerateRoute: RouteService.generateRoute,
        initialRoute: initialRoute);
  }
}
