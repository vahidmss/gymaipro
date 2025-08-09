import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../services/chat_service.dart';
import '../../services/supabase_service.dart';
import '../../utils/safe_set_state.dart';
import 'chat_conversations_screen.dart';
import 'chat_trainer_selection_screen.dart';
import '../widgets/chat_search_bar.dart';
import '../../widgets/public_chat_widget.dart';

class ChatMainScreen extends StatefulWidget {
  const ChatMainScreen({Key? key}) : super(key: key);

  @override
  State<ChatMainScreen> createState() => _ChatMainScreenState();
}

class _ChatMainScreenState extends State<ChatMainScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ChatService _chatService;
  int _currentIndex = 0;
  int _totalUnreadCount = 0;
  bool _isLoading = true;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _chatService = ChatService(supabaseService: SupabaseService());
    _loadUserInfo();

    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
      });
    });
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = await SupabaseService().getProfileByAuthId();
      if (user != null) {
        setState(() {
          _userRole = user.role;
        });
      }
      await _loadUnreadCount();
    } catch (e) {
      debugPrint('Error loading user info: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUnreadCount() async {
    try {
      SafeSetState.call(this, () => _isLoading = true);
      final unreadCount = await _chatService.getUnreadMessageCount();
      SafeSetState.call(this, () {
        _totalUnreadCount = unreadCount;
        _isLoading = false;
      });
    } catch (e) {
      SafeSetState.call(this, () => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchSection(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // تب گفتگوها
                const ChatConversationsScreen(),
                // تب چت عمومی - مستقیماً PublicChatWidget
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: const PublicChatWidget(),
                ),
                // تب انتخاب مربی
                const ChatTrainerSelectionScreen(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.cardColor,
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.goldColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              LucideIcons.messageCircle,
              color: AppTheme.goldColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'گفتگو',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'با مربیان و کاربران چت کنید',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (_totalUnreadCount > 0)
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$_totalUnreadCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        IconButton(
          icon: const Icon(LucideIcons.settings, color: Colors.white),
          onPressed: () => _showChatSettings(),
        ),
      ],
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ChatSearchBar(
        onSearch: (query) {
          // TODO: پیاده‌سازی جستجو
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.goldColor,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.black,
        unselectedLabelColor: Colors.white70,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 14,
        ),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.messageSquare, size: 16),
                SizedBox(width: 6),
                Text('گفتگوها'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.users, size: 16),
                SizedBox(width: 6),
                Text('همگانی'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.userPlus, size: 16),
                SizedBox(width: 6),
                Text('مربی‌ها'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    if (_currentIndex == 0) {
      // برای تب گفتگوها - شروع گفتگوی جدید
      return FloatingActionButton(
        onPressed: () => _showNewChatOptions(),
        backgroundColor: AppTheme.goldColor,
        child: const Icon(
          LucideIcons.messageCircle,
          color: Colors.black,
        ),
      );
    } else if (_currentIndex == 1 && _userRole == 'trainer') {
      // برای تب عمومی - ارسال پیام عمومی (فقط برای مربیان)
      return FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/broadcast-messages'),
        backgroundColor: AppTheme.goldColor,
        child: const Icon(
          LucideIcons.megaphone,
          color: Colors.black,
        ),
      );
    } else if (_currentIndex == 2) {
      // برای تب مربی‌ها - جستجوی مربی
      return FloatingActionButton(
        onPressed: () => _showTrainerSearch(),
        backgroundColor: AppTheme.goldColor,
        child: const Icon(
          LucideIcons.search,
          color: Colors.black,
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _showChatSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'تنظیمات چت',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(LucideIcons.bell, color: AppTheme.goldColor),
              title:
                  const Text('اعلان‌ها', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // TODO: تنظیمات اعلان
              },
            ),
            ListTile(
              leading:
                  const Icon(LucideIcons.shield, color: AppTheme.goldColor),
              title: const Text('حریم خصوصی',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // TODO: تنظیمات حریم خصوصی
              },
            ),
            ListTile(
              leading:
                  const Icon(LucideIcons.download, color: AppTheme.goldColor),
              title: const Text('پشتیبان‌گیری',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // TODO: پشتیبان‌گیری
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNewChatOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'شروع گفتگوی جدید',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading:
                  const Icon(LucideIcons.userPlus, color: AppTheme.goldColor),
              title: const Text('انتخاب مربی',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _tabController.animateTo(2); // برو به تب مربی‌ها
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.users, color: AppTheme.goldColor),
              title:
                  const Text('چت عمومی', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _tabController.animateTo(1); // برو به تب عمومی
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTrainerSearch() {
    // TODO: پیاده‌سازی جستجوی مربی
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('جستجوی مربی به زودی اضافه می‌شود')),
    );
  }
}
