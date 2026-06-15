import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/chat/models/user_chat_message.dart';
import 'package:gymaipro/config/app_config.dart';
import 'package:gymaipro/chat/screens/chat_screen.dart';
import 'package:gymaipro/chat/services/chat_service.dart';
import 'package:gymaipro/chat/services/chat_cache_service.dart';
import 'package:gymaipro/chat/services/chat_unread_sync_bus.dart';
import 'package:gymaipro/chat/widgets/chat_hub_ui.dart';
import 'package:gymaipro/chat/widgets/user_avatar_widget.dart';
import 'package:gymaipro/my_club/services/friendship_service.dart';
import 'package:gymaipro/profile/repositories/profile_repository.dart';
import 'package:gymaipro/services/connectivity_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:gymaipro/widgets/user_role_badge.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// لیست گفتگوهای خصوصی در هاب اجتماعی (با جستجو و کشیدن برای به‌روزرسانی).
class ChatConversationsScreen extends StatefulWidget {
  const ChatConversationsScreen({
    super.key,
    this.standalone = false,
  });

  final bool standalone;

  @override
  State<ChatConversationsScreen> createState() =>
      _ChatConversationsScreenState();
}

class _ChatConversationsScreenState extends State<ChatConversationsScreen>
    with AutomaticKeepAliveClientMixin {
  late ChatService _chatService;
  List<ChatConversation> _conversations = [];
  List<ChatConversation> _filteredConversations = [];
  bool _isLoading = true;
  String _searchQuery = '';
  late final TextEditingController _searchController;
  StreamSubscription<dynamic>? _conversationsSubscription;
  StreamSubscription<void>? _unreadSyncSubscription;
  Timer? _searchDebounceTimer;
  final ChatCacheService _chatCache = ChatCacheService();
  final Map<String, String?> _avatarCache = {};
  final Map<String, String> _nameCache = {};
  final Map<String, String> _roleCache = {};
  bool _avatarSetStatePending = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _chatService = ChatService();
    _loadConversations();
    _subscribeToConversations();
    _unreadSyncSubscription =
        ChatUnreadSyncBus.instance.stream.listen((_) {
      unawaited(_refreshConversationsSilently());
    });
  }

  Future<void> _refreshConversationsSilently() async {
    try {
      if (!ConnectivityService.instance.isConnected) return;
      final conversations = await _chatService.getConversations().timeout(
        const Duration(seconds: 10),
      );
      if (!mounted) return;
      SafeSetState.call(this, () {
        _conversations = conversations;
        _filterConversations();
      });
      unawaited(_warmUpAvatarCache(conversations));
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    _conversationsSubscription?.cancel();
    _unreadSyncSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    try {
      if (_conversations.isEmpty) {
        final cached = await _chatCache.loadConversationsDisk();
        if (cached.isNotEmpty) {
          SafeSetState.call(this, () {
            _conversations = cached;
            _filterConversations();
            _isLoading = false;
          });
          unawaited(_preloadUserMeta(cached));
          unawaited(_warmUpAvatarCache(cached));
        } else {
          SafeSetState.call(this, () => _isLoading = true);
        }
      } else {
        SafeSetState.call(this, () => _isLoading = true);
      }

      if (!ConnectivityService.instance.isConnected) {
        if (_conversations.isEmpty) {
          SafeSetState.call(this, () {
            _filteredConversations = [];
            _isLoading = false;
          });
        } else {
          SafeSetState.call(this, () => _isLoading = false);
        }
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
      if (!mounted) return;
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

      // به‌روزرسانی وقتی پیام جدید است یا شمارندهٔ نخوانده عوض شده (مثلاً خوانده شد)
      final existingIndex = _conversations.indexWhere(
        (c) => c.id == newConversation.id,
      );
      final int oldUnread = existingIndex == -1
          ? -1
          : _conversations[existingIndex].getUnreadCount(currentUserId);
      final int newUnread = newConversation.getUnreadCount(currentUserId);
      final bool shouldUpdate =
          existingIndex == -1 ||
          _conversations[existingIndex].lastMessageDateTime !=
              newConversation.lastMessageDateTime ||
          oldUnread != newUnread;
      if (shouldUpdate) {
        _conversations.add(newConversation);
        _conversations.sort(
          (a, b) => b.lastMessageDateTime.compareTo(a.lastMessageDateTime),
        );
        _filterConversations();
        _chatCache.patchConversation(newConversation);
      }

      // از به‌روزرسانی notifier داخل این صفحه صرف‌نظر می‌کنیم تا رندرهای اضافی ایجاد نشود
    });
  }

  void _filterConversations() {
    List<ChatConversation> filtered = _conversations;

    // فیلترها حذف شده‌اند

    // اعمال جستجو
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where(
            (c) =>
                c.otherUserName.toLowerCase().contains(query) ||
                (c.lastMessageText?.toLowerCase().contains(query) ??
                    false),
          )
          .toList();
    }

    _filteredConversations = filtered;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final content = Column(
      children: [
        ChatHubSearchBar(
          controller: _searchController,
          hint: 'جستجو بر اساس نام یا متن آخرین پیام',
          onChanged: (value) {
            _searchDebounceTimer?.cancel();
            _searchDebounceTimer = Timer(const Duration(milliseconds: 180), () {
              if (!mounted) return;
              SafeSetState.call(this, () {
                _searchQuery = value;
                _filterConversations();
              });
            });
          },
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(18.w, 0, 18.w, 10.h),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Text(
                'پیام‌های اخیر',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: context.textColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppTheme.goldColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  '${_filteredConversations.length}',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: AppTheme.goldColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const ChatHubLoadingView(
                  subtitle: 'لیست گفتگوهای شما از سرور به‌روز می‌شود',
                )
              : _filteredConversations.isEmpty
                  ? _buildEmptyState()
                  : _buildConversationsList(),
        ),
      ],
    );

    if (!widget.standalone) {
      return content;
    }

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text(
          'پیام‌ها',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.w700,
            color: context.textColor,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: content,
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  Widget _buildEmptyState() {
    String message;
    String subtitle;
    IconData icon;

    if (!ConnectivityService.instance.isConnected) {
      message = 'بدون اتصال';
      subtitle =
          'اینترنت را وصل کنید تا بتوانید گفتگوها را ببینید و ادامه دهید';
      icon = LucideIcons.wifiOff;
    } else if (_searchQuery.isNotEmpty) {
      message = 'نتیجه‌ای پیدا نشد';
      subtitle = 'عبارت دیگری امتحان کنید یا املای جستجو را بررسی کنید';
      icon = LucideIcons.search;
    } else {
      message = 'هنوز پیامی ندارید';
      subtitle =
          'وقتی با دوستان یا اعضای ${AppConfig.gymAiDisplayName} گفتگو کنید، همهٔ مکالمات اینجا '
          'مرتب و زنده نمایش داده می‌شود';
      icon = LucideIcons.messagesSquare;
    }

    return ChatHubEmptyView(
      icon: icon,
      title: message,
      subtitle: subtitle,
    );
  }

  Widget _buildConversationsList() {
    return RefreshIndicator(
      onRefresh: _loadConversations,
      color: AppTheme.goldColor,
      edgeOffset: 52,
      child: ListView.separated(
        key: const PageStorageKey('chat_conversations_list'),
        padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 20.h),
        cacheExtent: 600,
        itemCount: _filteredConversations.length,
        separatorBuilder: (_, __) => SizedBox(height: 10.h),
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unreadLabel = unreadCount > 99 ? '99+' : '$unreadCount';

    return Material(
      key: ValueKey(conversation.id),
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToChatScreen(conversation, otherUserId),
        onLongPress: () => _showConversationActions(conversation),
        borderRadius: BorderRadius.circular(16.r),
        child: Ink(
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: hasUnread
                  ? AppTheme.goldColor.withValues(alpha: 0.28)
                  : context.separatorColor.withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.veryDarkBackground.withValues(alpha: isDark ? 0.18 : 0.04),
                blurRadius: 10,
                offset: Offset(0, 3.h),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    UserAvatarWidget(
                      avatarUrl: _avatarCache[otherUserId],
                      showOnlineStatus: false,
                    ),
                    if (hasUnread)
                      Positioned(
                        top: -1,
                        left: -1,
                        child: Container(
                          width: 14.w,
                          height: 14.h,
                          decoration: BoxDecoration(
                            color: AppTheme.goldColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: context.cardColor,
                              width: 2.w,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(width: 14.w),
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
                                color: context.textColor,
                                fontSize: 14.sp,
                                fontWeight: hasUnread
                                    ? FontWeight.w800
                                    : FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            timeString,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color: context.textSecondary.withValues(
                                alpha: 0.95,
                              ),
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          UserRoleBadge(
                            role: _roleCache[otherUserId] ?? 'athlete',
                            fontSize: 10.sp,
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 2.h,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              conversation.lastMessageText ?? 'بدون پیام',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color: hasUnread
                                    ? context.textColor.withValues(
                                        alpha: 0.92,
                                      )
                                    : context.textSecondary,
                                fontSize: 13.5.sp,
                                height: 1.25,
                                fontWeight: hasUnread
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasUnread) ...[
                            SizedBox(width: 8.w),
                            Container(
                              constraints: BoxConstraints(minWidth: 22.w),
                              padding: EdgeInsets.symmetric(
                                horizontal: 7.w,
                                vertical: 3.h,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: context.goldGradientColors,
                                ),
                                borderRadius: BorderRadius.circular(12.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.goldColor.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 8,
                                    offset: Offset(0, 2.h),
                                  ),
                                ],
                              ),
                              child: Text(
                                unreadLabel,
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  color: AppTheme.onGoldColor,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w800,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 6.w),
                Icon(
                  LucideIcons.chevronLeft,
                  size: 22.sp,
                  color: context.textSecondary.withValues(alpha: 0.35),
                ),
              ],
            ),
          ),
        ),
      ),
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
                leading: const Icon(LucideIcons.pin, color: AppTheme.goldColor),
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
                leading: const Icon(
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
                leading: const Icon(
                  LucideIcons.userX,
                  color: Colors.redAccent,
                ),
                title: const Text(
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
                leading: const Icon(
                  LucideIcons.trash2,
                  color: AppTheme.goldColor,
                ),
                title: const Text(
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
            child: const Text(
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

      if (!mounted) return;
      SafeSetState.call(this, () {
        _conversations.removeWhere((c) => c.id == conversation.id);
        _filterConversations();
      });

      WidgetSafetyUtils.safeShowSnackBar(
        context,
        'کاربر "$otherUserName" بلاک شد و گفتگو حذف شد',
      );
    } catch (e) {
      if (!mounted) return;
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
            child: const Text(
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
      if (!mounted) return;
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
      if (!mounted) return;
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
          initialConversationId: conversation.id,
        ),
      ),
    );
  }

  // بارگذاری آواتار کاربر
  Future<String?> _loadUserAvatar(String userId) =>
      ProfileRepository.instance.getUserAvatar(userId);

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

      final profiles = await ProfileRepository.instance.fetchProfilesByAuthUserIds(
        userIds.toList(),
      );

      for (final row in profiles) {
        final authUserId = (row['auth_user_id'] as String?)?.trim();
        if (authUserId == null || authUserId.isEmpty) continue;

        _nameCache[authUserId] = ProfileRepository.instance.displayNameFromMap(
          row,
          fallback: 'کاربر',
        );

        final role = (row['role'] as String?)?.trim();
        if (role != null && role.isNotEmpty) {
          _roleCache[authUserId] = role;
        }
      }
    } catch (_) {}
  }
}
