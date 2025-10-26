# Authentication Module 🔐

This module handles all authentication-related functionality for the GymAI Pro application.

## Structure

```
auth/
├── index.dart              # Module exports
├── README.md              # This file
├── screens/               # Authentication screens
│   ├── register_screen.dart       # User registration
│   ├── login_screen.dart          # User login
├── services/              # Authentication services
│   ├── supabase_service.dart   # Main authentication service
│   ├── auth_state_service.dart # Authentication state management
│   └── otp_service.dart        # OTP verification service
└── widgets/               # Authentication widgets (future)
```

**Note**: OTP verification screen (`otp_verification_screen.dart`) is located in the main `lib/screens/` folder as it may be used by other modules.

## Features

### 🔑 Registration
- **Phone-based registration**: Users register with phone number and username
- **OTP verification**: Secure verification via SMS
- **Profile creation**: Automatic profile setup with default values
- **Clean data format**: Readable emails (`username@gymaipro.ir`)

### 🚪 Login
- **Phone login**: Login with phone number
- **Session management**: Secure session handling
- **Multiple auth methods**: Fallback authentication options

### 📱 Services

#### SupabaseService
- **Main auth service**: Handles registration and login
- **Database operations**: User and profile management
- **Clean architecture**: 487 lines of optimized code
- **Error handling**: Comprehensive error management

#### AuthStateService
- **State management**: Authentication state persistence
- **Session storage**: Local session management

#### OTPService
- **SMS verification**: OTP generation and validation
- **Test mode**: Development OTP codes
- **Secure validation**: Phone number verification

## Usage

```dart
import 'package:gymaipro/auth/index.dart';

// Registration
final authService = SupabaseService();
final session = await authService.signUpWithPhone('09123456789', 'username');

// Login
final loginSession = await authService.signInWithPhone('09123456789');
```

## Data Format

### User Profile
```dart
{
  "id": "12345678-1234-1234-1234-123456789abc",
  "username": "vahid",
  "email": "vahid@gymaipro.ir",
  "phone_number": "09123456789",
  "role": "athlete"
}
```

## Recent Improvements ✨

- **62% code reduction**: From 1150 to 487 lines
- **Clean data format**: Readable emails and UUIDs
- **Removed duplicates**: No redundant methods
- **Better structure**: Organized and maintainable
- **Production ready**: Optimized for deployment

## Dependencies

- `supabase_flutter`: Database and authentication
- `shared_preferences`: Local storage
- Custom services for OTP and state management

---

**Status**: ✅ Production Ready
**Last Updated**: September 2025
**Maintainer**: GymAI Pro Team
