import 'package:gymaipro/utils/json_parse_utils.dart';
import 'package:gymaipro/utils/wordpress_media.dart';

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
    final rawTitle = json['title'];
    final rawContent = json['content'];
    final rawExcerpt = json['excerpt'];

    final titleRendered = rawTitle is Map<String, dynamic>
        ? (rawTitle['rendered'] ?? '').toString()
        : (rawTitle ?? '').toString();
    final contentRendered = rawContent is Map<String, dynamic>
        ? (rawContent['rendered'] ?? '').toString()
        : (rawContent ?? '').toString();
    final excerptRendered = rawExcerpt is Map<String, dynamic>
        ? (rawExcerpt['rendered'] ?? '').toString()
        : (rawExcerpt ?? '').toString();

    final imageUrl = WordPressMedia.bestFeaturedImageUrl(json);

    int id = 0;
    try {
      final rawId = json['id'];
      if (rawId is int) {
        id = rawId;
      } else if (rawId != null) {
        id = int.tryParse(rawId.toString()) ?? 0;
      }
    } catch (_) {
      id = 0;
    }

    DateTime date;
    try {
      final rawDate = (json['date'] ?? '').toString();
      date = DateTime.tryParse(rawDate) ?? DateTime.now();
    } catch (_) {
      date = DateTime.now();
    }

    return Article(
      id: id,
      title: _stripHtml(titleRendered).trim(),
      excerpt: _stripHtml(excerptRendered).trim(),
      contentHtml: contentRendered,
      link: (json['link'] ?? '').toString(),
      date: date,
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
      id: JsonParse.integer(json, 'id'),
      title: JsonParse.string(json, 'title'),
      excerpt: JsonParse.string(json, 'excerpt'),
      contentHtml: JsonParse.string(json, 'contentHtml'),
      link: JsonParse.string(json, 'link'),
      date: JsonParse.dateTime(json, 'date'),
      featuredImageUrl: JsonParse.stringOrNull(json, 'featuredImageUrl'),
    );
  }
}
