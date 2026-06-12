import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

typedef ApkDownloadProgress = void Function(int receivedBytes, int? totalBytes);

/// Downloads and triggers installation of sideloaded APK files (Android only).
class ApkInstallService {
  ApkInstallService._();

  static final ApkInstallService instance = ApkInstallService._();

  bool _isBusy = false;

  bool get isBusy => _isBusy;

  bool get isSupported => !kIsWeb && Platform.isAndroid;

  Future<bool> canInstallPackages() async {
    if (!isSupported) return false;
    try {
      final status = await Permission.requestInstallPackages.status;
      if (status.isGranted) return true;
      final requested = await Permission.requestInstallPackages.request();
      return requested.isGranted;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApkInstallService.canInstallPackages error: $e');
      }
      return false;
    }
  }

  Future<String?> downloadApk({
    required String url,
    ApkDownloadProgress? onProgress,
  }) async {
    if (!isSupported) return null;
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return null;

    _isBusy = true;
    http.Client? client;
    IOSink? sink;
    try {
      final dir = await getTemporaryDirectory();
      final fileName = 'gymaipro_update_${DateTime.now().millisecondsSinceEpoch}.apk';
      final filePath = p.join(dir.path, fileName);
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }

      client = http.Client();
      final request = http.Request('GET', uri);
      final response = await client.send(request);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('HTTP ${response.statusCode}');
      }

      final totalBytes = response.contentLength;
      var received = 0;
      sink = file.openWrite();
      await for (final chunk in response.stream) {
        received += chunk.length;
        sink.add(chunk);
        onProgress?.call(received, totalBytes);
      }
      await sink.flush();
      await sink.close();
      sink = null;

      if (!await file.exists() || await file.length() < 1024) {
        throw const FormatException('فایل APK نامعتبر است');
      }

      return filePath;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApkInstallService.downloadApk error: $e');
      }
      return null;
    } finally {
      await sink?.close();
      client?.close();
      _isBusy = false;
    }
  }

  Future<bool> installApk(String filePath) async {
    if (!isSupported) return false;
    final file = File(filePath);
    if (!await file.exists()) return false;

    final canInstall = await canInstallPackages();
    if (!canInstall) return false;

    try {
      final result = await OpenFilex.open(
        filePath,
        type: 'application/vnd.android.package-archive',
      );
      return result.type == ResultType.done;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApkInstallService.installApk error: $e');
      }
      return false;
    }
  }

  Future<bool> downloadAndInstall({
    required String url,
    ApkDownloadProgress? onProgress,
  }) async {
    final filePath = await downloadApk(url: url, onProgress: onProgress);
    if (filePath == null) return false;
    return installApk(filePath);
  }
}
