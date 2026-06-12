import 'package:gymaipro/utils/json_parse_utils.dart';

class FitnessLegend {
  FitnessLegend({
    required this.id,
    required this.title,
    required this.contentHtml,
    required this.link,
    required this.date,
    required this.fullName,
    this.nickname,
    this.nationality,
    this.heightCm,
    this.weightStage,
    this.olympiaTitles,
    this.featuredImageUrl,
  });

  final int id;
  final String title;
  final String contentHtml;
  final String link;
  final DateTime date;
  final String fullName;
  final String? nickname;
  final String? nationality;
  final String? heightCm;
  final String? weightStage;
  final String? olympiaTitles;
  final String? featuredImageUrl;

  static FitnessLegend fromWordPressJson(Map<String, dynamic> json) {
    final rawTitle = json['title'];
    final rawContent = json['content'];

    final titleRendered = rawTitle is Map<String, dynamic>
        ? (rawTitle['rendered'] ?? '').toString()
        : (rawTitle ?? '').toString();
    final contentRendered = rawContent is Map<String, dynamic>
        ? (rawContent['rendered'] ?? '').toString()
        : (rawContent ?? '').toString();

    // Extract meta fields (defensively)
    final rawMeta = json['meta'];
    final meta = rawMeta is Map<String, dynamic>
        ? rawMeta
        : <String, dynamic>{};

    final fullName = (meta['full_name'] ?? '').toString();
    final nickname = meta['nickname']?.toString();
    final nationality = meta['nationality']?.toString();
    final heightCm = meta['height_cm']?.toString();
    final weightStage = meta['weight_stage']?.toString();
    final olympiaTitles = meta['olympia_titles']?.toString();

    // Extract featured image
    String? imageUrl;
    try {
      final embedded = json['_embedded'];
      if (embedded is Map<String, dynamic>) {
        final media = embedded['wp:featuredmedia'];
        if (media is List && media.isNotEmpty) {
          final first = media.first;
          if (first is Map<String, dynamic>) {
            final mediaSource = first['source_url']?.toString();
            if (mediaSource != null && mediaSource.isNotEmpty) {
              imageUrl = mediaSource;
            }
          }
        }
      }
    } catch (_) {}

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

    return FitnessLegend(
      id: id,
      title: _stripHtml(titleRendered).trim(),
      contentHtml: contentRendered,
      link: (json['link'] ?? '').toString(),
      date: date,
      fullName: fullName.isNotEmpty
          ? fullName
          : _stripHtml(titleRendered).trim(),
      nickname: nickname?.isNotEmpty ?? false ? nickname : null,
      nationality: nationality?.isNotEmpty ?? false ? nationality : null,
      heightCm: heightCm?.isNotEmpty ?? false ? heightCm : null,
      weightStage: weightStage?.isNotEmpty ?? false ? weightStage : null,
      olympiaTitles: olympiaTitles?.isNotEmpty ?? false ? olympiaTitles : null,
      featuredImageUrl: imageUrl,
    );
  }

  static List<FitnessLegend> listFromWordPress(List<dynamic> data) {
    return data
        .whereType<Map<String, dynamic>>()
        .map(FitnessLegend.fromWordPressJson)
        .toList();
  }

  static String _stripHtml(String html) {
    return html.replaceAll(RegExp('<[^>]*>'), '');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'contentHtml': contentHtml,
      'link': link,
      'date': date.toIso8601String(),
      'fullName': fullName,
      'nickname': nickname,
      'nationality': nationality,
      'heightCm': heightCm,
      'weightStage': weightStage,
      'olympiaTitles': olympiaTitles,
      'featuredImageUrl': featuredImageUrl,
    };
  }

  static FitnessLegend fromJson(Map<String, dynamic> json) {
    return FitnessLegend(
      id: JsonParse.integer(json, 'id'),
      title: JsonParse.string(json, 'title'),
      contentHtml: JsonParse.string(json, 'contentHtml'),
      link: JsonParse.string(json, 'link'),
      date: JsonParse.dateTime(json, 'date'),
      fullName: JsonParse.string(json, 'fullName', 'نام'),
      nickname: JsonParse.stringOrNull(json, 'nickname'),
      nationality: JsonParse.stringOrNull(json, 'nationality'),
      heightCm: JsonParse.stringOrNull(json, 'heightCm'),
      weightStage: JsonParse.stringOrNull(json, 'weightStage'),
      olympiaTitles: JsonParse.stringOrNull(json, 'olympiaTitles'),
      featuredImageUrl: JsonParse.stringOrNull(json, 'featuredImageUrl'),
    );
  }
}
