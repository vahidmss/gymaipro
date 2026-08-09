import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// آپلود تصویر تمرین به dl.gymaipro.ir
/// endpoint: /upload-exercise-image.php
/// path: custom_exercises/{username}/images/
class ExerciseImageUploadService {
  static const String _baseUrl = 'https://dl.gymaipro.ir';
  static const String _endpoint = '/upload-exercise-image.php';
  static const int _maxFileSize = 10 * 1024 * 1024;

  Future<String> uploadImage(
    XFile imageFile, {
    void Function(double progress)? onProgress,
  }) async {
    final file = File(imageFile.path);
    if (!await file.exists()) {
      throw Exception('فایل تصویر وجود ندارد');
    }

    final fileSize = await file.length();
    if (fileSize > _maxFileSize) {
      throw Exception('حجم تصویر بیشتر از حد مجاز است (حداکثر ۱۰MB)');
    }

    Session? session = Supabase.instance.client.auth.currentSession;
    if (session == null || session.accessToken.isEmpty) {
      try {
        final refreshed = await Supabase.instance.client.auth.refreshSession();
        session = refreshed.session;
      } catch (_) {}
      if (session == null || session.accessToken.isEmpty) {
        throw Exception('لطفاً ابتدا وارد حساب کاربری شوید');
      }
    }

    if (Supabase.instance.client.auth.currentUser == null) {
      throw Exception('کاربر احراز هویت نشده است');
    }

    final profile = await SimpleProfileService.queryCurrentUserProfile(
      select: 'role',
    );
    final role = profile?['role'] as String?;
    if (role != 'admin' && role != 'trainer') {
      throw Exception('فقط ادمین و مربی می‌توانند تصویر تمرین آپلود کنند');
    }

    final uri = Uri.parse('$_baseUrl$_endpoint');
    final request = http.MultipartRequest('POST', uri);
    final bearer = 'Bearer ${session.accessToken}';
    request.headers['Authorization'] = bearer;
    request.headers['X-Auth-Token'] = bearer;
    request.fields['auth_token'] = session.accessToken;
    request.fields['upload_context'] = 'custom_exercise';

    var uploadedBytes = 0;
    final progressStream = file.openRead().transform<List<int>>(
      StreamTransformer<List<int>, List<int>>.fromHandlers(
        handleData: (data, sink) {
          uploadedBytes += data.length;
          onProgress?.call((uploadedBytes / fileSize).clamp(0.0, 0.95));
          sink.add(data);
        },
      ),
    );

    final ext = imageFile.path.split('.').last.toLowerCase();
    final safeExt = (ext.isEmpty || ext.length > 5) ? 'jpg' : ext;
    final fileName =
        'exercise_img_${DateTime.now().millisecondsSinceEpoch}.$safeExt';

    request.files.add(
      http.MultipartFile(
        'image',
        progressStream,
        fileSize,
        filename: fileName,
      ),
    );

    debugPrint(
      'ExerciseImageUploadService: POST $uri ($fileSize bytes) name=$fileName',
    );

    late final http.StreamedResponse streamed;
    try {
      streamed = await request.send().timeout(const Duration(minutes: 5));
    } on TimeoutException {
      throw Exception('زمان آپلود تمام شد');
    } on SocketException catch (e) {
      throw Exception('اتصال به سرور دانلود برقرار نشد: ${e.message}');
    } on http.ClientException catch (e) {
      throw Exception('خطای شبکه: ${e.message}');
    }

    onProgress?.call(0.97);
    final response = await http.Response.fromStream(streamed);
    onProgress?.call(1);

    debugPrint(
      'ExerciseImageUploadService: status=${response.statusCode} '
      'body=${_clip(response.body)}',
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        final data = jsonDecode(response.body);
        if (data is Map) {
          final url = (data['image_url'] ?? data['url'] ?? data['cover_url'])
              ?.toString();
          if (url != null && url.isNotEmpty) {
            return url;
          }
        }
      } catch (_) {}
      throw Exception('پاسخ سرور نامعتبر است');
    }

    if (response.statusCode == 502 || response.statusCode == 503) {
      throw Exception(
        'خطای 502 سرور (PHP-FPM). اگر ping.php هم ok نیست با هاست تماس بگیر؛ '
        'وگرنه upload-exercise-image.php را در private_html جایگذاری کن.',
      );
    }

    if (response.statusCode == 401) {
      throw Exception('احراز هویت ناموفق. دوباره وارد شوید');
    }
    if (response.statusCode == 403) {
      throw Exception(_extractMessage(response.body) ?? 'دسترسی آپلود ندارید');
    }

    throw Exception(
      _extractMessage(response.body) ??
          'خطا در آپلود تصویر (کد ${response.statusCode})',
    );
  }

  String? _extractMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['message'] != null) {
        return decoded['message'].toString();
      }
    } catch (_) {}
    return null;
  }

  String _clip(String body, [int max = 250]) {
    final t = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (t.length <= max) return t;
    return '${t.substring(0, max)}…';
  }
}
