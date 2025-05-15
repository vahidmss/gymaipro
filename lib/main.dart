import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/route_service.dart';
import 'theme/app_theme.dart';
import 'services/auth_state_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('Starting application...');

  try {
    await Supabase.initialize(
      url: 'http://10.0.2.2:54321',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0',
    );
    print('Supabase initialized successfully');
  } catch (e) {
    print('Error initializing Supabase: $e');
  }

  final authService = AuthStateService();
  try {
    final session = await authService.restoreSession();
    print('Session restored: ${session != null}');

    if (session != null) {
      print('User is logged in: ${session.user.id}');
    } else {
      print('No active session found');
    }
  } catch (e) {
    print('Error restoring session: $e');
  }

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
