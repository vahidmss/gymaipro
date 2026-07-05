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

  /// Preferred size keys, largest-useful first. `large` (~1024px) is plenty for
  /// full-width phone cards; smaller ones are used only if `large` is missing.
  static const List<String> _preferredSizes = [
    'large',
    'medium_large',
    'medium',
  ];

  /// Returns the best featured image URL for the given WordPress post JSON,
  /// preferring a resized variant over the full-size original. Returns null
  /// when no image is embedded.
  static String? bestFeaturedImageUrl(Map<String, dynamic> json) {
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
          for (final key in _preferredSizes) {
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
