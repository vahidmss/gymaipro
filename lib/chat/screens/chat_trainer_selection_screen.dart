import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/chat/screens/chat_screen.dart';
import 'package:gymaipro/chat/widgets/search_bar_widget.dart';
import 'package:gymaipro/chat/widgets/user_avatar_widget.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/services/trainer_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/widgets/gymai_network_image.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:gymaipro/widgets/user_role_badge.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _trainers = [];
  List<Map<String, dynamic>> _filteredTrainers = [];
  bool _isLoading = true;
  String? _currentUserId;
  String? _userRole;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _trainerService = TrainerService();
    _loadCachedRoleAndId();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      if (!mounted) return;
      WidgetSafetyUtils.safeShowSnackBar(
        context,
        'خطا در بارگذاری ${_userRole == 'trainer' ? 'شاگردان' : 'مربیان'}: $e',
      );
    }
  }

  Future<void> _refreshData() async {
    await _loadTrainers();
  }

  void _filterTrainers(String query) {
    SafeSetState.call(this, () {
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppTheme.goldColor),
            SizedBox(height: 16.h),
            Text(
              'در حال بارگذاری...',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: context.textSecondary,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildHeader(),
        SearchBarWidget(
          controller: _searchController,
          onChanged: _filterTrainers,
          hintText: _userRole == 'trainer' ? 'جستجوی شاگرد...' : 'جستجوی مربی...',
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
            const CircularProgressIndicator(
              color: AppTheme.goldColor,
              strokeWidth: 3,
            ),
            SizedBox(height: 16.h),
            Text(
              'در حال بارگذاری...',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: context.textSecondary,
                fontSize: 14.sp,
              ),
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
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: AppTheme.goldColor.withValues(alpha: 0.2),
                ),
              ),
              child: Icon(
                LucideIcons.alertCircle,
                size: 64.sp,
                color: AppTheme.goldColor.withValues(alpha: 0.6),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              _errorMessage!,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
                color: context.textColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: context.goldGradientColors,
                ),
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.goldColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2.h),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _loadUserInfo,
                icon: const Icon(LucideIcons.refreshCw, color: AppTheme.onGoldColor),
                label: const Text(
                  'تلاش مجدد',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: AppTheme.onGoldColor,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = _userRole == 'trainer' ? 'شاگردان من' : 'مربیان';
    final subtitle = _userRole == 'trainer'
        ? 'شاگردان خود را انتخاب کنید و با آن‌ها چت کنید'
        : 'مربی مورد نظر خود را انتخاب کنید';
    final icon = _userRole == 'trainer'
        ? LucideIcons.users
        : LucideIcons.userCheck;

    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: isDark ? 0.3 : 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldColor.withValues(alpha: isDark ? 0.05 : 0.1),
            blurRadius: 8,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: context.goldGradientColors
                    .map((c) => c.withValues(alpha: 0.2))
                    .toList(),
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              icon,
              color: AppTheme.goldColor,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                    color: context.textColor,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14.sp,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final query = _searchController.text;
    final message = query.isNotEmpty
        ? 'نتیجه‌ای یافت نشد'
        : _userRole == 'trainer'
        ? 'هنوز شاگردی ندارید'
        : 'مربی‌ای یافت نشد';

    final subtitle = query.isNotEmpty
        ? 'جستجوی خود را تغییر دهید'
        : _userRole == 'trainer'
        ? 'شاگردان شما اینجا نمایش داده می‌شوند'
        : 'مربیان موجود اینجا نمایش داده می‌شوند';

    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(32.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: AppTheme.goldColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Icon(
                  query.isNotEmpty
                      ? LucideIcons.search
                      : LucideIcons.userX,
                  size: 64.sp,
                  color: AppTheme.goldColor.withValues(alpha: 0.6),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = trainer['name'] ?? 'نامشخص';
    final specialization = (trainer['specialization'] as String?) ?? '';
    final rating = trainer['rating']?.toString() ?? '0';
    final avatar = trainer['avatar'];
    final isOnline = (trainer['is_online'] as bool?) ?? false;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: isDark ? 0.2 : 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldColor.withValues(alpha: isDark ? 0.05 : 0.08),
            blurRadius: 8,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _startChat(trainer),
          onLongPress: () => _showTrainerInfo(trainer),
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                // دکمه چت
                Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: context.goldGradientColors,
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.goldColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2.h),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12.r),
                      onTap: () => _startChat(trainer),
                      child: Icon(
                        LucideIcons.messageCircle,
                        color: AppTheme.onGoldColor,
                        size: 20.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),

                // محتوا
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          Expanded(
                            child: Text(
                              name as String,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color: context.textColor,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          UserRoleBadge(
                            role: _userRole == 'trainer'
                                ? 'athlete'
                                : 'trainer',
                            fontSize: 10.sp,
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      if (specialization.isNotEmpty)
                        Text(
                          specialization,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            color: context.textSecondary,
                            fontSize: 14.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      SizedBox(height: 4.h),
                      Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          Icon(
                            LucideIcons.star,
                            color: AppTheme.goldColor,
                            size: 16.sp,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            rating,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
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
                SizedBox(width: 12.w),

                // آواتار
                UserAvatarWidget(
                  avatarUrl: avatar as String?,
                  isOnline: isOnline,
                  role: _userRole == 'trainer' ? 'athlete' : 'trainer',
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
      if (!mounted) return;
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }

  void _showTrainerInfo(Map<String, dynamic> trainer) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.cardColor,
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
                color: context.separatorColor,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  width: 60.w,
                  height: 60.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: context.goldGradientColors
                          .map((c) => c.withValues(alpha: 0.2))
                          .toList(),
                    ),
                    borderRadius: BorderRadius.circular(30.r),
                    border: Border.all(
                      color: AppTheme.goldColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: trainer['avatar'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(30.r),
                          child: GymaiNetworkImage(
                            imageUrl: trainer['avatar'] as String,
                            errorWidget: Icon(
                              _userRole == 'trainer'
                                  ? LucideIcons.user
                                  : LucideIcons.userCheck,
                              color: AppTheme.goldColor,
                              size: 30.sp,
                            ),
                          ),
                        )
                      : Icon(
                          _userRole == 'trainer'
                              ? LucideIcons.user
                              : LucideIcons.userCheck,
                          color: AppTheme.goldColor,
                          size: 30.sp,
                        ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (trainer['name'] as String?) ?? 'نامشخص',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: context.textColor,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      UserRoleBadge(
                        role: _userRole == 'trainer' ? 'athlete' : 'trainer',
                        fontSize: 12.sp,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: context.goldGradientColors,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.goldColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: Offset(0, 2.h),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _startChat(trainer);
                      },
                      icon: const Icon(
                        LucideIcons.messageCircle,
                        color: AppTheme.onGoldColor,
                      ),
                      label: const Text(
                        'شروع چت',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: AppTheme.onGoldColor,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
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
