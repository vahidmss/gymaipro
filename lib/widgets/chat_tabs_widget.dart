import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:gymaipro/services/public_chat_service.dart';
import 'package:gymaipro/models/public_chat_message.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'dart:async';

class ChatTabsWidget extends StatefulWidget {
  const ChatTabsWidget({Key? key}) : super(key: key);

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
  bool _isRefreshing = false;
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
              _scrollController
                  .jumpTo(_scrollController.position.maxScrollExtent);
            }
          });
        }
      }
    });
  }

  Future<void> _loadMessages({bool initial = false}) async {
    if (!initial) {
      setState(() => _isRefreshing = true);
    }
    try {
      final messages = await _publicChatService.getMessages(limit: 50);
      SafeSetState.call(this, () {
        _messages = messages;
        _isLoading = false;
        _firstLoadDone = true;
        _errorMessage = null;
        _isRefreshing = false;
      });
      if (initial || _autoScroll || _isAtBottom) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController
                .jumpTo(_scrollController.position.maxScrollExtent);
          }
        });
      }
    } catch (e) {
      SafeSetState.call(this, () {
        _isLoading = false;
        _firstLoadDone = true;
        _errorMessage = 'خطا در بارگیری پیام‌ها';
        _isRefreshing = false;
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
    Color color = Colors.green;
    if (role == 'trainer') {
      text = 'مربی';
      color = Colors.purple;
    } else if (role == 'admin') {
      text = 'ادمین';
      color = AppTheme.goldColor;
    }
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getSafeInitial(String? name) {
    if (name == null || name.isEmpty) {
      return 'ک';
    }
    return name.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280, // کاهش ارتفاع
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header ساده‌تر
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.goldColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.messageSquare,
                  color: AppTheme.goldColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'آخرین پیام‌ها',
                  style: TextStyle(
                    color: AppTheme.goldColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                if (_isRefreshing)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: AppTheme.goldColor,
                      strokeWidth: 2,
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
          // Footer ساده‌تر
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_messages.length} پیام',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/chat-main'),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.goldColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.messageCircle,
                          color: Colors.black,
                          size: 12,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'چت',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 11,
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
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.goldColor),
          SizedBox(height: 12),
          Text(
            'در حال بارگیری پیام‌ها...',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.alertCircle,
            color: Colors.red.withValues(alpha: 0.5),
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _loadMessages,
            icon: const Icon(LucideIcons.refreshCw, size: 14),
            label: const Text('تلاش مجدد', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.goldColor,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.goldColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              LucideIcons.messageSquare,
              color: AppTheme.goldColor.withValues(alpha: 0.5),
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'هنوز پیامی ارسال نشده',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اولین پیام را ارسال کنید!',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageCard(message);
      },
    );
  }

  Widget _buildMessageCard(PublicChatMessage message) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/chat-main'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.goldColor.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.goldColor.withValues(alpha: 0.2),
              child: Text(
                _getSafeInitial(message.senderName),
                style: const TextStyle(
                  color: AppTheme.goldColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildRoleTag(message.senderRole),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          message.senderName ?? 'کاربر ناشناس',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTime(message.createdAt),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      height: 1.3,
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
