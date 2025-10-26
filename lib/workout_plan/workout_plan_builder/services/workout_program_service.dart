import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gymaipro/notification/services/notification_data_service.dart';
import 'package:gymaipro/services/connectivity_service.dart';
import 'package:gymaipro/utils/auth_helper.dart';
import 'package:gymaipro/workout_plan/workout_plan_builder/models/workout_program.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorkoutProgramService {
  factory WorkoutProgramService() {
    return _instance;
  }

  WorkoutProgramService._internal();
  static final WorkoutProgramService _instance =
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
    // If offline, return cache immediately
    final isOnline = await ConnectivityService.instance.checkNow();
    if (!isOnline) {
      return _cachedPrograms;
    }
    // Always refresh from database to get the latest data when online
    await _loadPrograms();
    return _cachedPrograms;
  }

  // Get programs for a specific user created by a specific trainer
  Future<List<WorkoutProgram>> getProgramsForUserByTrainer(
    String userId,
    String trainerId,
  ) async {
    try {
      final List<dynamic> response = await _client
          .from('workout_programs')
          .select()
          .eq('user_id', userId)
          .eq('trainer_id', trainerId)
          .eq('is_deleted', false)
          .order('created_at', ascending: false);

      final programs = <WorkoutProgram>[];
      for (final row in response) {
        final program = _parseProgramFromRow(
          Map<String, dynamic>.from(row as Map),
        );
        if (program != null) {
          programs.add(program);
        }
      }
      return programs;
    } catch (e) {
      debugPrint('خطا در دریافت برنامه‌های کاربر/مربی: $e');
      return [];
    }
  }

  // Get programs created by a specific trainer
  Future<List<WorkoutProgram>> getProgramsByTrainer(String trainerId) async {
    try {
      final userId = await AuthHelper.getCurrentUserId();
      if (userId == null) {
        debugPrint('کاربر وارد نشده است');
        return [];
      }

      debugPrint('دریافت برنامه‌های مربی: $trainerId');

      final List<dynamic> response = await _client
          .from('workout_programs')
          .select()
          .eq('user_id', userId)
          .eq('trainer_id', trainerId)
          .eq('is_deleted', false)
          .order('created_at', ascending: false);

      debugPrint('تعداد برنامه‌های مربی دریافت شده: ${response.length}');

      final programs = <WorkoutProgram>[];
      for (final row in response) {
        try {
          final program = _parseProgramFromRow(
            Map<String, dynamic>.from(row as Map),
          );
          if (program != null) {
            programs.add(program);
          }
        } catch (e) {
          debugPrint('خطا در پارس برنامه: $e');
        }
      }

      debugPrint('تعداد برنامه‌های پارس شده: ${programs.length}');
      return programs;
    } catch (e) {
      debugPrint('خطا در دریافت برنامه‌های مربی: $e');
      return [];
    }
  }

  // Get programs created by a trainer for any user (show only trainer-authored)
  Future<List<WorkoutProgram>> getProgramsCreatedByTrainer(
    String trainerId,
  ) async {
    try {
      final List<dynamic> response = await _client
          .from('workout_programs')
          .select()
          .eq('trainer_id', trainerId)
          .eq('is_deleted', false)
          .order('created_at', ascending: false);

      final programs = <WorkoutProgram>[];
      for (final row in response) {
        final program = _parseProgramFromRow(
          Map<String, dynamic>.from(row as Map),
        );
        if (program != null) {
          programs.add(program);
        }
      }
      return programs;
    } catch (e) {
      debugPrint('خطا در دریافت برنامه‌های ساخته شده توسط مربی: $e');
      return [];
    }
  }

  // Parse program from database row
  WorkoutProgram? _parseProgramFromRow(Map<String, dynamic> row) {
    try {
      final dynamic data = row['data'];
      Map<String, dynamic> programData;

      if (data is String) {
        programData = Map<String, dynamic>.from(jsonDecode(data) as Map);
      } else if (data is Map<String, dynamic>) {
        programData = Map<String, dynamic>.from(data);
      } else {
        debugPrint('نوع داده برنامه تمرینی ناشناخته است: ${data.runtimeType}');
        return null;
      }

      // اطمینان از وجود فیلدهای ضروری در داده
      if (row.containsKey('program_name')) {
        programData['program_name'] = row['program_name'];
      }

      // استفاده از شناسه ردیف جدول به جای شناسه داخل JSON
      final String dbId = row['id'].toString();
      programData['id'] = dbId;
      programData['db_id'] = dbId;

      // همواره از created_at / updated_at جدول استفاده کن (ارجح بر داخل JSON)
      if (row.containsKey('created_at')) {
        programData['created_at'] = row['created_at'];
      }
      if (row.containsKey('updated_at')) {
        programData['updated_at'] = row['updated_at'];
      }

      // انتقال شناسه‌های مالک و مربی از ستون‌های جدول به مدل
      if (row.containsKey('user_id')) {
        programData['user_id'] = row['user_id'];
      }
      if (row.containsKey('trainer_id')) {
        programData['trainer_id'] = row['trainer_id'];
      }

      return WorkoutProgram.fromJson(programData);
    } catch (e) {
      debugPrint('خطا در پارس برنامه: $e');
      return null;
    }
  }

  // Get a specific program by ID
  Future<WorkoutProgram?> getProgramById(String programId) async {
    await init();

    // If offline, try cache only
    final isOnline = await ConnectivityService.instance.checkNow();
    if (!isOnline) {
      final cached = _cachedPrograms.firstWhere(
        (p) => p.id == programId,
        orElse: WorkoutProgram.empty,
      );
      return cached.id.isEmpty ? null : cached;
    }

    // Always fetch latest from database by ID to avoid stale cache when online.
    // RLS policies should enforce access (owner or trainer author).
    final Map<String, dynamic>? response = await _client
        .from('workout_programs')
        .select()
        .eq('id', programId)
        .maybeSingle();

    if (response != null) {
      try {
        // Check if data is already a Map or still a String
        final dynamic data = response['data'];
        Map<String, dynamic> programData;

        if (data is String) {
          programData = Map<String, dynamic>.from(jsonDecode(data) as Map);
        } else if (data is Map<String, dynamic>) {
          programData = Map<String, dynamic>.from(data);
        } else {
          debugPrint(
            'نوع داده ناشناخته برای برنامه تمرینی: ${data.runtimeType}',
          );
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

        // Include timestamps from DB so createdAt is correct
        if (!programData.containsKey('created_at') &&
            response.containsKey('created_at')) {
          programData['created_at'] = response['created_at'];
        }
        if (!programData.containsKey('updated_at') &&
            response.containsKey('updated_at')) {
          programData['updated_at'] = response['updated_at'];
        }

        // Include owner/trainer identifiers
        if (response.containsKey('user_id')) {
          programData['user_id'] = response['user_id'];
        }
        if (response.containsKey('trainer_id')) {
          programData['trainer_id'] = response['trainer_id'];
        }

        final program = WorkoutProgram.fromJson(programData);
        debugPrint(
          'برنامه "${program.name}" با ${program.sessions.length} سشن از دیتابیس بارگذاری شد',
        );

        // Update cache (replace by id if exists)
        _cachedPrograms
          ..removeWhere((p) => p.id == program.id)
          ..add(program);

        return program;
      } catch (e) {
        debugPrint('خطا در پارس کردن برنامه تمرینی با شناسه $programId: $e');
        // Fallback to cache if available
        final cached = _cachedPrograms.firstWhere(
          (p) => p.id == programId,
          orElse: WorkoutProgram.empty,
        );
        return cached.id.isEmpty ? null : cached;
      }
    }

    // Not found in DB, fallback to cache if present
    final cached = _cachedPrograms.firstWhere(
      (p) => p.id == programId,
      orElse: WorkoutProgram.empty,
    );
    return cached.id.isEmpty ? null : cached;
  }

  // Create a new workout program
  Future<WorkoutProgram> createProgram(
    WorkoutProgram program, {
    String? trainerId,
    String? targetUserId,
    String? subscriptionId, // برای اتصال دقیق به اشتراک
    String? paymentTransactionId, // برای اتصال دقیق بر اساس پرداخت
  }) async {
    await init();

    // اگر targetUserId مشخص باشد، برنامه برای آن کاربر ذخیره می‌شود
    final userId = targetUserId ?? await AuthHelper.getCurrentUserId();
    if (userId == null) {
      throw Exception('کاربر وارد سیستم نشده است');
    }

    // اطمینان از اینکه UUID استاندارد است
    final String normalizedId = _normalizeUuid(program.id);
    if (normalizedId != program.id) {
      debugPrint('شناسه برنامه استاندارد شد از ${program.id} به $normalizedId');
      program.id = normalizedId;
    }

    debugPrint('ایجاد برنامه جدید: ${program.name} با شناسه ${program.id}');

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
      // If offline, throw a friendly error immediately
      final isOnline = await ConnectivityService.instance.checkNow();
      if (!isOnline) {
        throw Exception('عدم دسترسی به اینترنت. بعداً دوباره تلاش کنید');
      }
      // ساختار بهینه‌شده برای ذخیره‌سازی JSON
      final jsonData = _createProgramJson(program);

      // چاپ اطلاعات برنامه قبل از ذخیره
      debugPrint(
        'داده‌های JSON برای ذخیره: ${jsonEncode(jsonData).substring(0, min(100, jsonEncode(jsonData).length))}...',
      );

      // بررسی اگر برنامه قبلاً وجود دارد
      final Map<String, dynamic>? existingProgram = await _client
          .from('workout_programs')
          .select()
          .eq('id', program.id)
          .maybeSingle();

      if (existingProgram != null) {
        debugPrint(
          'برنامه با شناسه ${program.id} از قبل وجود دارد. انجام به‌روزرسانی به جای ایجاد...',
        );
        return await updateProgram(program);
      }

      // Insert into Supabase
      final insertData = <String, dynamic>{};

      // اضافه کردن trainer_id اگر ارائه شده باشد
      if (trainerId != null) {
        insertData['trainer_id'] = trainerId;
      }

      final List<dynamic> response = await _client
          .from('workout_programs')
          .insert(insertData)
          .select();

      if (response.isNotEmpty) {
        // Create a new program object with the DB-generated ID
        final String generatedId = (response[0] as Map)['id'].toString();
        debugPrint('شناسه تولید شده توسط دیتابیس: $generatedId');

        // بررسی تفاوت با شناسه اصلی
        if (generatedId != program.id) {
          debugPrint(
            'هشدار: شناسه تولید شده ($generatedId) با شناسه اصلی (${program.id}) متفاوت است',
          );
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
        _cachedPrograms.removeWhere(
          (p) => p.id == generatedId || p.id == program.id,
        );
        // Then add the new one
        _cachedPrograms.add(newProgram);

        debugPrint('برنامه "${newProgram.name}" با موفقیت ایجاد شد');

        // اگر برنامه توسط مربی برای کاربر دیگری ثبت شده، وضعیت اشتراک را به‌روزرسانی و اعلان ارسال شود
        try {
          if (trainerId != null &&
              trainerId.isNotEmpty &&
              targetUserId != null &&
              targetUserId.isNotEmpty) {
            await _updatePendingSubscriptionAfterProgram(
              trainerId: trainerId,
              userId: targetUserId,
              subscriptionId: subscriptionId,
              paymentTransactionId: paymentTransactionId,
              programDataPreview: {
                'program_id': generatedId,
                'program_name': newProgram.name,
              },
            );

            await _notifyUserProgramCreated(
              recipientUserId: targetUserId,
              trainerId: trainerId,
              isDiet: false,
            );
          }
        } catch (e) {
          debugPrint(
            '⚠️ خطا در به‌روزرسانی اشتراک/ارسال اعلان پس از ایجاد برنامه: $e',
          );
        }

        return newProgram;
      } else {
        debugPrint('هشدار: پاسخ خالی از ایجاد برنامه');
        // بررسی برای تایید ایجاد
        final Map<String, dynamic>? checkProgram = await _client
            .from('workout_programs')
            .select()
            .eq('id', program.id)
            .maybeSingle();

        if (checkProgram != null) {
          debugPrint('برنامه با موفقیت ایجاد شده اما پاسخ خالی بود');
          // Update cache
          _cachedPrograms.removeWhere((p) => p.id == program.id);
          _cachedPrograms.add(program);
          return program;
        }
      }

      // در صورت عدم موفقیت ذخیره، فقط برنامه را برگردان
      debugPrint('هشدار: احتمالا برنامه ایجاد نشده است');
      return program;
    } catch (e) {
      debugPrint('خطا در ایجاد برنامه تمرینی: $e');
      throw Exception('خطا در ایجاد برنامه تمرینی: $e');
    }
  }

  // به‌روز کردن اشتراک مربی برای انتقال درخواست از "در انتظار" به "در حال انجام"
  Future<void> _updatePendingSubscriptionAfterProgram({
    required String trainerId,
    required String userId,
    String? subscriptionId,
    String? paymentTransactionId,
    Map<String, dynamic>? programDataPreview,
  }) async {
    try {
      Map<String, dynamic>? sub;

      if (subscriptionId != null && subscriptionId.isNotEmpty) {
        sub = await _client
            .from('trainer_subscriptions')
            .select('id,status,program_status')
            .eq('id', subscriptionId)
            .eq('trainer_id', trainerId)
            .eq('user_id', userId)
            .maybeSingle();
      }

      if (sub == null &&
          paymentTransactionId != null &&
          paymentTransactionId.isNotEmpty) {
        sub = await _client
            .from('trainer_subscriptions')
            .select('id,status,program_status')
            .eq('payment_transaction_id', paymentTransactionId)
            .eq('trainer_id', trainerId)
            .eq('user_id', userId)
            .maybeSingle();
      }

      if (sub == null) {
        final q = _client
            .from('trainer_subscriptions')
            .select('id,status,program_status')
            .eq('trainer_id', trainerId)
            .eq('user_id', userId)
            // در حالت fallback، pending را هم در نظر بگیر تا درخواست‌های ثبت‌شده بدون پرداخت قبلی هم منتقل شوند
            .or('status.eq.pending,status.eq.paid,status.eq.active')
            .or('program_status.eq.not_started,program_status.eq.delayed')
            .order('created_at', ascending: false)
            .limit(1);
        sub = await q.maybeSingle();
      }

      // در صورتی که هیچ اشتراک معتبری پیدا نشد، از به‌روزرسانی صرف‌نظر کن
      if (sub == null || sub['id'] == null) {
        debugPrint(
          '⚠️ اشتراک معتبری برای به‌روزرسانی پیدا نشد (trainer_id=$trainerId, user_id=$userId)',
        );
        return;
      }

      final now = DateTime.now().toIso8601String();
      await _client
          .from('trainer_subscriptions')
          .update(<String, dynamic>{
            'program_registration_date': now,
            'program_status': 'in_progress',
            'status': 'active',
            'updated_at': now,
            'metadata': <String, dynamic>{
              'registered_by_trainer': true,
              if (programDataPreview != null)
                'program_preview': programDataPreview,
            },
          })
          .eq('id', sub['id'].toString());
    } catch (e) {
      debugPrint('خطا در به‌روزرسانی وضعیت اشتراک پس از ایجاد برنامه: $e');
    }
  }

  // ارسال اعلان و پوش برای کاربر پس از ثبت برنامه توسط مربی
  Future<void> _notifyUserProgramCreated({
    required String recipientUserId,
    required String trainerId,
    required bool isDiet,
  }) async {
    try {
      String trainerName = 'مربی شما';
      // واکشی نام مربی (با فیلدهای امن)
      try {
        final trainerProfile = await _client
            .from('profiles')
            .select('first_name,last_name,username')
            .eq('id', trainerId)
            .maybeSingle();
        if (trainerProfile != null) {
          final first = (trainerProfile['first_name'] as String?)?.trim() ?? '';
          final last = (trainerProfile['last_name'] as String?)?.trim() ?? '';
          final username =
              (trainerProfile['username'] as String?)?.trim() ?? '';
          if ((first + last).trim().isNotEmpty) {
            trainerName = '$first $last'.trim();
          } else if (username.isNotEmpty) {
            trainerName = username;
          }
        }
      } catch (e) {
        // در صورت خطا در خواندن پروفایل، از عنوان پیش‌فرض استفاده می‌کنیم و ادامه می‌دهیم
        debugPrint('⚠️ خطا در واکشی نام مربی: $e');
      }

      const title = 'برنامه جدید آماده شد';
      final body =
          '$trainerName برای شما ${isDiet ? 'برنامه غذایی' : 'برنامه تمرینی'} ارسال کرد';

      // ایجاد نوتیفیکیشن داخل برنامه
      await NotificationDataService.createNotification(
        userId: recipientUserId,
        title: title,
        message: body,
        type: NotificationType.system,
        data: {
          'type': isDiet ? 'diet_program' : 'workout_program',
          'route': '/my_programs',
          'trainer_id': trainerId,
        },
      );

      // ارسال پوش نوتیفیکیشن مستقیم به device tokens
      try {
        final List<dynamic> tokensRes = await _client
            .from('device_tokens')
            .select('token')
            .eq('user_id', recipientUserId)
            .eq('is_push_enabled', true);
        final List<String> tokens = tokensRes
            .map((e) => (e as Map)['token']?.toString() ?? '')
            .whereType<String>()
            .where((t) => t.isNotEmpty)
            .toList();

        if (tokens.isNotEmpty) {
          await _client.functions.invoke(
            'send-notifications',
            body: {
              'mode': 'direct',
              'target_type': 'device_tokens',
              'tokens': tokens,
              'title': title,
              'body': body,
              'data': {
                'type': isDiet ? 'diet_program' : 'workout_program',
                'route': '/my_programs',
                'trainer_id': trainerId,
              },
            },
          );
        }
      } catch (e) {
        debugPrint('⚠️ خطا در ارسال پوش نوتیفیکیشن: $e');
      }
    } catch (e) {
      debugPrint('⚠️ خطا در ایجاد اعلان ارسال برنامه: $e');
    }
  }

  // Update an existing workout program
  Future<WorkoutProgram> updateProgram(WorkoutProgram program) async {
    await init();

    final userId = await AuthHelper.getCurrentUserId();
    if (userId == null) {
      throw Exception('کاربر وارد سیستم نشده است');
    }

    // اطمینان از استاندارد بودن UUID
    final String normalizedId = _normalizeUuid(program.id);
    if (normalizedId != program.id) {
      debugPrint('شناسه برنامه استاندارد شد از ${program.id} به $normalizedId');
      program.id = normalizedId;
    }

    // بررسی اینکه آیا نام برنامه تکراری است یا خیر (فقط برای برنامه‌های دیگر)
    final existingPrograms = await getPrograms();
    if (existingPrograms.any(
      (p) => p.name == program.name && p.id != program.id,
    )) {
      throw Exception('برنامه‌ای با این نام قبلاً ثبت شده است');
    }

    program.updatedAt = DateTime.now();

    // Enforce 3-day edit window for trainer-authored programs
    try {
      if (program.trainerId != null && program.trainerId!.isNotEmpty) {
        final now = DateTime.now();
        final created = program.createdAt;
        final diff = now.difference(created).inDays;
        if (diff > 3) {
          throw Exception('مهلت ویرایش این برنامه به پایان رسیده است');
        }
      }
    } catch (_) {}

    try {
      debugPrint('بروزرسانی برنامه با شناسه: ${program.id}');
      // ساختار بهینه‌شده برای ذخیره‌سازی JSON
      final jsonData = _createProgramJson(program);

      // جستجوی برنامه در دیتابیس برای تایید وجود آن (بر اساس شناسه)
      final Map<String, dynamic>? existingProgram = await _client
          .from('workout_programs')
          .select()
          .eq('id', program.id)
          .maybeSingle();

      if (existingProgram == null) {
        debugPrint(
          'برنامه با شناسه ${program.id} در دیتابیس یافت نشد. تلاش برای ایجاد جدید...',
        );
        // برنامه وجود ندارد، ایجاد برنامه جدید
        return await createProgram(program);
      }

      debugPrint(
        'برنامه یافت شده در دیتابیس: ${existingProgram['program_name']}',
      );

      // Update in Supabase (بر اساس شناسه)
      final List<dynamic> response = await _client
          .from('workout_programs')
          .update({
            'program_name': program.name,
            'data': jsonEncode(jsonData),
            'updated_at': program.updatedAt.toIso8601String(),
          })
          .eq('id', program.id)
          .select();

      if (response.isEmpty) {
        debugPrint('پاسخ خالی از به‌روزرسانی. بررسی وضعیت...');

        // بررسی دوباره برای تایید به‌روزرسانی
        final Map<String, dynamic>? checkProgram = await _client
            .from('workout_programs')
            .select()
            .eq('id', program.id)
            .maybeSingle();

        if (checkProgram != null &&
            checkProgram['program_name'] == program.name) {
          debugPrint('برنامه به‌روزرسانی شده تایید شد');
        } else {
          debugPrint('خطا: به‌روزرسانی ناموفق بود');
        }
      } else {
        debugPrint('پاسخ به‌روزرسانی: ${response.length} سطر');
      }

      // Update cache - first remove any existing
      _cachedPrograms
        ..removeWhere((p) => p.id == program.id)
        ..add(program);

      debugPrint('برنامه "${program.name}" با موفقیت بروزرسانی شد');
      return program;
    } catch (e) {
      debugPrint('خطا در بروزرسانی برنامه تمرینی: $e');
      throw Exception('خطا در بروزرسانی برنامه تمرینی: $e');
    }
  }

  // Delete a workout program
  Future<bool> deleteProgram(String programId) async {
    await init();

    final userId = await AuthHelper.getCurrentUserId();
    if (userId == null) {
      throw Exception('کاربر وارد سیستم نشده است');
    }

    try {
      // اطمینان از اینکه UUID استاندارد است
      final String normalizedId = _normalizeUuid(programId);

      debugPrint('تلاش برای حذف برنامه با شناسه: $normalizedId');
      debugPrint('شناسه کاربر: $userId');

      // جستجوی برنامه در حافظه کش
      final cachedProgramIndex = _cachedPrograms.indexWhere(
        (p) => p.id == normalizedId,
      );
      WorkoutProgram? programToDelete;

      if (cachedProgramIndex >= 0) {
        programToDelete = _cachedPrograms[cachedProgramIndex];
        debugPrint('برنامه در کش پیدا شد: ${programToDelete.name}');
      } else {
        debugPrint('برنامه در کش پیدا نشد. جستجوی بیشتر...');

        // بررسی برنامه‌های کش شده با نام و شناسه
        for (final prog in _cachedPrograms) {
          debugPrint('بررسی برنامه ${prog.name} با شناسه ${prog.id}');
          if (prog.id.contains(normalizedId) ||
              normalizedId.contains(prog.id)) {
            programToDelete = prog;
            debugPrint('تطابق نسبی شناسه پیدا شد: ${prog.id}');
            break;
          }
        }
      }

      if (programToDelete == null) {
        debugPrint('هیچ برنامه‌ای با این شناسه در حافظه نزدیک پیدا نشد.');
        throw Exception('برنامه مورد نظر یافت نشد یا متعلق به کاربر فعلی نیست');
      }

      // بررسی وجود برنامه در پایگاه داده با استفاده از شناسه
      debugPrint(
        'تلاش برای یافتن برنامه در دیتابیس با شناسه: ${programToDelete.id}',
      );

      final List<dynamic> existingPrograms = await _client
          .from('workout_programs')
          .select()
          .eq('user_id', userId);

      debugPrint(
        'تعداد برنامه‌های یافت شده در دیتابیس: ${existingPrograms.length}',
      );

      String? foundDbId;

      // جستجوی تطابق در برنامه‌ها
      for (final raw in existingPrograms) {
        final dbProgram = raw as Map;
        final dynamic data = dbProgram['data'];
        if (data == null) continue;

        Map<String, dynamic> programData;
        try {
          if (data is String) {
            programData = Map<String, dynamic>.from(jsonDecode(data) as Map);
          } else if (data is Map<String, dynamic>) {
            programData = Map<String, dynamic>.from(data);
          } else {
            continue;
          }

          final dbProgramId = programData['id']?.toString() ?? '';
          final dbProgramName =
              programData['program_name']?.toString() ??
              dbProgram['program_name'].toString();

          debugPrint(
            'بررسی برنامه دیتابیس: $dbProgramName با ID: $dbProgramId',
          );

          if (dbProgramId == programToDelete.id ||
              dbProgramName == programToDelete.name ||
              dbProgram['program_name'] == programToDelete.name) {
            foundDbId = dbProgram['id'].toString();
            debugPrint('برنامه در دیتابیس پیدا شد با شناسه اصلی: $foundDbId');
            break;
          }
        } catch (e) {
          debugPrint('خطا در پارس داده برنامه: $e');
          continue;
        }
      }

      if (foundDbId == null) {
        debugPrint('برنامه در دیتابیس پیدا نشد، فقط از کش محلی حذف می‌شود');
        _cachedPrograms.removeWhere((p) => p.id == programToDelete!.id);
        return true;
      }

      // حذف مستقیم
      debugPrint('تلاش برای حذف برنامه با شناسه دیتابیس: $foundDbId');
      await _client.from('workout_programs').delete().eq('id', foundDbId);

      // بررسی مجدد برای اطمینان از حذف
      final Map<String, dynamic>? stillExists = await _client
          .from('workout_programs')
          .select()
          .eq('id', foundDbId)
          .maybeSingle();

      if (stillExists != null) {
        debugPrint('برنامه هنوز در دیتابیس وجود دارد! حذف ناموفق بود.');
        throw Exception(
          'عملیات حذف ناموفق بود - برنامه هنوز در دیتابیس وجود دارد',
        );
      }

      // حذف از کش
      _cachedPrograms.removeWhere((p) => p.id == programToDelete!.id);
      debugPrint('برنامه با موفقیت حذف شد');

      return true;
    } catch (e) {
      debugPrint('خطا در حذف برنامه تمرینی: $e');
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
          .map(
            (session) => {
              'id': session.id,
              'day': session.day,
              'notes': session.notes,
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
                    'note': exercise.note, // اضافه شد
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
                        .map(
                          (item) => {
                            'exercise_id': item.exerciseId,
                            'sets': item.sets
                                .map((set) => set.toJson())
                                .toList(),
                          },
                        )
                        .toList(),
                    'note': exercise.note, // اضافه شد
                  };
                } else {
                  throw Exception('نوع تمرین نامشخص');
                }
              }).toList(),
            },
          )
          .toList(),
      'created_at': program.createdAt.toIso8601String(),
      'updated_at': program.updatedAt.toIso8601String(),
    };
  }

  // Load programs from Supabase
  Future<void> _loadPrograms() async {
    final userId = await AuthHelper.getCurrentUserId();
    if (userId == null) {
      _cachedPrograms = [];
      return;
    }

    try {
      // Load from Supabase
      final List<dynamic> response = await _client
          .from('workout_programs')
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false);

      final List<WorkoutProgram> programs = [];

      for (final item in response) {
        final mapItem = item as Map;
        try {
          // Check if data is already a Map or still a String
          final dynamic data = mapItem['data'];
          Map<String, dynamic> programData;

          if (data is String) {
            programData = Map<String, dynamic>.from(jsonDecode(data) as Map);
          } else if (data is Map<String, dynamic>) {
            programData = Map<String, dynamic>.from(data);
          } else {
            debugPrint(
              'نوع داده برنامه تمرینی ناشناخته است: ${data.runtimeType}',
            );
            continue;
          }

          // اطمینان از وجود فیلدهای ضروری در داده
          if (!programData.containsKey('program_name') &&
              mapItem.containsKey('program_name')) {
            programData['program_name'] = mapItem['program_name'];
          }

          // استفاده از شناسه ردیف جدول به جای شناسه داخل JSON
          final String dbId = mapItem['id'].toString();
          programData['id'] = dbId;
          programData['db_id'] =
              dbId; // ذخیره شناسه اصلی دیتابیس در یک فیلد جداگانه
          debugPrint('شناسه دیتابیس برای "${mapItem['program_name']}": $dbId');

          // اگر created_at و updated_at در دیتا وجود ندارند از موارد موجود در جدول استفاده کنیم
          if (!programData.containsKey('created_at') &&
              mapItem.containsKey('created_at')) {
            programData['created_at'] = mapItem['created_at'];
          }

          if (!programData.containsKey('updated_at') &&
              mapItem.containsKey('updated_at')) {
            programData['updated_at'] = mapItem['updated_at'];
          }

          // بررسی ساختار sessions و در صورت نیاز پر کردن آن
          programData.putIfAbsent('sessions', () => <Map<String, dynamic>>[]);

          final program = WorkoutProgram.fromJson(programData);
          debugPrint(
            'برنامه "${program.name}" با ${program.sessions.length} سشن بارگذاری شد',
          );
          programs.add(program);
        } catch (e) {
          debugPrint('خطا در پارس کردن برنامه تمرینی: $e');
          // Skip this program and continue with others
        }
      }

      _cachedPrograms = programs;
    } catch (e) {
      debugPrint('خطا در بارگذاری برنامه‌های تمرینی: $e');
      // Keep using the cached programs if loading fails
    }
  }
}
