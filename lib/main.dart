import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // بهینه‌سازی عملکرد
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ),
  );

  // محدود کردن فریم‌ریت برای کاهش مصرف باتری
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  print('Starting application...');

  // Initialize Supabase
  try {
    await Supabase.initialize(
      url: 'http://192.168.1.3:54321',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0',
      debug: false, // غیرفعال کردن حالت دیباگ در محیط اصلی
    );
    print('Supabase initialized successfully');

    // اولیه‌سازی سرویس‌های اپلیکیشن - به صورت موازی
    Future.wait([
      _initExerciseService(),
      _initFoodService(),
      _runDatabaseMigrations(),
    ]).then((_) {
      print('All initialization services completed');
    }).catchError((error) {
      print('Error in initialization services: $error');
    });
  } catch (e) {
    print('Error initializing services: $e');
  }

  // Auth service setup
  final authService = AuthStateService();
  try {
    // Check current authentication state
    final currentUser = Supabase.instance.client.auth.currentUser;
    print('Current user at startup: ${currentUser?.id ?? "None"}');

    final session = await authService.restoreSession();
    print('Session restored: ${session != null}');

    if (session != null) {
      print('User is logged in: ${session.user.id}');

      // Verify the user has a profile
      try {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', session.user.id)
            .maybeSingle();

        if (profile != null) {
          print('User profile found: ${profile['username']}');
        } else {
          print('Warning: No profile found for authenticated user');
        }
      } catch (e) {
        print('Error checking user profile: $e');
      }
    } else {
      print('No active session found');
    }
  } catch (e) {
    print('Error restoring session: $e');
  }

  // Determine initial route
  String initialRoute;
  try {
    initialRoute = await RouteService.getInitialRoute();
    print('Initial route: $initialRoute');
  } catch (e) {
    print('Error determining initial route: $e');
    initialRoute = '/welcome'; // Default route if error occurs
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
    print('Exercise service initialized successfully');
  } catch (e) {
    print('Error initializing exercise service: $e');
  }
}

// اولیه‌سازی سرویس خوراکی‌ها به صورت جداگانه
Future<void> _initFoodService() async {
  try {
    await FoodService.initAll();
    print('Food service initialized successfully');
  } catch (e) {
    print('Error initializing food service: $e');
  }
}

// اجرای مهاجرت‌های پایگاه داده به صورت جداگانه
Future<void> _runDatabaseMigrations() async {
  try {
    await DatabaseMigrationService.runMigrations();
    print('Database migrations completed');
  } catch (e) {
    print('Error running database migrations: $e');
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
