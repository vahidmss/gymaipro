import 'package:flutter/material.dart';
import '../models/workout_program.dart';
import '../models/exercise.dart';
import '../services/workout_program_service.dart';
import '../models/workout_program_log.dart';
import '../services/workout_program_log_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/exercise_service.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:cached_network_image/cached_network_image.dart';

class WorkoutLogScreen extends StatefulWidget {
  const WorkoutLogScreen({Key? key}) : super(key: key);

  @override
  State<WorkoutLogScreen> createState() => _WorkoutLogScreenState();
}

class _WorkoutLogScreenState extends State<WorkoutLogScreen> {
  final _workoutProgramService = WorkoutProgramService();
  final _workoutProgramLogService = WorkoutProgramLogService();
  final _exerciseService = ExerciseService();

  List<WorkoutProgram> _programs = [];
  WorkoutProgram? _selectedProgram;
  WorkoutSession? _selectedSession;
  bool _isLoading = true;
  final Map<int, Exercise?> _exerciseDetails = {};
  List<WorkoutProgramLog> _historyLogs = [];
  final Map<String, Map<int, bool>> _savedSets = {};
  final Map<int, List<TextEditingController>> _repsControllers = {};
  final Map<int, List<TextEditingController>> _weightControllers = {};

  @override
  void initState() {
    super.initState();
    _loadPrograms();
    _loadHistory();
  }

  @override
  void dispose() {
    // Clean up all controllers
    for (var controllers in _repsControllers.values) {
      for (var controller in controllers) {
        controller.dispose();
      }
    }
    for (var controllers in _weightControllers.values) {
      for (var controller in controllers) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  /// Load available workout programs
  Future<void> _loadPrograms() async {
    final programs = await _workoutProgramService.getPrograms();
    if (mounted) {
      setState(() {
        _programs = programs;
        _selectedProgram = programs.isNotEmpty ? programs.first : null;
        _selectedSession = _selectedProgram?.sessions.isNotEmpty == true
            ? _selectedProgram!.sessions.first
            : null;
        _isLoading = false;
      });
    }
    await _initExerciseControllers();
  }

  /// Load workout history logs
  Future<void> _loadHistory() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final logs = await _workoutProgramLogService.getUserProgramLogs(userId);

      if (mounted) {
        setState(() {
          _historyLogs = logs;
        });
      }

      _updateSavedSetsFromLogs();
    } catch (e) {
      debugPrint('Error loading workout history: $e');
    }
  }

  /// Update saved sets from logs
  void _updateSavedSetsFromLogs() {
    _savedSets.clear();

    final today = DateTime.now().toUtc();

    // Sort logs by creation time (newest first)
    final sortedLogs = List.of(_historyLogs)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Consider only today's logs
    final todayLogs = sortedLogs
        .where((log) =>
            log.createdAt.year == today.year &&
            log.createdAt.month == today.month &&
            log.createdAt.day == today.day)
        .toList();

    if (todayLogs.isEmpty) {
      return;
    }

    // For each program, find the latest logs of today (grouped by program name)
    final Map<String, WorkoutProgramLog> latestLogsByProgram = {};
    for (final log in todayLogs) {
      final programName = log.programName;
      if (!latestLogsByProgram.containsKey(programName) ||
          log.updatedAt.isAfter(latestLogsByProgram[programName]!.updatedAt)) {
        latestLogsByProgram[programName] = log;
      }
    }

    // For each program, update all exercises recorded in the latest log
    for (final log in latestLogsByProgram.values) {
      for (final session in log.sessions) {
        for (final exercise in session.exercises) {
          if (exercise is NormalExerciseLog) {
            final exerciseKey = exercise.exerciseId.toString();

            if (!_savedSets.containsKey(exerciseKey)) {
              _savedSets[exerciseKey] = {};
            }

            for (int i = 0; i < exercise.sets.length; i++) {
              _savedSets[exerciseKey]![i] = true;
            }
          }
        }
      }
    }
  }

  /// Handle program selection
  void _onSelectProgram(WorkoutProgram? program) async {
    setState(() {
      _selectedProgram = program;
      _selectedSession =
          program?.sessions.isNotEmpty == true ? program!.sessions.first : null;
    });
    await _initExerciseControllers();
  }

  /// Handle session selection
  void _onSelectSession(WorkoutSession? session) async {
    setState(() {
      _selectedSession = session;
    });
    await _initExerciseControllers();
  }

  /// Initialize controllers for all exercises in the selected session
  Future<void> _initExerciseControllers() async {
    // Clear previous controllers
    for (var controllers in _repsControllers.values) {
      for (var controller in controllers) {
        controller.dispose();
      }
    }
    for (var controllers in _weightControllers.values) {
      for (var controller in controllers) {
        controller.dispose();
      }
    }

    _repsControllers.clear();
    _weightControllers.clear();
    _exerciseDetails.clear();

    if (_selectedSession == null) return;

    for (final ex in _selectedSession!.exercises) {
      if (ex is NormalExercise) {
        final exercise = await _exerciseService.getExerciseById(ex.exerciseId);
        _exerciseDetails[ex.exerciseId] = exercise;

        // Create controllers for each set
        _repsControllers[ex.exerciseId] =
            List.generate(ex.sets.length, (i) => TextEditingController());
        _weightControllers[ex.exerciseId] =
            List.generate(ex.sets.length, (i) => TextEditingController());
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  /// Find the last set log for a specific exercise and set index
  ExerciseSetLog? _findLastSetLog(int exerciseId, int setIdx) {
    final sortedLogs = List.of(_historyLogs)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    for (final log in sortedLogs) {
      for (final session in log.sessions) {
        for (final ex in session.exercises) {
          if (ex is NormalExerciseLog &&
              ex.exerciseId == exerciseId &&
              ex.sets.length > setIdx) {
            return ex.sets[setIdx];
          }
        }
      }
    }
    return null;
  }

  /// Save a set to the database
  Future<void> _saveSet(int exerciseId, int setIdx) async {
    // Close keyboard first
    FocusScope.of(context).unfocus();

    setState(() {});
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      final exercise = _selectedSession!.exercises.firstWhere(
              (ex) => ex is NormalExercise && ex.exerciseId == exerciseId)
          as NormalExercise;

      final reps = exercise.style == ExerciseStyle.setsReps
          ? int.tryParse(_repsControllers[exerciseId]![setIdx].text)
          : null;
      final seconds = exercise.style == ExerciseStyle.setsTime
          ? int.tryParse(_repsControllers[exerciseId]![setIdx].text)
          : null;
      final weight =
          double.tryParse(_weightControllers[exerciseId]![setIdx].text);

      if ((reps == null && seconds == null) || (reps == 0 && seconds == 0)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('لطفا مقدار تکرار یا زمان را وارد کنید'),
            backgroundColor: Colors.amber));
        setState(() {});
        return;
      }

      final programName = _selectedProgram?.name ?? 'برنامه تمرینی';
      final sessionDay = _selectedSession?.day ?? 'جلسه تمرینی';

      final log = WorkoutProgramLog(
        id: '',
        userId: userId,
        programName: programName,
        sessions: [
          WorkoutSessionLog(
            id: '',
            day: sessionDay,
            exercises: [
              NormalExerciseLog(
                id: '',
                exerciseId: exerciseId,
                exerciseName: _exerciseDetails[exerciseId]?.name ?? '',
                tag: exercise.tag,
                style: exercise.style == ExerciseStyle.setsReps
                    ? 'sets_reps'
                    : 'sets_time',
                sets: [
                  ExerciseSetLog(reps: reps, seconds: seconds, weight: weight)
                ],
              ),
            ],
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Use WorkoutProgramLogService to save the log
      final workoutProgramLogService = WorkoutProgramLogService();
      final savedLog = await workoutProgramLogService.saveProgramLog(log);

      if (savedLog == null) {
        throw Exception('Failed to save log. Database returned null.');
      }

      // Update saved sets tracking
      final exerciseKey = exerciseId.toString();
      if (!_savedSets.containsKey(exerciseKey)) {
        _savedSets[exerciseKey] = {};
      }
      _savedSets[exerciseKey]![setIdx] = true;

      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ست با موفقیت ثبت شد'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('خطا در ثبت ست: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get current date for header
    final now = DateTime.now();
    final persianDate = _getPersianFormattedDate(now);

    return GestureDetector(
      onTap: () {
        // Close keyboard when tapping elsewhere
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(persianDate),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildProgramSelectionRow(),
                  Expanded(
                    child: _buildExercisesList(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildProgramSelectionRow() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<WorkoutProgram>(
              value: _selectedProgram,
              decoration: const InputDecoration(
                labelText: 'برنامه تمرینی',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _programs
                  .map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(p.name, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: _onSelectProgram,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<WorkoutSession>(
              value: _selectedSession,
              decoration: const InputDecoration(
                labelText: 'جلسه',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _selectedProgram?.sessions
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.day, overflow: TextOverflow.ellipsis),
                          ))
                      .toList() ??
                  [],
              onChanged: _onSelectSession,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExercisesList() {
    if (_selectedSession == null) {
      return const Center(
        child: Text(
          'جلسه‌ای انتخاب نشده',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_selectedSession!.exercises.isEmpty) {
      return const Center(
        child: Text(
          'هیچ تمرینی برای این جلسه تعریف نشده است.',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );
    }

    // Filter to show only NormalExercise for now
    final exercises =
        _selectedSession!.exercises.whereType<NormalExercise>().toList();

    if (exercises.isEmpty) {
      return const Center(
        child: Text(
          'هیچ تمرین استانداردی برای این جلسه تعریف نشده است.',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: exercises.length,
      itemBuilder: (context, idx) {
        final exercise = exercises[idx];
        return _buildExerciseCard(exercise);
      },
    );
  }

  Widget _buildExerciseCard(NormalExercise exercise) {
    final exerciseDetails = _exerciseDetails[exercise.exerciseId];
    final exerciseKey = exercise.exerciseId.toString();

    // Check how many sets are logged
    final loggedSets =
        _savedSets[exerciseKey]?.entries.where((entry) => entry.value).length ??
            0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Exercise header with image and name
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Exercise image
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(0),
                ),
                child: exerciseDetails?.imageUrl != null &&
                        exerciseDetails!.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: exerciseDetails.imageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey.shade300,
                          child: const Center(
                              child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )),
                        ),
                        errorWidget: (c, e, s) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.fitness_center, size: 40),
                        ),
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.fitness_center, size: 40),
                      ),
              ),

              // Exercise info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exerciseDetails?.name ?? 'تمرین',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        exercise.tag,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              exercise.style == ExerciseStyle.setsReps
                                  ? 'ست-تکرار'
                                  : 'ست-زمان',
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (loggedSets > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '$loggedSets/${exercise.sets.length}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Exercise sets logging
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              children: List.generate(
                exercise.sets.length,
                (setIdx) => _buildSetRow(exercise, setIdx),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetRow(NormalExercise exercise, int setIdx) {
    final exerciseId = exercise.exerciseId;
    final exerciseKey = exerciseId.toString();
    final isLogged = _savedSets[exerciseKey]?[setIdx] ?? false;
    final lastLog = _findLastSetLog(exerciseId, setIdx);

    // Get planned value for this set
    final setPlannedValue = exercise.style == ExerciseStyle.setsReps
        ? (exercise.sets[setIdx].reps?.toString() ?? '')
        : (exercise.sets[setIdx].timeSeconds?.toString() ?? '');

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          // Set number indicator
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isLogged
                  ? Colors.green
                  : Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${setIdx + 1}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isLogged
                    ? Colors.white
                    : Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Reps/Time input
          Expanded(
            child: TextField(
              controller: _repsControllers[exerciseId]?[setIdx],
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                border: const OutlineInputBorder(),
                labelText: exercise.style == ExerciseStyle.setsReps
                    ? 'تکرار'
                    : 'ثانیه',
                hintText: setPlannedValue,
                suffixIcon: lastLog != null
                    ? IconButton(
                        icon: const Icon(Icons.history, size: 16),
                        onPressed: () {
                          final value = exercise.style == ExerciseStyle.setsReps
                              ? lastLog.reps?.toString() ?? ''
                              : lastLog.seconds?.toString() ?? '';
                          setState(() {
                            _repsControllers[exerciseId]![setIdx].text = value;
                          });
                        },
                      )
                    : null,
              ),
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 8),

          // Weight input
          Expanded(
            child: TextField(
              controller: _weightControllers[exerciseId]?[setIdx],
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                border: const OutlineInputBorder(),
                labelText: 'وزن',
                hintText: lastLog?.weight?.toString() ?? '',
                suffixIcon: lastLog?.weight != null
                    ? IconButton(
                        icon: const Icon(Icons.history, size: 16),
                        onPressed: () {
                          setState(() {
                            _weightControllers[exerciseId]![setIdx].text =
                                lastLog!.weight?.toString() ?? '';
                          });
                        },
                      )
                    : null,
              ),
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 8),

          // Save button
          ElevatedButton(
            onPressed: () => _saveSet(exerciseId, setIdx),
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(8),
              backgroundColor: isLogged
                  ? Colors.green
                  : Theme.of(context).colorScheme.primary,
            ),
            child: Icon(
              isLogged ? Icons.check : Icons.save,
              color: Colors.white,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  /// Convert DateTime to Persian formatted date
  String _getPersianFormattedDate(DateTime date) {
    final gregorian = Gregorian.fromDateTime(date);
    final jalali = gregorian.toJalali();

    final weekDay = _getPersianWeekDay(date.weekday);

    return '$weekDay ${jalali.day}/${jalali.month}/${jalali.year}';
  }

  /// Get Persian weekday name
  String _getPersianWeekDay(int weekday) {
    switch (weekday) {
      case 1:
        return 'دوشنبه';
      case 2:
        return 'سه‌شنبه';
      case 3:
        return 'چهارشنبه';
      case 4:
        return 'پنجشنبه';
      case 5:
        return 'جمعه';
      case 6:
        return 'شنبه';
      case 7:
        return 'یکشنبه';
      default:
        return '';
    }
  }
}
