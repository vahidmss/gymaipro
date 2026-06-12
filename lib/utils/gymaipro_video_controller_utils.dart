import 'dart:io';

import 'package:gymaipro/network/gymaipro_insecure_tls_hosts.dart';
import 'package:gymaipro/services/video_cache_service.dart';
import 'package:video_player/video_player.dart';

/// `VideoPlayerController.network` روی اندروید/iOS از TLS دارت استفاده نمی‌کند؛ برای HTTPS
/// gymaipro با گواهی خراب، اول با [VideoCacheService] (همان `http` + HttpOverrides) کش می‌کنیم.
class GymaiproVideoControllerUtils {
  GymaiproVideoControllerUtils._();

  static Future<VideoPlayerController> createForUrl(String url) async {
    final cache = VideoCacheService();
    var path = await cache.getCachedVideoPath(url);
    if (path != null) {
      return VideoPlayerController.file(File(path));
    }
    final uri = Uri.tryParse(url);
    if (uri != null &&
        uri.hasScheme &&
        uri.scheme == 'https' &&
        GymaiproInsecureTlsHosts.allowInsecureConnectionTo(uri.host)) {
      await cache.cacheVideo(url);
      path = await cache.getCachedVideoPath(url);
      if (path != null) {
        return VideoPlayerController.file(File(path));
      }
    }
    return VideoPlayerController.networkUrl(Uri.parse(url));
  }
}
