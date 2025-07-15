import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/workout_program.dart';
import '../models/exercise.dart';
import '../services/workout_program_service.dart';
import '../models/workout_program_log.dart';
import '../services/workout_program_log_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/exercise_service.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../theme/app_theme.dart';
import '../widgets/program_selection_card.dart';
import '../widgets/exercise_card.dart';
import '../widgets/workout_calendar.dart';

class WorkoutLogScreen extends StatefulWidget {
  const WorkoutLogScreen({Key? key}) : super(key: key);

  @override
  State<WorkoutLogScreen> createState() => _WorkoutLogScreenState();
}

class _WorkoutLogScreenState extends State<WorkoutLogScreen>
    with TickerProviderStateMixin {
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

  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  final Map<DateTime, List<WorkoutProgramLog>> _workoutCalendar = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPrograms();
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
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
  }

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

  Future<void> _loadHistory() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final logs = await _workoutProgramLogService.getUserProgramLogs(userId);

      if (mounted) {
        setState(() {
          _historyLogs = logs;
        });
        _buildWorkoutCalendar();
      }

      _updateSavedSetsFromLogs();
    } catch (e) {
      debugPrint('Error loading workout history: $e');
    }
  }

  void _buildWorkoutCalendar() {
    _workoutCalendar.clear();
    for (final log in _historyLogs) {
      final date =
          DateTime(log.createdAt.year, log.createdAt.month, log.createdAt.day);
      if (!_workoutCalendar.containsKey(date)) {
        _workoutCalendar[date] = [];
      }
      _workoutCalendar[date]!.add(log);
    }
  }

  void _updateSavedSetsFromLogs() {
    _savedSets.clear();
    final today = DateTime.now().toUtc();
    final sortedLogs = List.of(_historyLogs)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final todayLogs = sortedLogs
        .where((log) =>
            log.createdAt.year == today.year &&
            log.createdAt.month == today.month &&
            log.createdAt.day == today.day)
        .toList();

    if (todayLogs.isEmpty) return;

    final Map<String, WorkoutProgramLog> latestLogsByProgram = {};
    for (final log in todayLogs) {
      final programName = log.programName;
      if (!latestLogsByProgram.containsKey(programName) ||
          log.updatedAt.isAfter(latestLogsByProgram[programName]!.updatedAt)) {
        latestLogsByProgram[programName] = log;
      }
    }

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

  void _onSelectProgram(WorkoutProgram? program) async {
    setState(() {
      _selectedProgram = program;
      _selectedSession =
          program?.sessions.isNotEmpty == true ? program!.sessions.first : null;
    });
    await _initExerciseControllers();
  }

  void _onSelectSession(WorkoutSession? session) async {
    setState(() {
      _selectedSession = session;
    });
    await _initExerciseControllers();
  }

  Future<void> _initExerciseControllers() async {
    _disposeControllers();
    _repsControllers.clear();
    _weightControllers.clear();
    _exerciseDetails.clear();

    if (_selectedSession == null) return;

    for (final ex in _selectedSession!.exercises) {
      if (ex is NormalExercise) {
        final exercise = await _exerciseService.getExerciseById(ex.exerciseId);
        _exerciseDetails[ex.exerciseId] = exercise;

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

  Future<void> _saveSet(int exerciseId, int setIdx) async {
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

      final workoutProgramLogService = WorkoutProgramLogService();
      final savedLog = await workoutProgramLogService.saveProgramLog(log);

      if (savedLog == null) {
        throw Exception('Failed to save log. Database returned null.');
      }

      final exerciseKey = exerciseId.toString();
      if (!_savedSets.containsKey(exerciseKey)) {
        _savedSets[exerciseKey] = {};
      }
      _savedSets[exerciseKey]![setIdx] = true;

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

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final persianDate = _getPersianFormattedDate(now);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: Column(
          children: [
            const Text(
              'ثبت تمرین',
              style: TextStyle(
                color: AppTheme.goldColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              persianDate,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowRight, color: AppTheme.goldColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.goldColor))
          : Column(
              children: [
                _buildTabBar(),
                Expanded(child: _buildTabBarView()),
              ],
            ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.goldColor,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.black,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.dumbbell, size: 16),
                SizedBox(width: 6),
                Text('امروز'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.calendar, size: 16),
                SizedBox(width: 6),
                Text('تقویم'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildTodayWorkout(),
        _buildCalendarTab(),
      ],
    );
  }

  Widget _buildTodayWorkout() {
    return Column(
      children: [
        ProgramSelectionCard(
          programs: _programs,
          selectedProgram: _selectedProgram,
          selectedSession: _selectedSession,
          onProgramChanged: _onSelectProgram,
          onSessionChanged: _onSelectSession,
        ),
        Expanded(child: _buildExercisesList()),
      ],
    );
  }

  Widget _buildCalendarTab() {
    return Column(
      children: [
        WorkoutCalendar(
          workoutCalendar: _workoutCalendar,
          onDateSelected: _onDateSelected,
        ),
        Expanded(
          child: WorkoutDayDetails(
            selectedDate: _selectedDate,
            workouts: _workoutCalendar[_selectedDate] ?? [],
          ),
        ),
      ],
    );
  }

  Widget _buildExercisesList() {
    if (_selectedSession == null) {
      return _buildEmptyState('جلسه‌ای انتخاب نشده');
    }

    if (_selectedSession!.exercises.isEmpty) {
      return _buildEmptyState('هیچ تمرینی برای این جلسه تعریف نشده است.');
    }

    final exercises =
        _selectedSession!.exercises.whereType<NormalExercise>().toList();

    if (exercises.isEmpty) {
      return _buildEmptyState(
          'هیچ تمرین استانداردی برای این جلسه تعریف نشده است.');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: exercises.length,
      itemBuilder: (context, idx) {
        final exercise = exercises[idx];
        final exerciseDetails = _exerciseDetails[exercise.exerciseId];
        final exerciseKey = exercise.exerciseId.toString();
        final loggedSets = _savedSets[exerciseKey]
                ?.entries
                .where((entry) => entry.value)
                .length ??
            0;

        return ExerciseCard(
          exercise: exercise,
          exerciseDetails: exerciseDetails,
          loggedSets: loggedSets,
          repsControllers: _repsControllers,
          weightControllers: _weightControllers,
          savedSets: _savedSets,
          onSaveSet: _saveSet,
          findLastSetLog: _findLastSetLog,
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.dumbbell,
            size: 64,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  String _getPersianFormattedDate(DateTime date) {
    final gregorian = Gregorian.fromDateTime(date);
    final jalali = gregorian.toJalali();
    final weekDay = _getPersianWeekDay(date.weekday);
    return '$weekDay ${jalali.day}/${jalali.month}/${jalali.year}';
  }

  String _getPersianWeekDay(int weekday) {
    const weekdays = [
      '',
      'دوشنبه',
      'سه‌شنبه',
      'چهارشنبه',
      'پنج‌شنبه',
      'جمعه',
      'شنبه',
      'یکشنبه'
    ];
    return weekdays[weekday];
  }
}
