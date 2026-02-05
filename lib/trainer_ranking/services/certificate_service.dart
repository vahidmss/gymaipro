import 'package:flutter/foundation.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/trainer_ranking/models/certificate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CertificateService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// دریافت مدارک تایید شده مربی
  static Future<List<Certificate>> getApprovedTrainerCertificates(
    String trainerId,
  ) async {
    try {
      final response = await _client
          .from('certificates')
          .select()
          .eq('trainer_id', trainerId)
          .eq('status', 'approved')
          .order('created_at', ascending: false)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => <Map<String, dynamic>>[],
          );

      return response.map<Certificate>(Certificate.fromJson).toList();
    } catch (e) {
      // به جای throw کردن، لیست خالی برمی‌گردانیم تا برنامه کرش نکند
      debugPrint('CertificateService.getApprovedTrainerCertificates error: $e');
      return [];
    }
  }

  /// دریافت همه مدارک مربی (شامل در انتظار و رد شده)
  static Future<List<Certificate>> getAllTrainerCertificates(
    String trainerId,
  ) async {
    try {
      final response = await _client
          .from('certificates')
          .select()
          .eq('trainer_id', trainerId)
          .order('created_at', ascending: false)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => <Map<String, dynamic>>[],
          );

      return response.map<Certificate>(Certificate.fromJson).toList();
    } catch (e) {
      // به جای throw کردن، لیست خالی برمی‌گردانیم تا برنامه کرش نکند
      debugPrint('CertificateService.getAllTrainerCertificates error: $e');
      return [];
    }
  }

  /// آپلود مدرک جدید
  static Future<Certificate> uploadCertificate({
    required String title,
    required CertificateType type,
    required String imageUrl,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('کاربر وارد نشده است');

      final response = await _client
          .from('certificates')
          .insert({
            'trainer_id': user.id,
            'title': title,
            'type': type.name,
            'certificate_url': imageUrl,
            'status': CertificateStatus.pending.name,
            'description': '',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single()
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('زمان اتصال به سرور به پایان رسید'),
          );

      return Certificate.fromJson(response);
    } catch (e) {
      // برای عملیات آپلود، خطا را throw می‌کنیم تا UI بتواند به کاربر اطلاع دهد
      debugPrint('CertificateService.uploadCertificate error: $e');
      if (e.toString().contains('Connection reset') ||
          e.toString().contains('Connection closed') ||
          e.toString().contains('ClientException')) {
        throw Exception('خطا در اتصال به سرور. لطفاً اتصال اینترنت خود را بررسی کنید.');
      }
      throw Exception('خطا در آپلود مدرک: $e');
    }
  }

  /// حذف مدرک (فقط اگر در انتظار تایید باشد)
  static Future<bool> deleteCertificate(String certificateId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('کاربر وارد نشده است');

      await _client
          .rpc<void>(
            'delete_certificate',
            params: {'cert_id': certificateId},
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception('زمان اتصال به سرور به پایان رسید'),
          );

      return true;
    } catch (e) {
      // برای عملیات حذف، خطا را throw می‌کنیم تا UI بتواند به کاربر اطلاع دهد
      debugPrint('CertificateService.deleteCertificate error: $e');
      if (e.toString().contains('Connection reset') ||
          e.toString().contains('Connection closed') ||
          e.toString().contains('ClientException')) {
        throw Exception('خطا در اتصال به سرور. لطفاً اتصال اینترنت خود را بررسی کنید.');
      }
      throw Exception('خطا در حذف مدرک: $e');
    }
  }

  /// دریافت آمار مدارک مربی
  static Future<Map<String, dynamic>> getTrainerCertificateStats(
    String trainerId,
  ) async {
    try {
      final response = await _client
          .rpc<List<dynamic>>(
            'get_trainer_certificate_stats',
            params: {'trainer_uuid': trainerId},
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => <dynamic>[],
          );

      if (response.isNotEmpty) {
        return Map<String, dynamic>.from(
          response.first as Map<dynamic, dynamic>,
        );
      }
      return {};
    } catch (e) {
      // به جای throw کردن، map خالی برمی‌گردانیم تا برنامه کرش نکند
      debugPrint('CertificateService.getTrainerCertificateStats error: $e');
      return {};
    }
  }

  /// دریافت مدارک در انتظار تایید (فقط برای ادمین‌ها)
  static Future<List<Map<String, dynamic>>> getPendingCertificates() async {
    try {
      final response = await _client
          .rpc<List<dynamic>>(
            'get_pending_certificates',
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => <dynamic>[],
          );
      return response
          .map(
            (item) => Map<String, dynamic>.from(item as Map<dynamic, dynamic>),
          )
          .toList();
    } catch (e) {
      // به جای throw کردن، لیست خالی برمی‌گردانیم تا برنامه کرش نکند
      debugPrint('CertificateService.getPendingCertificates error: $e');
      return [];
    }
  }

  /// تایید مدرک (فقط برای ادمین‌ها)
  static Future<bool> approveCertificate(String certificateId) async {
    try {
      await _client
          .rpc<void>(
            'approve_certificate',
            params: {'cert_id': certificateId, 'new_status': 'approved'},
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception('زمان اتصال به سرور به پایان رسید'),
          );
      return true;
    } catch (e) {
      // برای عملیات تایید، خطا را throw می‌کنیم تا UI بتواند به کاربر اطلاع دهد
      debugPrint('CertificateService.approveCertificate error: $e');
      if (e.toString().contains('Connection reset') ||
          e.toString().contains('Connection closed') ||
          e.toString().contains('ClientException')) {
        throw Exception('خطا در اتصال به سرور. لطفاً اتصال اینترنت خود را بررسی کنید.');
      }
      throw Exception('خطا در تایید مدرک: $e');
    }
  }

  /// رد مدرک (فقط برای ادمین‌ها)
  static Future<bool> rejectCertificate(
    String certificateId,
    String reason,
  ) async {
    try {
      await _client
          .rpc<void>(
            'approve_certificate',
            params: {
              'cert_id': certificateId,
              'new_status': 'rejected',
              'rejection_reason': reason,
            },
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception('زمان اتصال به سرور به پایان رسید'),
          );
      return true;
    } catch (e) {
      // برای عملیات رد، خطا را throw می‌کنیم تا UI بتواند به کاربر اطلاع دهد
      debugPrint('CertificateService.rejectCertificate error: $e');
      if (e.toString().contains('Connection reset') ||
          e.toString().contains('Connection closed') ||
          e.toString().contains('ClientException')) {
        throw Exception('خطا در اتصال به سرور. لطفاً اتصال اینترنت خود را بررسی کنید.');
      }
      throw Exception('خطا در رد مدرک: $e');
    }
  }

  /// دریافت آمار کلی مدارک
  static Future<Map<String, dynamic>> getCertificateStatistics() async {
    try {
      final response = await _client
          .from('certificate_statistics')
          .select()
          .single()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => <String, dynamic>{},
          );
      return response;
    } catch (e) {
      // به جای throw کردن، map خالی برمی‌گردانیم تا برنامه کرش نکند
      debugPrint('CertificateService.getCertificateStatistics error: $e');
      return {};
    }
  }

  /// دریافت مدارک با اطلاعات مربی
  static Future<List<Map<String, dynamic>>> getCertificatesWithTrainerInfo({
    String? status,
    String? type,
    int? limit,
    int? offset,
  }) async {
    try {
      final response = await _client
          .from('certificates_with_trainer_info')
          .select()
          .eq('status', status ?? '')
          .eq('type', type ?? '')
          .order('created_at', ascending: false)
          .limit(limit ?? 10)
          .range(offset ?? 0, (offset ?? 0) + (limit ?? 10) - 1)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => <Map<String, dynamic>>[],
          );

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // به جای throw کردن، لیست خالی برمی‌گردانیم تا برنامه کرش نکند
      debugPrint('CertificateService.getCertificatesWithTrainerInfo error: $e');
      return [];
    }
  }

  /// بررسی دسترسی ادمین
  static Future<bool> isAdmin() async {
    try {
      final profile = await SimpleProfileService.queryCurrentUserProfile(
        select: 'role',
      );
      if (profile == null) return false;
      return profile['role'] == 'admin';
    } catch (e) {
      return false;
    }
  }

  /// دریافت مدارک تایید شده برای نمایش عمومی
  static Future<List<Certificate>> getPublicCertificates(
    String trainerId,
  ) async {
    try {
      final response = await _client
          .from('certificates')
          .select()
          .eq('trainer_id', trainerId)
          .eq('status', 'approved')
          .order('created_at', ascending: false)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => <Map<String, dynamic>>[],
          );

      return response.map<Certificate>(Certificate.fromJson).toList();
    } catch (e) {
      // به جای throw کردن، لیست خالی برمی‌گردانیم تا برنامه کرش نکند
      debugPrint('CertificateService.getPublicCertificates error: $e');
      return [];
    }
  }
}
