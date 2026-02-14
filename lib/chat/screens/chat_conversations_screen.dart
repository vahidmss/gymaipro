import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/chat/models/user_chat_message.dart';
import 'package:gymaipro/chat/screens/chat_screen.dart';
import 'package:gymaipro/chat/services/chat_service.dart';
import 'package:gymaipro/chat/widgets/user_avatar_widget.dart';
import 'package:gymaipro/my_club/services/friendship_service.dart';
import 'package:gymaipro/services/connectivity_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
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
  final Map<String, String> _nameCache = {};
  final Map<String, String> _roleCache = {};
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
      // جلوگیری از لودینگ بی‌نهایت در صورت مشکل شبکه/دسترسی
      final conversations = await _chatService.getConversations().timeout(
        const Duration(seconds: 15),
      );

      // قبل از نمایش، نام و نقش تمام کاربران طرف مکالمه را پیش‌لود می‌کنیم
      await _preloadUserMeta(conversations);

      SafeSetState.call(this, () {
        _conversations = conversations;
        _filterConversations();
        _isLoading = false;
      });
      // Warm up avatar cache and refresh in background (no UI blocking)
      unawaited(_warmUpAvatarCache(conversations));
    } catch (e) {
      SafeSetState.call(this, () => _isLoading = false);
      // هنگام آفلاین بودن یا خطاهای شبکه، پیام کاربرپسند نشان بده
      final isOffline = !ConnectivityService.instance.isConnected;
      final msg = isOffline
          ? 'اتصال اینترنت برقرار نیست. لطفاً اینترنت را بررسی کنید.'
          : 'خطا در بارگذاری گفتگوها. لطفاً دوباره تلاش کنید.';
      WidgetSafetyUtils.safeShowSnackBar(context, msg);
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
      SafeSetState.call(this, () {});

      // Refresh latest avatar URLs from server in background
      for (int i = 0; i < limit; i++) {
        final conv = conversations[i];
        final currentUserId = Supabase.instance.client.auth.currentUser?.id;
        if (currentUserId == null) continue;
        final otherUserId = conv.getOtherUserId(currentUserId);
        unawaited(_refreshAvatar(otherUserId));
      }
    } catch (_) {}
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
    } catch (_) {}
  }

  void _scheduleAvatarSetState() {
    if (_avatarSetStatePending || !mounted) return;
    _avatarSetStatePending = true;
    Future.delayed(const Duration(milliseconds: 120), () {
      _avatarSetStatePending = false;
      SafeSetState.call(this, () {});
    });
  }

  void _subscribeToConversations() {
    try {
      final stream = _chatService.subscribeToConversations();
      _conversationsSubscription = stream.listen(_updateConversation);
    } catch (_) {}
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
              color: context.cardColor,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: AppTheme.goldColor.withValues(alpha: 0.2),
              ),
            ),
            child: Icon(
              icon,
              size: 64.sp,
              color: AppTheme.goldColor.withValues(alpha: 0.5),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            message,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
              color: context.textColor,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 14.sp,
              color: context.textSecondary,
            ),
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
    final initialOtherUserName = conversation.getOtherUserName(currentUserId);
    final unreadCount = conversation.getUnreadCount(currentUserId);
    final hasUnread = conversation.hasUnreadForUser(currentUserId);

    return Column(
      key: ValueKey(conversation.id),
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: hasUnread
                  ? AppTheme.goldColor.withValues(alpha: 0.3)
                  : context.separatorColor.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.goldColor.withValues(alpha: 0.05),
                blurRadius: 8.r,
                offset: Offset(0.w, 2.h),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _navigateToChatScreen(conversation, otherUserId),
              onLongPress: () => _showConversationActions(conversation),
              borderRadius: BorderRadius.circular(16.r),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Row(
                  textDirection: TextDirection.rtl,
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    SizedBox(width: 16.w),

                    // محتوا به سبک تلگرام: ردیف بالا نام + تاریخ، ردیف پایین نقش + آخرین پیام، نشان نخوانده کنار پیام
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _nameCache[otherUserId] ??
                                      initialOtherUserName,
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    color: hasUnread
                                        ? context.textColor
                                        : context.textColor.withValues(
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
                              SizedBox(width: 8.w),
                              Flexible(
                                child: Text(
                                  timeString,
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    color: context.textSecondary,
                                    fontSize: 11.sp,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                padding: EdgeInsetsDirectional.only(
                                  end: 6.w,
                                ),
                                child: UserRoleBadge(
                                  role: _roleCache[otherUserId] ?? 'athlete',
                                  fontSize: 10.sp,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 5.w,
                                    vertical: 1.h,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  conversation.lastMessageText ?? 'بدون پیام',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    color: hasUnread
                                        ? context.textColor.withValues(
                                            alpha: 0.95,
                                          )
                                        : context.textSecondary,
                                    fontSize: 13.sp,
                                    fontWeight: hasUnread
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: 6.w),
                              if (hasUnread)
                                Container(
                                  constraints: BoxConstraints(
                                    minWidth: 20.w,
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: context.goldGradientColors,
                                    ),
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: Text(
                                    '$unreadCount',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      color: AppTheme.onGoldColor,
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
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
      backgroundColor: context.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: context.separatorColor,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 16.h),
            Directionality(
              textDirection: TextDirection.rtl,
              child: ListTile(
                leading: Icon(LucideIcons.pin, color: AppTheme.goldColor),
                title: Text(
                  'پین کردن گفتگو',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: context.textColor,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Pin feature not implemented yet
                },
              ),
            ),
            Directionality(
              textDirection: TextDirection.rtl,
              child: ListTile(
                leading: Icon(
                  LucideIcons.bellOff,
                  color: AppTheme.goldColor,
                ),
                title: Text(
                  'بی‌صدا کردن',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: context.textColor,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Mute feature not implemented yet
                },
              ),
            ),
            Directionality(
              textDirection: TextDirection.rtl,
              child: ListTile(
                leading: Icon(
                  LucideIcons.userX,
                  color: Colors.redAccent,
                ),
                title: Text(
                  'بلاک کردن کاربر',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmAndBlockUser(conversation);
                },
              ),
            ),
            Directionality(
              textDirection: TextDirection.rtl,
              child: ListTile(
                leading: Icon(
                  LucideIcons.trash2,
                  color: AppTheme.goldColor,
                ),
                title: Text(
                  'حذف گفتگو',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: AppTheme.goldColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmAndDeleteConversation(conversation);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndBlockUser(ChatConversation conversation) async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) {
      WidgetSafetyUtils.safeShowSnackBar(
        context,
        'برای بلاک کردن کاربر باید وارد شوید',
      );
      return;
    }

    final otherUserId = conversation.getOtherUserId(currentUserId);
    final otherUserName = conversation.getOtherUserName(currentUserId);

    final confirmed = await WidgetSafetyUtils.safeShowDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: dialogContext.cardColor,
        title: Text(
          'بلاک کردن کاربر',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.bold,
            color: dialogContext.textColor,
          ),
        ),
        content: Text(
          'آیا مطمئن هستید که می‌خواهید کاربر "$otherUserName" را بلاک کنید؟\n\n'
          'پس از بلاک، دیگر پیامی از این کاربر دریافت نخواهید کرد و مکالمه فعلی نیز حذف می‌شود.',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: dialogContext.textColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'انصراف',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: dialogContext.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'بلاک کن',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FriendshipService.blockUser(otherUserId);

      SafeSetState.call(this, () {
        _conversations.removeWhere((c) => c.id == conversation.id);
        _filterConversations();
      });

      WidgetSafetyUtils.safeShowSnackBar(
        context,
        'کاربر "$otherUserName" بلاک شد و گفتگو حذف شد',
      );
    } catch (e) {
      WidgetSafetyUtils.safeShowSnackBar(
        context,
        'خطا در بلاک کردن کاربر: $e',
      );
    }
  }

  Future<void> _confirmAndDeleteConversation(
    ChatConversation conversation,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.cardColor,
        title: Text(
          'حذف گفتگو',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.bold,
            color: context.textColor,
          ),
        ),
        content: Text(
          'آیا مطمئن هستید که می‌خواهید این گفتگو را حذف کنید؟',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: context.textColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'انصراف',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: context.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'حذف',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: AppTheme.goldColor,
                fontWeight: FontWeight.bold,
              ),
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

      WidgetSafetyUtils.safeShowSnackBar(
        context,
        'گفتگو با موفقیت حذف شد',
      );
    } catch (e) {
      WidgetSafetyUtils.safeShowSnackBar(
        context,
        'خطا در حذف گفتگو: $e',
      );
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

    // تشخیص نام کاربر دیگر؛ از کش پیش‌لودشده استفاده می‌کنیم
    final initialOtherUserName = conversation.getOtherUserName(currentUserId);
    final otherUserName = _nameCache[otherUserId] ?? initialOtherUserName;

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => ChatScreen(
          otherUserId: otherUserId,
          otherUserName: otherUserName,
        ),
      ),
    );
  }

  // بارگذاری آواتار کاربر
  Future<String?> _loadUserAvatar(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('avatar_url')
          .or('id.eq.$userId,auth_user_id.eq.$userId')
          .maybeSingle();

      return response?['avatar_url'] as String?;
    } catch (_) {
      return null;
    }
  }

  // پیش‌لود نام و نقش کاربرانِ طرف مکالمه‌ها تا بدون فلیکر نمایش داده شوند
  Future<void> _preloadUserMeta(List<ChatConversation> conversations) async {
    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null) return;

      final Set<String> userIds = {};
      for (final conv in conversations) {
        userIds.add(conv.getOtherUserId(currentUserId));
      }
      if (userIds.isEmpty) return;

      final response = await Supabase.instance.client
          .from('profiles')
          .select(
            'auth_user_id, first_name, last_name, username, phone_number, role',
          )
          .inFilter('auth_user_id', userIds.toList());

      for (final row in response) {
        final authUserId = (row['auth_user_id'] as String?)?.trim();
        if (authUserId == null || authUserId.isEmpty) continue;

        final firstName = (row['first_name'] as String? ?? '').trim();
        final lastName = (row['last_name'] as String? ?? '').trim();
        final username = (row['username'] as String? ?? '').trim();
        final phone = (row['phone_number'] as String? ?? '').trim();

        String name;
        if (firstName.isNotEmpty && lastName.isNotEmpty) {
          name = '$firstName $lastName';
        } else if (firstName.isNotEmpty) {
          name = firstName;
        } else if (lastName.isNotEmpty) {
          name = lastName;
        } else if (username.isNotEmpty) {
          name = username;
        } else if (phone.isNotEmpty) {
          name = phone.length > 7 ? phone.replaceRange(0, 7, '***') : phone;
        } else {
          name = 'کاربر';
        }

        _nameCache[authUserId] = name;

        final role = (row['role'] as String?)?.trim();
        if (role != null && role.isNotEmpty) {
          _roleCache[authUserId] = role;
        }
      }
    } catch (_) {}
  }
}
