import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../services/trainer_service.dart';
import '../../services/supabase_service.dart';
import 'chat_screen.dart';
import '../../utils/safe_set_state.dart';
import '../../widgets/user_role_badge.dart';

class ChatTrainerSelectionScreen extends StatefulWidget {
  const ChatTrainerSelectionScreen({Key? key}) : super(key: key);

  @override
  State<ChatTrainerSelectionScreen> createState() =>
      _ChatTrainerSelectionScreenState();
}

class _ChatTrainerSelectionScreenState
    extends State<ChatTrainerSelectionScreen> {
  late TrainerService _trainerService;
  late SupabaseService _supabaseService;
  List<Map<String, dynamic>> _trainers = [];
  List<Map<String, dynamic>> _filteredTrainers = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _searchQuery = '';
  String? _currentUserId;
  String? _userRole;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _trainerService = TrainerService();
    _supabaseService = SupabaseService();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = await _supabaseService.getProfileByAuthId();
      if (user != null) {
        setState(() {
          _currentUserId = user.id;
          _userRole = user.role;
          _errorMessage = null;
        });
        await _loadTrainers();
      } else {
        setState(() {
          _errorMessage = 'کاربر یافت نشد';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user info: $e');
      setState(() {
        _errorMessage = 'خطا در بارگذاری اطلاعات کاربر';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTrainers() async {
    if (_currentUserId == null) return;

    try {
      SafeSetState.call(this, () {
        _isLoading = true;
        _errorMessage = null;
      });

      List<Map<String, dynamic>> trainers = [];

      if (_userRole == 'trainer') {
        // اگر کاربر مربی است، شاگردانش را نمایش بده
        final clientsWithProfiles = await _trainerService
            .getTrainerClientsWithProfiles(_currentUserId!);
        trainers = clientsWithProfiles.map((clientData) {
          final clientProfile =
              clientData['client_profile'] as Map<String, dynamic>;
          return {
            'id': clientData['client_id'],
            'name': '${clientProfile['first_name'] ?? ''} ${clientProfile['last_name'] ?? ''}'
                    .trim()
                    .isNotEmpty
                ? '${clientProfile['first_name'] ?? ''} ${clientProfile['last_name'] ?? ''}'
                    .trim()
                : clientProfile['username'] ?? 'کاربر',
            'specialization': '',
            'rating': '0',
            'avatar': clientProfile['avatar_url'],
            'is_online': false,
            'role': clientProfile['role'] ?? 'athlete',
          };
        }).toList();
      } else {
        // اگر کاربر شاگرد است، مربیان را نمایش بده
        final trainersWithProfiles = await _trainerService
            .getClientTrainersWithProfiles(_currentUserId!);
        trainers = trainersWithProfiles.map((trainerData) {
          final trainerProfile =
              trainerData['trainer_profile'] as Map<String, dynamic>;
          return {
            'id': trainerData['trainer_id'],
            'name': '${trainerProfile['first_name'] ?? ''} ${trainerProfile['last_name'] ?? ''}'
                    .trim()
                    .isNotEmpty
                ? '${trainerProfile['first_name'] ?? ''} ${trainerProfile['last_name'] ?? ''}'
                    .trim()
                : trainerProfile['username'] ?? 'مربی',
            'specialization': trainerProfile['bio'] ?? '',
            'rating': '0',
            'avatar': trainerProfile['avatar_url'],
            'is_online': false,
            'role': trainerProfile['role'] ?? 'trainer',
          };
        }).toList();
      }

      SafeSetState.call(this, () {
        _trainers = trainers;
        _filteredTrainers = trainers;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      SafeSetState.call(this, () {
        _isLoading = false;
        _isRefreshing = false;
        _errorMessage =
            'خطا در بارگذاری ${_userRole == 'trainer' ? 'شاگردان' : 'مربیان'}';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'خطا در بارگذاری ${_userRole == 'trainer' ? 'شاگردان' : 'مربیان'}: $e')),
        );
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    await _loadTrainers();
  }

  void _filterTrainers(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredTrainers = _trainers;
      } else {
        _filteredTrainers = _trainers.where((trainer) {
          final name = trainer['name']?.toString().toLowerCase() ?? '';
          final specialization =
              trainer['specialization']?.toString().toLowerCase() ?? '';
          return name.contains(query.toLowerCase()) ||
              specialization.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildSearchBar(),
        Expanded(
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.goldColor),
            SizedBox(height: 16),
            Text(
              'در حال بارگذاری...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_filteredTrainers.isEmpty) {
      return _buildEmptyState();
    }

    return _buildTrainersList();
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              LucideIcons.alertCircle,
              size: 64,
              color: Colors.red.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _errorMessage!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadUserInfo,
            icon: const Icon(LucideIcons.refreshCw),
            label: const Text('تلاش مجدد'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.goldColor,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final title = _userRole == 'trainer' ? 'شاگردان من' : 'مربیان';
    final subtitle = _userRole == 'trainer'
        ? 'شاگردان خود را انتخاب کنید و با آن‌ها چت کنید'
        : 'مربی مورد نظر خود را انتخاب کنید';
    final icon =
        _userRole == 'trainer' ? LucideIcons.users : LucideIcons.userCheck;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (_userRole == 'trainer' ? Colors.green : Colors.purple)
                  .withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: _userRole == 'trainer' ? Colors.green : Colors.purple,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText:
              'جستجو در ${_userRole == 'trainer' ? 'شاگردان' : 'مربیان'}...',
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            LucideIcons.search,
            color: AppTheme.goldColor,
            size: 20,
          ),
          filled: true,
          fillColor: AppTheme.cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppTheme.goldColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppTheme.goldColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: AppTheme.goldColor,
              width: 2,
            ),
          ),
        ),
        onChanged: _filterTrainers,
      ),
    );
  }

  Widget _buildEmptyState() {
    final message = _searchQuery.isNotEmpty
        ? 'نتیجه‌ای یافت نشد'
        : _userRole == 'trainer'
            ? 'هنوز شاگردی ندارید'
            : 'مربی‌ای یافت نشد';

    final subtitle = _searchQuery.isNotEmpty
        ? 'جستجوی خود را تغییر دهید'
        : _userRole == 'trainer'
            ? 'شاگردان شما اینجا نمایش داده می‌شوند'
            : 'مربیان موجود اینجا نمایش داده می‌شوند';

    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                _searchQuery.isNotEmpty
                    ? LucideIcons.search
                    : LucideIcons.userX,
                size: 64,
                color: AppTheme.goldColor.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainersList() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppTheme.goldColor,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filteredTrainers.length,
        itemBuilder: (context, index) {
          final trainer = _filteredTrainers[index];
          return _buildTrainerTile(trainer);
        },
      ),
    );
  }

  Widget _buildTrainerTile(Map<String, dynamic> trainer) {
    final name = trainer['name'] ?? 'نامشخص';
    final specialization = trainer['specialization'] ?? '';
    final rating = trainer['rating']?.toString() ?? '0';
    final avatar = trainer['avatar'];
    final isOnline = trainer['is_online'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _startChat(trainer),
          onLongPress: () => _showTrainerInfo(trainer),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // آواتار
                Stack(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: (_userRole == 'trainer'
                                ? Colors.green
                                : Colors.purple)
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: avatar != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: Image.network(
                                avatar,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    _userRole == 'trainer'
                                        ? LucideIcons.user
                                        : LucideIcons.userCheck,
                                    color: _userRole == 'trainer'
                                        ? Colors.green
                                        : Colors.purple,
                                    size: 28,
                                  );
                                },
                              ),
                            )
                          : Icon(
                              _userRole == 'trainer'
                                  ? LucideIcons.user
                                  : LucideIcons.userCheck,
                              color: _userRole == 'trainer'
                                  ? Colors.green
                                  : Colors.purple,
                              size: 28,
                            ),
                    ),
                    if (isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppTheme.backgroundColor, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),

                // محتوا
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          UserRoleBadge(
                            role:
                                _userRole == 'trainer' ? 'athlete' : 'trainer',
                            fontSize: 10,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (specialization.isNotEmpty)
                        Text(
                          specialization,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.star,
                            color: AppTheme.goldColor,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating,
                            style: const TextStyle(
                              color: AppTheme.goldColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // دکمه چت
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.goldColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      LucideIcons.messageCircle,
                      color: Colors.black,
                      size: 20,
                    ),
                    onPressed: () => _startChat(trainer),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startChat(Map<String, dynamic> trainer) {
    final trainerId = trainer['id'];
    final trainerName = trainer['name'] ?? 'نامشخص';

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppTheme.goldColor),
      ),
    );

    // Navigate to chat screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          otherUserId: trainerId,
          otherUserName: trainerName,
        ),
      ),
    ).then((_) {
      // Close loading dialog if still showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }

  void _showTrainerInfo(Map<String, dynamic> trainer) {
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
            Container(
              width: 60,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color:
                        (_userRole == 'trainer' ? Colors.green : Colors.purple)
                            .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: trainer['avatar'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Image.network(
                            trainer['avatar'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                _userRole == 'trainer'
                                    ? LucideIcons.user
                                    : LucideIcons.userCheck,
                                color: _userRole == 'trainer'
                                    ? Colors.green
                                    : Colors.purple,
                                size: 30,
                              );
                            },
                          ),
                        )
                      : Icon(
                          _userRole == 'trainer'
                              ? LucideIcons.user
                              : LucideIcons.userCheck,
                          color: _userRole == 'trainer'
                              ? Colors.green
                              : Colors.purple,
                          size: 30,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trainer['name'] ?? 'نامشخص',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      UserRoleBadge(
                        role: _userRole == 'trainer' ? 'athlete' : 'trainer',
                        fontSize: 12,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _startChat(trainer);
                    },
                    icon: const Icon(LucideIcons.messageCircle),
                    label: const Text('شروع چت'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.goldColor,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
