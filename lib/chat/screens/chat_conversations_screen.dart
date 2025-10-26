import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/chat/screens/chat_screen.dart';
import 'package:gymaipro/chat/models/user_chat_message.dart';
import 'package:gymaipro/chat/services/chat_service.dart';
import 'package:gymaipro/services/connectivity_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:gymaipro/chat/widgets/user_avatar_widget.dart';
import 'package:gymaipro/widgets/user_role_badge.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatConversationsScreen extends StatefulWidget {
  const ChatConversationsScreen({super.key});

  @override
  State<ChatConversationsScreen> createState() =>
      _ChatConversationsScreenState();
}

class _ChatConversationsScreenState extends State<ChatConversationsScreen> {
  late ChatService _chatService;
  List<ChatConversation> _conversations = [];
  List<ChatConversation> _filteredConversations = [];
  bool _isLoading = true;
  final String _searchQuery = '';
  StreamSubscription<dynamic>? _conversationsSubscription;
  final Map<String, String?> _avatarCache = {};
  bool _avatarSetStatePending = false;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService();
    _loadConversations();
    _subscribeToConversations();
  }

  @override
  void dispose() {
    _conversationsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    try {
      SafeSetState.call(this, () => _isLoading = true);
      // اگر آفلاین هستیم، درخواست شبکه نزنیم و پیام مناسب نشان دهیم
      if (!ConnectivityService.instance.isConnected) {
        SafeSetState.call(this, () {
          _conversations = [];
          _filteredConversations = [];
          _isLoading = false;
        });
        return;
      }
      debugPrint('=== CHAT CONVERSATIONS: Loading conversations... ===');
      // جلوگیری از لودینگ بی‌نهایت در صورت مشکل شبکه/دسترسی
      final conversations = await _chatService.getConversations().timeout(
        const Duration(seconds: 15),
      );
      SafeSetState.call(this, () {
        _conversations = conversations;
        _filterConversations();
        _isLoading = false;
      });
      // Warm up avatar cache and refresh in background (no UI blocking)
      unawaited(_warmUpAvatarCache(conversations));
      debugPrint(
        '=== CHAT CONVERSATIONS: Loaded ${conversations.length} conversations ===',
      );
    } catch (e) {
      SafeSetState.call(this, () => _isLoading = false);
      // هنگام آفلاین بودن یا خطاهای شبکه، پیام کاربرپسند نشان بده
      if (mounted) {
        final isOffline = !ConnectivityService.instance.isConnected;
        final msg = isOffline
            ? 'اتصال اینترنت برقرار نیست. لطفاً اینترنت را بررسی کنید.'
            : 'خطا در بارگذاری گفتگوها. لطفاً دوباره تلاش کنید.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  Future<void> _warmUpAvatarCache(List<ChatConversation> conversations) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Load cached URLs from local storage for first 30 items
      final int limit = conversations.length < 30 ? conversations.length : 30;
      for (int i = 0; i < limit; i++) {
        final conv = conversations[i];
        final currentUserId = Supabase.instance.client.auth.currentUser?.id;
        if (currentUserId == null) continue;
        final otherUserId = conv.getOtherUserId(currentUserId);
        final cached = prefs.getString('avatar_url_$otherUserId');
        if (cached != null && !_avatarCache.containsKey(otherUserId)) {
          _avatarCache[otherUserId] = cached;
        }
      }
      if (mounted) setState(() {});

      // Refresh latest avatar URLs from server in background
      for (int i = 0; i < limit; i++) {
        final conv = conversations[i];
        final currentUserId = Supabase.instance.client.auth.currentUser?.id;
        if (currentUserId == null) continue;
        final otherUserId = conv.getOtherUserId(currentUserId);
        unawaited(_refreshAvatar(otherUserId));
      }
    } catch (e) {
      debugPrint('Error warming up avatar cache: $e');
    }
  }

  Future<void> _refreshAvatar(String userId) async {
    try {
      final latest = await _loadUserAvatar(userId);
      if (_avatarCache[userId] != latest) {
        _avatarCache[userId] = latest;
        final prefs = await SharedPreferences.getInstance();
        if (latest != null) {
          await prefs.setString('avatar_url_$userId', latest);
        }
        _scheduleAvatarSetState();
      }
    } catch (e) {
      debugPrint('Error refreshing avatar: $e');
    }
  }

  void _scheduleAvatarSetState() {
    if (_avatarSetStatePending || !mounted) return;
    _avatarSetStatePending = true;
    Future.delayed(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      _avatarSetStatePending = false;
      setState(() {});
    });
  }

  void _subscribeToConversations() {
    try {
      final stream = _chatService.subscribeToConversations();
      _conversationsSubscription = stream.listen(_updateConversation);
    } catch (e) {
      debugPrint('Error subscribing to conversations: $e');
    }
  }

  void _updateConversation(ChatConversation newConversation) {
    SafeSetState.call(this, () {
      // حذف مکالمات تکراری بر اساس ترکیب user1_id و user2_id
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null) return;

      // ایجاد کلید منحصر به فرد
      final newKey =
          newConversation.user1Id.compareTo(newConversation.user2Id) < 0
          ? '${newConversation.user1Id}_${newConversation.user2Id}'
          : '${newConversation.user2Id}_${newConversation.user1Id}';

      // حذف مکالمات قدیمی با همان کلید
      _conversations.removeWhere((conv) {
        final convKey = conv.user1Id.compareTo(conv.user2Id) < 0
            ? '${conv.user1Id}_${conv.user2Id}'
            : '${conv.user2Id}_${conv.user1Id}';
        return convKey == newKey;
      });

      // فقط در صورت تغییر آخرین پیام، لیست را به‌روزرسانی کن تا پرش کم شود
      final existingIndex = _conversations.indexWhere(
        (c) => c.id == newConversation.id,
      );
      final bool shouldUpdate =
          existingIndex == -1 ||
          _conversations[existingIndex].lastMessageDateTime !=
              newConversation.lastMessageDateTime;
      if (shouldUpdate) {
        _conversations.add(newConversation);
        _conversations.sort(
          (a, b) => b.lastMessageDateTime.compareTo(a.lastMessageDateTime),
        );
        _filterConversations();
      }

      // از به‌روزرسانی notifier داخل این صفحه صرف‌نظر می‌کنیم تا رندرهای اضافی ایجاد نشود
    });
  }

  void _filterConversations() {
    List<ChatConversation> filtered = _conversations;

    // فیلترها حذف شده‌اند

    // اعمال جستجو
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (c) =>
                c.otherUserName.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                (c.lastMessageText?.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ??
                    false),
          )
          .toList();
    }

    _filteredConversations = filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.goldColor),
                )
              : _filteredConversations.isEmpty
              ? _buildEmptyState()
              : _buildConversationsList(),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    String message;
    String subtitle;
    IconData icon;

    if (!ConnectivityService.instance.isConnected) {
      message = 'آفلاین هستید';
      subtitle = 'برای مشاهده گفتگوها، اتصال اینترنت را برقرار کنید';
      icon = LucideIcons.wifiOff;
    } else if (_searchQuery.isNotEmpty) {
      message = 'نتیجه‌ای یافت نشد';
      subtitle = 'جستجو یا فیلتر خود را تغییر دهید';
      icon = LucideIcons.search;
    } else {
      message = 'هنوز گفتگویی شروع نشده است';
      subtitle = 'برای شروع گفتگو با مربیان یا سایر کاربران چت کنید';
      icon = LucideIcons.messageCircle;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Icon(
              icon,
              size: 64.sp,
              color: AppTheme.goldColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: AppTheme.headingStyle.copyWith(fontSize: 18.sp),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTheme.bodyStyle.copyWith(fontSize: 14.sp),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConversationsList() {
    return RefreshIndicator(
      onRefresh: _loadConversations,
      color: AppTheme.goldColor,
      child: ListView.builder(
        key: const PageStorageKey('chat_conversations_list'),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8),
        itemExtent: 104,
        cacheExtent: 600,
        itemCount: _filteredConversations.length,
        itemBuilder: (context, index) {
          final conversation = _filteredConversations[index];
          return _buildConversationTile(conversation);
        },
      ),
    );
  }

  Widget _buildConversationTile(ChatConversation conversation) {
    final timeString = _formatLastMessageTime(conversation.lastMessageDateTime);

    // دریافت ID کاربر فعلی
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return const SizedBox.shrink();

    // تشخیص کاربر دیگر
    final otherUserId = conversation.getOtherUserId(currentUserId);
    final otherUserName = conversation.getOtherUserName(currentUserId);
    final unreadCount = conversation.getUnreadCount(currentUserId);
    final hasUnread = conversation.hasUnreadForUser(currentUserId);

    return Column(
      key: ValueKey(conversation.id),
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: hasUnread
                  ? AppTheme.goldColor.withValues(alpha: 0.3)
                  : AppTheme.backgroundColor,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.backgroundColor.withValues(alpha: 0.06),
                blurRadius: 8.r,
                offset: Offset(0.w, 2.h),
              ),
            ],
          ),
          child: Material(
            color: AppTheme.backgroundColor,
            child: InkWell(
              onTap: () => _navigateToChatScreen(conversation, otherUserId),
              onLongPress: () => _showConversationActions(conversation),
              borderRadius: BorderRadius.circular(16.r),
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  children: [
                    // آواتار
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        UserAvatarWidget(
                          avatarUrl: _avatarCache[otherUserId],
                          showOnlineStatus: false,
                        ),
                        if (hasUnread)
                          Positioned(
                            top: -2,
                            left: -2,
                            child: Container(
                              width: 16.w,
                              height: 16.h,
                              decoration: BoxDecoration(
                                color: AppTheme.goldColor,
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                  color: AppTheme.cardColor,
                                  width: 2.w,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),

                    // محتوا به سبک تلگرام: ردیف بالا نام + تاریخ، ردیف پایین نقش + آخرین پیام، نشان نخوانده کنار پیام
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  otherUserName,
                                  style: TextStyle(
                                    color: hasUnread
                                        ? AppTheme.textColor
                                        : AppTheme.textColor.withValues(
                                            alpha: 0.9,
                                          ),
                                    fontSize: 16.sp,
                                    fontWeight: hasUnread
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                timeString,
                                style: TextStyle(
                                  color: AppTheme.bodyStyle.color,
                                  fontSize: 11.sp,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              FutureBuilder<String?>(
                                future: _loadUserRole(otherUserId),
                                builder: (context, snapshot) {
                                  final role = snapshot.data ?? 'athlete';
                                  return Padding(
                                    padding: const EdgeInsetsDirectional.only(
                                      end: 8,
                                    ),
                                    child: UserRoleBadge(
                                      role: role,
                                      fontSize: 10.sp,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 6.w,
                                        vertical: 2.h,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              Expanded(
                                child: Text(
                                  conversation.lastMessageText ?? 'بدون پیام',
                                  style: TextStyle(
                                    color: hasUnread
                                        ? AppTheme.textColor.withValues(
                                            alpha: 0.95,
                                          )
                                        : AppTheme.textColor.withValues(
                                            alpha: 0.65,
                                          ),
                                    fontSize: 13.sp,
                                    fontWeight: hasUnread
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (hasUnread)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 3.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.goldColor,
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Text(
                                    '$unreadCount',
                                    style: TextStyle(
                                      color: AppTheme.textColor,
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  void _showConversationActions(ChatConversation conversation) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(LucideIcons.pin, color: AppTheme.bodyStyle.color),
              title: const Text(
                'پین کردن گفتگو',
                style: TextStyle(color: AppTheme.textColor),
              ),
              onTap: () {
                Navigator.pop(context);
                // Pin feature not implemented yet
              },
            ),
            ListTile(
              leading: Icon(
                LucideIcons.bellOff,
                color: AppTheme.bodyStyle.color,
              ),
              title: const Text(
                'بی‌صدا کردن',
                style: TextStyle(color: AppTheme.textColor),
              ),
              onTap: () {
                Navigator.pop(context);
                // Mute feature not implemented yet
              },
            ),
            ListTile(
              leading: const Icon(
                LucideIcons.trash2,
                color: AppTheme.goldColor,
              ),
              title: const Text(
                'حذف گفتگو',
                style: TextStyle(color: AppTheme.goldColor),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmAndDeleteConversation(conversation);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndDeleteConversation(
    ChatConversation conversation,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text(
          'حذف گفتگو',
          style: TextStyle(color: AppTheme.textColor),
        ),
        content: Text(
          'آیا مطمئن هستید که می‌خواهید این گفتگو را حذف کنید؟',
          style: TextStyle(color: AppTheme.bodyStyle.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'حذف',
              style: TextStyle(color: AppTheme.goldColor),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _chatService.deleteConversation(conversation.id);
      // حذف از لیست‌های داخلی و رفرش UI
      SafeSetState.call(this, () {
        _conversations.removeWhere((c) => c.id == conversation.id);
        _filterConversations();
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('گفتگو با موفقیت حذف شد')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطا در حذف گفتگو: $e')));
      }
    }
  }

  String _formatLastMessageTime(DateTime dateTime) {
    // تبدیل تاریخ میلادی به شمسی و نمایش به صورت «روز ماه» مثل «20 مهر»
    final Jalali j = Jalali.fromDateTime(dateTime);
    final f = j.formatter;
    return '${f.d} ${f.mN}';
  }

  void _navigateToChatScreen(
    ChatConversation conversation,
    String otherUserId,
  ) {
    // دریافت ID کاربر فعلی
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return;

    // تشخیص نام کاربر دیگر
    final otherUserName = conversation.getOtherUserName(currentUserId);

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) =>
            ChatScreen(otherUserId: otherUserId, otherUserName: otherUserName),
      ),
    );
  }

  // بارگذاری آواتار کاربر
  Future<String?> _loadUserAvatar(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('avatar_url')
          .eq('id', userId)
          .maybeSingle();

      return response?['avatar_url'] as String?;
    } catch (e) {
      debugPrint('Error loading user avatar: $e');
      return null;
    }
  }

  // بارگذاری نقش کاربر (trainer/athlete/...)
  Future<String?> _loadUserRole(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .maybeSingle();
      return response?['role'] as String?;
    } catch (e) {
      debugPrint('Error loading user role: $e');
      return null;
    }
  }
}
