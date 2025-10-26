# Workout Log Module

## Overview
The Workout Log module provides comprehensive functionality for tracking and managing workout sessions. It allows users to log their workouts, track progress, and analyze their fitness data.

## Structure

```
workout_log/
├── models/
│   ├── workout_log.dart              # Main workout log data model
│   └── workout_program_log.dart      # Program-specific workout logs
├── screens/
│   ├── workout_log_screen.dart       # Main workout logging interface
│   └── workout_log_details_screen.dart # Detailed view of workout logs
├── services/
│   └── workout_program_log_service.dart # Program-specific logging service
├── widgets/
│   ├── workout_log_app_bar.dart      # Custom app bar for workout log
│   ├── workout_session_selector.dart # Session selection widget
│   ├── persian_date_picker_dialog.dart # Persian date picker dialog
│   ├── exercise_card.dart            # Exercise card component
│   ├── empty_state_widgets.dart      # Empty state widgets
│   └── workout_log_widgets.dart      # Widget exports
└── README.md                         # This file
```

## Features

### Core Functionality
- **Workout Logging**: Record individual workout sessions with exercises, sets, reps, and weights
- **Program Integration**: Log workouts based on predefined workout programs
- **Progress Tracking**: Track performance over time with detailed analytics
- **Data Export**: Export workout data for external analysis

### Data Models

#### WorkoutLog
- `id`: Unique identifier
- `userId`: User who performed the workout
- `exerciseId`: Exercise performed
- `exerciseName`: Name of the exercise
- `exerciseTag`: Muscle group or category
- `sets`: List of sets with reps, weight, and rest time
- `durationSeconds`: Total workout duration
- `createdAt`: Timestamp of the workout
- `notes`: Optional notes about the workout

#### WorkoutProgramLog
- `id`: Unique identifier
- `userId`: User who performed the workout
- `programId`: Associated workout program
- `sessionIndex`: Which session of the program
- `workoutData`: JSON data containing exercise details
- `createdAt`: Timestamp of the workout

### Services

#### WorkoutLogService
- `getUserLogs()`: Retrieve all workout logs for a user
- `saveWorkoutLog()`: Save a new workout log
- `updateWorkoutLog()`: Update an existing workout log
- `deleteWorkoutLog()`: Delete a workout log
- `getLogsByProgram()`: Get logs for a specific program
- `getLogsByExercise()`: Get logs for a specific exercise

#### WorkoutProgramLogService
- `getUserProgramLogs()`: Get all program logs for a user
- `saveProgramLog()`: Save a program workout log
- `getLogsByDate()`: Get logs for a specific date range

### UI Components

#### WorkoutLogScreen
- Main interface for logging workouts
- Calendar view for selecting dates
- Exercise selection and input
- Set/rep/weight tracking
- Integration with workout programs

#### WorkoutLogDetailsScreen
- Detailed view of completed workouts
- Exercise breakdown
- Performance metrics
- Notes and comments

#### WorkoutLogExportButton
- Export workout data to JSON format
- Filtering options for export
- File download functionality

## Usage

### Basic Workout Logging
```dart
final workoutLogService = WorkoutLogService();

// Create a new workout log
final workoutLog = WorkoutLog(
  id: 'unique_id',
  userId: 'user_id',
  exerciseId: 'exercise_id',
  exerciseName: 'Bench Press',
  exerciseTag: 'Chest',
  sets: [
    WorkoutSet(reps: 10, weight: 135, restSeconds: 60),
    WorkoutSet(reps: 8, weight: 155, restSeconds: 60),
  ],
  durationSeconds: 1800,
  notes: 'Felt strong today!',
);

// Save the workout log
await workoutLogService.saveWorkoutLog(workoutLog);
```

### Program-Based Logging
```dart
final programLogService = WorkoutProgramLogService();

// Create a program log
final programLog = WorkoutProgramLog(
  id: 'unique_id',
  userId: 'user_id',
  programId: 'program_id',
  sessionIndex: 0,
  workoutData: {
    'exercises': [
      {
        'name': 'Bench Press',
        'sets': [
          {'reps': 10, 'weight': 135, 'completed': true},
          {'reps': 8, 'weight': 155, 'completed': true},
        ]
      }
    ]
  },
);

// Save the program log
await programLogService.saveProgramLog(programLog);
```

## Database Schema

### workout_logs Table
```sql
CREATE TABLE workout_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  exercise_id TEXT,
  exercise_name TEXT,
  exercise_tag TEXT,
  sets JSONB,
  duration_seconds INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  notes TEXT
);
```

### workout_program_logs Table
```sql
CREATE TABLE workout_program_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  program_id UUID REFERENCES workout_programs(id),
  session_index INTEGER,
  workout_data JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## Integration

### With Workout Programs
The workout log module integrates seamlessly with the workout plan builder:
- Users can log workouts based on predefined programs
- Automatic tracking of program completion
- Progress comparison against program goals

### With Analytics
- Provides data for fitness analytics
- Performance trend analysis
- Progress visualization

## Future Enhancements

- **Real-time Tracking**: Live workout tracking with timers
- **Social Features**: Share workouts with friends
- **Advanced Analytics**: Machine learning-based insights
- **Mobile Notifications**: Reminder and achievement notifications
- **Integration**: Connect with fitness devices and apps

## Dependencies

- `supabase_flutter`: Database operations
- `uuid`: Unique ID generation
- `flutter`: UI framework
- `path_provider`: File system access for exports

## Contributing

When contributing to this module:
1. Follow the existing code structure
2. Add comprehensive tests for new features
3. Update this README for any new functionality
4. Ensure proper error handling
5. Maintain backward compatibility 