import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// سرویس آپلود تصویر کاور موزیک به هاست دانلود
class CoverUploadService {
  // آدرس هاست دانلود (مستقل از WordPress)
  static const String _baseUrl = 'https://dl.gymaipro.ir';
  static const String _endpoint = '/upload-cover.php';
  static const int _maxFileSize = 5 * 1024 * 1024; // 5MB

  /// آپلود تصویر کاور
  /// 
  /// [imageFile]: فایل تصویر برای آپلود
  /// [onProgress]: تابع callback برای نمایش پیشرفت آپلود (0.0 تا 1.0)
  /// 
  /// Returns: URL کامل تصویر آپلود شده
  Future<String> uploadCover(
    File imageFile, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      // بررسی وجود فایل
      if (!await imageFile.exists()) {
        throw Exception('فایل تصویر وجود ندارد');
      }

      // بررسی حجم فایل
      final fileSize = await imageFile.length();
      if (fileSize > _maxFileSize) {
        throw Exception(
          'حجم فایل بیشتر از حد مجاز است (حداکثر 5MB)',
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
          debugPrint('CoverUploadService: Found profile, role: $role');
        } else {
          throw Exception('پروفایل کاربر یافت نشد. لطفاً ابتدا پروفایل خود را تکمیل کنید');
        }
        
        // بررسی role
        if (role == null || role.isEmpty) {
          debugPrint('CoverUploadService: Role is null or empty');
          throw Exception('نقش کاربر مشخص نیست. لطفاً با پشتیبانی تماس بگیرید');
        }
        
        if (role != 'admin' && role != 'trainer') {
          debugPrint('CoverUploadService: User role is $role, not allowed to upload');
          throw Exception('فقط ادمین‌ها و مربیان می‌توانند تصویر کاور آپلود کنند');
        }
        
        debugPrint('CoverUploadService: Role check passed: $role');
      } catch (e) {
        debugPrint('CoverUploadService: Error checking role: $e');
        debugPrint('CoverUploadService: Error type: ${e.runtimeType}');
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

      // اضافه کردن فایل با progress tracking واقعی
      final originalFileName = imageFile.path.split('/').last;
      final fileExtension = originalFileName.split('.').last;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'cover_$timestamp.$fileExtension';
      
      // ساخت stream با progress tracking
      int uploadedBytes = 0;
      final fileStream = imageFile.openRead();
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
        'cover',
        progressStream,
        fileSize,
        filename: fileName,
      );
      request.files.add(multipartFile);

      // ارسال درخواست با progress tracking
      debugPrint('CoverUploadService: Starting upload to $_baseUrl$_endpoint');
      debugPrint('CoverUploadService: File size: $fileSize bytes');
      debugPrint('CoverUploadService: File name: $fileName');

      http.StreamedResponse? streamedResponse;
      const maxRetries = 3;
      int retryCount = 0;
      Exception? lastError;
      
      while (retryCount < maxRetries) {
        try {
          debugPrint('CoverUploadService: Attempt ${retryCount + 1}/$maxRetries');
          streamedResponse = await request.send().timeout(
            const Duration(minutes: 5),
          );
          debugPrint('CoverUploadService: Request sent successfully, waiting for response...');
          onProgress?.call(0.95);
          break; // موفق شد، از حلقه خارج شو
        } catch (e) {
          retryCount++;
          lastError = e is Exception ? e : Exception(e.toString());
          debugPrint('CoverUploadService: Error sending request (attempt $retryCount/$maxRetries): $e');
          debugPrint('CoverUploadService: Error type: ${e.runtimeType}');
          
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
          debugPrint('CoverUploadService: Retrying in 2 seconds...');
          await Future<void>.delayed(const Duration(seconds: 2));
          // ساخت دوباره request برای retry
          uploadedBytes = 0;
          final fileStream = imageFile.openRead();
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
            'cover',
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
      debugPrint('CoverUploadService: Reading response from server...');
      final response = await http.Response.fromStream(streamedResponse);

      onProgress?.call(0.98);

      debugPrint('CoverUploadService: Response status: ${response.statusCode}');
      debugPrint('CoverUploadService: Response headers: ${response.headers}');
      debugPrint('CoverUploadService: Response body length: ${response.body.length}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          debugPrint('CoverUploadService: Parsing response JSON...');
          final responseData = jsonDecode(response.body) as Map<String, dynamic>;
          debugPrint('CoverUploadService: Response data keys: ${responseData.keys}');
          
          if (responseData.containsKey('cover_url') || 
              responseData.containsKey('image_url') ||
              responseData.containsKey('url')) {
            final coverUrl = responseData['cover_url'] as String? ??
                           responseData['image_url'] as String? ??
                           responseData['url'] as String?;
            if (coverUrl != null && coverUrl.isNotEmpty) {
              debugPrint('CoverUploadService: Upload successful! URL: $coverUrl');
              onProgress?.call(1.0);
              return coverUrl;
            }
          }

          debugPrint('CoverUploadService: Invalid response format');
          debugPrint('CoverUploadService: Response data: $responseData');
          throw Exception('پاسخ سرور نامعتبر است');
        } catch (e) {
          debugPrint('CoverUploadService: Error parsing response: $e');
          debugPrint('CoverUploadService: Response body: ${response.body}');
          if (e is FormatException) {
            debugPrint('CoverUploadService: Response is not valid JSON');
            throw Exception('پاسخ سرور نامعتبر است (JSON نامعتبر)');
          }
          throw Exception('خطا در پردازش پاسخ سرور: $e');
        }
      } else if (response.statusCode == 401) {
        debugPrint('CoverUploadService: Authentication failed');
        throw Exception('احراز هویت ناموفق. لطفاً دوباره وارد شوید');
      } else if (response.statusCode == 403) {
        debugPrint('CoverUploadService: Access forbidden');
        debugPrint('CoverUploadService: Response body: ${response.body}');
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          final errorMessage = errorData['message'] as String? ?? 'دسترسی به آپلود تصویر کاور ندارید';
          throw Exception(errorMessage);
        } catch (e) {
          if (e is Exception && e.toString().contains('دسترسی')) {
            rethrow;
          }
          throw Exception('شما دسترسی به آپلود تصویر کاور ندارید: ${response.body}');
        }
      } else if (response.statusCode == 400) {
        debugPrint('CoverUploadService: Bad request');
        final errorMessage = _extractErrorMessage(response.body);
        debugPrint('CoverUploadService: Error message: $errorMessage');
        throw Exception(errorMessage ?? 'خطا در آپلود فایل');
      } else {
        debugPrint('CoverUploadService: Upload failed with status: ${response.statusCode}');
        debugPrint('CoverUploadService: Response body: ${response.body}');
        throw Exception(
          'خطا در آپلود تصویر کاور (کد خطا: ${response.statusCode})',
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('خطای ناشناخته در آپلود تصویر کاور: $e');
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
}

