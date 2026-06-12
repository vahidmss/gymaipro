import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gymaipro/notification/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// سرویس مدیریت ارسال نوتیفیکیشن همگانی
class AdminBroadcastService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final NotificationService _notificationService = NotificationService();

  /// ارسال نوتیفیکیشن به همه کاربران (topic: all)
  Future<Map<String, dynamic>> sendToAll({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? backgroundColor,
    String? imageUrl,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'کاربر احراز هویت نشده است'};
      }

      // ساخت data با اطلاعات طراحی (آیکون همیشه لوگو اصلی اپ است)
      final notificationData = {
        ...?data,
        if (backgroundColor != null) 'background_color': backgroundColor,
        if (imageUrl != null) 'image_url': imageUrl,
      };

      // ارسال مستقیم به topic
      final success = await _notificationService.sendDirectToTopic(
        topic: 'all',
        title: title,
        body: body,
        data: notificationData,
      );

      if (success) {
        // ثبت در تاریخچه
        await _supabase.from('notification_broadcast_requests').insert({
          'created_by': user.id,
          'target_type': 'topic',
          'topic': 'all',
          'title': title,
          'body': body,
          'data': jsonEncode(notificationData),
          'status': 'sent',
          'processed_at': DateTime.now().toIso8601String(),
        });

        return {'success': true, 'message': 'نوتیفیکیشن با موفقیت ارسال شد'};
      } else {
        return {'success': false, 'error': 'خطا در ارسال نوتیفیکیشن'};
      }
    } catch (e) {
      debugPrint('Error in sendToAll: $e');
      return {'success': false, 'error': 'خطا: $e'};
    }
  }

  /// ارسال نوتیفیکیشن به کاربران غیرفعال 7 روزه
  Future<Map<String, dynamic>> sendToInactiveUsers({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? backgroundColor,
    String? imageUrl,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'کاربر احراز هویت نشده است'};
      }

      // ساخت data با اطلاعات طراحی (آیکون همیشه لوگو اصلی اپ است)
      final notificationData = {
        ...?data,
        if (backgroundColor != null) 'background_color': backgroundColor,
        if (imageUrl != null) 'image_url': imageUrl,
      };

      // ثبت در صف
      final response = await _supabase
          .from('notification_broadcast_requests')
          .insert({
            'created_by': user.id,
            'target_type': 'inactive_7d',
            'title': title,
            'body': body,
            'data': jsonEncode(notificationData),
            'status': 'queued',
          })
          .select()
          .single();

      // پردازش صف
      await _notificationService.processBroadcastQueue();

      return {
        'success': true,
        'message': 'درخواست ارسال به کاربران غیرفعال ثبت شد و در صف پردازش قرار گرفت',
        'request_id': response['id'],
      };
    } catch (e) {
      debugPrint('Error in sendToInactiveUsers: $e');
      return {'success': false, 'error': 'خطا: $e'};
    }
  }

  /// ارسال نوتیفیکیشن به تاپیک خاص
  Future<Map<String, dynamic>> sendToTopic({
    required String topic,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? backgroundColor,
    String? imageUrl,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'کاربر احراز هویت نشده است'};
      }

      // ساخت data با اطلاعات طراحی (آیکون همیشه لوگو اصلی اپ است)
      final notificationData = {
        ...?data,
        if (backgroundColor != null) 'background_color': backgroundColor,
        if (imageUrl != null) 'image_url': imageUrl,
      };

      // ارسال مستقیم به topic
      final success = await _notificationService.sendDirectToTopic(
        topic: topic,
        title: title,
        body: body,
        data: notificationData,
      );

      if (success) {
        // ثبت در تاریخچه
        await _supabase.from('notification_broadcast_requests').insert({
          'created_by': user.id,
          'target_type': 'topic',
          'topic': topic,
          'title': title,
          'body': body,
          'data': jsonEncode(notificationData),
          'status': 'sent',
          'processed_at': DateTime.now().toIso8601String(),
        });

        return {'success': true, 'message': 'نوتیفیکیشن با موفقیت ارسال شد'};
      } else {
        return {'success': false, 'error': 'خطا در ارسال نوتیفیکیشن'};
      }
    } catch (e) {
      debugPrint('Error in sendToTopic: $e');
      return {'success': false, 'error': 'خطا: $e'};
    }
  }

  /// دریافت تاریخچه ارسال‌ها
  Future<List<Map<String, dynamic>>> getBroadcastHistory({
    int limit = 50,
  }) async {
    try {
      final response = await _supabase
          .from('notification_broadcast_requests')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    } catch (e) {
      debugPrint('Error in getBroadcastHistory: $e');
      return [];
    }
  }

  /// دریافت جزئیات یک ارسال
  Future<Map<String, dynamic>?> getBroadcastDetails(String requestId) async {
    try {
      final response = await _supabase
          .from('notification_broadcast_requests')
          .select()
          .eq('id', requestId)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Error in getBroadcastDetails: $e');
      return null;
    }
  }
}

