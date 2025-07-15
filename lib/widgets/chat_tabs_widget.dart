import 'package:flutter/material.dart';
import 'package:gymaipro/services/chat_service.dart';
import 'package:gymaipro/services/public_chat_service.dart';
import 'package:gymaipro/services/supabase_service.dart';
import 'package:gymaipro/widgets/public_chat_widget.dart';
import 'package:gymaipro/widgets/trainers_chat_section.dart';
import 'package:gymaipro/theme/app_theme.dart';

class ChatTabsWidget extends StatefulWidget {
  const ChatTabsWidget({Key? key}) : super(key: key);

  @override
  State<ChatTabsWidget> createState() => _ChatTabsWidgetState();
}

class _ChatTabsWidgetState extends State<ChatTabsWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ChatService _chatService;
  late PublicChatService _publicChatService;
  int _publicUnreadCount = 0;
  int _privateUnreadCount = 0;

  // Add GlobalKey for PublicChatWidget
  final GlobalKey<PublicChatWidgetState> _publicChatKey =
      GlobalKey<PublicChatWidgetState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _chatService = ChatService(supabaseService: SupabaseService());
    _publicChatService = PublicChatService();
    _loadUnreadCounts();

    // اضافه کردن listener برای تغییر تب
    _tabController.addListener(() {
      if (_tabController.index == 0) {
        // وقتی به تب چت عمومی برمی‌گردیم، پیام‌ها را refresh کنیم
        _publicChatKey.currentState?.reloadMessages();
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUnreadCounts() async {
    try {
      final privateCount = await _chatService.getUnreadMessageCount();
      final publicCount = await _publicChatService.getUnreadCount();
      setState(() {
        _privateUnreadCount = privateCount;
        _publicUnreadCount = publicCount;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 380,
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header مینیمال و زیبا
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.goldColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.goldColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    color: AppTheme.goldColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'گفتگو',
                        style: TextStyle(
                          color: AppTheme.goldColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'با کاربران و مربیان چت کنید',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tabs مینیمال
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppTheme.goldColor,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 14,
              ),
              dividerColor: Colors.transparent,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.public,
                        size: 16,
                        color: _tabController.index == 0
                            ? Colors.black
                            : Colors.white.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 6),
                      const Text('همگانی'),
                      if (_publicUnreadCount > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _publicUnreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 16,
                        color: _tabController.index == 1
                            ? Colors.black
                            : Colors.white.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 6),
                      const Text('خصوصی'),
                      if (_privateUnreadCount > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _privateUnreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Public Chat Tab
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: PublicChatWidget(key: _publicChatKey),
                ),
                // Private Chat Tab
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: const TrainersChatSection(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
