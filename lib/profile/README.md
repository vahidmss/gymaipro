# Profile Module - GymAI Pro

## Overview
The Profile module manages user profiles, including personal information, fitness data, and profile management functionality.

## Structure
```
lib/profile/
├── models/
│   └── user_profile.dart          # User profile data model
├── services/
│   └── profile_service.dart       # Profile management service
├── screens/
│   ├── profile_screen.dart        # Main profile screen
│   └── trainer_profile_screen.dart # Trainer profile screen
├── widgets/
│   └── (profile-related widgets)
└── README.md                      # This file
```

## Features

### User Profile Management
- **Profile Creation**: Automatic profile creation for new users
- **Profile Updates**: Update personal information, fitness goals, and preferences
- **Avatar Management**: Upload and manage profile pictures
- **Weight Tracking**: Record and track weight history
- **Profile Completeness**: Check and improve profile completion status

### Data Models

#### UserProfile
The main data model for user profiles containing:
- Personal information (name, email, phone, avatar)
- Fitness data (weight, height, measurements)
- Goals and preferences
- Weight history tracking
- Profile completion status

### Services

#### ProfileService
Singleton service providing:
- `getProfileByAuthId()`: Get current user's profile
- `updateProfile()`: Update profile information
- `addWeightRecord()`: Add new weight record
- `getWeightRecords()`: Get weight history
- `createInitialProfile()`: Create new user profile
- `getProfileById()`: Get profile by ID
- `getAllProfiles()`: Get all profiles (admin)
- `deleteProfile()`: Delete profile (admin)

### Screens

#### ProfileScreen
Main profile management screen with:
- Profile information display and editing
- Avatar upload functionality
- Weight tracking interface
- Profile completion indicators
- Settings and preferences

#### TrainerProfileScreen
Specialized screen for trainer profiles with:
- Trainer-specific information
- Client management
- Professional details
- Certifications and experience

## Usage

### Basic Profile Operations
```dart
// Get current user's profile
final profileService = ProfileService();
final profile = await profileService.getProfileByAuthId();

// Update profile
await profileService.updateProfile(userId, {
  'first_name': 'John',
  'last_name': 'Doe',
  'weight': 75.5,
});

// Add weight record
await profileService.addWeightRecord(userId, 75.5);
```

### Profile Screen Navigation
```dart
// Navigate to profile screen
Navigator.pushNamed(context, '/profile');

// Navigate to trainer profile
Navigator.pushNamed(context, '/trainer-profile', arguments: trainerId);
```

## Database Schema

### Profiles Table
- `id`: UUID (primary key)
- `username`: String
- `phone_number`: String
- `email`: String
- `first_name`: String
- `last_name`: String
- `avatar_url`: String
- `bio`: String
- `birth_date`: Date
- `height`: Integer
- `weight`: Double
- `gender`: String
- `role`: String (athlete/trainer/admin)
- `fitness_goals`: JSON array
- `weight_history`: JSON array
- `created_at`: Timestamp
- `updated_at`: Timestamp
- `last_active_at`: Timestamp
- `is_online`: Boolean

### Weight Records Table (Optional)
- `id`: UUID (primary key)
- `profile_id`: UUID (foreign key)
- `weight`: Double
- `recorded_at`: Timestamp

## Integration

### With Other Modules
- **Authentication**: Uses Supabase auth for user identification
- **Storage**: Uses Supabase storage for avatar uploads
- **Chat**: Provides user information for chat functionality
- **Workout**: Uses profile data for workout recommendations
- **Meal Plan**: Uses profile data for nutrition calculations

### Dependencies
- `supabase_flutter`: Database and authentication
- `image_picker`: Avatar upload functionality
- `flutter_local_notifications`: Profile update notifications

## Error Handling
The module includes comprehensive error handling for:
- Network connectivity issues
- Database connection problems
- Invalid data formats
- Permission errors
- Profile creation failures

## Performance Considerations
- Profile data is cached locally when possible
- Weight history is paginated for large datasets
- Avatar images are optimized and cached
- Database queries are optimized with proper indexing

## Security
- Row Level Security (RLS) policies protect user data
- Profile updates require authentication
- Avatar uploads are validated and sanitized
- Sensitive data is properly encrypted

## Future Enhancements
- Profile verification system
- Advanced analytics and insights
- Social features (following, sharing)
- Integration with fitness devices
- Advanced weight tracking with trends
- Profile templates for different user types
