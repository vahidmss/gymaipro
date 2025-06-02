import 'package:flutter/material.dart';
import '../models/workout_program.dart';
import '../models/exercise.dart';
import '../services/workout_program_service.dart';
import '../models/workout_program_log.dart';
import '../services/workout_program_log_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/exercise_service.dart';
import 'package:shamsi_date/shamsi_date.dart';

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
  int _selectedTab = 0;
  final List<_ExerciseLogState> _exerciseStates = [];
  final Map<int, Exercise?> _exerciseDetails = {};
  List<WorkoutProgramLog> _historyLogs = [];
  final Map<String, Map<int, bool>> _savedSets = {};

  @override
  void initState() {
    super.initState();
    _loadPrograms();
    _loadHistory();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // بارگذاری مجدد تاریخچه در صورت نیاز
    _loadHistory();
  }

  Future<void> _loadPrograms() async {
    final programs = await _workoutProgramService.getPrograms();
    setState(() {
      _programs = programs;
      _selectedProgram = programs.isNotEmpty ? programs.first : null;
      _selectedSession = _selectedProgram?.sessions.isNotEmpty == true
          ? _selectedProgram!.sessions.first
          : null;
      _isLoading = false;
    });
    await _initExerciseStates();
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
      }

      _updateSavedSetsFromLogs(shouldInitStates: true);
    } catch (e) {
      debugPrint('خطا در بارگیری تاریخچه تمرین: $e');
    }
  }

  void _updateSavedSetsFromLogs({bool shouldInitStates = true}) {
    _savedSets.clear();

    final today = DateTime.now().toUtc();

    // ابتدا لاگ‌ها را بر اساس زمان ایجاد مرتب می‌کنیم (جدیدترین اول)
    final sortedLogs = List.of(_historyLogs)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // فقط لاگ‌های امروز را در نظر می‌گیریم
    final todayLogs = sortedLogs
        .where((log) =>
            log.createdAt.year == today.year &&
            log.createdAt.month == today.month &&
            log.createdAt.day == today.day)
        .toList();

    if (todayLogs.isEmpty) {
      return; // اگر امروز هیچ لاگی نداریم، کاری نمی‌کنیم
    }

    // برای هر برنامه، آخرین لاگ‌های امروز را پیدا می‌کنیم (گروه‌بندی بر اساس نام برنامه)
    final Map<String, WorkoutProgramLog> latestLogsByProgram = {};
    for (final log in todayLogs) {
      final programName = log.programName;
      if (!latestLogsByProgram.containsKey(programName) ||
          log.updatedAt.isAfter(latestLogsByProgram[programName]!.updatedAt)) {
        latestLogsByProgram[programName] = log;
      }
    }

    // برای هر برنامه، تمام تمرین‌های ثبت شده در آخرین لاگ را به‌روز می‌کنیم
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

    // به‌روزرسانی وضعیت تمرین‌های نمایش داده شده
    if (shouldInitStates) {
      _initExerciseStates();
    }
  }

  void _onSelectProgram(WorkoutProgram? program) async {
    setState(() {
      _selectedProgram = program;
      _selectedSession =
          program?.sessions.isNotEmpty == true ? program!.sessions.first : null;
    });
    await _initExerciseStates();
  }

  void _onSelectSession(WorkoutSession? session) async {
    setState(() {
      _selectedSession = session;
    });
    await _initExerciseStates();
  }

  Future<void> _initExerciseStates() async {
    _exerciseStates.clear();
    _exerciseDetails.clear();
    if (_selectedSession == null) return;
    for (final ex in _selectedSession!.exercises) {
      if (ex is NormalExercise) {
        final exercise = await _exerciseService.getExerciseById(ex.exerciseId);
        _exerciseDetails[ex.exerciseId] = exercise;

        final exerciseKey = ex.exerciseId.toString();
        Map<int, bool> setStates = {};

        if (_savedSets.containsKey(exerciseKey)) {
          setStates = _savedSets[exerciseKey]!;
        }

        _exerciseStates.add(_ExerciseLogState(
          normalExercise: ex,
          exercise: exercise,
          savedSets: setStates,
          onSetLogged: (exerciseId, setIdx, isSaved) {
            _onSetLogged(exerciseId, setIdx, isSaved);
          },
          findLastSetLog: (setIdx) => _findLastSetLog(ex.exerciseId, setIdx),
        ));
      }
    }
    setState(() {});
  }

  void _onSetLogged(int exerciseId, int setIdx, bool isSaved) async {
    final exerciseKey = exerciseId.toString();
    if (!_savedSets.containsKey(exerciseKey)) {
      _savedSets[exerciseKey] = {};
    }
    _savedSets[exerciseKey]![setIdx] = isSaved;

    await _loadHistory();
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

  @override
  Widget build(BuildContext context) {
    // Get current date for header
    final now = DateTime.now();
    final persianDate = _getPersianFormattedDate(now);

    return GestureDetector(
      onTap: () {
        // بستن کیبورد با لمس صفحه
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        persianDate,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Program and session selection
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButton<WorkoutProgram>(
                              value: _selectedProgram,
                              isExpanded: true,
                              hint: const Text('برنامه تمرینی'),
                              items: _programs
                                  .map((p) => DropdownMenuItem(
                                        value: p,
                                        child: Text(p.name),
                                      ))
                                  .toList(),
                              onChanged: _onSelectProgram,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButton<WorkoutSession>(
                              value: _selectedSession,
                              isExpanded: true,
                              hint: const Text('جلسه'),
                              items: _selectedProgram?.sessions
                                      .map((s) => DropdownMenuItem(
                                            value: s,
                                            child: Text(s.day),
                                          ))
                                      .toList() ??
                                  [],
                              onChanged: _onSelectSession,
                            ),
                          ),
                          const SizedBox(width: 12),
                          ToggleButtons(
                            isSelected: [_selectedTab == 0, _selectedTab == 1],
                            onPressed: (idx) =>
                                setState(() => _selectedTab = idx),
                            borderRadius: BorderRadius.circular(8),
                            children: const [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Icon(Icons.edit_note),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Icon(Icons.history),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _selectedTab == 0
                          ? _buildLogTab(context)
                          : _buildHistoryTab(context),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildLogTab(BuildContext context) {
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('در حال بارگذاری تمرین‌ها...')
          ],
        ),
      );
    }

    if (_exerciseStates.isEmpty) {
      return const Center(
        child: Text(
          'هیچ تمرینی برای این جلسه تعریف نشده است.',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _exerciseStates.length,
      itemBuilder: (context, idx) => _exerciseStates[idx],
    );
  }

  Widget _buildHistoryTab(BuildContext context) {
    if (_historyLogs.isEmpty) {
      return const Center(child: Text('تاریخچه‌ای ثبت نشده است.'));
    }

    final Map<String, List<WorkoutProgramLog>> groupedLogs = {};

    for (final log in _historyLogs) {
      final date = _getPersianFormattedDate(log.createdAt);
      if (!groupedLogs.containsKey(date)) {
        groupedLogs[date] = [];
      }
      groupedLogs[date]!.add(log);
    }

    final sortedDates = groupedLogs.keys.toList()
      ..sort((a, b) {
        final aParts = a.split(' ')[1].split('/');
        final bParts = b.split(' ')[1].split('/');

        final yearComparison =
            int.parse(bParts[2]).compareTo(int.parse(aParts[2]));
        if (yearComparison != 0) return yearComparison;

        final monthComparison =
            int.parse(bParts[1]).compareTo(int.parse(aParts[1]));
        if (monthComparison != 0) return monthComparison;

        return int.parse(bParts[0]).compareTo(int.parse(aParts[0]));
      });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDates.length,
      itemBuilder: (context, dateIdx) {
        final date = sortedDates[dateIdx];
        final logs = groupedLogs[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 8),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  date,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length,
              itemBuilder: (context, logIdx) {
                final log = logs[logIdx];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ExpansionTile(
                    title: Text(log.programName,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(_getTimeFromDate(log.createdAt)),
                    leading: const Icon(Icons.fitness_center),
                    children: [
                      for (final session in log.sessions) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Text('جلسه: ${session.day}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        for (final ex in session.exercises)
                          if (ex is NormalExerciseLog) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('- ${ex.exerciseName}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500)),
                                  for (int i = 0; i < ex.sets.length; i++)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          right: 8, top: 2),
                                      child: Text(
                                          '  ست ${i + 1}: ${_formatSet(ex.sets[i], ex.style)}',
                                          style: TextStyle(
                                              color: Colors.grey.shade700,
                                              fontSize: 13)),
                                    ),
                                ],
                              ),
                            ),
                          ],
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  String _formatSet(ExerciseSetLog set, String style) {
    if (style == 'sets_time') {
      return '${set.seconds} ثانیه${set.weight != null && set.weight! > 0 ? ' - وزن: ${set.weight} کیلوگرم' : ''}';
    } else {
      return '${set.reps} تکرار${set.weight != null && set.weight! > 0 ? ' - وزن: ${set.weight} کیلوگرم' : ''}';
    }
  }

  String _getPersianFormattedDate(DateTime date) {
    final gregorian = Gregorian.fromDateTime(date);
    final jalali = gregorian.toJalali();

    final weekDay = _getPersianWeekDay(date.weekday);

    return '$weekDay ${jalali.day}/${jalali.month}/${jalali.year}';
  }

  String _getTimeFromDate(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

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

class _ExerciseLogState extends StatefulWidget {
  final NormalExercise normalExercise;
  final Exercise? exercise;
  final Map<int, bool> savedSets;
  final void Function(int exerciseId, int setIdx, bool isSaved) onSetLogged;
  final ExerciseSetLog? Function(int setIdx) findLastSetLog;

  const _ExerciseLogState({
    required this.normalExercise,
    required this.exercise,
    required this.onSetLogged,
    required this.findLastSetLog,
    this.savedSets = const {},
    Key? key,
  }) : super(key: key);

  @override
  State<_ExerciseLogState> createState() => _ExerciseLogStateState();
}

class _ExerciseLogStateState extends State<_ExerciseLogState> {
  late List<TextEditingController> repsOrTimeControllers;
  late List<TextEditingController> weightControllers;
  late List<bool> isSetLoading;
  late List<bool> isSetLogged;
  late bool expanded;

  @override
  void initState() {
    super.initState();
    // Use TextEditingController for each input field to prevent lag
    repsOrTimeControllers = List.generate(
        widget.normalExercise.sets.length, (i) => TextEditingController());
    weightControllers = List.generate(
        widget.normalExercise.sets.length, (i) => TextEditingController());
    isSetLoading =
        List.generate(widget.normalExercise.sets.length, (i) => false);

    // Initialize saved state for each set
    isSetLogged = List.generate(widget.normalExercise.sets.length,
        (i) => widget.savedSets.containsKey(i) ? widget.savedSets[i]! : false);

    expanded = false;
  }

  @override
  void dispose() {
    // Clean up controllers to prevent memory leaks
    for (final c in repsOrTimeControllers) {
      c.dispose();
    }
    for (final c in weightControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveSet(int setIdx) async {
    // قبل از هر کاری، کیبورد را ببندیم
    FocusScope.of(context).unfocus();

    setState(() => isSetLoading[setIdx] = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');
      final reps = widget.normalExercise.style == ExerciseStyle.setsReps
          ? int.tryParse(repsOrTimeControllers[setIdx].text)
          : null;
      final seconds = widget.normalExercise.style == ExerciseStyle.setsTime
          ? int.tryParse(repsOrTimeControllers[setIdx].text)
          : null;
      final weight = double.tryParse(weightControllers[setIdx].text);

      if ((reps == null && seconds == null) || (reps == 0 && seconds == 0)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('لطفا مقدار تکرار یا زمان را وارد کنید'),
            backgroundColor: Colors.amber));
        setState(() => isSetLoading[setIdx] = false);
        return;
      }

      // استخراج نام برنامه و روز تمرین از متغیرهای وابسته به صفحه اصلی
      final programName =
          (context.findAncestorStateOfType<_WorkoutLogScreenState>())
                  ?._selectedProgram
                  ?.name ??
              'برنامه تمرینی';
      final sessionDay =
          (context.findAncestorStateOfType<_WorkoutLogScreenState>())
                  ?._selectedSession
                  ?.day ??
              'جلسه تمرینی';

      final log = WorkoutProgramLog(
        id: '',
        userId: userId,
        programName: programName, // حتما نام برنامه ست شود
        sessions: [
          WorkoutSessionLog(
            id: '',
            day: sessionDay, // حتما روز تمرین ست شود
            exercises: [
              NormalExerciseLog(
                id: '',
                exerciseId: widget.normalExercise.exerciseId,
                exerciseName: widget.exercise?.name ?? '',
                tag: widget.normalExercise.tag,
                style: widget.normalExercise.style == ExerciseStyle.setsReps
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

      // از سرویس WorkoutProgramLogService استفاده کنیم که متد آن را اصلاح کرده‌ایم
      final workoutProgramLogService = WorkoutProgramLogService();
      final savedLog = await workoutProgramLogService.saveProgramLog(log);

      if (savedLog == null) {
        throw Exception('Failed to save log. Database returned null.');
      }

      // بعد از ذخیره موفق، علامت تیک را نمایش دهیم
      setState(() {
        isSetLogged[setIdx] = true;
      });

      // اطلاع به صفحه اصلی
      widget.onSetLogged(widget.normalExercise.exerciseId, setIdx, true);

      // بازخورد موفقیت نمایش دهیم
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ست با موفقیت ثبت شد'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );

      // پاک کردن فیلدها بعد از ذخیره موفق (اختیاری)
      // repsOrTimeControllers[setIdx].clear();
      // weightControllers[setIdx].clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('خطا در ثبت ست: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => isSetLoading[setIdx] = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.normalExercise;
    final exercise = widget.exercise;

    // Count how many sets are saved for this exercise
    final savedCount = isSetLogged.where((saved) => saved).length;

    // Get planned reps/time for hint display
    final plannedValue = ex.style == ExerciseStyle.setsReps
        ? (ex.sets.first.reps?.toString() ?? '')
        : (ex.sets.first.timeSeconds?.toString() ?? '');

    return Card(
      margin: const EdgeInsets.only(bottom: 18),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        initiallyExpanded: expanded,
        onExpansionChanged: (val) => setState(() => expanded = val),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        childrenPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Hero(
          tag: 'exercise_image_${widget.normalExercise.exerciseId}',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: exercise?.imageUrl != null && exercise!.imageUrl.isNotEmpty
                ? Image.network(
                    exercise.imageUrl,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      width: 72,
                      height: 72,
                      color: Colors.grey.shade800,
                      child: const Icon(Icons.fitness_center,
                          color: Colors.white, size: 36),
                    ),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 72,
                        height: 72,
                        color: Colors.grey.shade800,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                  )
                : Container(
                    width: 72,
                    height: 72,
                    color: Colors.grey.shade800,
                    child: const Icon(Icons.fitness_center,
                        color: Colors.white, size: 36),
                  ),
          ),
        ),
        title: Text(
          exercise?.name ?? '...',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Row(
          children: [
            Flexible(
              child: Text('${ex.sets.length} × $plannedValue',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  overflow: TextOverflow.ellipsis),
            ),
            if (savedCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check, size: 14, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      '$savedCount/${ex.sets.length}',
                      style: const TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        children: [
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: ex.sets.length,
            itemBuilder: (context, setIdx) {
              final lastLog = widget.findLastSetLog(setIdx);
              // Get planned reps/time for this specific set as hint
              final setPlannedValue = ex.style == ExerciseStyle.setsReps
                  ? (ex.sets[setIdx].reps?.toString() ?? plannedValue)
                  : (ex.sets[setIdx].timeSeconds?.toString() ?? plannedValue);

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Set number indicator
                        Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSetLogged[setIdx]
                                ? Colors.green
                                : Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${setIdx + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSetLogged[setIdx]
                                  ? Colors.white
                                  : Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Reps/Time input
                        SizedBox(
                          width: 100,
                          child: TextField(
                            controller: repsOrTimeControllers[setIdx],
                            decoration: InputDecoration(
                              labelText: ex.style == ExerciseStyle.setsReps
                                  ? 'تکرار'
                                  : 'ثانیه',
                              hintText: setPlannedValue,
                              suffixIcon: lastLog != null
                                  ? Tooltip(
                                      message:
                                          ex.style == ExerciseStyle.setsReps
                                              ? 'آخرین: ${lastLog.reps}'
                                              : 'آخرین: ${lastLog.seconds}',
                                      child: IconButton(
                                        icon:
                                            const Icon(Icons.history, size: 18),
                                        onPressed: () {
                                          setState(() {
                                            if (ex.style ==
                                                ExerciseStyle.setsReps) {
                                              repsOrTimeControllers[setIdx]
                                                      .text =
                                                  lastLog.reps?.toString() ??
                                                      '';
                                            } else {
                                              repsOrTimeControllers[setIdx]
                                                      .text =
                                                  lastLog.seconds?.toString() ??
                                                      '';
                                            }
                                          });
                                        },
                                      ))
                                  : null,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Weight input
                        SizedBox(
                          width: 100,
                          child: TextField(
                            controller: weightControllers[setIdx],
                            decoration: InputDecoration(
                              labelText: 'وزن (Kg)',
                              hintText: lastLog?.weight?.toString() ?? '',
                              suffixIcon: lastLog?.weight != null
                                  ? Tooltip(
                                      message: 'آخرین: ${lastLog!.weight}',
                                      child: IconButton(
                                        icon:
                                            const Icon(Icons.history, size: 18),
                                        onPressed: () {
                                          setState(() {
                                            weightControllers[setIdx].text =
                                                lastLog.weight?.toString() ??
                                                    '';
                                          });
                                        },
                                      ))
                                  : null,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Save button
                        isSetLoading[setIdx]
                            ? const SizedBox(
                                width: 40,
                                height: 40,
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ))
                            : ElevatedButton(
                                onPressed: () => _saveSet(setIdx),
                                style: ElevatedButton.styleFrom(
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(12),
                                  backgroundColor: isSetLogged[setIdx]
                                      ? Colors.green
                                      : Theme.of(context).colorScheme.primary,
                                ),
                                child: Icon(
                                  isSetLogged[setIdx]
                                      ? Icons.check
                                      : Icons.save,
                                  color: Colors.white,
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
