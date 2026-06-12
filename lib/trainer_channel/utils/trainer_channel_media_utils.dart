import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// آماده‌سازی فایل محلی برای آپلود (رفع مشکل content URI در اندروید)
class TrainerChannelMediaUtils {
  TrainerChannelMediaUtils._();

  static Future<File> ensureLocalFile(XFile file) async {
    final path = file.path;
    if (path.isNotEmpty) {
      try {
        final f = File(path);
        if (await f.exists()) {
          final len = await f.length();
          if (len > 0) return f;
        }
      } catch (e) {
        debugPrint('TrainerChannelMediaUtils: path check failed: $e');
      }
    }

    final ext = _extensionFromName(file.name) ?? 'bin';
    final dest = File(
      '${Directory.systemTemp.path}/channel_${DateTime.now().millisecondsSinceEpoch}.$ext',
    );
    await dest.writeAsBytes(await file.readAsBytes());
    return dest;
  }

  static Future<File> ensureLocalFileFromPath(String path, {String? name}) async {
    if (path.isEmpty) {
      throw Exception('مسیر فایل نامعتبر است');
    }
    final f = File(path);
    if (await f.exists() && await f.length() > 0) {
      return f;
    }
    throw Exception('فایل «${name ?? path}» در دسترس نیست. دوباره انتخاب کنید.');
  }

  static String? _extensionFromName(String name) {
    final dot = name.lastIndexOf('.');
    if (dot <= 0 || dot >= name.length - 1) return null;
    return name.substring(dot + 1).toLowerCase();
  }

  /// مدت فایل صوتی محلی (ثانیه)
  static Future<int?> readAudioDurationSeconds(File file) async {
    final player = AudioPlayer();
    try {
      await player.setSource(DeviceFileSource(file.path));
      final d = await player.getDuration();
      if (d == null || d <= Duration.zero) return null;
      return d.inSeconds;
    } catch (e) {
      debugPrint('TrainerChannelMediaUtils.readAudioDurationSeconds: $e');
      return null;
    } finally {
      await player.dispose();
    }
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
