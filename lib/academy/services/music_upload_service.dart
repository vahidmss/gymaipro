import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// سرویس آپلود موزیک به هاست دانلود (مثل ویدیوهای تمرین)
class MusicUploadService {
  // آدرس هاست دانلود (مستقل از WordPress)
  static const String _baseUrl = 'https://dl.gymaipro.ir';
  static const String _endpoint = '/upload-music.php';
  static const int _maxFileSize = 50 * 1024 * 1024; // 50MB

  /// آپلود موزیک
  /// 
  /// [audioFile]: فایل موزیک برای آپلود
  /// [onProgress]: تابع callback برای نمایش پیشرفت آپلود (0.0 تا 1.0)
  /// 
  /// Returns: URL کامل موزیک آپلود شده
  Future<String> uploadMusic(
    File audioFile, {
    void Function(double progress)? onProgress,
    String? uploadContext,
  }) async {
    try {
      // بررسی وجود فایل
      if (!await audioFile.exists()) {
        throw Exception('فایل موزیک وجود ندارد');
      }

      // بررسی حجم فایل
      final fileSize = await audioFile.length();
      if (fileSize > _maxFileSize) {
        throw Exception(
          'حجم فایل بیشتر از حد مجاز است (حداکثر 50MB)',
        );
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
      String? role;
      try {
        final profile = await SimpleProfileService.queryCurrentUserProfile(
          select: 'role',
        );
        
        if (profile != null) {
          role = profile['role'] as String?;
          debugPrint('MusicUploadService: Found profile, role: $role');
        } else {
          throw Exception('پروفایل کاربر یافت نشد. لطفاً ابتدا پروفایل خود را تکمیل کنید');
        }
        
        // بررسی role
        if (role == null || role.isEmpty) {
          debugPrint('MusicUploadService: Role is null or empty');
          throw Exception('نقش کاربر مشخص نیست. لطفاً با پشتیبانی تماس بگیرید');
        }
        
        if (role != 'admin' && role != 'trainer') {
          debugPrint('MusicUploadService: User role is $role, not allowed to upload');
          throw Exception('فقط ادمین‌ها و مربیان می‌توانند موزیک آپلود کنند');
        }
        
        debugPrint('MusicUploadService: Role check passed: $role');
      } catch (e) {
        debugPrint('MusicUploadService: Error checking role: $e');
        debugPrint('MusicUploadService: Error type: ${e.runtimeType}');
        if (e is Exception) {
          rethrow;
        }
        throw Exception('خطا در بررسی دسترسی: $e');
      }

      // ساخت multipart request
      final uri = Uri.parse('$_baseUrl$_endpoint');
      final request = http.MultipartRequest('POST', uri);

      // اضافه کردن header احراز هویت
      request.headers['Authorization'] = 'Bearer ${session.accessToken}';

      if (uploadContext != null && uploadContext.trim().isNotEmpty) {
        request.fields['upload_context'] = uploadContext.trim();
      }

      // اضافه کردن فایل با progress tracking واقعی
      final originalFileName = audioFile.path.split('/').last;
      final fileExtension = originalFileName.split('.').last;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'music_$timestamp.$fileExtension';
      
      // ساخت stream با progress tracking
      int uploadedBytes = 0;
      final fileStream = audioFile.openRead();
      final progressStream = fileStream.transform<List<int>>(
        StreamTransformer<List<int>, List<int>>.fromHandlers(
          handleData: (List<int> data, EventSink<List<int>> sink) {
            uploadedBytes += data.length;
            final progress = (uploadedBytes / fileSize).clamp(0.0, 0.95);
            onProgress?.call(progress);
            sink.add(data);
          },
        ),
      );
      
      final multipartFile = http.MultipartFile(
        'audio',
        progressStream,
        fileSize,
        filename: fileName,
      );
      request.files.add(multipartFile);

      // ارسال درخواست با progress tracking
      debugPrint('MusicUploadService: Starting upload to $_baseUrl$_endpoint');
      debugPrint('MusicUploadService: File size: $fileSize bytes');
      debugPrint('MusicUploadService: File name: $fileName');

      http.StreamedResponse? streamedResponse;
      const maxRetries = 3;
      int retryCount = 0;
      Exception? lastError;
      
      while (retryCount < maxRetries) {
        try {
          debugPrint('MusicUploadService: Attempt ${retryCount + 1}/$maxRetries');
          streamedResponse = await request.send().timeout(
            const Duration(minutes: 10),
          );
          debugPrint('MusicUploadService: Request sent successfully, waiting for response...');
          onProgress?.call(0.95);
          break; // موفق شد، از حلقه خارج شو
        } catch (e) {
          retryCount++;
          lastError = e is Exception ? e : Exception(e.toString());
          debugPrint('MusicUploadService: Error sending request (attempt $retryCount/$maxRetries): $e');
          debugPrint('MusicUploadService: Error type: ${e.runtimeType}');
          
          if (retryCount >= maxRetries) {
            // آخرین تلاش هم ناموفق بود
            if (e.toString().contains('Connection reset') || 
                e.toString().contains('Connection refused') ||
                e.toString().contains('SocketException')) {
              throw Exception(
                'خطا در اتصال به سرور. لطفاً اتصال اینترنت خود را بررسی کنید و دوباره تلاش کنید.',
              );
            }
            rethrow;
          }
          
          // صبر کن و دوباره تلاش کن
          debugPrint('MusicUploadService: Retrying in 2 seconds...');
          await Future<void>.delayed(const Duration(seconds: 2));
          // ساخت دوباره request برای retry
          uploadedBytes = 0;
          final fileStream = audioFile.openRead();
          final progressStream = fileStream.transform<List<int>>(
            StreamTransformer<List<int>, List<int>>.fromHandlers(
              handleData: (List<int> data, EventSink<List<int>> sink) {
                uploadedBytes += data.length;
                final progress = (uploadedBytes / fileSize).clamp(0.0, 0.95);
                onProgress?.call(progress);
                sink.add(data);
              },
            ),
          );
          final multipartFile = http.MultipartFile(
            'audio',
            progressStream,
            fileSize,
            filename: fileName,
          );
          request.files.clear();
          request.files.add(multipartFile);
        }
      }
      
      if (streamedResponse == null) {
        throw lastError ?? Exception('خطا در ارسال درخواست به سرور');
      }

      // خواندن پاسخ
      debugPrint('MusicUploadService: Reading response from server...');
      final response = await http.Response.fromStream(streamedResponse);

      onProgress?.call(0.98);

      debugPrint('MusicUploadService: Response status: ${response.statusCode}');
      debugPrint('MusicUploadService: Response headers: ${response.headers}');
      debugPrint('MusicUploadService: Response body length: ${response.body.length}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          debugPrint('MusicUploadService: Parsing response JSON...');
          final responseData = jsonDecode(response.body) as Map<String, dynamic>;
          debugPrint('MusicUploadService: Response data keys: ${responseData.keys}');
          
          if (responseData.containsKey('audio_url') || 
              responseData.containsKey('music_url') ||
              responseData.containsKey('url')) {
            final audioUrl = responseData['audio_url'] as String? ??
                           responseData['music_url'] as String? ??
                           responseData['url'] as String?;
            if (audioUrl != null && audioUrl.isNotEmpty) {
              debugPrint('MusicUploadService: Upload successful! URL: $audioUrl');
              onProgress?.call(1.0);
              return audioUrl;
            }
          }

          debugPrint('MusicUploadService: Invalid response format');
          debugPrint('MusicUploadService: Response data: $responseData');
          throw Exception('پاسخ سرور نامعتبر است');
        } catch (e) {
          debugPrint('MusicUploadService: Error parsing response: $e');
          debugPrint('MusicUploadService: Response body: ${response.body}');
          if (e is FormatException) {
            debugPrint('MusicUploadService: Response is not valid JSON');
            throw Exception('پاسخ سرور نامعتبر است (JSON نامعتبر)');
          }
          throw Exception('خطا در پردازش پاسخ سرور: $e');
        }
      } else if (response.statusCode == 401) {
        debugPrint('MusicUploadService: Authentication failed');
        throw Exception('احراز هویت ناموفق. لطفاً دوباره وارد شوید');
      } else if (response.statusCode == 403) {
        debugPrint('MusicUploadService: Access forbidden');
        debugPrint('MusicUploadService: Response body: ${response.body}');
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          final errorMessage = errorData['message'] as String? ?? 'دسترسی به آپلود موزیک ندارید';
          throw Exception(errorMessage);
        } catch (e) {
          if (e is Exception && e.toString().contains('دسترسی')) {
            rethrow;
          }
          throw Exception('شما دسترسی به آپلود موزیک ندارید: ${response.body}');
        }
      } else if (response.statusCode == 400) {
        debugPrint('MusicUploadService: Bad request');
        final errorMessage = _extractErrorMessage(response.body);
        debugPrint('MusicUploadService: Error message: $errorMessage');
        throw Exception(errorMessage ?? 'خطا در آپلود فایل');
      } else {
        debugPrint('MusicUploadService: Upload failed with status: ${response.statusCode}');
        debugPrint('MusicUploadService: Response body: ${response.body}');
        throw Exception(
          'خطا در آپلود موزیک (کد خطا: ${response.statusCode})',
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('خطای ناشناخته در آپلود موزیک: $e');
    }
  }

  /// استخراج پیام خطا از پاسخ JSON
  String? _extractErrorMessage(String responseBody) {
    try {
      // سعی می‌کنیم JSON parse کنیم
      final jsonMatch = RegExp(r'"message"\s*:\s*"([^"]+)"')
          .firstMatch(responseBody);
      if (jsonMatch != null) {
        return jsonMatch.group(1);
      }

      // یا خطای مستقیم
      final errorMatch = RegExp(r'"error"\s*:\s*"([^"]+)"')
          .firstMatch(responseBody);
      if (errorMatch != null) {
        return errorMatch.group(1);
      }
    } catch (e) {
      debugPrint('Error extracting error message: $e');
    }
    return null;
  }

  /// بررسی اینکه آیا کاربر می‌تواند موزیک آپلود کند
  Future<bool> canUploadMusic() async {
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

