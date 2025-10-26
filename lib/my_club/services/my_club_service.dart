import 'package:gymaipro/utils/auth_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyClubService {
  factory MyClubService() => _instance;
  MyClubService._internal();
  static final MyClubService _instance = MyClubService._internal();

  final SupabaseClient _db = Supabase.instance.client;

  // دریافت آمار کلی باشگاه من
  Future<Map<String, int>> getClubStats() async {
    try {
      final userId = await AuthHelper.getCurrentUserId();
      if (userId == null) throw Exception('کاربر احراز هویت نشده');

      // آمار مربی‌ها
      final trainerStats = await _db
          .from('trainer_clients')
          .select('status')
          .eq('client_id', userId);

      // آمار دوستان (user_friends بدون وضعیت)
      final friendStats = await _db
          .from('user_friends')
          .select('id')
          .or('user_id.eq.$userId,friend_id.eq.$userId');

      // آمار برنامه‌ها
      final programStats = await _db
          .from('workout_programs')
          .select('id')
          .eq('user_id', userId)
          .eq('is_deleted', false);

      // آمار درخواست‌ها
      final pendingTrainerRequests = await _db
          .from('trainer_clients')
          .select('id')
          .eq('client_id', userId)
          .eq('status', 'pending');

      // درخواست‌های دوستی در جدول friendship_requests نگه‌داری می‌شوند
      final pendingFriendRequests = await _db
          .from('friendship_requests')
          .select('id')
          .eq('requested_id', userId)
          .eq('status', 'pending');

      return {
        'active_trainers': trainerStats
            .where((t) => t['status'] == 'active')
            .length,
        'pending_trainer_requests': pendingTrainerRequests.length,
        // هر ردیف در user_friends نشان‌دهنده یک دوستی پذیرفته‌شده است
        'friends': friendStats.length,
        'pending_friend_requests': pendingFriendRequests.length,
        'programs': programStats.length,
        'total_requests':
            pendingTrainerRequests.length + pendingFriendRequests.length,
      };
    } catch (e) {
      throw Exception('خطا در دریافت آمار باشگاه: $e');
    }
  }

  // دریافت آخرین فعالیت‌ها
  Future<List<Map<String, dynamic>>> getRecentActivities() async {
    try {
      final userId = await AuthHelper.getCurrentUserId();
      if (userId == null) throw Exception('کاربر احراز هویت نشده');

      final activities = <Map<String, dynamic>>[];

      // آخرین برنامه‌های ورزشی
      final recentPrograms = await _db
          .from('workout_programs')
          .select('id, program_name, created_at, trainer_id')
          .eq('user_id', userId)
          .eq('is_deleted', false)
          .order('created_at', ascending: false)
          .limit(3);

      for (final program in recentPrograms) {
        activities.add({
          'type': 'program',
          'title': 'برنامه جدید: ${program['program_name']}',
          'subtitle': 'برنامه ورزشی',
          'created_at': program['created_at'],
          'icon': 'dumbbell',
        });
      }

      // آخرین روابط مربی
      final recentTrainers = await _db
          .from('trainer_clients')
          .select('''
            *, 
            trainer:profiles!trainer_clients_trainer_id_fkey(
              first_name, last_name, username
            )
          ''')
          .eq('client_id', userId)
          .order('created_at', ascending: false)
          .limit(3);

      for (final trainer in recentTrainers) {
        final trainerData = trainer['trainer'] as Map<String, dynamic>?;
        final trainerName = _getTrainerName(trainerData);
        activities.add({
          'type': 'trainer',
          'title': 'رابطه جدید با مربی: $trainerName',
          'subtitle': 'مربی',
          'created_at': trainer['created_at'],
          'icon': 'user-check',
        });
      }

      // آخرین دوستان (user_friends بدون وضعیت)
      final recentFriends = await _db
          .from('user_friends')
          .select('''
            *, 
            friend:profiles!user_friends_friend_id_fkey(
              first_name, last_name, username
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(3);

      for (final friend in recentFriends) {
        final friendData = friend['friend'] as Map<String, dynamic>?;
        final friendName = _getFriendName(friendData);
        activities.add({
          'type': 'friend',
          'title': 'دوست جدید: $friendName',
          'subtitle': 'دوست',
          'created_at': friend['created_at'],
          'icon': 'user-plus',
        });
      }

      // مرتب‌سازی بر اساس تاریخ
      activities.sort((a, b) {
        final dateA = DateTime.tryParse(a['created_at']?.toString() ?? '');
        final dateB = DateTime.tryParse(b['created_at']?.toString() ?? '');
        if (dateA == null || dateB == null) return 0;
        return dateB.compareTo(dateA);
      });

      return activities.take(10).toList();
    } catch (e) {
      throw Exception('خطا در دریافت فعالیت‌های اخیر: $e');
    }
  }

  // دریافت پیشنهادات
  Future<List<Map<String, dynamic>>> getSuggestions() async {
    try {
      final userId = await AuthHelper.getCurrentUserId();
      if (userId == null) throw Exception('کاربر احراز هویت نشده');

      final suggestions = <Map<String, dynamic>>[];

      // بررسی تعداد مربی‌ها
      final trainerCount = await _db
          .from('trainer_clients')
          .select('id')
          .eq('client_id', userId)
          .eq('status', 'active');

      if (trainerCount.isEmpty) {
        suggestions.add({
          'type': 'trainer',
          'title': 'مربی پیدا کنید',
          'subtitle': 'برای شروع، یک مربی انتخاب کنید',
          'action': 'search_trainers',
          'icon': 'user-check',
        });
      }

      // بررسی تعداد دوستان (user_friends بدون وضعیت)
      final friendCount = await _db
          .from('user_friends')
          .select('id')
          .or('user_id.eq.$userId,friend_id.eq.$userId');

      if (friendCount.isEmpty) {
        suggestions.add({
          'type': 'friend',
          'title': 'دوستان جدید پیدا کنید',
          'subtitle': 'با دوستان خود تمرین کنید',
          'action': 'search_friends',
          'icon': 'user-plus',
        });
      }

      // بررسی برنامه‌ها
      final programCount = await _db
          .from('workout_programs')
          .select('id')
          .eq('user_id', userId)
          .eq('is_deleted', false);

      if (programCount.isEmpty) {
        suggestions.add({
          'type': 'program',
          'title': 'برنامه تمرینی بسازید',
          'subtitle': 'برنامه شخصی خود را ایجاد کنید',
          'action': 'create_program',
          'icon': 'clipboard-list',
        });
      }

      return suggestions;
    } catch (e) {
      throw Exception('خطا در دریافت پیشنهادات: $e');
    }
  }

  // دریافت نوتیفیکیشن‌های باشگاه
  Future<List<Map<String, dynamic>>> getClubNotifications() async {
    try {
      final userId = await AuthHelper.getCurrentUserId();
      if (userId == null) throw Exception('کاربر احراز هویت نشده');

      final notifications = <Map<String, dynamic>>[];

      // درخواست‌های مربی
      final trainerRequests = await _db
          .from('trainer_clients')
          .select('''
            *, 
            trainer:profiles!trainer_clients_trainer_id_fkey(
              first_name, last_name, username, avatar_url
            )
          ''')
          .eq('client_id', userId)
          .eq('status', 'pending');

      for (final request in trainerRequests) {
        final trainerData = request['trainer'] as Map<String, dynamic>?;
        notifications.add({
          'type': 'trainer_request',
          'title': 'درخواست مربیگری جدید',
          'subtitle': '${_getTrainerName(trainerData)} می‌خواهد مربی شما باشد',
          'created_at': request['created_at'],
          'data': request,
        });
      }

      // درخواست‌های دوستی از جدول friendship_requests
      final friendRequests = await _db
          .from('friendship_requests')
          .select('''
            *, 
            requester:profiles!friendship_requests_requester_id_fkey(
              first_name, last_name, username, avatar_url
            )
          ''')
          .eq('requested_id', userId)
          .eq('status', 'pending');

      for (final request in friendRequests) {
        final requesterData = request['requester'] as Map<String, dynamic>?;
        notifications.add({
          'type': 'friend_request',
          'title': 'درخواست دوستی جدید',
          'subtitle': '${_getFriendName(requesterData)} می‌خواهد دوست شما باشد',
          'created_at': request['created_at'],
          'data': request,
        });
      }

      // مرتب‌سازی بر اساس تاریخ
      notifications.sort((a, b) {
        final dateA = DateTime.tryParse(a['created_at']?.toString() ?? '');
        final dateB = DateTime.tryParse(b['created_at']?.toString() ?? '');
        if (dateA == null || dateB == null) return 0;
        return dateB.compareTo(dateA);
      });

      return notifications;
    } catch (e) {
      throw Exception('خطا در دریافت نوتیفیکیشن‌ها: $e');
    }
  }

  // Helper methods
  String _getTrainerName(Map<String, dynamic>? trainerData) {
    if (trainerData == null) return 'مربی ناشناس';

    final firstName = (trainerData['first_name'] as String?) ?? '';
    final lastName = (trainerData['last_name'] as String?) ?? '';
    final username = (trainerData['username'] as String?) ?? '';

    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    } else if (firstName.isNotEmpty) {
      return firstName;
    } else if (lastName.isNotEmpty) {
      return lastName;
    } else if (username.isNotEmpty) {
      return username;
    }
    return 'مربی ناشناس';
  }

  String _getFriendName(Map<String, dynamic>? friendData) {
    if (friendData == null) return 'کاربر ناشناس';

    final firstName = (friendData['first_name'] as String?) ?? '';
    final lastName = (friendData['last_name'] as String?) ?? '';
    final username = (friendData['username'] as String?) ?? '';

    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    } else if (firstName.isNotEmpty) {
      return firstName;
    } else if (lastName.isNotEmpty) {
      return lastName;
    } else if (username.isNotEmpty) {
      return username;
    }
    return 'کاربر ناشناس';
  }
}
