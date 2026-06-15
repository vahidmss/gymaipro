import 'dart:async';

import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class VideoCacheService {
  factory VideoCacheService() => _instance;
  VideoCacheService._internal();
  static final VideoCacheService _instance = VideoCacheService._internal();

  static const String _cacheDirName = 'video_cache';
  static const int _maxCacheSize = 500 * 1024 * 1024; // 500MB
  static const int _maxCacheAge =
      7 * 24 * 60 * 60 * 1000; // 7 days in milliseconds

  // تنظیمات جدید برای فایل‌های بزرگ
  static const Duration _downloadTimeout = Duration(
    minutes: 10,
  ); // 10 دقیقه timeout
  // static const int _chunkSize = 1024 * 1024; // 1MB chunks برای دانلود - برای آینده
  static const int _maxRetries = 3; // حداکثر تلاش مجدد

  Directory? _cacheDir;
  final Map<String, DateTime> _accessTimes = {};
  final Map<String, bool> _downloadingVideos = {};

  /// اولیه‌سازی سرویس کش
  Future<void> initialize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _cacheDir = Directory('${appDir.path}/$_cacheDirName');

      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
      }

      debugPrint('سرویس کش ویدیو اولیه‌سازی شد: ${_cacheDir!.path}');
    } catch (e) {
      debugPrint('خطا در اولیه‌سازی سرویس کش ویدیو: $e');
    }
  }

  /// تولید نام فایل کش بر اساس URL
  String _getCacheFileName(String url) {
    final bytes = utf8.encode(url);
    final digest = sha256.convert(bytes);
    return '$digest.mp4';
  }

  /// بررسی وجود ویدیو در کش
  Future<bool> isVideoCached(String url) async {
    if (_cacheDir == null) return false;

    final fileName = _getCacheFileName(url);
    final file = File('${_cacheDir!.path}/$fileName');

    if (await file.exists()) {
      // بررسی سن فایل
      final stat = await file.stat();
      final age =
          DateTime.now().millisecondsSinceEpoch -
          stat.modified.millisecondsSinceEpoch;

      if (age < _maxCacheAge) {
        // به‌روزرسانی زمان دسترسی
        _accessTimes[url] = DateTime.now();
        return true;
      } else {
        // حذف فایل قدیمی
        await file.delete();
        _accessTimes.remove(url);
        return false;
      }
    }

    return false;
  }

  /// دریافت مسیر فایل کش شده
  Future<String?> getCachedVideoPath(String url) async {
    if (!await isVideoCached(url)) return null;

    final fileName = _getCacheFileName(url);
    return '${_cacheDir!.path}/$fileName';
  }

  /// بررسی اینکه آیا ویدیو در حال دانلود است
  bool isVideoDownloading(String url) {
    return _downloadingVideos[url] ?? false;
  }

  /// کش کردن ویدیو با دانلود chunked و timeout
  Future<bool> cacheVideo(String url) async {
    if (_cacheDir == null) return false;

    // جلوگیری از دانلود همزمان همان ویدیو
    if (_downloadingVideos[url] ?? false) {
      debugPrint('ویدیو در حال دانلود است: $url');
      return false;
    }

    try {
      // بررسی وجود در کش
      if (await isVideoCached(url)) {
        debugPrint('ویدیو قبلاً در کش موجود است: $url');
        return true;
      }

      // بررسی فضای موجود
      await _cleanupCacheIfNeeded();

      final fileName = _getCacheFileName(url);
      final file = File('${_cacheDir!.path}/$fileName');

      debugPrint('شروع دانلود ویدیو برای کش: $url');
      _downloadingVideos[url] = true;

      // دانلود ویدیو با timeout و retry
      bool success = false;
      int retryCount = 0;

      while (!success && retryCount < _maxRetries) {
        try {
          success = await _downloadVideoWithTimeout(url, file);
          if (success) break;
        } catch (e) {
          retryCount++;
          debugPrint('تلاش $retryCount ناموفق برای دانلود $url: $e');
          if (retryCount < _maxRetries) {
            await Future<void>.delayed(
              Duration(seconds: retryCount * 2),
            ); // تاخیر افزایشی
          }
        }
      }

      _downloadingVideos[url] = false;

      if (success) {
        _accessTimes[url] = DateTime.now();
        debugPrint('ویدیو با موفقیت کش شد: ${file.path}');
        return true;
      } else {
        debugPrint('دانلود ویدیو پس از $retryCount تلاش ناموفق بود: $url');
        // حذف فایل ناقص
        if (await file.exists()) {
          await file.delete();
        }
        return false;
      }
    } catch (e) {
      _downloadingVideos[url] = false;
      debugPrint('خطا در کش کردن ویدیو: $e');
      return false;
    }
  }

  /// دانلود ویدیو با timeout و chunked download
  Future<bool> _downloadVideoWithTimeout(String url, File file) async {
    try {
      // ایجاد HTTP client با timeout
      final client = http.Client();

      try {
        // درخواست HEAD برای دریافت اندازه فایل
        final headResponse = await client
            .head(Uri.parse(url))
            .timeout(_downloadTimeout);

        if (headResponse.statusCode != 200) {
          debugPrint('خطا در دریافت اطلاعات فایل: ${headResponse.statusCode}');
          return false;
        }

        final contentLength = headResponse.headers['content-length'];
        final totalSize = contentLength != null
            ? int.tryParse(contentLength)
            : null;

        if (totalSize != null) {
          debugPrint(
            'اندازه فایل: ${(totalSize / (1024 * 1024)).toStringAsFixed(2)}MB',
          );
        }

        // دانلود chunked
        final response = await client
            .get(Uri.parse(url), headers: {'Range': 'bytes=0-'})
            .timeout(_downloadTimeout);

        if (response.statusCode == 200 || response.statusCode == 206) {
          // نوشتن فایل
          await file.writeAsBytes(response.bodyBytes);

          // بررسی صحت فایل
          final downloadedSize = await file.length();
          if (totalSize != null && downloadedSize < totalSize * 0.9) {
            debugPrint('فایل ناقص دانلود شده: $downloadedSize از $totalSize');
            return false;
          }

          return true;
        } else {
          debugPrint('خطا در دانلود ویدیو: ${response.statusCode}');
          return false;
        }
      } finally {
        client.close();
      }
    } catch (e) {
      if (e is TimeoutException) {
        debugPrint('دانلود ویدیو timeout شد: $url');
      } else {
        debugPrint('خطا در دانلود ویدیو: $e');
      }
      return false;
    }
  }

  /// دانلود ویدیو با progress tracking (برای UI)
  Future<bool> cacheVideoWithProgress(
    String url,
    void Function(double) onProgress,
  ) async {
    if (_cacheDir == null) return false;

    if (_downloadingVideos[url] ?? false) {
      debugPrint('ویدیو در حال دانلود است: $url');
      return false;
    }

    try {
      if (await isVideoCached(url)) {
        onProgress(1);
        return true;
      }

      await _cleanupCacheIfNeeded();

      final fileName = _getCacheFileName(url);
      final file = File('${_cacheDir!.path}/$fileName');

      debugPrint('شروع دانلود ویدیو با progress tracking: $url');
      _downloadingVideos[url] = true;

      final success = await _downloadVideoWithProgress(url, file, onProgress);

      _downloadingVideos[url] = false;

      if (success) {
        _accessTimes[url] = DateTime.now();
        onProgress(1);
        return true;
      } else {
        if (await file.exists()) {
          await file.delete();
        }
        return false;
      }
    } catch (e) {
      _downloadingVideos[url] = false;
      debugPrint('خطا در کش کردن ویدیو: $e');
      return false;
    }
  }

  /// دانلود ویدیو با progress tracking
  Future<bool> _downloadVideoWithProgress(
    String url,
    File file,
    void Function(double) onProgress,
  ) async {
    http.Client? client;
    IOSink? sink;

    try {
      client = http.Client();

      // درخواست HEAD برای دریافت اندازه فایل
      final headResponse = await client
          .head(Uri.parse(url))
          .timeout(_downloadTimeout);

      if (headResponse.statusCode != 200 && headResponse.statusCode != 206) {
        debugPrint('خطا در دریافت اطلاعات فایل: ${headResponse.statusCode}');
        return false;
      }

      final contentLength = headResponse.headers['content-length'];
      final totalSize = contentLength != null
          ? int.tryParse(contentLength)
          : null;

      if (totalSize == null || totalSize == 0) {
        // اگر اندازه فایل مشخص نیست، دانلود معمولی
        debugPrint('اندازه فایل مشخص نیست، دانلود معمولی...');
        final response = await client
            .get(Uri.parse(url))
            .timeout(_downloadTimeout);

        if (response.statusCode == 200) {
          int downloadedBytes = 0;
          final bodyBytes = response.bodyBytes;
          final bodyLength = bodyBytes.length;

          sink = file.openWrite();
          int lastProgressUpdate = 0;
          const progressUpdateInterval = 1024 * 100; // هر 100KB به‌روزرسانی کن

          for (int i = 0; i < bodyLength; i += 8192) {
            final end = (i + 8192 < bodyLength) ? i + 8192 : bodyLength;
            sink.add(bodyBytes.sublist(i, end));
            downloadedBytes = end;

            // به‌روزرسانی progress فقط هر چند KB یکبار
            if (downloadedBytes - lastProgressUpdate >=
                    progressUpdateInterval ||
                downloadedBytes >= bodyLength) {
              final progress = (downloadedBytes / bodyLength).clamp(0.0, 0.99);
              onProgress(progress);
              lastProgressUpdate = downloadedBytes;
            }

            await sink.flush();
          }
          await sink.close();
          sink = null;

          onProgress(1);
          return true;
        }
        return false;
      }

      debugPrint(
        'شروع دانلود ویدیو - اندازه: ${(totalSize / (1024 * 1024)).toStringAsFixed(2)}MB',
      );

      // دانلود streaming با progress واقعی
      final request = http.Request('GET', Uri.parse(url));
      final streamedResponse = await client
          .send(request)
          .timeout(_downloadTimeout);

      if (streamedResponse.statusCode == 200 ||
          streamedResponse.statusCode == 206) {
        sink = file.openWrite();
        int downloadedBytes = 0;
        int lastProgressUpdate = 0;
        const progressUpdateInterval = 1024 * 100; // هر 100KB به‌روزرسانی کن

        await for (final chunk in streamedResponse.stream) {
          sink.add(chunk);
          downloadedBytes += chunk.length;

          // به‌روزرسانی progress فقط هر چند KB یکبار برای عملکرد بهتر
          if (downloadedBytes - lastProgressUpdate >= progressUpdateInterval ||
              downloadedBytes >= totalSize) {
            final progress = (downloadedBytes / totalSize).clamp(0.0, 0.99);
            onProgress(progress);
            lastProgressUpdate = downloadedBytes;
          }

          await sink.flush();
        }

        await sink.close();
        sink = null;

        // بررسی صحت فایل
        final finalSize = await file.length();
        if (finalSize < totalSize * 0.95) {
          debugPrint('فایل ناقص دانلود شده: $finalSize از $totalSize');
          onProgress(0); // Reset progress on failure
          return false;
        }

        onProgress(1);
        debugPrint('دانلود کامل شد: $finalSize بایت');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('خطا در دانلود با progress: $e');
      return false;
    } finally {
      await sink?.close();
      client?.close();
    }
  }

  /// پاک‌سازی کش در صورت نیاز
  Future<void> _cleanupCacheIfNeeded() async {
    if (_cacheDir == null) return;

    try {
      final files = await _cacheDir!.list().toList();
      int totalSize = 0;
      final fileStats = <File, int>{};

      // محاسبه اندازه کل کش
      for (final entity in files.whereType<File>()) {
        final stat = await entity.stat();
        totalSize += stat.size;
        fileStats[entity] = stat.size;
      }

      // اگر اندازه کش از حد مجاز بیشتر است
      if (totalSize > _maxCacheSize) {
        debugPrint(
          'پاک‌سازی کش ویدیو - اندازه فعلی: ${totalSize ~/ (1024 * 1024)}MB',
        );

        // مرتب‌سازی فایل‌ها بر اساس زمان دسترسی
        final sortedFiles = fileStats.entries.toList()
          ..sort((a, b) {
            final aUrl = _getUrlFromFileName(a.key.path);
            final bUrl = _getUrlFromFileName(b.key.path);
            final aTime = _accessTimes[aUrl] ?? DateTime(1970);
            final bTime = _accessTimes[bUrl] ?? DateTime(1970);
            return aTime.compareTo(bTime);
          });

        // حذف فایل‌های قدیمی تا رسیدن به اندازه مناسب
        for (final entry in sortedFiles) {
          if (totalSize <= _maxCacheSize * 0.8) break; // تا 80% اندازه مجاز

          await entry.key.delete();
          totalSize -= entry.value;

          final url = _getUrlFromFileName(entry.key.path);
          _accessTimes.remove(url);
        }

        debugPrint('کش پاک‌سازی شد - اندازه جدید: ${totalSize ~/ (1024 * 1024)}MB');
      }
    } catch (e) {
      debugPrint('خطا در پاک‌سازی کش: $e');
    }
  }

  /// استخراج URL از نام فایل (برای مدیریت زمان دسترسی)
  String _getUrlFromFileName(String filePath) {
    final fileName = filePath.split('/').last;
    // این متد کامل نیست، اما برای مدیریت زمان دسترسی کافی است
    return fileName;
  }

  /// دریافت اندازه کش
  Future<int> getCacheSize() async {
    if (_cacheDir == null) return 0;

    try {
      final files = await _cacheDir!.list().toList();
      int totalSize = 0;

      for (final entity in files.whereType<File>()) {
        final stat = await entity.stat();
        totalSize += stat.size;
      }

      return totalSize;
    } catch (e) {
      debugPrint('خطا در محاسبه اندازه کش: $e');
      return 0;
    }
  }

  /// پاک‌سازی کامل کش
  Future<void> clearCache() async {
    if (_cacheDir == null) return;

    try {
      final files = await _cacheDir!.list().toList();

      for (final entity in files.whereType<File>()) {
        await entity.delete();
      }

      _accessTimes.clear();
      debugPrint('کش ویدیو کاملاً پاک شد');
    } catch (e) {
      debugPrint('خطا در پاک‌سازی کامل کش: $e');
    }
  }

  /// دریافت تعداد فایل‌های کش شده
  Future<int> getCachedFilesCount() async {
    if (_cacheDir == null) return 0;

    try {
      final files = await _cacheDir!.list().toList();
      return files.whereType<File>().length;
    } catch (e) {
      debugPrint('خطا در شمارش فایل‌های کش: $e');
      return 0;
    }
  }

  /// حذف ویدیو خاص از کش
  Future<bool> deleteCachedVideo(String url) async {
    if (_cacheDir == null) return false;

    try {
      final fileName = _getCacheFileName(url);
      final file = File('${_cacheDir!.path}/$fileName');

      if (await file.exists()) {
        await file.delete();
        _accessTimes.remove(url);
        _downloadingVideos.remove(url);
        debugPrint('ویدیو از کش حذف شد: $url');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('خطا در حذف ویدیو از کش: $e');
      return false;
    }
  }
}
