enum AnnouncementMediaType { image, video }

enum AnnouncementCtaType { none, deepLink, externalUrl }

enum AnnouncementDismissMode { always, daily, once }

class InAppAnnouncement {
  InAppAnnouncement({
    required this.id,
    required this.title,
    required this.description,
    required this.mediaType,
    required this.ctaType,
    required this.dismissMode,
    required this.priority,
    required this.isActive,
    required this.createdAt,
    this.mediaUrl,
    this.ctaText,
    this.ctaValue,
    this.startAt,
    this.endAt,
    this.updatedAt,
  });

  factory InAppAnnouncement.fromMap(Map<String, dynamic> map) {
    return InAppAnnouncement(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      mediaType: _parseMediaType(map['media_type']?.toString()),
      mediaUrl: map['media_url']?.toString(),
      ctaType: _parseCtaType(map['cta_type']?.toString()),
      ctaText: map['cta_text']?.toString(),
      ctaValue: map['cta_value']?.toString(),
      dismissMode: _parseDismissMode(map['dismiss_mode']?.toString()),
      priority: (map['priority'] as num?)?.toInt() ?? 0,
      isActive: map['is_active'] == true,
      startAt: _parseDateTime(map['start_at']),
      endAt: _parseDateTime(map['end_at']),
      createdAt: _parseDateTime(map['created_at']) ?? DateTime.now(),
      updatedAt: _parseDateTime(map['updated_at']),
    );
  }

  final String id;
  final String title;
  final String description;
  final AnnouncementMediaType mediaType;
  final String? mediaUrl;
  final AnnouncementCtaType ctaType;
  final String? ctaText;
  final String? ctaValue;
  final AnnouncementDismissMode dismissMode;
  final int priority;
  final bool isActive;
  final DateTime? startAt;
  final DateTime? endAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  bool get hasCta => ctaType != AnnouncementCtaType.none;

  Map<String, dynamic> toInsertMap() {
    return {
      'title': title,
      'description': description,
      'media_type': mediaType.name,
      'media_url': _emptyToNull(mediaUrl),
      'cta_type': _ctaTypeToDb(ctaType),
      'cta_text': _emptyToNull(ctaText),
      'cta_value': _emptyToNull(ctaValue),
      'dismiss_mode': _dismissModeToDb(dismissMode),
      'priority': priority,
      'is_active': isActive,
      'start_at': startAt?.toIso8601String(),
      'end_at': endAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toUpdateMap() => toInsertMap();

  static DateTime? _parseDateTime(dynamic value) {
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  static AnnouncementMediaType _parseMediaType(String? raw) {
    if (raw == 'video') return AnnouncementMediaType.video;
    return AnnouncementMediaType.image;
  }

  static AnnouncementCtaType _parseCtaType(String? raw) {
    switch (raw) {
      case 'deep_link':
        return AnnouncementCtaType.deepLink;
      case 'external_url':
        return AnnouncementCtaType.externalUrl;
      default:
        return AnnouncementCtaType.none;
    }
  }

  static AnnouncementDismissMode _parseDismissMode(String? raw) {
    switch (raw) {
      case 'daily':
        return AnnouncementDismissMode.daily;
      case 'once':
        return AnnouncementDismissMode.once;
      default:
        return AnnouncementDismissMode.always;
    }
  }

  static String _ctaTypeToDb(AnnouncementCtaType type) {
    switch (type) {
      case AnnouncementCtaType.deepLink:
        return 'deep_link';
      case AnnouncementCtaType.externalUrl:
        return 'external_url';
      case AnnouncementCtaType.none:
        return 'none';
    }
  }

  static String _dismissModeToDb(AnnouncementDismissMode mode) {
    switch (mode) {
      case AnnouncementDismissMode.always:
        return 'always';
      case AnnouncementDismissMode.daily:
        return 'daily';
      case AnnouncementDismissMode.once:
        return 'once';
    }
  }

  static String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
