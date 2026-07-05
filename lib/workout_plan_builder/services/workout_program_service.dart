import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gymaipro/notification/models/notification_model.dart';
import 'package:gymaipro/notification/services/notification_push_invoker.dart';
import 'package:gymaipro/notification/services/notification_data_service.dart';
import 'package:gymaipro/payment/services/trainer_escrow_service.dart';
import 'package:gymaipro/profile/repositories/profile_repository.dart';
import 'package:gymaipro/services/connectivity_service.dart';
import 'package:gymaipro/utils/auth_helper.dart';
import 'package:gymaipro/workout_plan_builder/models/workout_program.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  static const String _starterGeneratedByKey = 'gymai_starter';

  bool _isStarterProgramData(dynamic dataRaw) {
    if (dataRaw == null) return false;
    try {
      final Map<String, dynamic> decoded = dataRaw is String
          ? Map<String, dynamic>.from(jsonDecode(dataRaw) as Map)
          : Map<String, dynamic>.from(dataRaw as Map);
      return decoded['generated_by'] == _starterGeneratedByKey;
    } catch (_) {
      return false;
    }
  }

  /// Find the user's installed beginner starter program, if any.
  Future<WorkoutProgram?> findStarterProgram() async {
    final userId = await AuthHelper.getCurrentUserId();
    if (userId == null) return null;

    try {
      final List<dynamic> response = await _client
          .from('workout_programs')
          .select()
          .eq('user_id', userId)
          .eq('is_deleted', false)
          .order('created_at', ascending: false);

      for (final row in response) {
        final map = Map<String, dynamic>.from(row as Map);
        if (!_isStarterProgramData(map['data'])) continue;
        final program = _parseProgramFromRow(map);
        if (program != null) return program;
      }
      return null;
    } catch (e) {
      debugPrint('خطا در findStarterProgram: $e');
      return null;
    }
  }

  // Get programs for a specific user created by a specific trainer
  // Returns all programs (sent and unsent) for trainer to edit
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

  // Get programs created by a specific trainer for current user
  // Only returns sent programs for students
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
          .not('sent_at', 'is', null) // فقط برنامه‌های ارسال شده
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
      if (row.containsKey('sent_at')) {
        programData['sent_at'] = row['sent_at'];
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

    // First, try to load from SharedPreferences cache (instant)
    final cachedProgram = await _loadProgramFromCache(programId);
    if (cachedProgram != null) {
      // Update from database in background (non-blocking)
      _updateProgramFromDatabaseInBackground(programId, cachedProgram);
      return cachedProgram;
    }

    // If offline, try in-memory cache only
    final isOnline = await ConnectivityService.instance.checkNow();
    if (!isOnline) {
      final cached = _cachedPrograms.firstWhere(
        (p) => p.id == programId,
        orElse: WorkoutProgram.empty,
      );
      return cached.id.isEmpty ? null : cached;
    }

    // Load from database
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
        if (response.containsKey('sent_at')) {
          programData['sent_at'] = response['sent_at'];
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

        // Save to SharedPreferences cache
        await _saveProgramToCache(program);

        // Update in-memory cache (replace by id if exists)
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
    bool autoSend = false, // اگر true باشد، sent_at بلافاصله تنظیم می‌شود (فقط برای برنامه‌های AI)
    bool starterProgram = false,
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
      final jsonData = _createProgramJson(
        program,
        starterProgram: starterProgram,
      );

      // چاپ اطلاعات برنامه قبل از ذخیره
      debugPrint(
        'داده‌های JSON برای ذخیره: ${jsonEncode(jsonData).substring(0, min(100, jsonEncode(jsonData).length))}...',
      );

      // اگر autoSend=false باشد، برنامه را در دیتابیس ذخیره نمی‌کنیم
      // فقط برای برنامه‌های AI (autoSend=true) یا زمانی که sendProgram فراخوانی می‌شود
      if (!autoSend) {
        debugPrint('⚠️ createProgram با autoSend=false فراخوانی شد - برنامه در دیتابیس ذخیره نمی‌شود');
        debugPrint('برنامه فقط در حافظه محلی ذخیره می‌شود تا زمان ارسال');
        // فقط برنامه را با timestamps برگردان
        return program;
      }

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

      // Insert into Supabase (فقط برای برنامه‌های AI با autoSend=true)
      final insertData = <String, dynamic>{
        'id': program.id,
        'program_name': program.name,
        'data': jsonEncode(jsonData),
        'user_id': userId,
        'created_at': program.createdAt.toIso8601String(),
        'updated_at': program.updatedAt.toIso8601String(),
      };

      // اضافه کردن trainer_id اگر ارائه شده باشد
      // editable_until و expiry_date فقط در sendProgram ثبت می‌شوند (بعد از پر شدن sent_at)
      if (trainerId != null && trainerId.isNotEmpty) {
        insertData['trainer_id'] = trainerId;
        // sent_at در sendProgram تنظیم می‌شود، نه اینجا
        // اینجا فقط برنامه را در دیتابیس ایجاد می‌کنیم
        debugPrint('برنامه در دیتابیس ایجاد شد (sent_at در sendProgram تنظیم می‌شود)');
      }

      final List<dynamic> response = await _client
          .from('workout_programs')
          .insert(insertData)
          .select(
            'id, program_name, data, user_id, trainer_id, created_at, updated_at, sent_at, editable_until, expiry_date',
          );

      if (response.isNotEmpty) {
        // Create a new program object with the DB-generated ID
        final responseData = response[0] as Map<String, dynamic>;
        final String generatedId = responseData['id'].toString();
        debugPrint('شناسه تولید شده توسط دیتابیس: $generatedId');

        // بررسی تفاوت با شناسه اصلی
        if (generatedId != program.id) {
          debugPrint(
            'هشدار: شناسه تولید شده ($generatedId) با شناسه اصلی (${program.id}) متفاوت است',
          );
          program.id = generatedId;
        }

        // خواندن sentAt از پاسخ دیتابیس
        DateTime? sentAt;
        if (responseData['sent_at'] != null) {
          try {
            sentAt = DateTime.parse(responseData['sent_at'] as String);
          } catch (e) {
            debugPrint('خطا در پارس sent_at: $e');
          }
        }

        final newProgram = WorkoutProgram(
          id: generatedId,
          name: program.name,
          sessions: program.sessions,
          createdAt: program.createdAt,
          updatedAt: program.updatedAt,
          sentAt: sentAt,
        );

        // Update the cache - first remove any existing with same ID
        _cachedPrograms.removeWhere(
          (p) => p.id == generatedId || p.id == program.id,
        );
        // Then add the new one
        _cachedPrograms.add(newProgram);

        debugPrint('برنامه "${newProgram.name}" با موفقیت ایجاد شد');
        // توجه: به‌روزرسانی subscription و ثبت program_registration_date فقط در sendProgram انجام می‌شود

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
  // مهم: این تابع فقط در sendProgram فراخوانی می‌شود و program_registration_date را تنظیم می‌کند
  Future<void> _updatePendingSubscriptionAfterProgram({
    required String trainerId,
    required String userId,
    required DateTime sentAt, required DateTime editableUntil, String? subscriptionId,
    String? paymentTransactionId,
    Map<String, dynamic>? programDataPreview,
  }) async {
    debugPrint('🔔 _updatePendingSubscriptionAfterProgram فراخوانی شد - program_registration_date تنظیم می‌شود');
    debugPrint('⚠️ این تابع فقط باید در sendProgram فراخوانی شود');
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

      final subId = sub['id'].toString();

      await TrainerEscrowService().onProgramSent(
        subscriptionId: subId,
        sentAt: sentAt,
        editableUntil: editableUntil,
      );

      if (programDataPreview != null) {
        await _client.from('trainer_subscriptions').update({
          'metadata': {
            'registered_by_trainer': true,
            'program_preview': programDataPreview,
          },
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', subId);
      }

      debugPrint('✅ Escrow به‌روز شد پس از ارسال برنامه: $subId');
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
      try {
        final trainerProfile =
            await ProfileRepository.instance.fetchProfile(trainerId);
        trainerName = ProfileRepository.instance.displayNameFromMap(
          trainerProfile,
          fallback: trainerName,
        );
      } catch (e) {
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
          await NotificationPushInvoker.sendNotifications(
            client: _client,
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

    // بررسی editable_until برای برنامه‌های ارسال شده
    // این بررسی در UI انجام می‌شود، اما اینجا هم بررسی می‌کنیم
    if (program.trainerId != null &&
        program.trainerId!.isNotEmpty &&
        program.sentAt != null) {
      try {
        final programData = await _client
            .from('workout_programs')
            .select('editable_until')
            .eq('id', program.id)
            .maybeSingle();

        if (programData != null && programData['editable_until'] != null) {
          final editableUntil = DateTime.parse(
            programData['editable_until'] as String,
          );
          final now = DateTime.now();
          if (now.isAfter(editableUntil)) {
            throw Exception('مهلت ویرایش این برنامه به پایان رسیده است');
          }
        }
      } catch (e) {
        if (e.toString().contains('مهلت ویرایش')) {
          rethrow;
        }
        // اگر خطای دیگری بود، ادامه می‌دهیم
      }
    }

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
          '⚠️ برنامه با شناسه ${program.id} در دیتابیس یافت نشد. برنامه باید ابتدا با createProgram ایجاد شود.',
        );
        // برنامه وجود ندارد - نباید خودکار ایجاد شود
        // فقط برنامه را با updatedAt جدید برگردان
        return program.copyWith(updatedAt: DateTime.now());
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
          .select(
            'id, program_name, data, user_id, trainer_id, created_at, updated_at, sent_at, editable_until, expiry_date',
          );

      WorkoutProgram updatedProgram = program;

      if (response.isNotEmpty) {
        debugPrint('پاسخ به‌روزرسانی: ${response.length} سطر');
        
        // Parse the updated program from database response
        try {
          final Map<String, dynamic> responseData = response[0] as Map<String, dynamic>;
          final dynamic data = responseData['data'];
          Map<String, dynamic> programData;

          if (data is String) {
            programData = Map<String, dynamic>.from(jsonDecode(data) as Map);
          } else if (data is Map<String, dynamic>) {
            programData = Map<String, dynamic>.from(data);
          } else {
            programData = jsonData; // Fallback to what we sent
          }

          // Ensure program_name is included
          if (!programData.containsKey('program_name') &&
              responseData.containsKey('program_name')) {
            programData['program_name'] = responseData['program_name'];
          }

          // Use database ID
          final String dbId = responseData['id'].toString();
          programData['id'] = dbId;

          // Include timestamps from DB
          if (responseData.containsKey('created_at')) {
            programData['created_at'] = responseData['created_at'];
          }
          if (responseData.containsKey('updated_at')) {
            programData['updated_at'] = responseData['updated_at'];
          }
          if (responseData.containsKey('sent_at')) {
            programData['sent_at'] = responseData['sent_at'];
          }
          if (responseData.containsKey('user_id')) {
            programData['user_id'] = responseData['user_id'];
          }
          if (responseData.containsKey('trainer_id')) {
            programData['trainer_id'] = responseData['trainer_id'];
          }

          updatedProgram = WorkoutProgram.fromJson(programData);
        } catch (e) {
          debugPrint('خطا در پارس برنامه به‌روزرسانی شده: $e');
          // Use the program we sent if parsing fails
        }
      } else {
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
          // Try to parse from checkProgram
          try {
            final dynamic data = checkProgram['data'];
            Map<String, dynamic> programData;

            if (data is String) {
              programData = Map<String, dynamic>.from(jsonDecode(data) as Map);
            } else if (data is Map<String, dynamic>) {
              programData = Map<String, dynamic>.from(data);
            } else {
              programData = jsonData;
            }

            if (!programData.containsKey('program_name') &&
                checkProgram.containsKey('program_name')) {
              programData['program_name'] = checkProgram['program_name'];
            }

            final String dbId = checkProgram['id'].toString();
            programData['id'] = dbId;

            if (checkProgram.containsKey('created_at')) {
              programData['created_at'] = checkProgram['created_at'];
            }
            if (checkProgram.containsKey('updated_at')) {
              programData['updated_at'] = checkProgram['updated_at'];
            }
            if (checkProgram.containsKey('sent_at')) {
              programData['sent_at'] = checkProgram['sent_at'];
            }
            if (checkProgram.containsKey('user_id')) {
              programData['user_id'] = checkProgram['user_id'];
            }
            if (checkProgram.containsKey('trainer_id')) {
              programData['trainer_id'] = checkProgram['trainer_id'];
            }

            updatedProgram = WorkoutProgram.fromJson(programData);
          } catch (e) {
            debugPrint('خطا در پارس برنامه از بررسی مجدد: $e');
          }
        } else {
          debugPrint('خطا: به‌روزرسانی ناموفق بود');
        }
      }

      // Update cache - first remove any existing
      _cachedPrograms
        ..removeWhere((p) => p.id == updatedProgram.id)
        ..add(updatedProgram);

      // Save to SharedPreferences cache
      await _saveProgramToCache(updatedProgram);

      debugPrint('برنامه "${updatedProgram.name}" با موفقیت بروزرسانی شد');
      return updatedProgram;
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

  /// ارسال برنامه به شاگرد (تنظیم sent_at، editable_until و expiry_date)
  /// همچنین محاسبه و ذخیره زمان انتظار تا ارسال برنامه (program_response_time)
  Future<void> sendProgram(String programId, {String? subscriptionId}) async {
    try {
      final isOnline = await ConnectivityService.instance.checkNow();
      if (!isOnline) {
        throw Exception(
          'عدم دسترسی به اینترنت. ارسال برنامه تمرینی بعداً تلاش شود',
        );
      }

      final now = DateTime.now();

      // تنظیم sent_at به زمان فعلی
      // تنظیم editable_until به 3 روز از sent_at
      // تنظیم expiry_date به 33 روز از sent_at
      final sentAt = now;
      final editableUntil = sentAt.add(const Duration(days: 3));
      final expiryDate = sentAt.add(const Duration(days: 33));

      // بررسی اینکه آیا برنامه در دیتابیس وجود دارد یا نه (قبل از UPDATE)
      final existingProgram = await _client
          .from('workout_programs')
          .select('id, user_id, trainer_id, program_name, sent_at')
          .eq('id', programId)
          .maybeSingle();

      if (existingProgram == null) {
        debugPrint('⚠️ برنامه در دیتابیس یافت نشد - باید ابتدا با createProgram ایجاد شود');
        throw Exception('برنامه در دیتابیس یافت نشد. لطفاً ابتدا برنامه را ذخیره کنید.');
      }

      // بررسی اینکه آیا برنامه قبلاً ارسال شده است یا نه
      if (existingProgram['sent_at'] != null) {
        debugPrint('⚠️ برنامه قبلاً ارسال شده است');
        throw Exception('این برنامه قبلاً ارسال شده است');
      }

      // همیشه هر سه فیلد را با هم set می‌کنیم
      final updateData = <String, dynamic>{
        'sent_at': sentAt.toIso8601String(),
        'editable_until': editableUntil.toIso8601String(),
        'expiry_date': expiryDate.toIso8601String(),
      };

      await _client
          .from('workout_programs')
          .update(updateData)
          .eq('id', programId);

      // استفاده از اطلاعات برنامه موجود
      final programData = existingProgram;

      // به‌روزرسانی subscription و ارسال نوتیفیکیشن
      // مهم: program_registration_date فقط اینجا تنظیم می‌شود (در sendProgram)
      final userId = programData['user_id'] as String?;
      final trainerId = programData['trainer_id'] as String?;
      final programName = programData['program_name'] as String? ?? '';
      
      if (trainerId != null && trainerId.isNotEmpty && userId != null && userId.isNotEmpty) {
        // پیدا کردن subscription مرتبط برای به‌روزرسانی و محاسبه زمان انتظار
        Map<String, dynamic>? sub;
        String? foundPaymentTransactionId;
        String? foundSubscriptionId;
        
        try {
          if (subscriptionId != null && subscriptionId.isNotEmpty) {
            sub = await _client
                .from('trainer_subscriptions')
                .select('id, created_at, payment_transaction_id')
                .eq('id', subscriptionId)
                .eq('trainer_id', trainerId)
                .eq('user_id', userId)
                .maybeSingle();
          }

          sub ??= await _client
                .from('trainer_subscriptions')
                .select('id, created_at, payment_transaction_id')
                .eq('trainer_id', trainerId)
                .eq('user_id', userId)
                .eq('service_type', 'training')
                .order('created_at', ascending: false)
                .limit(1)
                .maybeSingle();
          
          if (sub != null) {
            foundSubscriptionId = sub['id'] as String?;
            foundPaymentTransactionId = sub['payment_transaction_id'] as String?;
          }
          
          // به‌روزرسانی subscription (program_registration_date و program_status)
          // این تنها جایی است که program_registration_date تنظیم می‌شود
          if (sub != null) {
            debugPrint('✅ تنظیم program_registration_date در sendProgram (تنها محل مجاز)');
            await _updatePendingSubscriptionAfterProgram(
              trainerId: trainerId,
              userId: userId,
              subscriptionId: foundSubscriptionId,
              paymentTransactionId: foundPaymentTransactionId,
              programDataPreview: {
                'program_id': programId,
                'program_name': programName,
              },
              sentAt: sentAt,
              editableUntil: editableUntil,
            );
          }
        } catch (e) {
          debugPrint('⚠️ خطا در به‌روزرسانی subscription: $e');
          // خطا در به‌روزرسانی subscription نباید جریان اصلی را متوقف کند
        }
        
        try {

          // محاسبه زمان انتظار (از created_at subscription تا sent_at program)
          if (sub != null && sub['created_at'] != null) {
            final subscriptionCreatedAt = DateTime.parse(
              sub['created_at'] as String,
            );
            final responseTimeSeconds = sentAt.difference(subscriptionCreatedAt).inSeconds;
            
            // ذخیره زمان انتظار در subscription
            await _client
                .from('trainer_subscriptions')
                .update({
                  'program_response_time': responseTimeSeconds,
                  'updated_at': now.toIso8601String(),
                })
                .eq('id', sub['id'] as String);
            
            debugPrint('زمان انتظار تا ارسال برنامه: $responseTimeSeconds ثانیه (${(responseTimeSeconds / 3600).toStringAsFixed(2)} ساعت)');
          }
        } catch (e) {
          debugPrint('⚠️ خطا در محاسبه زمان انتظار: $e');
          // خطا در محاسبه زمان انتظار نباید جریان اصلی را متوقف کند
        }

        // ارسال نوتیفیکیشن به کاربر
        try {
          await _notifyUserProgramCreated(
            recipientUserId: userId,
            trainerId: trainerId,
            isDiet: false,
          );
        } catch (e) {
          debugPrint('⚠️ خطا در ارسال نوتیفیکیشن: $e');
        }
      }

      debugPrint('برنامه تمرینی با موفقیت ارسال شد');
      debugPrint('sent_at: $sentAt');
      debugPrint('editable_until: $editableUntil');
      debugPrint('expiry_date: $expiryDate');
    } catch (e) {
      debugPrint('خطا در ارسال برنامه تمرینی: $e');
      rethrow;
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
  Map<String, dynamic> _createProgramJson(
    WorkoutProgram program, {
    bool starterProgram = false,
  }) {
    final map = <String, dynamic>{
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

    if (program.isSelfServiceAi) {
      map['is_self_service_ai'] = true;
    }
    if (starterProgram) {
      map['generated_by'] = _starterGeneratedByKey;
      map['starter_version'] = 5;
    }

    return map;
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
      // فقط برنامه‌های ارسال شده را برای شاگرد نمایش می‌دهیم
      final List<dynamic> response = await _client
          .from('workout_programs')
          .select()
          .eq('user_id', userId)
          .eq('is_deleted', false)
          .not('sent_at', 'is', null) // فقط برنامه‌های ارسال شده
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

  /// Load program from SharedPreferences cache
  Future<WorkoutProgram?> _loadProgramFromCache(String programId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'workout_program_$programId';
      final jsonStr = prefs.getString(key);
      if (jsonStr == null) return null;
      final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
      return WorkoutProgram.fromJson(jsonMap);
    } catch (e) {
      debugPrint('Error loading program from cache: $e');
      return null;
    }
  }

  /// Save program to SharedPreferences cache
  Future<void> _saveProgramToCache(WorkoutProgram program) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'workout_program_${program.id}';
      await prefs.setString(key, jsonEncode(program.toJson()));
    } catch (e) {
      debugPrint('Error saving program to cache: $e');
    }
  }

  /// Update program from database in background (non-blocking)
  Future<void> _updateProgramFromDatabaseInBackground(
    String programId,
    WorkoutProgram cachedProgram,
  ) async {
    try {
      final response = await _client
          .from('workout_programs')
          .select()
          .eq('id', programId)
          .maybeSingle();

      if (response != null) {
        try {
          final dynamic data = response['data'];
          Map<String, dynamic> programData;

          if (data is String) {
            programData = Map<String, dynamic>.from(jsonDecode(data) as Map);
          } else if (data is Map<String, dynamic>) {
            programData = Map<String, dynamic>.from(data);
          } else {
            return;
          }

          if (response.containsKey('program_name')) {
            programData['program_name'] = response['program_name'];
          }

          final String dbId = response['id'].toString();
          programData['id'] = dbId;
          programData['db_id'] = dbId;

          if (response.containsKey('created_at')) {
            programData['created_at'] = response['created_at'];
          }
          if (response.containsKey('updated_at')) {
            programData['updated_at'] = response['updated_at'];
          }
          if (response.containsKey('sent_at')) {
            programData['sent_at'] = response['sent_at'];
          }
          if (response.containsKey('user_id')) {
            programData['user_id'] = response['user_id'];
          }
          if (response.containsKey('trainer_id')) {
            programData['trainer_id'] = response['trainer_id'];
          }

          final program = WorkoutProgram.fromJson(programData);

          // Only update cache if database version is newer
          if (program.updatedAt.isAfter(cachedProgram.updatedAt)) {
            await _saveProgramToCache(program);
            _cachedPrograms
              ..removeWhere((p) => p.id == program.id)
              ..add(program);
          }
        } catch (e) {
          debugPrint('Error parsing program in background: $e');
        }
      }
    } catch (e) {
      debugPrint('Error updating program from database in background: $e');
      // Silently fail - cache is still valid
    }
  }
}
