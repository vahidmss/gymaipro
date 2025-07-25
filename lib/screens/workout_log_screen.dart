import 'package:flutter/material.dart';
import 'package:gymaipro/workout_plan/workout_plan_builder/models/workout_program.dart';
import 'package:gymaipro/workout_plan/workout_plan_builder/services/workout_program_service.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/exercise.dart';
import '../models/workout_program_log.dart';
import '../services/workout_program_log_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/exercise_service.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../theme/app_theme.dart';
import '../widgets/program_selection_card.dart';
import '../widgets/gold_button.dart';
/*
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

  final Map<DateTime, List<WorkoutProgramLog>> _workoutCalendar = {};
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
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

  Future<void> _loadHistory({DateTime? forDate}) async {
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

      _updateSavedSetsFromLogs(forDate: forDate ?? _selectedDate);
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

  void _updateSavedSetsFromLogs({DateTime? forDate}) {
    _savedSets.clear();
    final targetDate = forDate ?? _selectedDate;
    final sortedLogs = List.of(_historyLogs)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final dayLogs = sortedLogs
        .where((log) =>
            log.createdAt.year == targetDate.year &&
            log.createdAt.month == targetDate.month &&
            log.createdAt.day == targetDate.day)
        .toList();

    if (dayLogs.isEmpty) return;

    final Map<String, WorkoutProgramLog> latestLogsByProgram = {};
    for (final log in dayLogs) {
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

    // پیدا کردن لاگ روز انتخاب‌شده برای مقداردهی اولیه
    final targetDate = _selectedDate;
    WorkoutProgramLog? dayLog;
    for (final log in _historyLogs) {
      if (log.programName == _selectedProgram?.name &&
          log.createdAt.year == targetDate.year &&
          log.createdAt.month == targetDate.month &&
          log.createdAt.day == targetDate.day) {
        dayLog = log;
        break;
      }
    }

    for (final ex in _selectedSession!.exercises) {
      if (ex is NormalExercise) {
        final exercise = await _exerciseService.getExerciseById(ex.exerciseId);
        _exerciseDetails[ex.exerciseId] = exercise;

        _repsControllers[ex.exerciseId] =
            List.generate(ex.sets.length, (i) => TextEditingController());
        _weightControllers[ex.exerciseId] =
            List.generate(ex.sets.length, (i) => TextEditingController());

        // اگر مقدار ثبت‌شده برای این ست وجود دارد، مقدار آن را در کنترلر قرار بده
        if (dayLog != null) {
          for (final session in dayLog.sessions) {
            for (final logEx in session.exercises) {
              if (logEx is NormalExerciseLog &&
                  logEx.exerciseId == ex.exerciseId) {
                for (int i = 0; i < ex.sets.length; i++) {
                  if (i < logEx.sets.length) {
                    final setLog = logEx.sets[i];
                    if (setLog.reps != null) {
                      _repsControllers[ex.exerciseId]![i].text =
                          setLog.reps.toString();
                    } else if (setLog.seconds != null) {
                      _repsControllers[ex.exerciseId]![i].text =
                          setLog.seconds.toString();
                    }
                    if (setLog.weight != null) {
                      _weightControllers[ex.exerciseId]![i].text =
                          setLog.weight.toString();
                    }
                  }
                }
              }
            }
          }
        }
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

      // جمع‌آوری همه ست‌های این حرکت از کنترلرها
      final allSets = List.generate(exercise.sets.length, (i) {
        final reps = exercise.style == ExerciseStyle.setsReps
            ? int.tryParse(_repsControllers[exerciseId]![i].text)
            : null;
        final seconds = exercise.style == ExerciseStyle.setsTime
            ? int.tryParse(_repsControllers[exerciseId]![i].text)
            : null;
        final weight = double.tryParse(_weightControllers[exerciseId]![i].text);
        return ExerciseSetLog(reps: reps, seconds: seconds, weight: weight);
      });

      // اگر مقدار ست فعلی خالی بود، خطا بده
      final currentSet = allSets[setIdx];
      if (((currentSet.reps == null && currentSet.seconds == null) ||
          ((currentSet.reps ?? 0) == 0 && (currentSet.seconds ?? 0) == 0))) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('لطفا مقدار تکرار یا زمان را وارد کنید'),
            backgroundColor: Colors.amber));
        setState(() {});
        return;
      }

      final programName = _selectedProgram?.name ?? 'برنامه تمرینی';
      final sessionDay = _selectedSession?.day ?? 'جلسه تمرینی';

      // جستجوی لاگ امروز برای این برنامه و جلسه
      WorkoutProgramLog? todayLog;
      final today = DateTime.now();
      for (final log in _historyLogs) {
        if (log.programName == programName &&
            log.createdAt.year == today.year &&
            log.createdAt.month == today.month &&
            log.createdAt.day == today.day) {
          todayLog = log;
          break;
        }
      }

      List<WorkoutSessionLog> sessions = [];
      if (todayLog != null) {
        // اگر لاگ امروز وجود دارد، سشن‌ها را کپی کن
        sessions = List.from(todayLog.sessions);
      }

      // پیدا کردن یا ساختن سشن فعلی
      WorkoutSessionLog? sessionLog = sessions.firstWhere(
          (s) => s.day == sessionDay,
          orElse: () =>
              WorkoutSessionLog(id: '', day: sessionDay, exercises: []));

      // پیدا کردن یا ساختن حرکت فعلی
      NormalExerciseLog? exerciseLog = sessionLog.exercises.firstWhere(
          (e) => e is NormalExerciseLog && e.exerciseId == exerciseId,
          orElse: () => NormalExerciseLog(
                id: '',
                exerciseId: exerciseId,
                exerciseName: _exerciseDetails[exerciseId]?.name ?? '',
                tag: exercise.tag,
                style: exercise.style == ExerciseStyle.setsReps
                    ? 'sets_reps'
                    : 'sets_time',
                sets: List.generate(
                    exercise.sets.length, (i) => ExerciseSetLog()),
              )) as NormalExerciseLog?;

      // ست‌های قبلی را حفظ کن و فقط مقدار ست فعلی را آپدیت کن
      List<ExerciseSetLog> updatedSets;
      if (exerciseLog != null) {
        updatedSets = List<ExerciseSetLog>.from(exerciseLog.sets);
        for (int i = 0; i < allSets.length; i++) {
          if (i == setIdx) {
            updatedSets[i] = allSets[i];
          } else if (updatedSets.length > i &&
              (updatedSets[i].reps != null || updatedSets[i].seconds != null)) {
            // مقدار قبلی را حفظ کن
          } else {
            updatedSets[i] = allSets[i];
          }
        }
      } else {
        updatedSets = List<ExerciseSetLog>.from(allSets);
      }
      final updatedExerciseLog = NormalExerciseLog(
        id: exerciseLog?.id ?? '',
        exerciseId: exerciseLog?.exerciseId ?? exerciseId,
        exerciseName: exerciseLog?.exerciseName ??
            (_exerciseDetails[exerciseId]?.name ?? ''),
        tag: exerciseLog?.tag ?? exercise.tag,
        style: exerciseLog?.style ??
            (exercise.style == ExerciseStyle.setsReps
                ? 'sets_reps'
                : 'sets_time'),
        sets: updatedSets,
      );

      // جایگزینی یا افزودن حرکت در سشن
      final updatedExercises =
          List<WorkoutExerciseLog>.from(sessionLog.exercises);
      final exIdx = updatedExercises.indexWhere(
          (e) => e is NormalExerciseLog && (e).exerciseId == exerciseId);
      if (exIdx >= 0) {
        updatedExercises[exIdx] = updatedExerciseLog;
      } else {
        updatedExercises.add(updatedExerciseLog);
      }

      final updatedSessionLog = WorkoutSessionLog(
        id: sessionLog.id,
        day: sessionLog.day,
        exercises: updatedExercises,
      );

      // جایگزینی یا افزودن سشن در لاگ
      final sessionIdx = sessions.indexWhere((s) => s.day == sessionDay);
      if (sessionIdx >= 0) {
        sessions[sessionIdx] = updatedSessionLog;
      } else {
        sessions.add(updatedSessionLog);
      }

      final log = WorkoutProgramLog(
        id: todayLog?.id ?? '',
        userId: userId,
        programName: programName,
        logDate: today,
        sessions: sessions,
        createdAt: todayLog?.createdAt ?? DateTime.now(),
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

      // مقدار ثبت‌شده را به عنوان مقدار value در کنترلر قرار بده
      if (exercise.style == ExerciseStyle.setsReps && currentSet.reps != null) {
        _repsControllers[exerciseId]![setIdx].text = currentSet.reps.toString();
      } else if (exercise.style == ExerciseStyle.setsTime &&
          currentSet.seconds != null) {
        _repsControllers[exerciseId]![setIdx].text =
            currentSet.seconds.toString();
      }
      if (currentSet.weight != null) {
        _weightControllers[exerciseId]![setIdx].text =
            currentSet.weight.toString();
      }

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
    // Handle date selection if needed
  }

  @override
  Widget build(BuildContext context) {
    final persianDate = _getPersianFormattedDate(_selectedDate);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.goldColor))
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Unified header (like food log)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 32),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.goldColor,
                            AppTheme.backgroundColor
                          ],
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Back arrow (arrowLeft)
                          IconButton(
                            icon: const Icon(LucideIcons.arrowLeft,
                                color: AppTheme.goldColor),
                            onPressed: () => Navigator.pop(context),
                            tooltip: 'بازگشت',
                          ),
                          const SizedBox(width: 8),
                          const Icon(LucideIcons.dumbbell,
                              color: AppTheme.goldColor, size: 36),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                ' ثبت تمرین امروز',
                                style: AppTheme.headingStyle,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                persianDate,
                                style:
                                    AppTheme.bodyStyle.copyWith(fontSize: 15),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // Calendar icon (like food log)
                          IconButton(
                            icon: const Icon(LucideIcons.calendar,
                                color: AppTheme.goldColor),
                            onPressed: _showDatePicker,
                            tooltip: 'انتخاب تاریخ',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ProgramSelectionCard(
                      programs: _programs,
                      selectedProgram: _selectedProgram,
                      selectedSession: _selectedSession,
                      onProgramChanged: _onSelectProgram,
                      onSessionChanged: _onSelectSession,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 500, // or use MediaQuery for dynamic height
                      child: _buildExercisesList(),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _showDatePicker() async {
    await _showPersianDatePicker();
  }

  Future<void> _showPersianDatePicker() async {
    await showDialog(
      context: context,
      builder: (context) => _PersianDatePickerDialog(
        selectedDate: _selectedDate,
        onDateSelected: (date) async {
          setState(() => _selectedDate = date);
          await _loadHistory(forDate: date);
          await _initExerciseControllers();
        },
      ),
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
    final weekDay = _getPersianWeekDay(jalali.weekDay); // Use Jalali weekDay
    return '$weekDay ${jalali.day}/${jalali.month}/${jalali.year}';
  }

  String _getPersianWeekDay(int weekday) {
    // Jalali: 1=Saturday, 2=Sunday, ..., 7=Friday
    const weekdays = [
      '',
      'شنبه',
      'یکشنبه',
      'دوشنبه',
      'سه‌شنبه',
      'چهارشنبه',
      'پنج‌شنبه',
      'جمعه'
    ];
    return weekdays[weekday];
  }
}

// --- Persian Date Picker Dialog (copied from food_log_screen.dart) ---
class _PersianDatePickerDialog extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const _PersianDatePickerDialog({
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  State<_PersianDatePickerDialog> createState() =>
      _PersianDatePickerDialogState();
}

class _PersianDatePickerDialogState extends State<_PersianDatePickerDialog> {
  late DateTime _currentMonth;
  late DateTime _selectedDate;
  Map<DateTime, bool> _workoutLogDates = {};

  @override
  void initState() {
    super.initState();
    _currentMonth = widget.selectedDate;
    _selectedDate = widget.selectedDate;
    _loadWorkoutLogDates();
  }

  Future<void> _loadWorkoutLogDates() async {
    // Load dates that have workout logs for the current user in the visible month
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final gregorian = Gregorian.fromDateTime(_currentMonth);
    final jalali = gregorian.toJalali();
    final startJalali = Jalali(jalali.year, jalali.month, 1);
    final endJalali = Jalali(
        jalali.year, jalali.month, _getDaysInMonth(jalali.year, jalali.month));
    final startDate = startJalali.toGregorian().toDateTime();
    final endDate = endJalali.toGregorian().toDateTime();
    try {
      final response = await Supabase.instance.client
          .from('workout_program_logs')
          .select('log_date')
          .eq('user_id', user.id)
          .gte('log_date', startDate.toIso8601String().substring(0, 10))
          .lte('log_date', endDate.toIso8601String().substring(0, 10));
      final logDates = <DateTime, bool>{};
      for (final row in response) {
        final logDate = DateTime.parse(row['log_date']);
        logDates[logDate] = true;
      }
      setState(() {
        _workoutLogDates = logDates;
      });
    } catch (e) {
      setState(() {
        _workoutLogDates = {};
      });
    }
  }

  int _getDaysInMonth(int year, int month) {
    if (month <= 6) return 31;
    if (month <= 11) return 30;
    return Jalali(year).isLeapYear() ? 30 : 29;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCalendarHeader(),
            const SizedBox(height: 16),
            _buildCalendarGrid(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    child: const Text('لغو',
                        style: TextStyle(color: Colors.white70)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Expanded(
                  child: GoldButton(
                    text: 'انتخاب',
                    onPressed: () {
                      widget.onDateSelected(_selectedDate);
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppTheme.goldColor),
          onPressed: () {
            setState(() {
              _currentMonth =
                  DateTime(_currentMonth.year, _currentMonth.month - 1);
            });
            _loadWorkoutLogDates();
          },
        ),
        Column(
          children: [
            Text(
              _getPersianMonthName(_getPersianMonthNumber()),
              style: const TextStyle(
                color: AppTheme.goldColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              _convertToPersianNumbers(_getPersianYear().toString()),
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(LucideIcons.chevronRight, color: AppTheme.goldColor),
          onPressed: () {
            setState(() {
              _currentMonth =
                  DateTime(_currentMonth.year, _currentMonth.month + 1);
            });
            _loadWorkoutLogDates();
          },
        ),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    final gregorian = Gregorian.fromDateTime(_currentMonth);
    final jalali = gregorian.toJalali();
    int daysInMonth = _getDaysInMonth(jalali.year, jalali.month);
    final firstDayOfPersianMonth = Jalali(jalali.year, jalali.month, 1);
    final firstWeekdayPersian = firstDayOfPersianMonth.weekDay;
    final emptyBoxes = firstWeekdayPersian - 1;
    final totalCells = emptyBoxes + daysInMonth;
    final weeks = (totalCells / 7).ceil();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          _buildWeekdayHeaders(),
          ...List.generate(
            weeks,
            (weekIndex) => _buildWeekRow(
                weekIndex, emptyBoxes, daysInMonth, jalali.year, jalali.month),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeaders() {
    const weekdays = ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];
    return Row(
      children: weekdays
          .map((day) => Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(
                      color: AppTheme.goldColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildWeekRow(
      int weekIndex, int emptyBoxes, int daysInMonth, int year, int month) {
    final startCell = weekIndex * 7;
    return Row(
      children: List.generate(7, (dayIndex) {
        final cellIndex = startCell + dayIndex;
        final dayNumber = cellIndex - emptyBoxes + 1;
        if (dayNumber < 1 || dayNumber > daysInMonth) {
          return Expanded(child: Container());
        }
        final persianDate = Jalali(year, month, dayNumber);
        final gregorianDate = persianDate.toGregorian().toDateTime();
        final hasWorkoutLog = _workoutLogDates.containsKey(DateTime(
            gregorianDate.year, gregorianDate.month, gregorianDate.day));
        final isSelected = _selectedDate.year == gregorianDate.year &&
            _selectedDate.month == gregorianDate.month &&
            _selectedDate.day == gregorianDate.day;
        final now = DateTime.now();
        final isToday = now.year == gregorianDate.year &&
            now.month == gregorianDate.month &&
            now.day == gregorianDate.day;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = gregorianDate;
              });
            },
            child: Container(
              margin: const EdgeInsets.all(2),
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.goldColor
                    : hasWorkoutLog
                        ? Colors.green.withOpacity(0.2)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isToday ? AppTheme.goldColor : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      _convertToPersianNumbers(dayNumber.toString()),
                      style: TextStyle(
                        color: isSelected
                            ? Colors.black
                            : hasWorkoutLog
                                ? Colors.green
                                : Colors.white,
                        fontWeight: isSelected || hasWorkoutLog || isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (hasWorkoutLog)
                    Positioned(
                      bottom: 4,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  String _getPersianMonthName(int month) {
    const months = [
      '',
      'فروردین',
      'اردیبهشت',
      'خرداد',
      'تیر',
      'مرداد',
      'شهریور',
      'مهر',
      'آبان',
      'آذر',
      'دی',
      'بهمن',
      'اسفند'
    ];
    return months[month];
  }

  String _convertToPersianNumbers(String text) {
    const persianNumbers = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    const englishNumbers = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

    String result = text;
    for (int i = 0; i < 10; i++) {
      result = result.replaceAll(englishNumbers[i], persianNumbers[i]);
    }
    return result;
  }

  int _getPersianMonthNumber() {
    final gregorian = Gregorian.fromDateTime(_currentMonth);
    final jalali = gregorian.toJalali();
    return jalali.month;
  }

  int _getPersianYear() {
    final gregorian = Gregorian.fromDateTime(_currentMonth);
    final jalali = gregorian.toJalali();
    return jalali.year;
  }
}
*/
