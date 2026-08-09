import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// آپلود پیوست چت خصوصی روی dl.gymaipro.ir
/// مسیر: chat/{conversationId}/{images|voice|files}/
class ChatMediaUploadService {
  static const String _baseUrl = 'https://dl.gymaipro.ir';
  static const String _endpoint = '/upload-chat-media.php';
  static const int maxVoiceBytes = 8 * 1024 * 1024;
  static const int maxImageBytes = 8 * 1024 * 1024;
  static const int maxFileBytes = 20 * 1024 * 1024;

  Future<String> uploadVoiceFile(
    File file, {
    String? conversationId,
    void Function(double progress)? onProgress,
  }) async {
    final size = await file.length();
    if (size > maxVoiceBytes) {
      throw Exception('حجم پیام صوتی بیش از ۸ مگابایت است');
    }
    return _upload(
      file: file,
      mediaKind: 'voice',
      conversationId: conversationId,
      onProgress: onProgress,
      fallbackName: 'voice.m4a',
    );
  }

  Future<String> uploadImage(
    XFile file, {
    String? conversationId,
    void Function(double progress)? onProgress,
  }) async {
    final local = File(file.path);
    final size = await local.length();
    if (size > maxImageBytes) {
      throw Exception('حجم تصویر بیش از ۸ مگابایت است');
    }
    final name = file.name.isNotEmpty ? file.name : file.path;
    return _upload(
      file: local,
      mediaKind: 'image',
      conversationId: conversationId,
      onProgress: onProgress,
      fallbackName: name,
    );
  }

  Future<String> uploadFile(
    File file, {
    String? conversationId,
    void Function(double progress)? onProgress,
  }) async {
    final size = await file.length();
    if (size > maxFileBytes) {
      throw Exception('حجم فایل بیش از ۲۰ مگابایت است');
    }
    final name = file.path.split(RegExp(r'[\\/]')).last;
    return _upload(
      file: file,
      mediaKind: 'file',
      conversationId: conversationId,
      onProgress: onProgress,
      fallbackName: name,
    );
  }

  Future<String> _upload({
    required File file,
    required String mediaKind,
    required String? conversationId,
    required String fallbackName,
    void Function(double progress)? onProgress,
  }) async {
    if (!await file.exists()) {
      throw Exception('فایل وجود ندارد');
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

    final fileSize = await file.length();
    final uri = Uri.parse('$_baseUrl$_endpoint');
    final request = http.MultipartRequest('POST', uri);
    final bearer = 'Bearer ${session.accessToken}';
    request.headers['Authorization'] = bearer;
    request.headers['X-Auth-Token'] = bearer;
    request.fields['auth_token'] = session.accessToken;
    request.fields['media_kind'] = mediaKind;
    request.fields['upload_context'] = 'private_chat';
    final conv = conversationId?.trim();
    if (conv != null && conv.isNotEmpty) {
      request.fields['conversation_id'] = conv;
    }

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

    final safeName = fallbackName.split(RegExp(r'[\\/]')).last;
    request.files.add(
      http.MultipartFile(
        'media',
        progressStream,
        fileSize,
        filename: safeName.isEmpty ? 'chat.bin' : safeName,
      ),
    );

    debugPrint(
      'ChatMediaUploadService: POST $uri kind=$mediaKind '
      'conv=${conv ?? "-"} size=$fileSize',
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
      'ChatMediaUploadService: status=${response.statusCode} '
      'body=${_clip(response.body)}',
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        final data = jsonDecode(response.body);
        if (data is Map) {
          final url = (data['url'] ??
                  data['media_url'] ??
                  data['image_url'] ??
                  data['audio_url'])
              ?.toString();
          if (url != null && url.isNotEmpty) return url;
        }
      } catch (_) {}
      throw Exception('پاسخ سرور نامعتبر است');
    }

    if (response.statusCode == 401) {
      throw Exception('احراز هویت ناموفق. دوباره وارد شوید');
    }
    if (response.statusCode == 502 || response.statusCode == 503) {
      throw Exception('سرور دانلود در دسترس نیست (۵۰۲). بعداً تلاش کنید');
    }

    throw Exception(
      _extractMessage(response.body) ??
          'خطا در آپلود پیوست چت (کد ${response.statusCode})',
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
