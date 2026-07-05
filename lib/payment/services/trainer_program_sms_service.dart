import 'package:flutter/foundation.dart';
import 'package:gymaipro/config/app_config.dart';
import 'package:gymaipro/services/pattern_sms_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// پیامک‌های الگویی مربوط به درخواست/دریافت برنامه مربی.
class TrainerProgramSmsService {
  static final Map<String, DateTime> _recentKeys = {};

  /// پس از **خرید موفق** اشتراک: پیامک مربی (درخواست/ثبت) + پیامک شاگرد (خرید ثبت شد).
  /// پیامک را فقط اینجا صدا بزنید — نه هنگام تحویل برنامه.
  static Future<void> notifyPurchaseCompleteSms({
    required String trainerProfileOrAuthId,
    required String buyerProfileId,
    required String subscriptionId,
  }) async {
    final sentViaServer = await _sendViaServer(subscriptionId: subscriptionId);
    if (sentViaServer) return;

    await notifyCoachNewProgramRequest(
      trainerProfileOrAuthId: trainerProfileOrAuthId,
    );
    await notifyUserProgramReceived(
      userProfileId: buyerProfileId,
      programId: subscriptionId,
    );
  }

  /// ارسال از Edge Function (اعتبار SMS روی سرور؛ قابل اطمینان‌تر از کلاینت)
  static Future<bool> _sendViaServer({required String subscriptionId}) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'send-program-sms',
        body: {'subscription_id': subscriptionId},
      );
      if (response.status != 200) {
        if (kDebugMode) {
          debugPrint(
            'TrainerProgramSmsService: send-program-sms status=${response.status} '
            'data=${response.data}',
          );
        }
        return false;
      }
      final data = response.data;
      if (data is Map) {
        final coachSent = data['coach_sent'] == true;
        if (kDebugMode) {
          debugPrint(
            'TrainerProgramSmsService: coach_sent=$coachSent '
            'buyer_sent=${data['buyer_sent']}',
          );
        }
        return coachSent;
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('TrainerProgramSmsService server route failed: $e');
      }
      return false;
    }
  }

  /// مربی: «{0} عزیز شما درخواست برنامه دارید…» — bodyId 450989
  static Future<void> notifyCoachNewProgramRequest({
    required String trainerProfileOrAuthId,
  }) async {
    await _sendOnce(
      dedupeKey: 'coach_req:$trainerProfileOrAuthId',
      cooldown: const Duration(hours: 2),
      send: () async {
        final phone = await PatternSmsService.phoneForProfile(
          trainerProfileOrAuthId,
        );
        if (phone == null) return;

        final name = await PatternSmsService.displayNameForProfile(
          trainerProfileOrAuthId,
        );

        await PatternSmsService.sendPattern(
          phoneNumber: phone,
          bodyId: AppConfig.smsBodyIdTrainerProgramRequest,
          parameters: [name],
        );
      },
    );
  }

  /// کاربر: «با سلام {0} عزیز خرید برنامه برای شما ثبت شد…» — bodyId 450988
  /// پس از خرید اشتراک (`subscriptionId`) یا تحویل برنامه (`delivered:…`).
  static Future<void> notifyUserProgramReceived({
    required String userProfileId,
    String? programId,
  }) async {
    final suffix = programId ?? userProfileId;
    await _sendOnce(
      dedupeKey: 'user_prog:$suffix',
      cooldown: const Duration(hours: 2),
      send: () async {
        final phone = await PatternSmsService.phoneForProfile(userProfileId);
        if (phone == null) return;

        final name = await PatternSmsService.displayNameForProfile(
          userProfileId,
        );

        await PatternSmsService.sendPattern(
          phoneNumber: phone,
          bodyId: AppConfig.smsBodyIdUserProgramPurchase,
          parameters: [name],
        );
      },
    );
  }

  static Future<void> _sendOnce({
    required String dedupeKey,
    required Duration cooldown,
    required Future<void> Function() send,
  }) async {
    final last = _recentKeys[dedupeKey];
    if (last != null && DateTime.now().difference(last) < cooldown) {
      return;
    }
    _recentKeys[dedupeKey] = DateTime.now();

    try {
      await send();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('TrainerProgramSmsService: $e');
      }
    }
  }
}
