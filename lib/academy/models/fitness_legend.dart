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
    final titleRendered = (json['title']?['rendered'] ?? '').toString();
    final contentRendered = (json['content']?['rendered'] ?? '').toString();

    // Extract meta fields
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
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

    return FitnessLegend(
      id: json['id'] as int,
      title: _stripHtml(titleRendered).trim(),
      contentHtml: contentRendered,
      link: (json['link'] ?? '').toString(),
      date:
          DateTime.tryParse((json['date'] ?? '').toString()) ?? DateTime.now(),
      fullName: fullName.isNotEmpty
          ? fullName
          : _stripHtml(titleRendered).trim(),
      nickname: nickname?.isNotEmpty == true ? nickname : null,
      nationality: nationality?.isNotEmpty == true ? nationality : null,
      heightCm: heightCm?.isNotEmpty == true ? heightCm : null,
      weightStage: weightStage?.isNotEmpty == true ? weightStage : null,
      olympiaTitles: olympiaTitles?.isNotEmpty == true ? olympiaTitles : null,
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
      id: json['id'] as int,
      title: json['title'] as String,
      contentHtml: json['contentHtml'] as String,
      link: json['link'] as String,
      date: DateTime.parse(json['date'] as String),
      fullName: json['fullName'] as String,
      nickname: json['nickname'] as String?,
      nationality: json['nationality'] as String?,
      heightCm: json['heightCm'] as String?,
      weightStage: json['weightStage'] as String?,
      olympiaTitles: json['olympiaTitles'] as String?,
      featuredImageUrl: json['featuredImageUrl'] as String?,
    );
  }
}
