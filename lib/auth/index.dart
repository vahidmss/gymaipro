// Auth module exports
// این فایل تمام کلاس‌ها و سرویس‌های مربوط به احراز هویت را export می‌کند

export 'screens/login_screen.dart';
// Screens
export 'screens/register_screen.dart';
export 'services/auth_state_service.dart';
// Services
export 'services/supabase_service.dart';

// Note: OTP verification screen is located in the main screens folder
// as it might be used by other modules as well
// Access via: import 'package:gymaipro/screens/otp_verification_screen.dart';
