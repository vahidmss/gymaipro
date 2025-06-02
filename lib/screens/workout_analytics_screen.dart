import 'package:flutter/material.dart';
import '../models/workout_log.dart';
import '../services/workout_log_service.dart';
import '../widgets/workout_log_export_button.dart';

class WorkoutAnalyticsScreen extends StatefulWidget {
  final String userId;

  const WorkoutAnalyticsScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<WorkoutAnalyticsScreen> createState() => _WorkoutAnalyticsScreenState();
}

class _WorkoutAnalyticsScreenState extends State<WorkoutAnalyticsScreen> {
  final WorkoutLogService _workoutLogService = WorkoutLogService();

  // Filters
  DateTime? _startDate;
  DateTime? _endDate;
  String? _muscleGroup;

  // Data
  Map<String, dynamic>? _analyticsData;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Set default date range to last 30 days
    _endDate = DateTime.now();
    _startDate = _endDate!.subtract(const Duration(days: 30));
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final filter = WorkoutLogFilter(
        startDate: _startDate,
        endDate: _endDate,
        exerciseTag: _muscleGroup,
      );

      final logs = await _workoutLogService.getUserLogs(
        widget.userId,
        filter: filter,
      );

      if (logs.isEmpty) {
        _analyticsData = {
          'total_workouts': 0,
          'total_exercises': 0,
          'total_sets': 0,
          'total_duration': 0,
          'most_trained_muscle': 'N/A',
          'favorite_exercise': 'N/A',
        };
      } else {
        _calculateAnalytics(logs);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _calculateAnalytics(List<WorkoutLog> logs) {
    // Calculate various metrics
    final totalWorkouts = logs.length;
    final exerciseIds = <String>{};
    var totalSets = 0;
    var totalDuration = 0;

    // Track muscle groups and exercises
    final muscleGroups = <String, int>{};
    final exercises = <String, int>{};

    for (final log in logs) {
      exerciseIds.add(log.exerciseId);
      totalSets += log.sets.length;

      if (log.durationSeconds != null) {
        totalDuration += log.durationSeconds!;
      }

      // Track muscle groups
      if (log.exerciseTag != null) {
        muscleGroups[log.exerciseTag!] =
            (muscleGroups[log.exerciseTag!] ?? 0) + 1;
      }

      // Track exercises
      if (log.exerciseName != null) {
        exercises[log.exerciseName!] = (exercises[log.exerciseName!] ?? 0) + 1;
      }
    }

    // Find most trained muscle group
    String mostTrainedMuscle = 'N/A';
    int maxMuscleCount = 0;
    muscleGroups.forEach((muscle, count) {
      if (count > maxMuscleCount) {
        maxMuscleCount = count;
        mostTrainedMuscle = muscle;
      }
    });

    // Find favorite exercise
    String favoriteExercise = 'N/A';
    int maxExerciseCount = 0;
    exercises.forEach((exercise, count) {
      if (count > maxExerciseCount) {
        maxExerciseCount = count;
        favoriteExercise = exercise;
      }
    });

    _analyticsData = {
      'total_workouts': totalWorkouts,
      'total_exercises': exerciseIds.length,
      'total_sets': totalSets,
      'total_duration': totalDuration,
      'most_trained_muscle': mostTrainedMuscle,
      'favorite_exercise': favoriteExercise,
      'muscle_groups': muscleGroups,
      'exercises': exercises,
    };

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterOptions,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: WorkoutLogExportButton(
        userId: widget.userId,
        filter: WorkoutLogFilter(
          startDate: _startDate,
          endDate: _endDate,
          exerciseTag: _muscleGroup,
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAnalytics,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_analyticsData == null || _analyticsData!['total_workouts'] == 0) {
      return const Center(
        child: Text('No workout data found for the selected period'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateRangeInfo(),
          const SizedBox(height: 24),
          _buildSummaryCards(),
          const SizedBox(height: 24),
          _buildMuscleGroupsChart(),
          const SizedBox(height: 24),
          _buildTopExercisesChart(),
        ],
      ),
    );
  }

  Widget _buildDateRangeInfo() {
    final startFormatted = _startDate?.toString().split(' ')[0] ?? 'All time';
    final endFormatted = _endDate?.toString().split(' ')[0] ?? 'Today';

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Workout Analysis',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Date Range: $startFormatted to $endFormatted',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (_muscleGroup != null) ...[
              const SizedBox(height: 4),
              Text(
                'Filtered by muscle group: $_muscleGroup',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildSummaryCard(
          'Total Workouts',
          _analyticsData!['total_workouts'].toString(),
          Icons.fitness_center,
        ),
        _buildSummaryCard(
          'Total Exercises',
          _analyticsData!['total_exercises'].toString(),
          Icons.sports_gymnastics,
        ),
        _buildSummaryCard(
          'Total Sets',
          _analyticsData!['total_sets'].toString(),
          Icons.repeat,
        ),
        _buildSummaryCard(
          'Total Duration',
          '${(_analyticsData!['total_duration'] / 60).toStringAsFixed(1)} min',
          Icons.timer,
        ),
        _buildSummaryCard(
          'Most Trained Muscle',
          _analyticsData!['most_trained_muscle'],
          Icons.accessibility_new,
        ),
        _buildSummaryCard(
          'Favorite Exercise',
          _analyticsData!['favorite_exercise'],
          Icons.favorite,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMuscleGroupsChart() {
    final muscleGroups = _analyticsData!['muscle_groups'] as Map<String, int>;
    if (muscleGroups.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sort by count
    final sortedEntries = muscleGroups.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Muscle Groups',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...sortedEntries.take(5).map((entry) {
              final percentage =
                  (entry.value / _analyticsData!['total_workouts'] * 100)
                      .toStringAsFixed(1);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key,
                            style: Theme.of(context).textTheme.titleSmall),
                        Text('${entry.value} ($percentage%)',
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: entry.value / _analyticsData!['total_workouts'],
                      minHeight: 8,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopExercisesChart() {
    final exercises = _analyticsData!['exercises'] as Map<String, int>;
    if (exercises.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sort by count
    final sortedEntries = exercises.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Exercises',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...sortedEntries.take(5).map((entry) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text('${entry.value}'),
                ),
                title: Text(entry.key),
                subtitle:
                    Text('${entry.value} workout${entry.value > 1 ? "s" : ""}'),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Options',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              // Date range
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setModalState(() => _startDate = date);
                        }
                      },
                      child: Text(
                          'Start: ${_startDate?.toString().split(' ')[0] ?? 'All'}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setModalState(() => _endDate = date);
                        }
                      },
                      child: Text(
                          'End: ${_endDate?.toString().split(' ')[0] ?? 'Now'}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Muscle group filter
              DropdownButtonFormField<String?>(
                value: _muscleGroup,
                decoration: const InputDecoration(
                  labelText: 'Muscle Group',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All Muscle Groups'),
                  ),
                  ...['Chest', 'Back', 'Legs', 'Shoulders', 'Arms', 'Core'].map(
                    (group) => DropdownMenuItem<String?>(
                      value: group,
                      child: Text(group),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setModalState(() => _muscleGroup = value);
                },
              ),
              const SizedBox(height: 24),
              // Apply filters button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _loadAnalytics();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Apply Filters'),
                ),
              ),
              const SizedBox(height: 8),
              // Reset filters button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    setModalState(() {
                      _startDate =
                          DateTime.now().subtract(const Duration(days: 30));
                      _endDate = DateTime.now();
                      _muscleGroup = null;
                    });
                  },
                  child: const Text('Reset Filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
