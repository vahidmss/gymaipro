class Article {
  Article({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.contentHtml,
    required this.link,
    required this.date,
    this.featuredImageUrl,
  });
  final int id;
  final String title;
  final String excerpt;
  final String contentHtml;
  final String link;
  final DateTime date;
  final String? featuredImageUrl;

  static Article fromWordPressJson(Map<String, dynamic> json) {
    final titleRendered = (json['title']?['rendered'] ?? '').toString();
    final contentRendered = (json['content']?['rendered'] ?? '').toString();
    final excerptRendered = (json['excerpt']?['rendered'] ?? '').toString();

    String? imageUrl;
    try {
      final embedded = json['_embedded'];
      if (embedded is Map && embedded['wp:featuredmedia'] is List) {
        final media = embedded['wp:featuredmedia'] as List;
        if (media.isNotEmpty) {
          final mediaItem = media.first as Map<String, dynamic>;
          final mediaSource = mediaItem['source_url']?.toString();
          if (mediaSource != null && mediaSource.isNotEmpty) {
            imageUrl = mediaSource;
          }
        }
      }
    } catch (_) {}

    return Article(
      id: json['id'] as int,
      title: _stripHtml(titleRendered).trim(),
      excerpt: _stripHtml(excerptRendered).trim(),
      contentHtml: contentRendered,
      link: (json['link'] ?? '').toString(),
      date:
          DateTime.tryParse((json['date'] ?? '').toString()) ?? DateTime.now(),
      featuredImageUrl: imageUrl,
    );
  }

  static List<Article> listFromWordPress(List<dynamic> data) {
    return data
        .whereType<Map<String, dynamic>>()
        .map(Article.fromWordPressJson)
        .toList();
  }

  static String _stripHtml(String html) {
    return html.replaceAll(RegExp('<[^>]*>'), '');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'excerpt': excerpt,
      'contentHtml': contentHtml,
      'link': link,
      'date': date.toIso8601String(),
      'featuredImageUrl': featuredImageUrl,
    };
  }

  static Article fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'] as int,
      title: json['title'] as String,
      excerpt: json['excerpt'] as String,
      contentHtml: json['contentHtml'] as String,
      link: json['link'] as String,
      date: DateTime.parse(json['date'] as String),
      featuredImageUrl: json['featuredImageUrl'] as String?,
    );
  }
}
