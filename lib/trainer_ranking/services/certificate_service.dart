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
          .order('created_at', ascending: false);

      return response.map<Certificate>(Certificate.fromJson).toList();
    } catch (e) {
      throw Exception('خطا در دریافت مدارک تایید شده: $e');
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
          .order('created_at', ascending: false);

      return response.map<Certificate>(Certificate.fromJson).toList();
    } catch (e) {
      throw Exception('خطا در دریافت مدارک مربی: $e');
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
          .single();

      return Certificate.fromJson(response);
    } catch (e) {
      throw Exception('خطا در آپلود مدرک: $e');
    }
  }

  /// حذف مدرک (فقط اگر در انتظار تایید باشد)
  static Future<bool> deleteCertificate(String certificateId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('کاربر وارد نشده است');

      await _client.rpc<void>(
        'delete_certificate',
        params: {'cert_id': certificateId},
      );

      return true;
    } catch (e) {
      throw Exception('خطا در حذف مدرک: $e');
    }
  }

  /// دریافت آمار مدارک مربی
  static Future<Map<String, dynamic>> getTrainerCertificateStats(
    String trainerId,
  ) async {
    try {
      final response = await _client.rpc<List<dynamic>>(
        'get_trainer_certificate_stats',
        params: {'trainer_uuid': trainerId},
      );

      if (response.isNotEmpty) {
        return Map<String, dynamic>.from(
          response.first as Map<dynamic, dynamic>,
        );
      }
      return {};
    } catch (e) {
      throw Exception('خطا در دریافت آمار مدارک: $e');
    }
  }

  /// دریافت مدارک در انتظار تایید (فقط برای ادمین‌ها)
  static Future<List<Map<String, dynamic>>> getPendingCertificates() async {
    try {
      final response = await _client.rpc<List<dynamic>>(
        'get_pending_certificates',
      );
      return response
          .map(
            (item) => Map<String, dynamic>.from(item as Map<dynamic, dynamic>),
          )
          .toList();
    } catch (e) {
      throw Exception('خطا در دریافت مدارک در انتظار: $e');
    }
  }

  /// تایید مدرک (فقط برای ادمین‌ها)
  static Future<bool> approveCertificate(String certificateId) async {
    try {
      await _client.rpc<void>(
        'approve_certificate',
        params: {'cert_id': certificateId, 'new_status': 'approved'},
      );
      return true;
    } catch (e) {
      throw Exception('خطا در تایید مدرک: $e');
    }
  }

  /// رد مدرک (فقط برای ادمین‌ها)
  static Future<bool> rejectCertificate(
    String certificateId,
    String reason,
  ) async {
    try {
      await _client.rpc<void>(
        'approve_certificate',
        params: {
          'cert_id': certificateId,
          'new_status': 'rejected',
          'rejection_reason': reason,
        },
      );
      return true;
    } catch (e) {
      throw Exception('خطا در رد مدرک: $e');
    }
  }

  /// دریافت آمار کلی مدارک
  static Future<Map<String, dynamic>> getCertificateStatistics() async {
    try {
      final response = await _client
          .from('certificate_statistics')
          .select()
          .single();
      return response;
    } catch (e) {
      throw Exception('خطا در دریافت آمار کلی: $e');
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
          .range(offset ?? 0, (offset ?? 0) + (limit ?? 10) - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('خطا در دریافت مدارک: $e');
    }
  }

  /// بررسی دسترسی ادمین
  static Future<bool> isAdmin() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      final response = await _client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();

      return response['role'] == 'admin';
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
          .order('created_at', ascending: false);

      return response.map<Certificate>(Certificate.fromJson).toList();
    } catch (e) {
      throw Exception('خطا در دریافت مدارک عمومی: $e');
    }
  }
}
