import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_dashboard/services/trainer_client_service.dart';
import 'package:gymaipro/utils/auth_helper.dart';
import 'package:gymaipro/utils/cache_service.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MyTrainersScreen extends StatefulWidget {
  const MyTrainersScreen({super.key});

  @override
  State<MyTrainersScreen> createState() => _MyTrainersScreenState();
}

class _MyTrainersScreenState extends State<MyTrainersScreen> {
  final TrainerClientService _trainerClientService = TrainerClientService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _trainers = [];

  @override
  void initState() {
    super.initState();
    _loadTrainers();
  }

  Future<void> _loadTrainers() async {
    // Cache-first render
    final cached = await CacheService.getJsonList('trainers_screen_cache');
    if (cached != null) {
      final trainers = cached
          .map((e) => Map<String, dynamic>.from(e as Map<dynamic, dynamic>))
          .toList();
      SafeSetState.call(this, () {
        _trainers = trainers;
        _isLoading = false;
      });
    } else {
      SafeSetState.call(this, () => _isLoading = true);
    }
    try {
      final userId = await AuthHelper.getCurrentUserId();
      if (userId == null) {
        print('خطا: کاربر احراز هویت نشده');
        SafeSetState.call(this, () => _isLoading = false);
        return;
      }

      print('در حال بارگذاری مربی‌ها برای کاربر: $userId');
      final trainers = await _trainerClientService.getClientTrainers(userId);
      print('تعداد مربی‌های دریافت شده: ${trainers.length}');

      SafeSetState.call(this, () {
        _trainers = trainers;
        _isLoading = false;
      });
      // Update cache
      await CacheService.setJson('trainers_screen_cache', trainers);
    } catch (e) {
      print('خطا در بارگذاری مربی‌ها: $e');
      SafeSetState.call(this, () => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در بارگذاری مربی‌ها: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'مربی‌های من',
          style: GoogleFonts.vazirmatn(
            fontWeight: FontWeight.w700,
            fontSize: 20.sp,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF1A1A1A),
                const Color(0xFF1A1A1A).withValues(alpha: 0.8),
              ],
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppTheme.goldColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppTheme.goldColor.withValues(alpha: 0.3),
              ),
            ),
            child: IconButton(
              onPressed: _loadTrainers,
              icon: Icon(
                LucideIcons.refreshCw,
                color: AppTheme.goldColor,
                size: 20.sp,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: AppTheme.goldColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: AppTheme.goldColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const CircularProgressIndicator(
                      color: AppTheme.goldColor,
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'در حال بارگذاری مربی‌ها...',
                    style: GoogleFonts.vazirmatn(
                      color: Colors.grey[400],
                      fontSize: 16.sp,
                    ),
                  ),
                ],
              ),
            )
          : _trainers.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadTrainers,
              color: AppTheme.goldColor,
              backgroundColor: const Color(0xFF2A2A2A),
              child: ListView.builder(
                padding: EdgeInsets.all(16.w),
                itemCount: _trainers.length,
                itemBuilder: (context, index) {
                  final trainer = _trainers[index];
                  return _TrainerCard(
                    trainer: trainer,
                    onChat: () => _openChat(trainer),
                    onViewProfile: () => _viewProfile(trainer),
                    onEndRelationship: () => _endRelationship(trainer),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(32.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.goldColor.withValues(alpha: 0.1),
                    AppTheme.goldColor.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                  color: AppTheme.goldColor.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(
                LucideIcons.userX,
                size: 80.sp,
                color: AppTheme.goldColor.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'هنوز مربی‌ای ندارید',
              style: GoogleFonts.vazirmatn(
                fontSize: 24.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'برای شروع سفر ورزشی خود، یک مربی حرفه‌ای انتخاب کنید',
              style: GoogleFonts.vazirmatn(
                color: Colors.grey[400],
                fontSize: 16.sp,
                height: 1.5.h,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.goldColor,
                    AppTheme.goldColor.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.goldColor.withValues(alpha: 0.3),
                    blurRadius: 12.r,
                    offset: Offset(0.w, 4.h),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pushNamed(context, '/trainers'),
                  borderRadius: BorderRadius.circular(16.r),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 32.w,
                      vertical: 16.h,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.search,
                          color: Colors.black,
                          size: 20.sp,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'جستجوی مربی‌ها',
                          style: GoogleFonts.vazirmatn(
                            color: Colors.black,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'یا از بخش "مربی‌ها" در منوی اصلی استفاده کنید',
              style: GoogleFonts.vazirmatn(
                color: Colors.grey[500],
                fontSize: 14.sp,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _openChat(Map<String, dynamic> trainer) {
    // Navigate to chat with trainer
    final trainerData = trainer['trainer'] as Map<String, dynamic>?;
    if (trainerData == null) {
      print('خطا: اطلاعات مربی موجود نیست');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطا در دریافت اطلاعات مربی'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final trainerId = trainerData['id'];
    final trainerName = _getTrainerName(trainer);

    print('در حال باز کردن چت با مربی: $trainerName (ID: $trainerId)');

    Navigator.pushNamed(
      context,
      '/chat',
      arguments: {'otherUserId': trainerId, 'otherUserName': trainerName},
    );
  }

  void _viewProfile(Map<String, dynamic> trainer) {
    Navigator.pushNamed(
      context,
      '/trainer-profile',
      arguments: trainer['trainer_id'],
    );
  }

  Future<void> _endRelationship(Map<String, dynamic> trainer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('پایان رابطه'),
        content: const Text(
          'آیا مطمئن هستید که می‌خواهید رابطه با این مربی را پایان دهید؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لغو'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تایید'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      try {
        await _trainerClientService.endRelationship(
          trainerId: trainer['trainer_id'] as String,
          clientId: trainer['client_id'] as String,
        );
        _loadTrainers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('رابطه با مربی پایان یافت'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطا در پایان رابطه: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _getTrainerName(Map<String, dynamic> trainer) {
    final trainerData = trainer['trainer'] as Map<String, dynamic>?;
    if (trainerData == null) return 'مربی ناشناس';

    final firstName = (trainerData['first_name'] as String?) ?? '';
    final lastName = (trainerData['last_name'] as String?) ?? '';
    final username = (trainerData['username'] as String?) ?? '';

    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    } else if (firstName.isNotEmpty) {
      return firstName;
    } else if (lastName.isNotEmpty) {
      return lastName;
    } else if (username.isNotEmpty) {
      return username;
    }
    return 'مربی ناشناس';
  }
}

class _TrainerCard extends StatelessWidget {
  const _TrainerCard({
    required this.trainer,
    required this.onChat,
    required this.onViewProfile,
    required this.onEndRelationship,
  });
  final Map<String, dynamic> trainer;
  final VoidCallback onChat;
  final VoidCallback onViewProfile;
  final VoidCallback onEndRelationship;

  @override
  Widget build(BuildContext context) {
    final trainerData = trainer['trainer'] as Map<String, dynamic>?;
    final status = trainer['status'] as String? ?? 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A2A2A), Color(0xFF1F1F1F)],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: status == 'active'
              ? AppTheme.goldColor.withValues(alpha: 0.3)
              : Colors.grey[700]!,
          width: 1.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: status == 'active'
                ? AppTheme.goldColor.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.3),
            blurRadius: 8.r,
            offset: Offset(0.w, 4.h),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with avatar and info
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.goldColor,
                        AppTheme.goldColor.withValues(alpha: 0.8),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.goldColor.withValues(alpha: 0.3),
                        blurRadius: 8.r,
                        offset: Offset(0.w, 2.h),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.transparent,
                    backgroundImage: trainerData?['avatar_url'] != null
                        ? NetworkImage(trainerData!['avatar_url'] as String)
                        : null,
                    child: trainerData?['avatar_url'] == null
                        ? Icon(
                            LucideIcons.user,
                            color: Colors.black,
                            size: 24.sp,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTrainerName(trainerData),
                        style: GoogleFonts.vazirmatn(
                          fontWeight: FontWeight.w700,
                          fontSize: 18.sp,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (trainerData?['specializations'] != null)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.goldColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: AppTheme.goldColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            (trainerData!['specializations'] as List<dynamic>?)
                                    ?.join(' • ') ??
                                'تخصص ثبت نشده',
                            style: GoogleFonts.vazirmatn(
                              color: AppTheme.goldColor,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: status == 'active'
                          ? [Colors.green, Colors.green.shade600]
                          : [Colors.orange, Colors.orange.shade600],
                    ),
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (status == 'active' ? Colors.green : Colors.orange)
                                .withValues(alpha: 0.3),
                        blurRadius: 4.r,
                        offset: Offset(0.w, 2.h),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        status == 'active'
                            ? LucideIcons.checkCircle
                            : LucideIcons.clock,
                        size: 14.sp,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        status == 'active' ? 'فعال' : 'در انتظار',
                        style: GoogleFonts.vazirmatn(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Stats row
            if (trainerData != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (trainerData['rating'] != null) ...[
                    _buildStatItem(
                      LucideIcons.star,
                      '${trainerData['rating']}',
                      'امتیاز',
                      AppTheme.goldColor,
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (trainerData['experience_years'] != null) ...[
                    _buildStatItem(
                      LucideIcons.award,
                      '${trainerData['experience_years']}',
                      'سال تجربه',
                      Colors.blue,
                    ),
                  ],
                ],
              ),
            ],

            // Action buttons
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: LucideIcons.messageCircle,
                    label: 'چت',
                    color: AppTheme.goldColor,
                    onPressed: status == 'active' ? onChat : null,
                    isEnabled: status == 'active',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: LucideIcons.user,
                    label: 'پروفایل',
                    color: Colors.blue,
                    onPressed: onViewProfile,
                    isEnabled: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: LucideIcons.userX,
                    label: 'پایان',
                    color: Colors.red,
                    onPressed: onEndRelationship,
                    isEnabled: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: GoogleFonts.vazirmatn(
              color: color,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
    required bool isEnabled,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: isEnabled && onPressed != null
            ? LinearGradient(colors: [color, color.withValues(alpha: 0.8)])
            : null,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isEnabled && onPressed != null ? color : Colors.grey[600]!,
          width: 1.5.w,
        ),
        boxShadow: isEnabled && onPressed != null
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 4.r,
                  offset: Offset(0.w, 2.h),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16.sp,
                  color: isEnabled && onPressed != null
                      ? Colors.white
                      : Colors.grey[500],
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.vazirmatn(
                    color: isEnabled && onPressed != null
                        ? Colors.white
                        : Colors.grey[500],
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getTrainerName(Map<String, dynamic>? trainerData) {
    if (trainerData == null) return 'مربی ناشناس';

    final firstName = (trainerData['first_name'] as String?) ?? '';
    final lastName = (trainerData['last_name'] as String?) ?? '';
    final username = (trainerData['username'] as String?) ?? '';

    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    } else if (firstName.isNotEmpty) {
      return firstName;
    } else if (lastName.isNotEmpty) {
      return lastName;
    } else if (username.isNotEmpty) {
      return username;
    }
    return 'مربی ناشناس';
  }
}
