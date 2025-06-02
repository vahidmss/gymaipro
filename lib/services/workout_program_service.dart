import 'dart:convert';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/workout_program.dart';

class WorkoutProgramService {
  static final WorkoutProgramService _instance =
      WorkoutProgramService._internal();

  factory WorkoutProgramService() {
    return _instance;
  }

  WorkoutProgramService._internal();

  final SupabaseClient _client = Supabase.instance.client;
  List<WorkoutProgram> _cachedPrograms = [];
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await _loadPrograms();
    _initialized = true;
  }

  // Get all workout programs for the current user
  Future<List<WorkoutProgram>> getPrograms() async {
    await init();
    // Always refresh from database to get the latest data
    await _loadPrograms();
    return _cachedPrograms;
  }

  // Get a specific program by ID
  Future<WorkoutProgram?> getProgramById(String programId) async {
    await init();

    // First check the cache
    for (final cachedProgram in _cachedPrograms) {
      if (cachedProgram.id == programId) {
        print('برنامه "${cachedProgram.name}" از کش بارگذاری شد');
        return cachedProgram;
      }
    }

    // If not found in cache, try to fetch from database
    final user = _client.auth.currentUser;
    if (user == null) {
      return null;
    }

    final response = await _client
        .from('workout_programs')
        .select()
        .eq('id', programId)
        .eq('profile_id', user.id)
        .maybeSingle();

    if (response != null) {
      try {
        // Check if data is already a Map or still a String
        final dynamic data = response['data'];
        Map<String, dynamic> programData;

        if (data is String) {
          programData = jsonDecode(data);
        } else if (data is Map<String, dynamic>) {
          programData = data;
        } else {
          print('نوع داده ناشناخته برای برنامه تمرینی: ${data.runtimeType}');
          return null;
        }

        // Ensure program_name is included as per the WorkoutProgram.fromJson requirements
        if (!programData.containsKey('program_name') &&
            response.containsKey('program_name')) {
          programData['program_name'] = response['program_name'];
        }

        // Make sure we include the database ID
        if (!programData.containsKey('id') || programData['id'] == null) {
          programData['id'] = response['id'];
        }

        final program = WorkoutProgram.fromJson(programData);
        print(
            'برنامه "${program.name}" با ${program.sessions.length} سشن از دیتابیس بارگذاری شد');

        // Add to cache
        _cachedPrograms.removeWhere((p) => p.id == program.id);
        _cachedPrograms.add(program);

        return program;
      } catch (e) {
        print('خطا در پارس کردن برنامه تمرینی با شناسه $programId: $e');
        return null;
      }
    }

    return null;
  }

  // Create a new workout program
  Future<WorkoutProgram> createProgram(WorkoutProgram program) async {
    await init();

    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('کاربر وارد سیستم نشده است');
    }

    // اطمینان از اینکه UUID استاندارد است
    final String normalizedId = _normalizeUuid(program.id);
    if (normalizedId != program.id) {
      print('شناسه برنامه استاندارد شد از ${program.id} به $normalizedId');
      program.id = normalizedId;
    }

    print('ایجاد برنامه جدید: ${program.name} با شناسه ${program.id}');

    // بررسی اینکه آیا نام برنامه تکراری است یا خیر
    final existingPrograms = await getPrograms();
    if (existingPrograms.any((p) => p.name == program.name)) {
      throw Exception('برنامه‌ای با این نام قبلاً ثبت شده است');
    }

    // Update timestamps
    final now = DateTime.now();
    program.createdAt = now;
    program.updatedAt = now;

    try {
      // ساختار بهینه‌شده برای ذخیره‌سازی JSON
      final jsonData = _createProgramJson(program);

      // چاپ اطلاعات برنامه قبل از ذخیره
      print(
          'داده‌های JSON برای ذخیره: ${jsonEncode(jsonData).substring(0, min(100, jsonEncode(jsonData).length))}...');

      // بررسی اگر برنامه قبلاً وجود دارد
      final existingProgram = await _client
          .from('workout_programs')
          .select()
          .eq('id', program.id)
          .maybeSingle();

      if (existingProgram != null) {
        print(
            'برنامه با شناسه ${program.id} از قبل وجود دارد. انجام به‌روزرسانی به جای ایجاد...');
        return await updateProgram(program);
      }

      // Insert into Supabase
      final response = await _client.from('workout_programs').insert({
        'id': program.id, // تنظیم صریح شناسه
        'profile_id': user.id,
        'program_name': program.name,
        'data': jsonEncode(jsonData),
        'created_at': program.createdAt.toIso8601String(),
        'updated_at': program.updatedAt.toIso8601String(),
      }).select();

      if (response.isNotEmpty) {
        // Create a new program object with the DB-generated ID
        final String generatedId = response[0]['id'].toString();
        print('شناسه تولید شده توسط دیتابیس: $generatedId');

        // بررسی تفاوت با شناسه اصلی
        if (generatedId != program.id) {
          print(
              'هشدار: شناسه تولید شده ($generatedId) با شناسه اصلی (${program.id}) متفاوت است');
          program.id = generatedId;
        }

        final newProgram = WorkoutProgram(
          id: generatedId,
          name: program.name,
          sessions: program.sessions,
          createdAt: program.createdAt,
          updatedAt: program.updatedAt,
        );

        // Update the cache - first remove any existing with same ID
        _cachedPrograms
            .removeWhere((p) => p.id == generatedId || p.id == program.id);
        // Then add the new one
        _cachedPrograms.add(newProgram);

        print('برنامه "${newProgram.name}" با موفقیت ایجاد شد');
        return newProgram;
      } else {
        print('هشدار: پاسخ خالی از ایجاد برنامه');
        // بررسی برای تایید ایجاد
        final checkProgram = await _client
            .from('workout_programs')
            .select()
            .eq('id', program.id)
            .maybeSingle();

        if (checkProgram != null) {
          print('برنامه با موفقیت ایجاد شده اما پاسخ خالی بود');
          // Update cache
          _cachedPrograms.removeWhere((p) => p.id == program.id);
          _cachedPrograms.add(program);
          return program;
        }
      }

      // در صورت عدم موفقیت ذخیره، فقط برنامه را برگردان
      print('هشدار: احتمالا برنامه ایجاد نشده است');
      return program;
    } catch (e) {
      print('خطا در ایجاد برنامه تمرینی: $e');
      throw Exception('خطا در ایجاد برنامه تمرینی: $e');
    }
  }

  // Update an existing workout program
  Future<WorkoutProgram> updateProgram(WorkoutProgram program) async {
    await init();

    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('کاربر وارد سیستم نشده است');
    }

    // اطمینان از استاندارد بودن UUID
    final String normalizedId = _normalizeUuid(program.id);
    if (normalizedId != program.id) {
      print('شناسه برنامه استاندارد شد از ${program.id} به $normalizedId');
      program.id = normalizedId;
    }

    // بررسی اینکه آیا نام برنامه تکراری است یا خیر (فقط برای برنامه‌های دیگر)
    final existingPrograms = await getPrograms();
    if (existingPrograms
        .any((p) => p.name == program.name && p.id != program.id)) {
      throw Exception('برنامه‌ای با این نام قبلاً ثبت شده است');
    }

    program.updatedAt = DateTime.now();

    try {
      print('بروزرسانی برنامه با شناسه: ${program.id}');
      // ساختار بهینه‌شده برای ذخیره‌سازی JSON
      final jsonData = _createProgramJson(program);

      // جستجوی برنامه در دیتابیس برای تایید وجود آن
      final existingProgram = await _client
          .from('workout_programs')
          .select()
          .eq('id', program.id)
          .eq('profile_id', user.id)
          .maybeSingle();

      if (existingProgram == null) {
        print(
            'برنامه با شناسه ${program.id} در دیتابیس یافت نشد. تلاش برای ایجاد جدید...');
        // برنامه وجود ندارد، ایجاد برنامه جدید
        return await createProgram(program);
      }

      print('برنامه یافت شده در دیتابیس: ${existingProgram['program_name']}');

      // Update in Supabase
      final response = await _client
          .from('workout_programs')
          .update({
            'program_name': program.name,
            'data': jsonEncode(jsonData),
            'updated_at': program.updatedAt.toIso8601String(),
          })
          .eq('id', program.id)
          .eq('profile_id', user.id)
          .select();

      if (response.isEmpty) {
        print('پاسخ خالی از به‌روزرسانی. بررسی وضعیت...');

        // بررسی دوباره برای تایید به‌روزرسانی
        final checkProgram = await _client
            .from('workout_programs')
            .select()
            .eq('id', program.id)
            .eq('profile_id', user.id)
            .maybeSingle();

        if (checkProgram != null &&
            checkProgram['program_name'] == program.name) {
          print('برنامه به‌روزرسانی شده تایید شد');
        } else {
          print('خطا: به‌روزرسانی ناموفق بود');
        }
      } else {
        print('پاسخ به‌روزرسانی: ${response.length} سطر');
      }

      // Update cache - first remove any existing
      _cachedPrograms.removeWhere((p) => p.id == program.id);
      // Then add the updated one
      _cachedPrograms.add(program);

      print('برنامه "${program.name}" با موفقیت بروزرسانی شد');
      return program;
    } catch (e) {
      print('خطا در بروزرسانی برنامه تمرینی: $e');
      throw Exception('خطا در بروزرسانی برنامه تمرینی: $e');
    }
  }

  // Delete a workout program
  Future<bool> deleteProgram(String programId) async {
    await init();

    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('کاربر وارد سیستم نشده است');
    }

    try {
      // اطمینان از اینکه UUID استاندارد است
      final String normalizedId = _normalizeUuid(programId);

      print('تلاش برای حذف برنامه با شناسه: $normalizedId');
      print('شناسه کاربر: ${user.id}');

      // جستجوی برنامه در حافظه کش
      final cachedProgramIndex =
          _cachedPrograms.indexWhere((p) => p.id == normalizedId);
      WorkoutProgram? programToDelete;

      if (cachedProgramIndex >= 0) {
        programToDelete = _cachedPrograms[cachedProgramIndex];
        print('برنامه در کش پیدا شد: ${programToDelete.name}');
      } else {
        print('برنامه در کش پیدا نشد. جستجوی بیشتر...');

        // بررسی برنامه‌های کش شده با نام و شناسه
        for (var prog in _cachedPrograms) {
          print('بررسی برنامه ${prog.name} با شناسه ${prog.id}');
          if (prog.id.contains(normalizedId) ||
              normalizedId.contains(prog.id)) {
            programToDelete = prog;
            print('تطابق نسبی شناسه پیدا شد: ${prog.id}');
            break;
          }
        }
      }

      if (programToDelete == null) {
        print('هیچ برنامه‌ای با این شناسه در حافظه نزدیک پیدا نشد.');
        throw Exception('برنامه مورد نظر یافت نشد یا متعلق به کاربر فعلی نیست');
      }

      // بررسی وجود برنامه در پایگاه داده با استفاده از شناسه
      print(
          'تلاش برای یافتن برنامه در دیتابیس با شناسه: ${programToDelete.id}');

      final existingPrograms = await _client
          .from('workout_programs')
          .select()
          .eq('profile_id', user.id);

      print('تعداد برنامه‌های یافت شده در دیتابیس: ${existingPrograms.length}');

      Map<String, dynamic>? foundDbProgram;
      String? foundDbId;

      // جستجوی تطابق در برنامه‌ها
      for (var dbProgram in existingPrograms) {
        final dynamic data = dbProgram['data'];
        if (data == null) continue;

        Map<String, dynamic> programData;
        try {
          if (data is String) {
            programData = jsonDecode(data);
          } else if (data is Map<String, dynamic>) {
            programData = data;
          } else {
            continue;
          }

          final dbProgramId = programData['id']?.toString() ?? '';
          final dbProgramName = programData['program_name']?.toString() ??
              dbProgram['program_name'];

          print('بررسی برنامه دیتابیس: $dbProgramName با ID: $dbProgramId');

          if (dbProgramId == programToDelete.id ||
              dbProgramName == programToDelete.name ||
              dbProgram['program_name'] == programToDelete.name) {
            foundDbProgram = dbProgram;
            foundDbId = dbProgram['id'];
            print('برنامه در دیتابیس پیدا شد با شناسه اصلی: $foundDbId');
            break;
          }
        } catch (e) {
          print('خطا در پارس داده برنامه: $e');
          continue;
        }
      }

      if (foundDbId == null) {
        print('برنامه در دیتابیس پیدا نشد، فقط از کش محلی حذف می‌شود');
        _cachedPrograms.removeWhere((p) => p.id == programToDelete!.id);
        return true;
      }

      // حذف مستقیم
      print('تلاش برای حذف برنامه با شناسه دیتابیس: $foundDbId');
      await _client.from('workout_programs').delete().eq('id', foundDbId);

      // بررسی مجدد برای اطمینان از حذف
      final stillExists = await _client
          .from('workout_programs')
          .select()
          .eq('id', foundDbId)
          .maybeSingle();

      if (stillExists != null) {
        print('برنامه هنوز در دیتابیس وجود دارد! حذف ناموفق بود.');
        throw Exception(
            'عملیات حذف ناموفق بود - برنامه هنوز در دیتابیس وجود دارد');
      }

      // حذف از کش
      _cachedPrograms.removeWhere((p) => p.id == programToDelete!.id);
      print('برنامه با موفقیت حذف شد');

      return true;
    } catch (e) {
      print('خطا در حذف برنامه تمرینی: $e');
      throw Exception('خطا در حذف برنامه تمرینی: $e');
    }
  }

  // تابع کمکی برای استاندارد کردن UUID (مشابه _normalizeUuid در model)
  String _normalizeUuid(String id) {
    if (id.isEmpty) {
      return id;
    }

    // اگر در فرمت استاندارد باشد
    if (id.length == 36 && id.contains('-')) {
      return id;
    }

    // اگر بدون خط تیره باشد، اضافه کردن خط تیره‌ها
    if (id.length == 32) {
      return '${id.substring(0, 8)}-${id.substring(8, 12)}-${id.substring(12, 16)}-${id.substring(16, 20)}-${id.substring(20)}';
    }

    // اگر نتوانیم به فرمت استاندارد تبدیل کنیم، همان را برگردانیم
    return id;
  }

  // ساختار بهینه‌شده برای ذخیره‌سازی JSON
  Map<String, dynamic> _createProgramJson(WorkoutProgram program) {
    return {
      'id': program.id,
      'program_name': program.name,
      'sessions': program.sessions
          .map((session) => {
                'id': session.id,
                'day': session.day,
                'exercises': session.exercises.map((exercise) {
                  if (exercise is NormalExercise) {
                    return {
                      'id': exercise.id,
                      'type': 'normal',
                      'exercise_id': exercise.exerciseId,
                      'tag': exercise.tag,
                      'style': exercise.style == ExerciseStyle.setsReps
                          ? 'sets_reps'
                          : 'sets_time',
                      'sets': exercise.sets.map((set) => set.toJson()).toList(),
                    };
                  } else if (exercise is SupersetExercise) {
                    return {
                      'id': exercise.id,
                      'type': 'superset',
                      'tag': exercise.tag,
                      'style': exercise.style == ExerciseStyle.setsReps
                          ? 'sets_reps'
                          : 'sets_time',
                      'exercises': exercise.exercises
                          .map((item) => {
                                'exercise_id': item.exerciseId,
                                'sets': item.sets
                                    .map((set) => set.toJson())
                                    .toList(),
                              })
                          .toList(),
                    };
                  } else if (exercise is TrisetExercise) {
                    return {
                      'id': exercise.id,
                      'type': 'triset',
                      'tag': exercise.tag,
                      'style': exercise.style == ExerciseStyle.setsReps
                          ? 'sets_reps'
                          : 'sets_time',
                      'exercises': exercise.exercises
                          .map((item) => {
                                'exercise_id': item.exerciseId,
                                'sets': item.sets
                                    .map((set) => set.toJson())
                                    .toList(),
                              })
                          .toList(),
                    };
                  } else {
                    throw Exception('نوع تمرین نامشخص');
                  }
                }).toList(),
              })
          .toList(),
      'created_at': program.createdAt.toIso8601String(),
      'updated_at': program.updatedAt.toIso8601String(),
    };
  }

  // Load programs from Supabase
  Future<void> _loadPrograms() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      _cachedPrograms = [];
      return;
    }

    try {
      // Load from Supabase
      final response = await _client
          .from('workout_programs')
          .select()
          .eq('profile_id', user.id)
          .order('updated_at', ascending: false);

      List<WorkoutProgram> programs = [];

      for (var item in response) {
        try {
          // Check if data is already a Map or still a String
          final dynamic data = item['data'];
          Map<String, dynamic> programData;

          if (data is String) {
            programData = jsonDecode(data);
          } else if (data is Map<String, dynamic>) {
            programData = data;
          } else {
            print('نوع داده برنامه تمرینی ناشناخته است: ${data.runtimeType}');
            continue;
          }

          // اطمینان از وجود فیلدهای ضروری در داده
          if (!programData.containsKey('program_name') &&
              item.containsKey('program_name')) {
            programData['program_name'] = item['program_name'];
          }

          // استفاده از شناسه ردیف جدول به جای شناسه داخل JSON
          final dbId = item['id'] as String;
          programData['id'] = dbId;
          programData['db_id'] =
              dbId; // ذخیره شناسه اصلی دیتابیس در یک فیلد جداگانه
          print('شناسه دیتابیس برای "${item['program_name']}": $dbId');

          // اگر created_at و updated_at در دیتا وجود ندارند از موارد موجود در جدول استفاده کنیم
          if (!programData.containsKey('created_at') &&
              item.containsKey('created_at')) {
            programData['created_at'] = item['created_at'];
          }

          if (!programData.containsKey('updated_at') &&
              item.containsKey('updated_at')) {
            programData['updated_at'] = item['updated_at'];
          }

          // بررسی ساختار sessions و در صورت نیاز پر کردن آن
          if (!programData.containsKey('sessions')) {
            programData['sessions'] = [];
          }

          final program = WorkoutProgram.fromJson(programData);
          print(
              'برنامه "${program.name}" با ${program.sessions.length} سشن بارگذاری شد');
          programs.add(program);
        } catch (e) {
          print('خطا در پارس کردن برنامه تمرینی: $e');
          // Skip this program and continue with others
        }
      }

      _cachedPrograms = programs;
    } catch (e) {
      print('خطا در بارگذاری برنامه‌های تمرینی: $e');
      // Keep using the cached programs if loading fails
    }
  }
}
