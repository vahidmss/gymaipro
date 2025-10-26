import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/chat/models/public_chat_message.dart';
import 'package:gymaipro/chat/services/public_chat_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatTabsWidget extends StatefulWidget {
  const ChatTabsWidget({super.key});

  @override
  State<ChatTabsWidget> createState() => _ChatTabsWidgetState();
}

class _ChatTabsWidgetState extends State<ChatTabsWidget> {
  late PublicChatService _publicChatService;
  List<PublicChatMessage> _messages = [];
  bool _isLoading = true;
  String? _errorMessage;
  final ScrollController _scrollController = ScrollController();
  bool _firstLoadDone = false;
  final bool _autoScroll = true;
  bool _isAtBottom = true;
  Stream<PublicChatMessage>? _subscription;
  late StreamSubscription<PublicChatMessage> _realtimeSub;

  @override
  void initState() {
    super.initState();
    _publicChatService = PublicChatService();
    _scrollController.addListener(_onScroll);
    _loadMessages(initial: true);
    _subscribeToRealtime();
  }

  @override
  void dispose() {
    _realtimeSub.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    _isAtBottom = (maxScroll - current).abs() < 40;
  }

  void _subscribeToRealtime() {
    _subscription = _publicChatService.subscribeMessages();
    _realtimeSub = _subscription!.listen((msg) {
      // اگر پیام تکراری نبود اضافه کن
      if (!_messages.any((m) => m.id == msg.id)) {
        SafeSetState.call(this, () {
          _messages.add(msg);
        });
        // اگر کاربر پایین بود، اسکرول کن به آخر
        if (_isAtBottom) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.jumpTo(
                _scrollController.position.maxScrollExtent,
              );
            }
          });
        }
      }
    });
  }

  Future<void> _loadMessages({bool initial = false}) async {
    try {
      final messages = await _publicChatService.getMessages();
      SafeSetState.call(this, () {
        _messages = messages;
        _isLoading = false;
        _firstLoadDone = true;
        _errorMessage = null;
      });
      if (initial || _autoScroll || _isAtBottom) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(
              _scrollController.position.maxScrollExtent,
            );
          }
        });
      }
    } catch (e) {
      SafeSetState.call(this, () {
        _isLoading = false;
        _firstLoadDone = true;
        _errorMessage = 'خطا در بارگیری پیام‌ها';
      });
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inMinutes < 1) {
      return 'الان';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} دقیقه پیش';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ساعت پیش';
    } else {
      return '${difference.inDays} روز پیش';
    }
  }

  Widget _buildRoleTag(String? role) {
    String text = 'کاربر';
    Color color = AppTheme.goldColor;
    IconData icon = LucideIcons.user;

    if (role == 'trainer') {
      text = 'مربی';
      color = AppTheme.primaryColor;
      icon = LucideIcons.crown;
    } else if (role == 'admin') {
      text = 'ادمین';
      color = AppTheme.goldColor;
      icon = LucideIcons.shield;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 4.r,
            offset: Offset(0.w, 1.h),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12.sp),
          SizedBox(width: 4.w),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  String _getSafeInitial(String? name) {
    if (name == null || name.isEmpty) {
      return 'ک';
    }
    return name.substring(0, 1).toUpperCase();
  }

  Future<String?> _getUserAvatarUrl(String? userId) async {
    if (userId == null || userId.isEmpty) return null;

    try {
      // دریافت عکس کاربر از Supabase
      final response = await Supabase.instance.client
          .from('profiles')
          .select('avatar_url')
          .eq('id', userId)
          .maybeSingle();

      if (response != null && response['avatar_url'] != null) {
        return response['avatar_url'] as String;
      }
      return null;
    } catch (e) {
      print('Error fetching user avatar: $e');
      return null;
    }
  }

  Widget _buildFallbackAvatar(String? senderName) {
    return Container(
      width: 36.w,
      height: 36.h,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.goldColor, AppTheme.darkGold],
        ),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Center(
        child: Text(
          _getSafeInitial(senderName),
          style: TextStyle(
            color: AppTheme.textColor,
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320.h, // افزایش ارتفاع برای نمایش بیشتر پیام
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.cardColor,
            AppTheme.cardColor.withValues(alpha: 0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldColor.withValues(alpha: 0.1),
            blurRadius: 20.r,
            offset: Offset(0.w, 8.h),
          ),
          BoxShadow(
            color: AppTheme.backgroundColor.withValues(alpha: 0.15),
            blurRadius: 12.r,
            offset: Offset(0.w, 4.h),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header مدرن با گرادیانت
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.goldColor.withValues(alpha: 0.15),
                  AppTheme.goldColor.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24.r),
                topRight: Radius.circular(24.r),
              ),
            ),
            child: Row(
              children: [
                // آیکون با پس‌زمینه دایره‌ای
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.goldColor, AppTheme.darkGold],
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.goldColor.withValues(alpha: 0.3),
                        blurRadius: 8.r,
                        offset: Offset(0.w, 2.h),
                      ),
                    ],
                  ),
                  child: Icon(
                    LucideIcons.messageSquare,
                    color: AppTheme.textColor,
                    size: 18.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'چت عمومی',
                        style: TextStyle(
                          color: AppTheme.textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'آخرین گفتگوها',
                        style: TextStyle(
                          color: AppTheme.bodyStyle.color,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                // دکمه ورود به چت در هدر
                GestureDetector(
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/chat-main',
                    arguments: {'initialTab': 1},
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.goldColor, AppTheme.darkGold],
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.goldColor.withValues(alpha: 0.3),
                          blurRadius: 4.r,
                          offset: Offset(0.w, 1.h),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.messageSquare,
                          color: AppTheme.textColor,
                          size: 12.sp,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'چت روم',
                          style: TextStyle(
                            color: AppTheme.textColor,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // پیام‌ها با اسکرول آزاد
          Expanded(
            child: _isLoading && !_firstLoadDone
                ? _buildLoadingState()
                : _errorMessage != null
                ? _buildErrorState()
                : _messages.isEmpty
                ? _buildEmptyState()
                : _buildMessagesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.goldColor.withValues(alpha: 0.15),
                  AppTheme.goldColor.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: AppTheme.goldColor.withValues(alpha: 0.2),
              ),
            ),
            child: SizedBox(
              width: 24.w,
              height: 24.h,
              child: const CircularProgressIndicator(
                color: AppTheme.goldColor,
                strokeWidth: 2,
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'در حال بارگیری...',
            style: TextStyle(
              color: AppTheme.textColor,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.goldColor.withValues(alpha: 0.15),
                  AppTheme.goldColor.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppTheme.goldColor.withValues(alpha: 0.2),
              ),
            ),
            child: Icon(
              LucideIcons.alertCircle,
              color: AppTheme.goldColor,
              size: 20.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            _errorMessage!,
            style: TextStyle(
              color: AppTheme.textColor,
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          GestureDetector(
            onTap: _loadMessages,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppTheme.goldColor,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                'تلاش مجدد',
                style: TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.goldColor.withValues(alpha: 0.15),
                  AppTheme.goldColor.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: AppTheme.goldColor.withValues(alpha: 0.2),
              ),
            ),
            child: Icon(
              LucideIcons.messageSquare,
              color: AppTheme.goldColor,
              size: 24.sp,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'هنوز پیامی ارسال نشده',
            style: TextStyle(
              color: AppTheme.textColor,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'اولین پیام را ارسال کنید!',
            style: TextStyle(color: AppTheme.bodyStyle.color, fontSize: 11.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(16.w),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageCard(message);
      },
    );
  }

  Widget _buildMessageCard(PublicChatMessage message) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/chat-main',
        arguments: {'initialTab': 0},
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.backgroundColor.withValues(alpha: 0.3),
              AppTheme.backgroundColor.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppTheme.goldColor.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.goldColor.withValues(alpha: 0.05),
              blurRadius: 8.r,
              offset: Offset(0.w, 2.h),
            ),
          ],
        ),
        child: Row(
          children: [
            // آواتار با عکس کاربر
            FutureBuilder<String?>(
              future: _getUserAvatarUrl(message.senderId),
              builder: (context, snapshot) {
                final avatarUrl = snapshot.data;
                return Container(
                  width: 36.w,
                  height: 36.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.goldColor.withValues(alpha: 0.3),
                        blurRadius: 6.r,
                        offset: Offset(0.w, 2.h),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18.r),
                    child: avatarUrl != null && avatarUrl.isNotEmpty
                        ? Image.network(
                            avatarUrl,
                            width: 36.w,
                            height: 36.h,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildFallbackAvatar(message.senderName),
                          )
                        : _buildFallbackAvatar(message.senderName),
                  ),
                );
              },
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildRoleTag(message.senderRole),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          message.senderName ?? 'کاربر ناشناس',
                          style: TextStyle(
                            color: AppTheme.textColor,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.goldColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          _formatTime(message.createdAt),
                          style: TextStyle(
                            color: AppTheme.goldColor,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    message.message,
                    style: TextStyle(
                      color: AppTheme.textColor.withValues(alpha: 0.9),
                      fontSize: 12.sp,
                      height: 1.4.h,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
