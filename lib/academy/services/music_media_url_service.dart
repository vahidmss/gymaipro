import 'package:gymaipro/academy/models/workout_music.dart';
import 'package:gymaipro/core/web_proxy_url.dart';

/// Resolves coach-music URLs for browser/PWA (CORS) via Supabase Edge Function.
abstract final class MusicMediaUrlService {
  static String playbackUrl(String originalUrl) {
    final normalized = WorkoutMusic.normalizeAudioUrl(originalUrl);
    if (normalized.isEmpty) return normalized;
    return WebProxyUrl.resolve(normalized);
  }

  static Map<String, String> fetchHeaders() => WebProxyUrl.fetchHeaders();

  static Uri fetchUri(String originalUrl) => Uri.parse(playbackUrl(originalUrl));
}
