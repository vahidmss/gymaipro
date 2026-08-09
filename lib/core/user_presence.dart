/// منطق واحد «آنلاین بودن» در کل اپ.
///
/// منبع حقیقت: تازگی `last_seen_at` یا `last_active_at` (نه پرچم چسبندهٔ `is_online`).
class UserPresence {
  UserPresence._();

  /// اگر آخرین حضور در این بازه باشد → آنلاین.
  static const Duration onlineWindow = Duration(minutes: 5);

  static DateTime? _parse(Object? raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw.toLocal();
    final s = raw.toString().trim();
    if (s.isEmpty || s.toLowerCase() == 'null') return null;
    return DateTime.tryParse(s)?.toLocal();
  }

  /// جدیدترین زمان حضور شناخته‌شده.
  static DateTime? effectiveLastSeen({
    DateTime? lastSeenAt,
    DateTime? lastActiveAt,
    Object? lastSeenRaw,
    Object? lastActiveRaw,
  }) {
    final seen = lastSeenAt ?? _parse(lastSeenRaw);
    final active = lastActiveAt ?? _parse(lastActiveRaw);
    if (seen == null) return active;
    if (active == null) return seen;
    return seen.isAfter(active) ? seen : active;
  }

  /// آیا کاربر الان آنلاین محسوب می‌شود؟
  static bool isOnline({
    DateTime? lastSeenAt,
    DateTime? lastActiveAt,
    Object? lastSeenRaw,
    Object? lastActiveRaw,
    DateTime? now,
  }) {
    final t = effectiveLastSeen(
      lastSeenAt: lastSeenAt,
      lastActiveAt: lastActiveAt,
      lastSeenRaw: lastSeenRaw,
      lastActiveRaw: lastActiveRaw,
    );
    if (t == null) return false;
    final n = now ?? DateTime.now();
    return !n.difference(t).isNegative && n.difference(t) <= onlineWindow;
  }

  /// از نقشهٔ پروفایل/JSON.
  static bool isOnlineFromMap(Map<String, dynamic>? json, {DateTime? now}) {
    if (json == null) return false;
    return isOnline(
      lastSeenRaw: json['last_seen_at'],
      lastActiveRaw: json['last_active_at'],
      now: now,
    );
  }
}
