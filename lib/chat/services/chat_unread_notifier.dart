import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gymaipro/chat/models/user_chat_message.dart';
import 'package:gymaipro/chat/services/chat_service.dart';
import 'package:gymaipro/debug/global_key_debugger.dart';
import 'package:gymaipro/services/connectivity_service.dart';
import 'package:gymaipro/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatUnreadNotifier extends ChangeNotifier {
  int _unreadCount = 0;
  ChatService? _chatService;
  SupabaseService? _supabaseService;
  bool _isLoading = false;
  bool _isInitialized = false;
  DateTime? _lastLoadTime;
  Timer? _refreshTimer;
  bool _disposed = false;

  void _log(String msg) {
    if (kDebugMode) debugPrint(msg);
  }

  int get unreadCount => _unreadCount;
  bool get isInitialized => _chatService != null && _supabaseService != null;

  void initialize(SupabaseService supabaseService) {
    // جلوگیری از مقداردهی مجدد
    if (_isInitialized) {
      _log('=== CHAT UNREAD NOTIFIER: Already initialized, skipping ===');
      return;
    }

    _log('=== CHAT UNREAD NOTIFIER: Initializing ===');
    _supabaseService = supabaseService;
    _chatService = ChatService();
    _isInitialized = true;
    
    // تاخیر کوچک برای اطمینان از آماده بودن Supabase
    // این کمک می‌کند تا از خطاهای Connection closed جلوگیری شود
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!_disposed && _isInitialized) {
        _loadUnreadCount();
      }
    });

    // شروع تایمر برای به‌روزرسانی خودکار (کم‌مصرف‌تر)
    _startRefreshTimer();
  }

  Future<void> _loadUnreadCount() async {
    try {
      // اگر notifier dispose شده، از ادامه کار جلوگیری کن
      if (_disposed) return;
      
      // جلوگیری از اجرای همزمان
      if (_isLoading) return;

      // جلوگیری از فراخوانی مکرر در مدت زمان کوتاه
      final now = DateTime.now();
      if (_lastLoadTime != null &&
          now.difference(_lastLoadTime!).inSeconds < 5) {
        _log(
          '=== CHAT UNREAD NOTIFIER: Skipping load - too frequent ===',
        );
        return;
      }

      // اگر آفلاین هستیم، از فراخوانی شبکه صرف‌نظر کنیم
      final isOnline = await ConnectivityService.instance.checkNow();
      if (!isOnline) {
        _log('=== CHAT UNREAD NOTIFIER: Offline, skipping fetch ===');
        _unreadCount = 0;
        _safeNotifyListeners();
        return;
      }

      _isLoading = true;
      _lastLoadTime = now;

      GlobalKeyDebugger.logChatUnreadNotifierCall('_loadUnreadCount');
      _log('=== CHAT UNREAD NOTIFIER: Loading unread count ===');
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null || _chatService == null) {
        _log('=== CHAT UNREAD NOTIFIER: User or chatService is null ===');
        _unreadCount = 0;
        _isLoading = false;
        _safeNotifyListeners();
        return;
      }

      _log(
        '=== CHAT UNREAD NOTIFIER: Getting conversations for user: ${user.id} ===',
      );
      // اضافه کردن timeout برای جلوگیری از انتظار بی‌نهایت
      final conversations = await _chatService!
          .getConversations()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              _log(
                '=== CHAT UNREAD NOTIFIER: Timeout loading conversations ===',
              );
              return <ChatConversation>[];
            },
          );
      _log(
        '=== CHAT UNREAD NOTIFIER: Found ${conversations.length} conversations ===',
      );

      _unreadCount = conversations
          .where((conv) => conv.hasUnreadForUser(user.id))
          .length;

      _log('=== CHAT UNREAD NOTIFIER: Unread count: $_unreadCount ===');
      _isLoading = false;
      _safeNotifyListeners();
    } catch (e) {
      _log(
        '=== CHAT UNREAD NOTIFIER: Error loading unread count: $e ===',
      );
      _unreadCount = 0;
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  // متد برای به‌روزرسانی تعداد پیام‌های نخوانده
  Future<void> refreshUnreadCount() async {
    if (!isInitialized) {
      _log('ChatUnreadNotifier not initialized, skipping refresh');
      return;
    }
    await _loadUnreadCount();
  }

  // متد برای lazy initialization
  Future<void> ensureInitialized(SupabaseService supabaseService) async {
    if (!isInitialized) {
      initialize(supabaseService);
    }
  }

  // متد برای کاهش تعداد (وقتی پیام‌ها خوانده می‌شوند)
  void markAsRead() {
    if (_unreadCount > 0) {
      _unreadCount--;
      _safeNotifyListeners();
    }
  }

  // متد برای افزایش تعداد (وقتی پیام جدید دریافت می‌شود)
  void incrementUnreadCount() {
    _unreadCount++;
    _safeNotifyListeners();
  }

  // متد امن برای notify کردن listeners
  void _safeNotifyListeners() {
    if (_disposed) return;
    try {
      notifyListeners();
    } catch (e) {
      debugPrint(
        '=== CHAT UNREAD NOTIFIER: Error notifying listeners: $e ===',
      );
    }
  }

  // شروع تایمر برای به‌روزرسانی خودکار
  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    // 60s is noticeably lighter on CPU/network while still feeling "live" for unread badges.
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (_disposed) {
        timer.cancel();
        return;
      }
      if (!_isInitialized || _isLoading) return;
      // اگر کاربر لاگین نیست، هیچ نیازی به poll نیست.
      if (Supabase.instance.client.auth.currentUser == null) return;
      _log('=== CHAT UNREAD NOTIFIER: Auto-refresh triggered ===');
      _loadUnreadCount();
    });
  }

  // متوقف کردن تایمر
  void _stopRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _stopRefreshTimer();
    super.dispose();
  }
}
