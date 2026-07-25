/// Helpers for picking the most bandwidth-friendly image URL from a
/// WordPress REST response (`_embed=true`).
///
/// WordPress exposes the full-size original at `wp:featuredmedia[0].source_url`
/// and smaller pre-generated variants under `media_details.sizes`. Cards and
/// thumbnails only need a mid-size variant, so downloading the full-size
/// original wastes a lot of data (often several MB per image). This picks a
/// resized variant when available and falls back to the original otherwise.
class WordPressMedia {
  const WordPressMedia._();

  /// Preferred size keys for cards/lists. Prefer mid sizes to cut WiFi usage;
  /// fall back to larger only if smaller variants are missing.
  static const List<String> _preferredSizes = [
    'medium_large',
    'medium',
    'large',
  ];

  /// Tiny variants for story circles / avatars (~64–150px on screen).
  static const List<String> _thumbnailSizes = [
    'medium',
    'thumbnail',
    'medium_large',
  ];

  /// Returns the best featured image URL for the given WordPress post JSON,
  /// preferring a resized variant over the full-size original. Returns null
  /// when no image is embedded.
  static String? bestFeaturedImageUrl(Map<String, dynamic> json) {
    return _pickFromEmbedded(json, _preferredSizes);
  }

  /// Smaller featured URL for story circles and compact thumbnails.
  static String? bestThumbnailUrl(Map<String, dynamic> json) {
    return _pickFromEmbedded(json, _thumbnailSizes);
  }

  static String? _pickFromEmbedded(
    Map<String, dynamic> json,
    List<String> preferredSizes,
  ) {
    try {
      final embedded = json['_embedded'];
      if (embedded is! Map<String, dynamic>) return null;

      final media = embedded['wp:featuredmedia'];
      if (media is! List || media.isEmpty) return null;

      final first = media.first;
      if (first is! Map<String, dynamic>) return null;

      final details = first['media_details'];
      if (details is Map<String, dynamic>) {
        final sizes = details['sizes'];
        if (sizes is Map<String, dynamic>) {
          for (final key in preferredSizes) {
            final size = sizes[key];
            if (size is Map<String, dynamic>) {
              final url = size['source_url']?.toString();
              if (url != null && url.isNotEmpty) return url;
            }
          }
        }
      }

      // Fallback: full-size original.
      final source = first['source_url']?.toString();
      if (source != null && source.isNotEmpty) return source;
    } catch (_) {}
    return null;
  }
}
