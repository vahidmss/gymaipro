import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/route_service.dart';
import 'theme/app_theme.dart';
import 'services/auth_state_service.dart';
import 'services/exercise_service.dart';
import 'services/database_migration_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('Starting application...');

  // Initialize Supabase
  try {
    await Supabase.initialize(
      url: 'http://10.0.2.2:54321',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0',
      debug: true, // Enable debug mode for more detailed logs
    );
    print('Supabase initialized successfully');

    // Verify Supabase connection
    try {
      final testResponse = await Supabase.instance.client
          .from('profiles')
          .select('count')
          .limit(1);
      print('Database connection test: $testResponse');
    } catch (e) {
      print('Warning: Database connection test failed: $e');
    }

    // اولیه‌سازی سرویس‌های اپلیکیشن
    await ExerciseService.initAll();
    print('Exercise service initialized successfully');

    // Run database migrations
    await DatabaseMigrationService.runMigrations();
    print('Database migrations completed');
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

  runApp(MyApp(initialRoute: initialRoute));
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
        ),
        debugShowCheckedModeBanner: false,
        onGenerateRoute: RouteService.generateRoute,
        initialRoute: initialRoute);
  }
}
