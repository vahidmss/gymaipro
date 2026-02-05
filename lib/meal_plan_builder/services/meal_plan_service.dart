import 'package:gymaipro/models/meal_plan.dart';
import 'package:gymaipro/notification/models/notification_model.dart';
import 'package:gymaipro/notification/services/notification_data_service.dart';
import 'package:gymaipro/payment/services/payout_service.dart';
import 'package:gymaipro/services/connectivity_service.dart';
import 'package:gymaipro/services/supabase_service.dart' as supabase_service;

class MealPlanService {
  Future<List<MealPlan>> getPlans() async {
    try {
      final isOnline = await ConnectivityService.instance.checkNow();
      if (!isOnline) {
        return [];
      }
      final response = await supabase_service.SupabaseService.client
          .from('meal_plans')
          .select()
          .order('created_at', ascending: false);
      return (response as List<dynamic>)
          .map((json) => MealPlan.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<MealPlan?> getPlanById(String id) async {
    try {
      final isOnline = await ConnectivityService.instance.checkNow();
      if (!isOnline) {
        return null;
      }
      final response = await supabase_service.SupabaseService.client
          .from('meal_plans')
          .select()
          .eq('id', id)
          .single();
      return MealPlan.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<void> savePlan(
    MealPlan plan, {
    String? trainerId,
  }) async {
    print('=== MEAL PLAN SERVICE SAVE ===');
    print('Plan userId: ${plan.userId}');
    print('Trainer ID: $trainerId');
    print('Plan toJson: ${plan.toJson()}');
    final client = supabase_service.SupabaseService.client;

    try {
      final isOnline = await ConnectivityService.instance.checkNow();
      if (!isOnline) {
        throw Exception(
          'عدم دسترسی به اینترنت. ذخیره برنامه غذایی بعداً تلاش شود',
        );
      }
      
      // ساخت داده‌های ذخیره‌سازی
      final dataToSave = Map<String, dynamic>.from(plan.toJson());
      
      // اگر مربی برنامه را می‌سازد (trainerId وجود دارد)
      if (trainerId != null && trainerId.isNotEmpty) {
        dataToSave['trainer_id'] = trainerId;
        // editable_until و expiry_date فقط در sendPlan ثبت می‌شوند (بعد از پر شدن sent_at)
      } else {
        // اگر کاربر خودش برنامه را می‌سازد
        if (plan.id.isEmpty) {
          dataToSave['trainer_id'] = null;
        }
      }
      
      // تلاش برای ذخیره برنامه
      try {
        if (plan.id.isEmpty) {
          // Check if a plan with the same user_id and plan_name exists
          final existing = await client
              .from('meal_plans')
              .select('id')
              .eq('user_id', plan.userId)
              .eq('plan_name', plan.planName)
              .maybeSingle();

          if (existing != null && existing['id'] != null) {
            // If exists, update it
            print('Plan with same name exists, updating instead of inserting...');
            await client
                .from('meal_plans')
                .update(dataToSave)
                .eq('id', existing['id'] as String);
          } else {
            // If not, insert new
            print('Inserting new meal plan...');
            await client.from('meal_plans').insert(dataToSave);
          }
        } else {
          // Update existing by id
          print('Updating existing meal plan...');
          await client.from('meal_plans').update(dataToSave).eq('id', plan.id);
        }
        print('Meal plan saved successfully');
      } catch (e) {
        // اگر خطا مربوط به ستون‌های missing بود، بدون آن‌ها دوباره تلاش می‌کنیم
        final errorMessage = e.toString();
        if (errorMessage.contains('editable_until') || 
            errorMessage.contains('expiry_date') ||
            errorMessage.contains('PGRST204')) {
          print('ستون‌های expiry_date یا editable_until در دیتابیس وجود ندارند. ذخیره بدون آن‌ها...');
          
          // حذف فیلدهای مشکل‌دار از dataToSave
          final dataToSaveWithoutOptionalFields = Map<String, dynamic>.from(dataToSave);
          dataToSaveWithoutOptionalFields.remove('expiry_date');
          dataToSaveWithoutOptionalFields.remove('editable_until');
          
          // دوباره تلاش برای ذخیره
          if (plan.id.isEmpty) {
            final existing = await client
                .from('meal_plans')
                .select('id')
                .eq('user_id', plan.userId)
                .eq('plan_name', plan.planName)
                .maybeSingle();

            if (existing != null && existing['id'] != null) {
              await client
                  .from('meal_plans')
                  .update(dataToSaveWithoutOptionalFields)
                  .eq('id', existing['id'] as String);
            } else {
              await client.from('meal_plans').insert(dataToSaveWithoutOptionalFields);
            }
          } else {
            await client.from('meal_plans').update(dataToSaveWithoutOptionalFields).eq('id', plan.id);
          }
          print('Meal plan saved successfully (without optional date fields)');
        } else {
          // اگر خطا مربوط به چیز دیگری بود، دوباره throw می‌کنیم
          rethrow;
        }
      }
    } catch (e) {
      print('Error saving meal plan: $e');
      rethrow; // Re-throw so the UI can handle the error
    }
  }

  Future<void> deletePlan(String id) async {
    final isOnline = await ConnectivityService.instance.checkNow();
    if (!isOnline) {
      throw Exception('عدم دسترسی به اینترنت. حذف برنامه غذایی بعداً تلاش شود');
    }
    await supabase_service.SupabaseService.client
        .from('meal_plans')
        .delete()
        .eq('id', id);
  }

  /// ارسال برنامه به شاگرد (تنظیم sent_at، editable_until و expiry_date)
  /// همچنین محاسبه و ذخیره زمان انتظار تا ارسال برنامه (program_response_time)
  Future<void> sendPlan(String planId, {String? subscriptionId}) async {
    try {
      final isOnline = await ConnectivityService.instance.checkNow();
      if (!isOnline) {
        throw Exception(
          'عدم دسترسی به اینترنت. ارسال برنامه غذایی بعداً تلاش شود',
        );
      }
      
      final client = supabase_service.SupabaseService.client;
      final now = DateTime.now();
      
      // تنظیم sent_at به زمان فعلی
      // تنظیم editable_until به 3 روز از sent_at
      // تنظیم expiry_date به 33 روز از sent_at
      final sentAt = now;
      final editableUntil = sentAt.add(const Duration(days: 3));
      final expiryDate = sentAt.add(const Duration(days: 33));
      
      // همیشه هر سه فیلد را با هم set می‌کنیم
      final updateData = <String, dynamic>{
        'sent_at': sentAt.toIso8601String(),
        'editable_until': editableUntil.toIso8601String(),
        'expiry_date': expiryDate.toIso8601String(),
      };
      
      await client
          .from('meal_plans')
          .update(updateData)
          .eq('id', planId);
      
      // دریافت اطلاعات برنامه برای ارسال نوتیفیکیشن و محاسبه زمان انتظار
      final planData = await client
          .from('meal_plans')
          .select('user_id, trainer_id')
          .eq('id', planId)
          .maybeSingle();
      
      // محاسبه و ذخیره زمان انتظار تا ارسال برنامه (program_response_time)
      if (planData != null && 
          planData['trainer_id'] != null && 
          planData['user_id'] != null) {
        final userId = planData['user_id'] as String;
        final trainerId = planData['trainer_id'] as String;
        
        try {

          // پیدا کردن subscription مرتبط
          Map<String, dynamic>? sub;
          
          if (subscriptionId != null && subscriptionId.isNotEmpty) {
            sub = await client
                .from('trainer_subscriptions')
                .select('id, created_at')
                .eq('id', subscriptionId)
                .eq('trainer_id', trainerId)
                .eq('user_id', userId)
                .maybeSingle();
          }

          if (sub == null) {
            // اگر subscriptionId مشخص نشده، از trainer_id و user_id پیدا کن
            sub = await client
                .from('trainer_subscriptions')
                .select('id, created_at')
                .eq('trainer_id', trainerId)
                .eq('user_id', userId)
                .eq('service_type', 'diet')
                .order('created_at', ascending: false)
                .limit(1)
                .maybeSingle();
          }

          // محاسبه زمان انتظار (از created_at subscription تا sent_at plan)
          if (sub != null && sub['created_at'] != null) {
            final subscriptionCreatedAt = DateTime.parse(
              sub['created_at'] as String,
            );
            final responseTimeSeconds = sentAt.difference(subscriptionCreatedAt).inSeconds;
            
            // ذخیره زمان انتظار در subscription
            await client
                .from('trainer_subscriptions')
                .update({
                  'program_response_time': responseTimeSeconds,
                  'updated_at': now.toIso8601String(),
                })
                .eq('id', sub['id'] as String);
            
            print('زمان انتظار تا ارسال برنامه: $responseTimeSeconds ثانیه (${(responseTimeSeconds / 3600).toStringAsFixed(2)} ساعت)');
          }
        } catch (e) {
          print('⚠️ خطا در محاسبه زمان انتظار: $e');
          // خطا در محاسبه زمان انتظار نباید جریان اصلی را متوقف کند
        }

        // ارسال نوتیفیکیشن به کاربر
        try {
          await _notifyUserPlanCreated(
            recipientUserId: userId,
            trainerId: trainerId,
          );
        } catch (e) {
          print('⚠️ خطا در ارسال نوتیفیکیشن: $e');
        }
      }
      
      print('Plan sent successfully');
      print('sent_at: $sentAt');
      print('editable_until: $editableUntil');
      print('expiry_date: $expiryDate');
    } catch (e) {
      print('Error sending meal plan: $e');
      rethrow;
    }
  }

  /// Get meal plan for a specific date
  Future<MealPlan?> getPlanForDate(DateTime date) async {
    try {
      final isOnline = await ConnectivityService.instance.checkNow();
      final user = supabase_service.SupabaseService.client.auth.currentUser;
      if (user == null) {
        return null;
      }

      // For now, return the most recent plan
      // In the future, this could be enhanced to support date-specific plans
      if (!isOnline) {
        return null;
      }
      final response = await supabase_service.SupabaseService.client
          .from('meal_plans')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        return MealPlan.fromJson(response);
      }

      return null;
    } catch (e) {
      print('Error getting meal plan for date: $e');
      return null;
    }
  }

  /// Get existing meal plan for a user created by a specific trainer
  /// Returns the most recent plan created by the trainer for the target user
  Future<MealPlan?> getExistingPlanForTrainerAndUser(
    String targetUserId,
    String trainerId,
  ) async {
    try {
      final isOnline = await ConnectivityService.instance.checkNow();
      if (!isOnline) {
        return null;
      }
      final response = await supabase_service.SupabaseService.client
          .from('meal_plans')
          .select()
          .eq('user_id', targetUserId)
          .eq('trainer_id', trainerId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        return MealPlan.fromJson(response);
      }

      return null;
    } catch (e) {
      print('Error getting existing plan for trainer and user: $e');
      return null;
    }
  }

  /// Get plans created by a trainer for any user (show only trainer-authored)
  Future<List<MealPlan>> getPlansCreatedByTrainer(String trainerId) async {
    try {
      final isOnline = await ConnectivityService.instance.checkNow();
      if (!isOnline) {
        return [];
      }
      final response = await supabase_service.SupabaseService.client
          .from('meal_plans')
          .select()
          .eq('trainer_id', trainerId)
          .order('created_at', ascending: false);
      
      return (response as List<dynamic>)
          .map((json) => MealPlan.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting plans created by trainer: $e');
      return [];
    }
  }

  /// Create a new meal plan (similar to createProgram in workout_program_service)
  Future<MealPlan> createPlan(
    MealPlan plan, {
    String? trainerId,
    String? targetUserId,
    String? subscriptionId,
    String? paymentTransactionId,
  }) async {
    final client = supabase_service.SupabaseService.client;
    final userId = targetUserId ?? plan.userId;

    try {
      final isOnline = await ConnectivityService.instance.checkNow();
      if (!isOnline) {
        throw Exception(
          'عدم دسترسی به اینترنت. ذخیره برنامه غذایی بعداً تلاش شود',
        );
      }

      // Update timestamps
      final now = DateTime.now();
      final planToSave = MealPlan(
        id: plan.id.isEmpty ? '' : plan.id,
        userId: userId,
        planName: plan.planName,
        days: plan.days,
        createdAt: plan.createdAt.isBefore(DateTime(2000)) ? now : plan.createdAt,
        updatedAt: now,
      );

      // ساخت داده‌های ذخیره‌سازی
      final dataToSave = Map<String, dynamic>.from(planToSave.toJson());

      // اضافه کردن trainer_id اگر ارائه شده باشد
      // editable_until و expiry_date فقط در sendPlan ثبت می‌شوند (بعد از پر شدن sent_at)
      if (trainerId != null && trainerId.isNotEmpty) {
        dataToSave['trainer_id'] = trainerId;
      }

      // بررسی اگر برنامه قبلاً وجود دارد
      if (planToSave.id.isNotEmpty) {
        final existing = await client
            .from('meal_plans')
            .select('id')
            .eq('id', planToSave.id)
            .maybeSingle();

        if (existing != null) {
          print(
            'برنامه با شناسه ${planToSave.id} از قبل وجود دارد. انجام به‌روزرسانی به جای ایجاد...',
          );
          return await updatePlan(planToSave, trainerId: trainerId);
        }
      }

      // Insert into Supabase
      try {
        await client.from('meal_plans').insert(dataToSave);
        print('Meal plan created successfully');
      } catch (e) {
        // اگر خطا مربوط به ستون‌های missing بود، بدون آن‌ها دوباره تلاش می‌کنیم
        final errorMessage = e.toString();
        if (errorMessage.contains('editable_until') || 
            errorMessage.contains('expiry_date') ||
            errorMessage.contains('PGRST204')) {
          print('ستون‌های expiry_date یا editable_until در دیتابیس وجود ندارند. ذخیره بدون آن‌ها...');
          
          // حذف فیلدهای مشکل‌دار از dataToSave
          final dataToSaveWithoutOptionalFields = Map<String, dynamic>.from(dataToSave);
          dataToSaveWithoutOptionalFields.remove('expiry_date');
          dataToSaveWithoutOptionalFields.remove('editable_until');
          
          await client.from('meal_plans').insert(dataToSaveWithoutOptionalFields);
          print('Meal plan created successfully (without optional date fields)');
        } else {
          rethrow;
        }
      }

      // اگر برنامه جدید بود، ID را از دیتابیس بگیر
      String finalPlanId = planToSave.id;
      if (planToSave.id.isEmpty) {
        final savedPlan = await getExistingPlanForTrainerAndUser(
          userId,
          trainerId ?? '',
        );
        if (savedPlan != null) {
          finalPlanId = savedPlan.id;
          // اگر برنامه توسط مربی برای کاربر دیگری ثبت شده، وضعیت اشتراک را به‌روزرسانی و اعلان ارسال شود
          try {
            if (trainerId != null &&
                trainerId.isNotEmpty &&
                targetUserId != null &&
                targetUserId.isNotEmpty) {
              await _updatePendingSubscriptionAfterPlan(
                trainerId: trainerId,
                userId: targetUserId,
                subscriptionId: subscriptionId,
                paymentTransactionId: paymentTransactionId,
                planDataPreview: {
                  'plan_id': finalPlanId,
                  'plan_name': planToSave.planName,
                },
              );
              // نوتیفیکیشن فقط در sendPlan ارسال می‌شود
            }
          } catch (e) {
            print(
              '⚠️ خطا در به‌روزرسانی اشتراک/ارسال اعلان پس از ایجاد برنامه: $e',
            );
          }
          return savedPlan;
        }
      } else {
        // اگر برنامه توسط مربی برای کاربر دیگری ثبت شده، وضعیت اشتراک را به‌روزرسانی و اعلان ارسال شود
        try {
          if (trainerId != null &&
              trainerId.isNotEmpty &&
              targetUserId != null &&
              targetUserId.isNotEmpty) {
            await _updatePendingSubscriptionAfterPlan(
              trainerId: trainerId,
              userId: targetUserId,
              subscriptionId: subscriptionId,
              paymentTransactionId: paymentTransactionId,
              planDataPreview: {
                'plan_id': finalPlanId,
                'plan_name': planToSave.planName,
              },
            );
            // نوتیفیکیشن فقط در sendPlan ارسال می‌شود
          }
        } catch (e) {
          print(
            '⚠️ خطا در به‌روزرسانی اشتراک/ارسال اعلان پس از ایجاد برنامه: $e',
          );
        }
      }

      return planToSave;
    } catch (e) {
      print('Error creating meal plan: $e');
      rethrow;
    }
  }

  /// Update an existing meal plan (similar to updateProgram in workout_program_service)
  Future<MealPlan> updatePlan(
    MealPlan plan, {
    String? trainerId,
  }) async {
    final client = supabase_service.SupabaseService.client;

    try {
      final isOnline = await ConnectivityService.instance.checkNow();
      if (!isOnline) {
        throw Exception(
          'عدم دسترسی به اینترنت. ذخیره برنامه غذایی بعداً تلاش شود',
        );
      }

      // Update timestamp
      final now = DateTime.now();
      final planToSave = MealPlan(
        id: plan.id,
        userId: plan.userId,
        planName: plan.planName,
        days: plan.days,
        createdAt: plan.createdAt,
        updatedAt: now,
      );

      // ساخت داده‌های ذخیره‌سازی
      final dataToSave = Map<String, dynamic>.from(planToSave.toJson());

      // اگر مربی برنامه را به‌روزرسانی می‌کند
      if (trainerId != null && trainerId.isNotEmpty) {
        dataToSave['trainer_id'] = trainerId;
      }

      // بررسی editable_until برای برنامه‌های ارسال شده
      if (trainerId != null && trainerId.isNotEmpty && plan.sentAt != null) {
        try {
          final planData = await client
              .from('meal_plans')
              .select('editable_until')
              .eq('id', plan.id)
              .maybeSingle();
          
          if (planData != null && planData['editable_until'] != null) {
            final editableUntil = DateTime.parse(planData['editable_until'] as String);
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

      // Update in Supabase
      try {
        await client
            .from('meal_plans')
            .update(dataToSave)
            .eq('id', plan.id);
        print('Meal plan updated successfully');
      } catch (e) {
        // اگر خطا مربوط به ستون‌های missing بود، بدون آن‌ها دوباره تلاش می‌کنیم
        final errorMessage = e.toString();
        if (errorMessage.contains('editable_until') || 
            errorMessage.contains('expiry_date') ||
            errorMessage.contains('PGRST204')) {
          print('ستون‌های expiry_date یا editable_until در دیتابیس وجود ندارند. ذخیره بدون آن‌ها...');
          
          // حذف فیلدهای مشکل‌دار از dataToSave
          final dataToSaveWithoutOptionalFields = Map<String, dynamic>.from(dataToSave);
          dataToSaveWithoutOptionalFields.remove('expiry_date');
          dataToSaveWithoutOptionalFields.remove('editable_until');
          
          await client
              .from('meal_plans')
              .update(dataToSaveWithoutOptionalFields)
              .eq('id', plan.id);
          print('Meal plan updated successfully (without optional date fields)');
        } else {
          rethrow;
        }
      }

      return planToSave;
    } catch (e) {
      print('Error updating meal plan: $e');
      rethrow;
    }
  }

  // به‌روز کردن اشتراک مربی برای انتقال درخواست از "در انتظار" به "در حال انجام"
  Future<void> _updatePendingSubscriptionAfterPlan({
    required String trainerId,
    required String userId,
    String? subscriptionId,
    String? paymentTransactionId,
    Map<String, dynamic>? planDataPreview,
  }) async {
    try {
      final client = supabase_service.SupabaseService.client;
      Map<String, dynamic>? sub;

      if (subscriptionId != null && subscriptionId.isNotEmpty) {
        sub = await client
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
        sub = await client
            .from('trainer_subscriptions')
            .select('id,status,program_status')
            .eq('payment_transaction_id', paymentTransactionId)
            .eq('trainer_id', trainerId)
            .eq('user_id', userId)
            .maybeSingle();
      }

      if (sub == null) {
        final q = client
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
        print(
          '⚠️ اشتراک معتبری برای به‌روزرسانی پیدا نشد (trainer_id=$trainerId, user_id=$userId)',
        );
        return;
      }

      final now = DateTime.now().toIso8601String();
      await client
          .from('trainer_subscriptions')
          .update(<String, dynamic>{
            'program_registration_date': now,
            'program_status': 'in_progress',
            'status': 'active',
            'updated_at': now,
            'metadata': <String, dynamic>{
              'registered_by_trainer': true,
              if (planDataPreview != null)
                'program_preview': planDataPreview,
            },
          })
          .eq('id', sub['id'].toString());

      // به‌روزرسانی trainer_withdrawable
      try {
        final payoutService = PayoutService();
        await payoutService.updateTrainerWithdrawable(trainerId);
      } catch (e) {
        print('⚠️ خطا در به‌روزرسانی موجودی قابل برداشت: $e');
        // خطا در به‌روزرسانی نباید جریان اصلی را متوقف کند
      }
    } catch (e) {
      print('خطا در به‌روزرسانی وضعیت اشتراک پس از ایجاد برنامه: $e');
    }
  }

  // ارسال اعلان و پوش برای کاربر پس از ثبت برنامه توسط مربی
  Future<void> _notifyUserPlanCreated({
    required String recipientUserId,
    required String trainerId,
  }) async {
    try {
      final client = supabase_service.SupabaseService.client;
      String trainerName = 'مربی شما';
      // واکشی نام مربی (با فیلدهای امن)
      try {
        final trainerProfile = await client
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
        print('⚠️ خطا در واکشی نام مربی: $e');
      }

      const title = 'برنامه جدید آماده شد';
      final body = '$trainerName برای شما برنامه غذایی ارسال کرد';

      // ایجاد نوتیفیکیشن داخل برنامه
      await NotificationDataService.createNotification(
        userId: recipientUserId,
        title: title,
        message: body,
        type: NotificationType.system,
        data: {
          'type': 'diet_program',
          'route': '/my_programs',
          'trainer_id': trainerId,
        },
      );

      // ارسال پوش نوتیفیکیشن مستقیم به device tokens
      try {
        final List<dynamic> tokensRes = await client
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
          await client.functions.invoke(
            'send-notifications',
            body: {
              'mode': 'direct',
              'target_type': 'device_tokens',
              'tokens': tokens,
              'title': title,
              'body': body,
              'data': {
                'type': 'diet_program',
                'route': '/my_programs',
                'trainer_id': trainerId,
              },
            },
          );
        }
      } catch (e) {
        print('⚠️ خطا در ارسال پوش نوتیفیکیشن: $e');
      }
    } catch (e) {
      print('⚠️ خطا در ایجاد اعلان ارسال برنامه: $e');
    }
  }
}
