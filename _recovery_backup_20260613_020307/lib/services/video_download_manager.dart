import 'package:flutter/foundation.dart';
import 'package:gymaipro/services/video_cache_service.dart';

/// Manager for tracking video download progress across the app
class VideoDownloadManager extends ChangeNotifier {
  factory VideoDownloadManager() => _instance;
  VideoDownloadManager._internal();
  static final VideoDownloadManager _instance =
      VideoDownloadManager._internal();

  final Map<String, double> _downloadProgress = {};
  final Map<String, bool> _isDownloading = {};
  final VideoCacheService _cacheService = VideoCacheService();

  /// Get download progress for a video URL
  double getProgress(String url) => _downloadProgress[url] ?? 0.0;

  /// Check if video is downloading
  bool isDownloading(String url) => _isDownloading[url] ?? false;

  /// Start downloading a video with progress tracking
  Future<bool> downloadVideo(String url) async {
    if (_isDownloading[url] == true) {
      return false; // Already downloading
    }

    _isDownloading[url] = true;
    _downloadProgress[url] = 0.0;
    notifyListeners();

    try {
      final success = await _cacheService.cacheVideoWithProgress(url, (
        progress,
      ) {
        _downloadProgress[url] = progress;
        notifyListeners();
      });

      if (success) {
        _downloadProgress[url] = 1.0;
      } else {
        _downloadProgress[url] = 0.0;
      }

      _isDownloading[url] = false;
      notifyListeners();

      return success;
    } catch (e) {
      _isDownloading[url] = false;
      _downloadProgress[url] = 0.0;
      notifyListeners();
      return false;
    }
  }

  /// Cancel download (if possible)
  void cancelDownload(String url) {
    _isDownloading[url] = false;
    _downloadProgress[url] = 0.0;
    notifyListeners();
  }

  /// Clear progress for a video
  void clearProgress(String url) {
    _downloadProgress.remove(url);
    _isDownloading.remove(url);
    notifyListeners();
  }
}
