import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  int get unreadCount => _unreadCount;
  bool get isInitialized => _chatService != null && _supabaseService != null;

  void initialize(SupabaseService supabaseService) {
    // جلوگیری از مقداردهی مجدد
    if (_isInitialized) {
      debugPrint('=== CHAT UNREAD NOTIFIER: Already initialized, skipping ===');
      return;
    }

    debugPrint('=== CHAT UNREAD NOTIFIER: Initializing ===');
    _supabaseService = supabaseService;
    _chatService = ChatService();
    _isInitialized = true;
    _loadUnreadCount();

    // شروع تایمر برای به‌روزرسانی خودکار هر 30 ثانیه
    _startRefreshTimer();
  }

  Future<void> _loadUnreadCount() async {
    try {
      // جلوگیری از اجرای همزمان
      if (_isLoading) return;

      // جلوگیری از فراخوانی مکرر در مدت زمان کوتاه
      final now = DateTime.now();
      if (_lastLoadTime != null &&
          now.difference(_lastLoadTime!).inSeconds < 5) {
        debugPrint(
          '=== CHAT UNREAD NOTIFIER: Skipping load - too frequent ===',
        );
        return;
      }

      // اگر آفلاین هستیم، از فراخوانی شبکه صرف‌نظر کنیم
      final isOnline = await ConnectivityService.instance.checkNow();
      if (!isOnline) {
        debugPrint('=== CHAT UNREAD NOTIFIER: Offline, skipping fetch ===');
        _unreadCount = 0;
        notifyListeners();
        return;
      }

      _isLoading = true;
      _lastLoadTime = now;

      GlobalKeyDebugger.logChatUnreadNotifierCall('_loadUnreadCount');
      debugPrint('=== CHAT UNREAD NOTIFIER: Loading unread count ===');
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null || _chatService == null) {
        debugPrint('=== CHAT UNREAD NOTIFIER: User or chatService is null ===');
        _unreadCount = 0;
        _isLoading = false;
        notifyListeners();
        return;
      }

      debugPrint(
        '=== CHAT UNREAD NOTIFIER: Getting conversations for user: ${user.id} ===',
      );
      final conversations = await _chatService!.getConversations();
      debugPrint(
        '=== CHAT UNREAD NOTIFIER: Found ${conversations.length} conversations ===',
      );

      _unreadCount = conversations
          .where((conv) => conv.hasUnreadForUser(user.id))
          .length;

      debugPrint('=== CHAT UNREAD NOTIFIER: Unread count: $_unreadCount ===');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint(
        '=== CHAT UNREAD NOTIFIER: Error loading unread count: $e ===',
      );
      _unreadCount = 0;
      _isLoading = false;
      notifyListeners();
    }
  }

  // متد برای به‌روزرسانی تعداد پیام‌های نخوانده
  Future<void> refreshUnreadCount() async {
    if (!isInitialized) {
      debugPrint('ChatUnreadNotifier not initialized, skipping refresh');
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
      notifyListeners();
    }
  }

  // متد برای افزایش تعداد (وقتی پیام جدید دریافت می‌شود)
  void incrementUnreadCount() {
    _unreadCount++;
    notifyListeners();
  }

  // شروع تایمر برای به‌روزرسانی خودکار
  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isInitialized && !_isLoading) {
        debugPrint('=== CHAT UNREAD NOTIFIER: Auto-refresh triggered ===');
        _loadUnreadCount();
      }
    });
  }

  // متوقف کردن تایمر
  void _stopRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  void dispose() {
    _stopRefreshTimer();
    super.dispose();
  }
}
