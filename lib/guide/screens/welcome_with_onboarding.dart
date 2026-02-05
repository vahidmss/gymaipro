import 'package:flutter/material.dart';
import 'package:gymaipro/guide/data/onboarding_data.dart';
import 'package:gymaipro/guide/services/onboarding_service.dart';
import 'package:gymaipro/guide/widgets/onboarding_screen.dart';
import 'package:gymaipro/screens/welcome_screen.dart';
import 'package:provider/provider.dart';

/// Wrapper برای WelcomeScreen که Onboarding را چک و نمایش می‌دهد
class WelcomeWithOnboarding extends StatefulWidget {
  const WelcomeWithOnboarding({super.key});

  @override
  State<WelcomeWithOnboarding> createState() => _WelcomeWithOnboardingState();
}

class _WelcomeWithOnboardingState extends State<WelcomeWithOnboarding> {
  bool _isLoading = true;
  bool _shouldShowOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    try {
      final onboardingService = Provider.of<OnboardingService>(
        context,
        listen: false,
      );

      // صبر کنیم تا سرویس initialize شود
      await onboardingService.initialize();

      if (mounted) {
        setState(() {
          _shouldShowOnboarding = onboardingService.shouldShowOnboarding();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking onboarding: $e');
      if (mounted) {
        setState(() {
          _shouldShowOnboarding = false;
          _isLoading = false;
        });
      }
    }
  }

  void _onOnboardingComplete() {
    setState(() {
      _shouldShowOnboarding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // نمایش یک loading screen ساده
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_shouldShowOnboarding) {
      return OnboardingScreen(
        pages: OnboardingData.getPages(),
        onComplete: _onOnboardingComplete,
      );
    }

    return const WelcomeScreen();
  }
}

