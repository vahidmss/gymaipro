import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/chat/screens/chat_screen.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/services/trainer_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:gymaipro/chat/widgets/user_avatar_widget.dart';
import 'package:gymaipro/chat/widgets/search_bar_widget.dart';
import 'package:gymaipro/widgets/user_role_badge.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatTrainerSelectionScreen extends StatefulWidget {
  const ChatTrainerSelectionScreen({super.key});

  @override
  State<ChatTrainerSelectionScreen> createState() =>
      _ChatTrainerSelectionScreenState();
}

class _ChatTrainerSelectionScreenState
    extends State<ChatTrainerSelectionScreen> {
  late TrainerService _trainerService;
  // SupabaseService usage removed
  // Profile via SimpleProfileService adapter
  List<Map<String, dynamic>> _trainers = [];
  List<Map<String, dynamic>> _filteredTrainers = [];
  bool _isLoading = true;
  // bool _isRefreshing = false;
  String _searchQuery = '';
  String? _currentUserId;
  String? _userRole;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _trainerService = TrainerService();
    // SimpleProfileService is static; no instance needed
    _loadCachedRoleAndId();
    _loadUserInfo();
  }

  Future<void> _loadCachedRoleAndId() async {
    try {
      // Load cached role to render correct tab instantly
      final prefs = await SharedPreferences.getInstance();
      final cachedRole = prefs.getString('cached_user_role');
      final authUser = Supabase.instance.client.auth.currentUser;
      if (mounted) {
        SafeSetState.call(this, () {
          _userRole = cachedRole ?? _userRole;
          _currentUserId = authUser?.id ?? _currentUserId;
        });
      }
      // If both are available, pre-load list without waiting for full profile
      if (_userRole != null && _currentUserId != null) {
        // Fire-and-forget without requiring unawaited helper
        // ignore: discarded_futures
        _loadTrainers();
      }
    } catch (_) {}
  }

  Future<void> _loadUserInfo() async {
    try {
      final profile = await SimpleProfileService.getCurrentProfile();
      if (profile != null) {
        SafeSetState.call(this, () {
          _currentUserId = profile['id'] as String?;
          _userRole = profile['role'] as String?;
          _errorMessage = null;
        });
        if (!mounted) return;
        await _loadTrainers();
      } else {
        SafeSetState.call(this, () {
          _errorMessage = 'کاربر یافت نشد';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user info: $e');
      SafeSetState.call(this, () {
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
            'name':
                '${clientProfile['first_name'] ?? ''} ${clientProfile['last_name'] ?? ''}'
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
            'name':
                '${trainerProfile['first_name'] ?? ''} ${trainerProfile['last_name'] ?? ''}'
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
      });
    } catch (e) {
      SafeSetState.call(this, () {
        _isLoading = false;
        _errorMessage =
            'خطا در بارگذاری ${_userRole == 'trainer' ? 'شاگردان' : 'مربیان'}';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا در بارگذاری ${_userRole == 'trainer' ? 'شاگردان' : 'مربیان'}: $e',
            ),
          ),
        );
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadTrainers();
  }

  void _filterTrainers(String query) {
    SafeSetState.call(this, () {
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
    if (_userRole == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.goldColor),
      );
    }

    return Column(
      children: [
        _buildHeader(),
        SearchBarWidget(
          controller: TextEditingController(text: _searchQuery),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
              _filterTrainers(value);
            });
          },
          hintText: 'جستجوی مربی...',
        ),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppTheme.goldColor),
            const SizedBox(height: 16),
            Text('در حال بارگذاری...', style: AppTheme.bodyStyle),
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
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Icon(
              LucideIcons.alertCircle,
              size: 64.sp,
              color: AppTheme.goldColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _errorMessage!,
            style: AppTheme.headingStyle.copyWith(fontSize: 18.sp),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadUserInfo,
            icon: const Icon(LucideIcons.refreshCw),
            label: const Text('تلاش مجدد'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.goldColor,
              foregroundColor: AppTheme.textColor,
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
    final icon = _userRole == 'trainer'
        ? LucideIcons.users
        : LucideIcons.userCheck;

    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppTheme.goldColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color:
                  (_userRole == 'trainer'
                          ? AppTheme.goldColor
                          : AppTheme.primaryColor)
                      .withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              icon,
              color: _userRole == 'trainer'
                  ? AppTheme.goldColor
                  : AppTheme.primaryColor,
              size: 24.sp,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.headingStyle.copyWith(fontSize: 18.sp),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTheme.bodyStyle.copyWith(fontSize: 14.sp),
                ),
              ],
            ),
          ),
        ],
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
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Icon(
                _searchQuery.isNotEmpty
                    ? LucideIcons.search
                    : LucideIcons.userX,
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
    final specialization = (trainer['specialization'] as String?) ?? '';
    final rating = trainer['rating']?.toString() ?? '0';
    final avatar = trainer['avatar'];
    final isOnline = (trainer['is_online'] as bool?) ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppTheme.goldColor.withValues(alpha: 0.2)),
      ),
      child: Material(
        color: AppTheme.backgroundColor,
        child: InkWell(
          onTap: () => _startChat(trainer),
          onLongPress: () => _showTrainerInfo(trainer),
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                // آواتار
                UserAvatarWidget(
                  avatarUrl: avatar as String?,
                  isOnline: isOnline,
                  role: _userRole == 'trainer' ? 'athlete' : 'trainer',
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
                              name as String,
                              style: TextStyle(
                                color: AppTheme.textColor,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          UserRoleBadge(
                            role: _userRole == 'trainer'
                                ? 'athlete'
                                : 'trainer',
                            fontSize: 10.sp,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (specialization.isNotEmpty)
                        Text(
                          specialization,
                          style: TextStyle(
                            color: AppTheme.bodyStyle.color,
                            fontSize: 14.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.star,
                            color: AppTheme.goldColor,
                            size: 16.sp,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating,
                            style: TextStyle(
                              color: AppTheme.goldColor,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // دکمه چت
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppTheme.goldColor,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: IconButton(
                    icon: Icon(
                      LucideIcons.messageCircle,
                      color: AppTheme.textColor,
                      size: 20.sp,
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
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppTheme.goldColor),
      ),
    );

    // Navigate to chat screen
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => ChatScreen(
          otherUserId: trainerId as String,
          otherUserName: trainerName as String,
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
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: (AppTheme.bodyStyle.color ?? AppTheme.textColor)
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 60.w,
                  height: 60.h,
                  decoration: BoxDecoration(
                    color:
                        (_userRole == 'trainer'
                                ? AppTheme.goldColor
                                : AppTheme.primaryColor)
                            .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                  child: trainer['avatar'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(30.r),
                          child: Image.network(
                            trainer['avatar'] as String,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                _userRole == 'trainer'
                                    ? LucideIcons.user
                                    : LucideIcons.userCheck,
                                color: _userRole == 'trainer'
                                    ? AppTheme.goldColor
                                    : AppTheme.primaryColor,
                                size: 30.sp,
                              );
                            },
                          ),
                        )
                      : Icon(
                          _userRole == 'trainer'
                              ? LucideIcons.user
                              : LucideIcons.userCheck,
                          color: _userRole == 'trainer'
                              ? AppTheme.goldColor
                              : AppTheme.primaryColor,
                          size: 30.sp,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (trainer['name'] as String?) ?? 'نامشخص',
                        style: TextStyle(
                          color: AppTheme.textColor,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      UserRoleBadge(
                        role: _userRole == 'trainer' ? 'athlete' : 'trainer',
                        fontSize: 12.sp,
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
                      foregroundColor: AppTheme.textColor,
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
