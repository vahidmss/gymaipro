import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:gymaipro/academy/models/workout_music.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

class MusicCacheService {
  static final MusicCacheService _instance = MusicCacheService._internal();
  factory MusicCacheService() => _instance;
  MusicCacheService._internal();

  Directory? _cacheDir;
  Directory? _downloadDir;
  final Map<String, bool> _downloadingUrls = {};
  final Map<String, bool> _cachingUrls = {};

  // Key for storing explicitly downloaded music URLs
  static const String _downloadedUrlsKey = 'downloaded_music_urls';

  /// Build a stable key for local storage, so signed URLs (with changing query params)
  /// still map to the same local file.
  ///
  /// Example:
  /// - Input:  https://.../file.mp3?token=abc
  /// - Output: https://.../file.mp3
  String _storageKey(String url) {
    final normalized = WorkoutMusic.normalizeAudioUrl(url);
    if (normalized.isEmpty) return normalized;
    try {
      final uri = Uri.parse(normalized);
      return uri.replace(query: null, fragment: null).toString();
    } catch (_) {
      return normalized;
    }
  }

  String _getLegacyFileName(String url) {
    final bytes = utf8.encode(url);
    final digest = sha256.convert(bytes);
    return '${digest.toString()}.${_getFileExtension(url)}';
  }

  Future<Directory> _getCacheDirectory() async {
    if (_cacheDir != null) return _cacheDir!;

    final appDir = await getApplicationDocumentsDirectory();
    _cacheDir = Directory(path.join(appDir.path, 'music_cache'));
    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }
    return _cacheDir!;
  }

  Future<Directory> _getDownloadDirectory() async {
    if (_downloadDir != null) return _downloadDir!;

    final appDir = await getApplicationDocumentsDirectory();
    _downloadDir = Directory(path.join(appDir.path, 'music_downloads'));
    if (!await _downloadDir!.exists()) {
      await _downloadDir!.create(recursive: true);
    }
    return _downloadDir!;
  }

  String _getFileName(String url) {
    final key = _storageKey(url);
    final bytes = utf8.encode(key);
    final digest = sha256.convert(bytes);
    return '${digest.toString()}.${_getFileExtension(key)}';
  }

  String _getFileExtension(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        final fileName = pathSegments.last;
        final ext = path.extension(fileName);
        if (ext.isNotEmpty) {
          return ext.substring(1); // Remove dot
        }
      }
    } catch (_) {}
    return 'mp3'; // Default extension
  }

  Future<String?> getCachedPath(String url) async {
    try {
      final cacheDir = await _getCacheDirectory();
      final fileName = _getFileName(url);
      final file = File(path.join(cacheDir.path, fileName));

      if (await file.exists()) {
        return file.path;
      }

      // Backward-compat: older versions hashed the full URL (including query).
      final legacyFileName = _getLegacyFileName(url);
      final legacyFile = File(path.join(cacheDir.path, legacyFileName));
      if (await legacyFile.exists()) {
        // Best-effort migration to stable filename.
        try {
          await legacyFile.rename(file.path);
          return file.path;
        } catch (_) {
          return legacyFile.path;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Cache music in background (for performance, temporary)
  /// This is automatic cache that happens after playback
  Future<String?> cacheMusic(String url) async {
    final key = _storageKey(url);
    if (_cachingUrls[key] == true) {
      // Already caching
      return null;
    }

    try {
      // Check if already cached
      final cachedPath = await getCachedPath(key);
      if (cachedPath != null) {
        return cachedPath;
      }

      _cachingUrls[key] = true;

      // Download music
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(minutes: 5));

      if (response.statusCode == 200) {
        final cacheDir = await _getCacheDirectory();
        final fileName = _getFileName(key);
        final file = File(path.join(cacheDir.path, fileName));

        await file.writeAsBytes(response.bodyBytes);
        _cachingUrls[key] = false;

        return file.path;
      } else {
        _cachingUrls[key] = false;
        return null;
      }
    } catch (e) {
      _cachingUrls[key] = false;
      debugPrint('Error caching music: $e');
      return null;
    }
  }

  /// Download music explicitly (permanent, user-initiated)
  /// This is for the "Downloaded" tab
  Future<String?> downloadMusic(String url) async {
    final key = _storageKey(url);
    if (_downloadingUrls[key] == true) {
      // Already downloading
      return null;
    }

    try {
      // Check if already downloaded
      final downloadedPath = await getDownloadedPath(key, legacyUrl: url);
      if (downloadedPath != null) {
        return downloadedPath;
      }

      _downloadingUrls[key] = true;

      // Download music
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(minutes: 5));

      if (response.statusCode == 200) {
        final downloadDir = await _getDownloadDirectory();
        final fileName = _getFileName(key);
        final file = File(path.join(downloadDir.path, fileName));

        await file.writeAsBytes(response.bodyBytes);

        // Mark as explicitly downloaded
        await _markAsDownloaded(key, legacyUrl: url);

        _downloadingUrls[key] = false;

        return file.path;
      } else {
        _downloadingUrls[key] = false;
        return null;
      }
    } catch (e) {
      _downloadingUrls[key] = false;
      debugPrint('Error downloading music: $e');
      return null;
    }
  }

  Future<String?> getDownloadedPath(String url, {String? legacyUrl}) async {
    try {
      final downloadDir = await _getDownloadDirectory();
      final fileName = _getFileName(url);
      final file = File(path.join(downloadDir.path, fileName));

      if (await file.exists()) {
        return file.path;
      }

      // Backward-compat: older versions hashed the full URL (including query).
      final legacyKey = legacyUrl ?? url;
      final legacyFileName = _getLegacyFileName(legacyKey);
      final legacyFile = File(path.join(downloadDir.path, legacyFileName));
      if (await legacyFile.exists()) {
        // Best-effort migration to stable filename.
        try {
          await legacyFile.rename(file.path);
          // Ensure prefs includes stable key too.
          await _markAsDownloaded(url, legacyUrl: legacyKey);
          return file.path;
        } catch (_) {
          return legacyFile.path;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> isDownloaded(String url) async {
    final key = _storageKey(url);
    final downloadedPath = await getDownloadedPath(key, legacyUrl: url);
    if (downloadedPath == null) return false;

    // Also check if marked as downloaded in preferences
    final prefs = await SharedPreferences.getInstance();
    final downloadedUrls = prefs.getStringList(_downloadedUrlsKey) ?? [];
    if (downloadedUrls.contains(key)) return true;

    // Legacy: if old key exists, migrate it.
    if (downloadedUrls.contains(url)) {
      await _markAsDownloaded(key, legacyUrl: url);
      return true;
    }

    // If file exists but prefs missing (e.g. after restore/cleanup), backfill it.
    await _markAsDownloaded(key);
    return true;
  }

  /// Best local path for playback (prefer explicit downloads, then cache).
  /// Returns null if nothing exists locally.
  Future<String?> getBestLocalPathForPlayback(String url) async {
    // Prefer downloads (explicit user action)
    final key = _storageKey(url);
    final downloadedPath = await getDownloadedPath(key, legacyUrl: url);
    if (downloadedPath != null) {
      return downloadedPath;
    }

    // Then fallback to auto-cache
    return await getCachedPath(key);
  }

  Future<void> _markAsDownloaded(String url, {String? legacyUrl}) async {
    final prefs = await SharedPreferences.getInstance();
    final downloadedUrls = prefs.getStringList(_downloadedUrlsKey) ?? [];
    if (!downloadedUrls.contains(url)) {
      downloadedUrls.add(url);
    }
    if (legacyUrl != null && downloadedUrls.contains(legacyUrl)) {
      downloadedUrls.remove(legacyUrl);
    }
    await prefs.setStringList(_downloadedUrlsKey, downloadedUrls);
  }

  Future<void> _unmarkAsDownloaded(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final downloadedUrls = prefs.getStringList(_downloadedUrlsKey) ?? [];
    downloadedUrls.remove(url);
    downloadedUrls.remove(_storageKey(url));
    await prefs.setStringList(_downloadedUrlsKey, downloadedUrls);
  }

  Future<void> deleteDownloadedMusic(String url) async {
    try {
      final key = _storageKey(url);
      final downloadedPath = await getDownloadedPath(key, legacyUrl: url);
      if (downloadedPath != null) {
        final file = File(downloadedPath);
        if (await file.exists()) {
          await file.delete();
        }
      }
      await _unmarkAsDownloaded(url);
    } catch (_) {}
  }

  /// Get list of explicitly downloaded URLs
  Future<List<String>> getDownloadedUrls(List<WorkoutMusic> allMusics) async {
    final result = <String>[];
    for (final music in allMusics) {
      final normalizedUrl = WorkoutMusic.normalizeAudioUrl(music.audioUrl);
      // isDownloaded() handles prefs + file existence + migration.
      if (await isDownloaded(normalizedUrl)) {
        result.add(normalizedUrl);
      }
    }
    return result;
  }

  Future<void> deleteCachedMusic(String url) async {
    try {
      final cachedPath = await getCachedPath(_storageKey(url));
      if (cachedPath != null) {
        final file = File(cachedPath);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (_) {}
  }

  Future<void> clearCache() async {
    try {
      final cacheDir = await _getCacheDirectory();
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        await cacheDir.create(recursive: true);
      }
    } catch (_) {}
  }

  Future<int> getCacheSize() async {
    try {
      final cacheDir = await _getCacheDirectory();
      if (!await cacheDir.exists()) return 0;

      int totalSize = 0;
      await for (final entity in cacheDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (_) {
      return 0;
    }
  }

  bool isDownloading(String url) {
    return _downloadingUrls[_storageKey(url)] == true;
  }

  bool isCaching(String url) {
    return _cachingUrls[_storageKey(url)] == true;
  }

  /// Check if a music is cached
  Future<bool> isCached(String url) async {
    final cachedPath = await getCachedPath(_storageKey(url));
    return cachedPath != null;
  }

  /// Get list of cached URLs from all music list
  Future<List<String>> getCachedUrls(List<WorkoutMusic> allMusics) async {
    final cachedUrls = <String>[];
    for (final music in allMusics) {
      final normalizedUrl = WorkoutMusic.normalizeAudioUrl(music.audioUrl);
      if (await isCached(normalizedUrl)) {
        cachedUrls.add(normalizedUrl);
      }
    }
    return cachedUrls;
  }
}
