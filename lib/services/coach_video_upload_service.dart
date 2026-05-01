import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// سرویس آپلود ویدیو مربی به هاست دانلود
class CoachVideoUploadService {
  // آدرس هاست دانلود (مستقل از WordPress)
  static const String _baseUrl = 'https://dl.gymaipro.ir';
  static const String _endpoint = '/upload-video.php';
  static const int _maxFileSize = 100 * 1024 * 1024; // 100MB

  /// آپلود ویدیو
  ///
  /// [videoFile]: فایل ویدیو برای آپلود
  /// [onProgress]: تابع callback برای نمایش پیشرفت آپلود (0.0 تا 1.0)
  ///
  /// Returns: URL کامل ویدیو آپلود شده
  Future<String> uploadVideo(
    File videoFile, {
    void Function(double progress)? onProgress,
    String? uploadContext,
  }) async {
    try {
      // بررسی وجود فایل
      if (!await videoFile.exists()) {
        throw Exception('فایل ویدیو وجود ندارد');
      }

      // بررسی حجم فایل
      final fileSize = await videoFile.length();
      if (fileSize > _maxFileSize) {
        throw Exception('حجم فایل بیشتر از حد مجاز است (حداکثر 100MB)');
      }

      // دریافت JWT token
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null || session.accessToken.isEmpty) {
        throw Exception('لطفاً ابتدا وارد حساب کاربری شوید');
      }

      // بررسی role
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('کاربر احراز هویت نشده است');
      }

      // Query role با استفاده از SimpleProfileService
      try {
        final profile = await SimpleProfileService.queryCurrentUserProfile(
          select: 'role',
        );

        if (profile == null) {
          throw Exception(
            'پروفایل کاربر یافت نشد. لطفاً ابتدا پروفایل خود را تکمیل کنید',
          );
        }

        final role = profile['role'] as String?;
        if (role != 'admin' && role != 'trainer') {
          throw Exception('فقط ادمین‌ها و مربیان می‌توانند ویدیو آپلود کنند');
        }
      } catch (e) {
        debugPrint('CoachVideoUploadService: Error checking role: $e');
        if (e is Exception && e.toString().contains('پروفایل')) {
          rethrow;
        }
        throw Exception('خطا در بررسی دسترسی: $e');
      }

      // ساخت multipart request
      final uri = Uri.parse('$_baseUrl$_endpoint');
      final request = http.MultipartRequest('POST', uri);

      // اضافه کردن header احراز هویت
      request.headers['Authorization'] = 'Bearer ${session.accessToken}';

      // اضافه کردن فایل
      final fileStream = videoFile.openRead();
      final fileLength = fileSize;
      final multipartFile = http.MultipartFile(
        'video',
        fileStream,
        fileLength,
        filename: videoFile.path.split('/').last,
      );
      request.files.add(multipartFile);
      if (uploadContext != null && uploadContext.trim().isNotEmpty) {
        request.fields['upload_context'] = uploadContext.trim();
      }

      // ارسال درخواست با progress tracking
      onProgress?.call(0.1);

      final streamedResponse = await request.send().timeout(
        const Duration(minutes: 10),
      );

      onProgress?.call(0.5);

      // خواندن پاسخ
      final response = await http.Response.fromStream(streamedResponse);

      onProgress?.call(0.9);

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData =
              jsonDecode(response.body) as Map<String, dynamic>;

          if (responseData.containsKey('video_url')) {
            final videoUrl = responseData['video_url'] as String;
            if (videoUrl.isNotEmpty) {
              onProgress?.call(1.0);
              return videoUrl;
            }
          }

          throw Exception('پاسخ سرور نامعتبر است');
        } catch (e) {
          debugPrint('Error parsing response: $e');
          debugPrint('Response body: ${response.body}');
          throw Exception('خطا در پردازش پاسخ سرور: $e');
        }
      } else if (response.statusCode == 401) {
        throw Exception('احراز هویت ناموفق. لطفاً دوباره وارد شوید');
      } else if (response.statusCode == 403) {
        throw Exception('شما دسترسی به آپلود ویدیو ندارید');
      } else if (response.statusCode == 400) {
        final errorMessage = _extractErrorMessage(response.body);
        throw Exception(errorMessage ?? 'خطا در آپلود فایل');
      } else {
        debugPrint('Upload failed with status: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        throw Exception('خطا در آپلود ویدیو (کد خطا: ${response.statusCode})');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('خطای ناشناخته در آپلود ویدیو: $e');
    }
  }

  /// استخراج پیام خطا از پاسخ JSON
  String? _extractErrorMessage(String responseBody) {
    try {
      // سعی می‌کنیم JSON parse کنیم
      final jsonMatch = RegExp(
        r'"message"\s*:\s*"([^"]+)"',
      ).firstMatch(responseBody);
      if (jsonMatch != null) {
        return jsonMatch.group(1);
      }

      // یا خطای مستقیم
      final errorMatch = RegExp(
        r'"error"\s*:\s*"([^"]+)"',
      ).firstMatch(responseBody);
      if (errorMatch != null) {
        return errorMatch.group(1);
      }
    } catch (e) {
      debugPrint('Error extracting error message: $e');
    }
    return null;
  }

  /// بررسی اینکه آیا کاربر می‌تواند ویدیو آپلود کند
  Future<bool> canUploadVideo() async {
    try {
      final profile = await SimpleProfileService.queryCurrentUserProfile(
        select: 'role',
      );

      if (profile == null) return false;

      final role = profile['role'] as String?;
      return role == 'admin' || role == 'trainer';
    } catch (e) {
      debugPrint('Error checking upload permission: $e');
      return false;
    }
  }
}
