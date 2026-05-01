import 'package:gymaipro/announcements/models/in_app_announcement.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InAppAnnouncementService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const _tableName = 'in_app_announcements';
  static const _eventTableName = 'in_app_announcement_events';

  Future<List<InAppAnnouncement>> getAllAnnouncements() async {
    final response = await _supabase
        .from(_tableName)
        .select('*')
        .order('priority', ascending: false)
        .order('created_at', ascending: false);
    return (response as List<dynamic>)
        .map((item) => InAppAnnouncement.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<InAppAnnouncement?> getTopActiveAnnouncement() async {
    final nowIso = DateTime.now().toIso8601String();
    final response = await _supabase
        .from(_tableName)
        .select('*')
        .eq('is_active', true)
        .or('start_at.is.null,start_at.lte.$nowIso')
        .or('end_at.is.null,end_at.gte.$nowIso')
        .order('priority', ascending: false)
        .order('created_at', ascending: false)
        .limit(10);

    final announcements = (response as List<dynamic>)
        .map((item) => InAppAnnouncement.fromMap(item as Map<String, dynamic>))
        .toList();
    if (announcements.isEmpty) return null;
    return announcements.firstWhere(
      (item) => item.title.trim().isNotEmpty,
      orElse: () => announcements.first,
    );
  }

  Future<void> createAnnouncement(InAppAnnouncement announcement) async {
    await _supabase.from(_tableName).insert(announcement.toInsertMap());
  }

  Future<void> updateAnnouncement(InAppAnnouncement announcement) async {
    await _supabase
        .from(_tableName)
        .update(announcement.toUpdateMap())
        .eq('id', announcement.id);
  }

  Future<void> toggleActive(String id, {required bool isActive}) async {
    await _supabase
        .from(_tableName)
        .update({
          'is_active': isActive,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  Future<void> deleteAnnouncement(String id) async {
    await _supabase.from(_tableName).delete().eq('id', id);
  }

  Future<bool> shouldShowAnnouncement(InAppAnnouncement announcement) async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = 'announcement_${announcement.id}';
    final shownAtIso = prefs.getString('${prefix}_shown_at');
    final dismissedAtIso = prefs.getString('${prefix}_dismissed_at');

    switch (announcement.dismissMode) {
      case AnnouncementDismissMode.always:
        return true;
      case AnnouncementDismissMode.daily:
        if (shownAtIso == null) return true;
        final shownAt = DateTime.tryParse(shownAtIso);
        if (shownAt == null) return true;
        final now = DateTime.now();
        return !(shownAt.year == now.year &&
            shownAt.month == now.month &&
            shownAt.day == now.day);
      case AnnouncementDismissMode.once:
        return shownAtIso == null && dismissedAtIso == null;
    }
  }

  Future<void> markAnnouncementShown(String announcementId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'announcement_${announcementId}_shown_at',
      DateTime.now().toIso8601String(),
    );
    await _safeInsertEvent(announcementId, 'shown');
  }

  Future<void> markAnnouncementDismissed(String announcementId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'announcement_${announcementId}_dismissed_at',
      DateTime.now().toIso8601String(),
    );
    await _safeInsertEvent(announcementId, 'dismissed');
  }

  Future<void> markAnnouncementClicked(String announcementId) async {
    await _safeInsertEvent(announcementId, 'clicked');
  }

  Future<void> _safeInsertEvent(String announcementId, String eventType) async {
    try {
      await _supabase.from(_eventTableName).insert({
        'announcement_id': announcementId,
        'user_id': _supabase.auth.currentUser?.id,
        'event_type': eventType,
      });
    } catch (_) {
      // بی‌صدا: خطای ثبت ایونت نباید UX کاربر را خراب کند.
    }
  }
}
