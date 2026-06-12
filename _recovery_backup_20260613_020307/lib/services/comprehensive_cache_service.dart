import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gymaipro/services/video_cache_service.dart';
import 'package:gymaipro/academy/services/music_cache_service.dart';

/// اطلاعات هر نوع کش
class CacheInfo {
  final String type;
  final String displayName;
  final int size;
  final int fileCount;
  final IconData icon;

  CacheInfo({
    required this.type,
    required this.displayName,
    required this.size,
    required this.fileCount,
    required this.icon,
  });
}

/// اطلاعات یک فایل کش شده
class CachedFile {
  final String path;
  final String fileName;
  final int size;
  final DateTime modifiedDate;
  final String type; // 'video', 'music_cache', 'music_downloads'

  CachedFile({
    required this.path,
    required this.fileName,
    required this.size,
    required this.modifiedDate,
    required this.type,
  });
}

/// سرویس جامع برای مدیریت همه انواع کش
class ComprehensiveCacheService {
  static final ComprehensiveCacheService _instance =
      ComprehensiveCacheService._internal();
  factory ComprehensiveCacheService() => _instance;
  ComprehensiveCacheService._internal();

  final VideoCacheService _videoCacheService = VideoCacheService();
  final MusicCacheService _musicCacheService = MusicCacheService();

  /// دریافت اطلاعات همه انواع کش
  Future<List<CacheInfo>> getAllCacheInfo() async {
    final List<CacheInfo> cacheInfos = [];

    try {
      // کش ویدیو
      final videoSize = await _videoCacheService.getCacheSize();
      final videoCount = await _videoCacheService.getCachedFilesCount();
      cacheInfos.add(
        CacheInfo(
          type: 'video',
          displayName: 'ویدیوها',
          size: videoSize,
          fileCount: videoCount,
          icon: Icons.video_library,
        ),
      );
    } catch (e) {
      // خطا را نادیده می‌گیریم و ادامه می‌دهیم
    }

    try {
      // کش موزیک (کش خودکار)
      final musicCacheSize = await _musicCacheService.getCacheSize();
      final musicCacheCount = await _getMusicCacheFileCount();

      // موزیک‌های دانلود شده (دانلودهای کاربر)
      final musicDownloadSize = await _getMusicDownloadSize();
      final musicDownloadCount = await _getMusicDownloadFileCount();

      // اگر کش خودکار وجود دارد
      if (musicCacheSize > 0) {
        cacheInfos.add(
          CacheInfo(
            type: 'music_cache',
            displayName: 'موزیک‌های کش شده',
            size: musicCacheSize,
            fileCount: musicCacheCount,
            icon: Icons.music_note,
          ),
        );
      }

      // اگر دانلودهای کاربر وجود دارد
      if (musicDownloadSize > 0) {
        cacheInfos.add(
          CacheInfo(
            type: 'music_downloads',
            displayName: 'موزیک‌های دانلود شده',
            size: musicDownloadSize,
            fileCount: musicDownloadCount,
            icon: Icons.download,
          ),
        );
      }
    } catch (e) {
      // خطا را نادیده می‌گیریم و ادامه می‌دهیم
    }

    try {
      // کش تصاویر (از دایرکتوری cache سیستم)
      final imageCacheInfo = await _getImageCacheInfo();
      if (imageCacheInfo.size > 0) {
        cacheInfos.add(imageCacheInfo);
      }
    } catch (e) {
      // خطا را نادیده می‌گیریم و ادامه می‌دهیم
    }

    try {
      // کش عمومی سیستم (از getTemporaryDirectory)
      final tempCacheInfo = await _getTempCacheInfo();
      if (tempCacheInfo.size > 0) {
        cacheInfos.add(tempCacheInfo);
      }
    } catch (e) {
      // خطا را نادیده می‌گیریم و ادامه می‌دهیم
    }

    return cacheInfos;
  }

  /// دریافت تعداد فایل‌های کش موزیک
  Future<int> _getMusicCacheFileCount() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDir.path}/music_cache');
      if (!await cacheDir.exists()) return 0;

      int count = 0;
      await for (final entity in cacheDir.list(recursive: true)) {
        if (entity is File) {
          count++;
        }
      }
      return count;
    } catch (_) {
      return 0;
    }
  }

  /// دریافت اندازه موزیک‌های دانلود شده
  Future<int> _getMusicDownloadSize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final downloadDir = Directory('${appDir.path}/music_downloads');
      if (!await downloadDir.exists()) return 0;

      int totalSize = 0;
      await for (final entity in downloadDir.list(recursive: true)) {
        if (entity is File) {
          try {
            totalSize += await entity.length();
          } catch (_) {
            // فایل ممکن است حذف شده باشد
          }
        }
      }
      return totalSize;
    } catch (_) {
      return 0;
    }
  }

  /// دریافت تعداد فایل‌های موزیک دانلود شده
  Future<int> _getMusicDownloadFileCount() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final downloadDir = Directory('${appDir.path}/music_downloads');
      if (!await downloadDir.exists()) return 0;

      int count = 0;
      await for (final entity in downloadDir.list(recursive: true)) {
        if (entity is File) {
          count++;
        }
      }
      return count;
    } catch (_) {
      return 0;
    }
  }

  /// دریافت اطلاعات کش تصاویر
  Future<CacheInfo> _getImageCacheInfo() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      int totalSize = 0;
      int fileCount = 0;

      // بررسی دایرکتوری‌های مربوط به تصاویر
      final imageDirs = [
        Directory('${cacheDir.path}/image_picker'),
        Directory('${cacheDir.path}/image_cropper'),
        Directory('${cacheDir.path}/flutter_image_cache'),
      ];

      for (final dir in imageDirs) {
        if (await dir.exists()) {
          await for (final entity in dir.list(recursive: true)) {
            if (entity is File) {
              try {
                totalSize += await entity.length();
                fileCount++;
              } catch (_) {
                // فایل ممکن است حذف شده باشد
              }
            }
          }
        }
      }

      return CacheInfo(
        type: 'images',
        displayName: 'تصاویر',
        size: totalSize,
        fileCount: fileCount,
        icon: Icons.image,
      );
    } catch (_) {
      return CacheInfo(
        type: 'images',
        displayName: 'تصاویر',
        size: 0,
        fileCount: 0,
        icon: Icons.image,
      );
    }
  }

  /// دریافت اطلاعات کش موقت سیستم
  Future<CacheInfo> _getTempCacheInfo() async {
    try {
      final tempDir = await getTemporaryDirectory();
      int totalSize = 0;
      int fileCount = 0;

      // فقط فایل‌های مستقیم در temp directory (نه زیرپوشه‌های خاص)
      if (await tempDir.exists()) {
        await for (final entity in tempDir.list()) {
          if (entity is File) {
            try {
              totalSize += await entity.length();
              fileCount++;
            } catch (_) {
              // فایل ممکن است حذف شده باشد
            }
          }
        }
      }

      if (totalSize == 0) {
        return CacheInfo(
          type: 'temp',
          displayName: 'کش موقت',
          size: 0,
          fileCount: 0,
          icon: Icons.folder,
        );
      }

      return CacheInfo(
        type: 'temp',
        displayName: 'کش موقت',
        size: totalSize,
        fileCount: fileCount,
        icon: Icons.folder,
      );
    } catch (_) {
      return CacheInfo(
        type: 'temp',
        displayName: 'کش موقت',
        size: 0,
        fileCount: 0,
        icon: Icons.folder,
      );
    }
  }

  /// دریافت اندازه کل همه کش‌ها
  Future<int> getTotalCacheSize() async {
    final cacheInfos = await getAllCacheInfo();
    return cacheInfos.fold<int>(0, (sum, info) => sum + info.size);
  }

  /// دریافت تعداد کل فایل‌های کش شده
  Future<int> getTotalFileCount() async {
    final cacheInfos = await getAllCacheInfo();
    return cacheInfos.fold<int>(0, (sum, info) => sum + info.fileCount);
  }

  /// پاک کردن کش خاص
  Future<bool> clearCacheByType(String type) async {
    try {
      switch (type) {
        case 'video':
          await _videoCacheService.clearCache();
          return true;
        case 'music_cache':
          await _musicCacheService.clearCache();
          return true;
        case 'music_downloads':
          return await _clearMusicDownloads();
        case 'images':
          return await _clearImageCache();
        case 'temp':
          return await _clearTempCache();
        default:
          return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// پاک کردن موزیک‌های دانلود شده
  Future<bool> _clearMusicDownloads() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final downloadDir = Directory('${appDir.path}/music_downloads');
      if (await downloadDir.exists()) {
        await downloadDir.delete(recursive: true);
        await downloadDir.create(recursive: true);
      }
      // همچنین لیست دانلود شده‌ها را از SharedPreferences پاک می‌کنیم
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('downloaded_music_urls');
      return true;
    } catch (_) {
      return false;
    }
  }

  /// پاک کردن کش تصاویر
  Future<bool> _clearImageCache() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final imageDirs = [
        Directory('${cacheDir.path}/image_picker'),
        Directory('${cacheDir.path}/image_cropper'),
        Directory('${cacheDir.path}/flutter_image_cache'),
      ];

      for (final dir in imageDirs) {
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// پاک کردن کش موقت
  Future<bool> _clearTempCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        await for (final entity in tempDir.list()) {
          if (entity is File) {
            try {
              await entity.delete();
            } catch (_) {
              // فایل ممکن است در حال استفاده باشد
            }
          }
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// پاک کردن همه کش‌ها
  Future<void> clearAllCache() async {
    try {
      await _videoCacheService.clearCache();
      await _musicCacheService.clearCache();
      await _clearMusicDownloads();
      await _clearImageCache();
      await _clearTempCache();
    } catch (e) {
      // حتی اگر خطایی رخ داد، ادامه می‌دهیم
    }
  }

  /// دریافت لیست فایل‌های ویدیو
  Future<List<CachedFile>> getVideoFiles() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDir.path}/video_cache');
      if (!await cacheDir.exists()) return [];

      final List<CachedFile> files = [];
      await for (final entity in cacheDir.list()) {
        if (entity is File) {
          try {
            final stat = await entity.stat();
            files.add(
              CachedFile(
                path: entity.path,
                fileName: entity.path.split('/').last,
                size: stat.size,
                modifiedDate: stat.modified,
                type: 'video',
              ),
            );
          } catch (_) {
            // فایل ممکن است حذف شده باشد
          }
        }
      }
      // مرتب‌سازی بر اساس تاریخ (جدیدترین اول)
      files.sort((a, b) => b.modifiedDate.compareTo(a.modifiedDate));
      return files;
    } catch (_) {
      return [];
    }
  }

  /// دریافت لیست فایل‌های موزیک کش شده
  Future<List<CachedFile>> getMusicCacheFiles() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDir.path}/music_cache');
      if (!await cacheDir.exists()) return [];

      final List<CachedFile> files = [];
      await for (final entity in cacheDir.list(recursive: true)) {
        if (entity is File) {
          try {
            final stat = await entity.stat();
            files.add(
              CachedFile(
                path: entity.path,
                fileName: entity.path.split('/').last,
                size: stat.size,
                modifiedDate: stat.modified,
                type: 'music_cache',
              ),
            );
          } catch (_) {
            // فایل ممکن است حذف شده باشد
          }
        }
      }
      files.sort((a, b) => b.modifiedDate.compareTo(a.modifiedDate));
      return files;
    } catch (_) {
      return [];
    }
  }

  /// دریافت لیست فایل‌های موزیک دانلود شده
  Future<List<CachedFile>> getMusicDownloadFiles() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final downloadDir = Directory('${appDir.path}/music_downloads');
      if (!await downloadDir.exists()) return [];

      final List<CachedFile> files = [];
      await for (final entity in downloadDir.list(recursive: true)) {
        if (entity is File) {
          try {
            final stat = await entity.stat();
            files.add(
              CachedFile(
                path: entity.path,
                fileName: entity.path.split('/').last,
                size: stat.size,
                modifiedDate: stat.modified,
                type: 'music_downloads',
              ),
            );
          } catch (_) {
            // فایل ممکن است حذف شده باشد
          }
        }
      }
      files.sort((a, b) => b.modifiedDate.compareTo(a.modifiedDate));
      return files;
    } catch (_) {
      return [];
    }
  }

  /// حذف فایل خاص
  Future<bool> deleteFile(CachedFile file) async {
    try {
      final fileEntity = File(file.path);
      if (await fileEntity.exists()) {
        await fileEntity.delete();

        // اگر موزیک دانلود شده است، فایل حذف می‌شود
        // نمی‌توانیم URL را از نام فایل استخراج کنیم، پس فقط فایل را حذف می‌کنیم

        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
