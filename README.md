# GymAI Pro - Flutter Fitness App

A comprehensive fitness application built with Flutter and Supabase.

## Database Structure

The application uses Supabase as its backend and contains the following main tables:

### Profiles

Stores user profile information including fitness metrics, preferences, and personal data.

### Exercises

Stores exercise information including:
- Name
- Description
- Muscle group
- Difficulty level
- Instructions
- Images

### Workouts

Stores workout sessions:
- Title
- Description
- Duration
- Calories
- Workout type
- Workout date

### Workout Programs

Stores workout programs with complex structures:

#### workout_program_logs
این جدول برای ذخیره برنامه‌های تمرینی کاربران استفاده می‌شود. ساختار آن به صورت زیر است:

```sql
CREATE TABLE workout_program_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  program_name TEXT NOT NULL,
  sessions JSONB NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);
```

### ساختار JSON برنامه تمرینی

برنامه‌های تمرینی به صورت یک ساختار JSON در ستون `sessions` ذخیره می‌شوند. نمونه ساختار به صورت زیر است:

```json
[
  {
    "id": "session-123",
    "day": "شنبه",
    "exercises": [
      {
        "id": "exercise-1",
        "type": "normal",
        "exercise_id": 1,
        "exercise_name": "پرس سینه",
        "tag": "سینه",
        "style": "normal",
        "sets": [
          {"reps": 12, "weight": 60},
          {"reps": 10, "weight": 70},
          {"reps": 8, "weight": 80}
        ]
      },
      {
        "id": "exercise-2",
        "type": "superset",
        "tag": "سینه و جلو بازو",
        "style": "superset",
        "exercises": [
          {
            "exercise_id": 2,
            "exercise_name": "جلو بازو هالتر",
            "sets": [
              {"reps": 12, "weight": 25},
              {"reps": 10, "weight": 30}
            ]
          },
          {
            "exercise_id": 3,
            "exercise_name": "قفسه سینه دمبل",
            "sets": [
              {"reps": 12, "weight": 20},
              {"reps": 10, "weight": 22.5}
            ]
          }
        ]
      }
    ]
  }
]
```

### نمونه استفاده

برای دریافت برنامه‌های تمرینی یک کاربر:

```dart
final workoutLogs = await workoutProgramLogService.getUserProgramLogs(userId);
```

برای ذخیره یک برنامه تمرینی جدید:

```dart
final newLog = WorkoutProgramLog(
  userId: currentUser.id,
  programName: 'برنامه جدید',
  sessions: [
    WorkoutSessionLog(
      id: 'session-1',
      day: 'شنبه',
      exercises: [
        NormalExerciseLog(
          id: 'exercise-1',
          exerciseId: 1,
          exerciseName: 'پرس سینه',
          tag: 'سینه',
          style: 'normal',
          sets: [
            ExerciseSetLog(reps: 12, weight: 60.0),
            ExerciseSetLog(reps: 10, weight: 70.0),
          ],
        ),
      ],
    ),
  ],
);

await workoutProgramLogService.saveProgramLog(newLog);
```

## مهاجرت های پایگاه داده

برای اجرای مهاجرت‌های پایگاه داده، از دستور زیر استفاده کنید:

```
supabase db reset
```

یا برای اعمال مهاجرت‌های جدید بدون حذف داده‌ها:

```
supabase db push
```

### Other Tables

- `weight_records`: Tracks user weight over time
- `exercise_likes`: Tracks exercise likes by users
- `exercise_comments`: Stores user comments on exercises
- `achievements`: Tracks user achievements

## Getting Started

### Prerequisites

- Flutter SDK
- Supabase account
- Firebase (for notifications)

### Installation

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Set up your Supabase credentials in the `.env` file
4. Run the app using `flutter run`

## Features

- User authentication
- Exercise library with detailed instructions
- Custom workout program builder
- Progress tracking
- Body metrics tracking
- Achievements system
