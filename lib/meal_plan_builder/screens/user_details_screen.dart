import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/services/fitness_calculator.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/widgets/gymai_network_image.dart';
import 'package:gymaipro/user_profile/services/user_profile_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserDetailsScreenMealPlanBuilder extends StatefulWidget {
  const UserDetailsScreenMealPlanBuilder({
    required this.userId,
    required this.userName,
    super.key,
  });

  final String userId;
  final String userName;

  @override
  State<UserDetailsScreenMealPlanBuilder> createState() =>
      _UserDetailsScreenMealPlanBuilderState();
}

class _UserDetailsScreenMealPlanBuilderState
    extends State<UserDetailsScreenMealPlanBuilder> {
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _confidentialData;
  bool _isLoading = true;
  final Map<String, bool> _expansionStates = {
    'profile': false,
    'confidential': false,
    'trainer_tools': true,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // بارگذاری پروفایل
      _profile = await UserProfileService.fetchProfile(widget.userId);

      // بارگذاری اطلاعات محرمانه - همیشه تلاش می‌کنیم حتی اگر consent نداشته باشد
      final supabase = Supabase.instance.client;
      try {
        final confRow = await supabase
            .from('confidential_user_info')
            .select()
            .eq('profile_id', widget.userId)
            .maybeSingle();
        if (confRow != null) {
          _confidentialData = Map<String, dynamic>.from(confRow);
          debugPrint('=== اطلاعات محرمانه دریافت شد ===');
          debugPrint('کلیدها: ${_confidentialData?.keys.toList()}');
          debugPrint(
            'body_measurements نوع: ${_confidentialData?['body_measurements'].runtimeType}',
          );
          debugPrint(
            'body_measurements مقدار: ${_confidentialData?['body_measurements']}',
          );
          debugPrint(
            'health_info نوع: ${_confidentialData?['health_info'].runtimeType}',
          );
          debugPrint('health_info مقدار: ${_confidentialData?['health_info']}');
          debugPrint(
            'fitness_goals نوع: ${_confidentialData?['fitness_goals'].runtimeType}',
          );
          debugPrint('fitness_goals مقدار: ${_confidentialData?['fitness_goals']}');
          debugPrint(
            'lifestyle_preferences نوع: ${_confidentialData?['lifestyle_preferences'].runtimeType}',
          );
          debugPrint(
            'lifestyle_preferences مقدار: ${_confidentialData?['lifestyle_preferences']}',
          );
          debugPrint('notes: ${_confidentialData?['notes']}');
          debugPrint('has_consented: ${_confidentialData?['has_consented']}');
          debugPrint(
            'lifestyle_preferences نوع: ${_confidentialData?['lifestyle_preferences'].runtimeType}',
          );
          debugPrint(
            'lifestyle_preferences مقدار: ${_confidentialData?['lifestyle_preferences']}',
          );
          debugPrint('================================');
        } else {
          debugPrint('⚠️ اطلاعات محرمانه یافت نشد - confRow null است');
        }
      } catch (e) {
        debugPrint('خطا در دریافت اطلاعات محرمانه: $e');
      }
    } catch (e) {
      debugPrint('خطا در بارگذاری اطلاعات: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatJalali(DateTime? dt) {
    if (dt == null) return '-';
    final j = Jalali.fromDateTime(dt);
    return '${j.year}/${j.month.toString().padLeft(2, '0')}/${j.day.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    return _formatJalali(dt);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: screenHeight * 0.9,
        decoration: BoxDecoration(
          color: isDark ? context.backgroundColor : context.cardColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30.r),
            topRight: Radius.circular(30.r),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppTheme.goldColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'مشخصات ${widget.userName}',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: isDark ? AppTheme.goldColor : context.textColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 20.sp,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      LucideIcons.x,
                      color: isDark ? AppTheme.goldColor : context.textColor,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(
              color: AppTheme.goldColor.withValues(alpha: 0.2),
              height: 1,
            ),
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: EdgeInsets.only(bottom: 32.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // عکس پروفایل و اطلاعات اصلی
                          _buildProfileHeader(isDark),
                          SizedBox(height: 12.h),
                          // شاخص‌های مربی
                          _buildTrainerToolsSection(isDark),
                          SizedBox(height: 12.h),
                          // اطلاعات پروفایل (پیش‌فرض بسته)
                          if (_profile != null)
                            _buildExpandableSection(
                              isDark: isDark,
                              key: 'profile',
                              title: 'اطلاعات پروفایل',
                              icon: LucideIcons.user,
                              child: _buildProfileInfoContent(isDark),
                            ),
                          SizedBox(height: 12.h),
                          // اطلاعات محرمانه (پیش‌فرض بسته)
                          _buildExpandableSection(
                            isDark: isDark,
                            key: 'confidential',
                            title: 'اطلاعات محرمانه',
                            icon: LucideIcons.lock,
                            child: _buildConfidentialInfoContent(isDark),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _surfaceDecoration(bool isDark) {
    return BoxDecoration(
      color: isDark ? AppTheme.darkCardColor : Colors.white,
      borderRadius: BorderRadius.circular(14.r),
      border: Border.all(
        color: AppTheme.goldColor.withValues(alpha: isDark ? 0.2 : 0.22),
      ),
    );
  }

  Widget _buildProfileHeader(bool isDark) {
    final avatarUrl = _profile?['avatar_url']?.toString() ?? '';
    final firstName = _profile?['first_name']?.toString() ?? '';
    final lastName = _profile?['last_name']?.toString() ?? '';
    final username = _profile?['username']?.toString() ?? '';
    final role = _profile?['role']?.toString() ?? 'athlete';
    final displayName = [
      firstName,
      lastName,
    ].where((n) => n.isNotEmpty).join(' ').trim();
    final finalName = displayName.isNotEmpty ? displayName : username;

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: _surfaceDecoration(isDark),
        child: Row(
          children: [
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.goldColor.withValues(alpha: 0.35),
                ),
              ),
              child: ClipOval(
                child: avatarUrl.isNotEmpty && avatarUrl != 'null'
                    ? GymaiNetworkImage(
                        imageUrl: avatarUrl,
                        errorWidget: Icon(
                          LucideIcons.user,
                          color: AppTheme.goldColor,
                          size: 22.sp,
                        ),
                      )
                    : Icon(
                        LucideIcons.user,
                        color: AppTheme.goldColor,
                        size: 22.sp,
                      ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    finalName.isNotEmpty ? finalName : widget.userName,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: isDark ? AppTheme.goldColor : context.textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 15.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (username.isNotEmpty)
                    Text(
                      '@$username',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: isDark
                            ? AppTheme.goldColor.withValues(alpha: 0.65)
                            : context.textColor.withValues(alpha: 0.55),
                        fontSize: 12.sp,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: AppTheme.goldColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                role == 'trainer' ? 'مربی' : 'ورزشکار',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: AppTheme.goldColor,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfoContent(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(
          isDark: isDark,
          label: 'نام',
          value: _profile?['first_name']?.toString() ?? '-',
          icon: LucideIcons.user,
        ),
        _buildInfoRow(
          isDark: isDark,
          label: 'نام خانوادگی',
          value: _profile?['last_name']?.toString() ?? '-',
          icon: LucideIcons.user,
        ),
        _buildInfoRow(
          isDark: isDark,
          label: 'نام کاربری',
          value: _profile?['username']?.toString() ?? '-',
          icon: LucideIcons.atSign,
        ),
        _buildInfoRow(
          isDark: isDark,
          label: 'شماره تلفن',
          value: _profile?['phone_number']?.toString() ?? '-',
          icon: LucideIcons.phone,
        ),
        _buildInfoRow(
          isDark: isDark,
          label: 'جنسیت',
          value: _getGenderLabel(_profile?['gender']?.toString()),
          icon: LucideIcons.user,
        ),
        if (_profile?['birth_date'] != null)
          _buildInfoRow(
            isDark: isDark,
            label: 'تاریخ تولد',
            value: _formatDate(
              DateTime.tryParse(_profile!['birth_date'].toString()),
            ),
            icon: LucideIcons.calendar,
          ),
        if (_profile?['height'] != null)
          _buildInfoRow(
            isDark: isDark,
            label: 'قد',
            value: '${_profile!['height']} سانتی‌متر',
            icon: LucideIcons.ruler,
          ),
        if (_profile?['weight'] != null)
          _buildInfoRow(
            isDark: isDark,
            label: 'وزن',
            value: '${_profile!['weight']} کیلوگرم',
            icon: LucideIcons.scale,
          ),
        if (_profile?['arm_circumference'] != null)
          _buildInfoRow(
            isDark: isDark,
            label: 'دور بازو',
            value: '${_profile!['arm_circumference']} سانتی‌متر',
            icon: LucideIcons.ruler,
          ),
        if (_profile?['chest_circumference'] != null)
          _buildInfoRow(
            isDark: isDark,
            label: 'دور سینه',
            value: '${_profile!['chest_circumference']} سانتی‌متر',
            icon: LucideIcons.ruler,
          ),
        if (_profile?['waist_circumference'] != null)
          _buildInfoRow(
            isDark: isDark,
            label: 'دور کمر',
            value: '${_profile!['waist_circumference']} سانتی‌متر',
            icon: LucideIcons.ruler,
          ),
        if (_profile?['hip_circumference'] != null)
          _buildInfoRow(
            isDark: isDark,
            label: 'دور باسن',
            value: '${_profile!['hip_circumference']} سانتی‌متر',
            icon: LucideIcons.ruler,
          ),
        if (_profile?['experience_level'] != null)
          _buildInfoRow(
            isDark: isDark,
            label: 'سطح تجربه',
            value: _getExperienceLevelLabel(
              _profile!['experience_level'].toString(),
            ),
            icon: LucideIcons.award,
          ),
        if (_profile?['preferred_training_days'] != null &&
            (_profile!['preferred_training_days'] as List).isNotEmpty)
          _buildInfoRow(
            isDark: isDark,
            label: 'روزهای تمرین ترجیحی',
            value: (_profile!['preferred_training_days'] as List)
                .map((e) => e.toString())
                .join('، '),
            icon: LucideIcons.calendar,
            isMultiline: true,
          ),
        if (_profile?['preferred_training_time'] != null)
          _buildInfoRow(
            isDark: isDark,
            label: 'زمان تمرین ترجیحی',
            value: _profile!['preferred_training_time'].toString(),
            icon: LucideIcons.clock,
          ),
        if (_profile?['fitness_goals'] != null &&
            (_profile!['fitness_goals'] as List).isNotEmpty)
          _buildInfoRow(
            isDark: isDark,
            label: 'اهداف تناسب اندام',
            value: (_profile!['fitness_goals'] as List)
                .map((e) => e.toString())
                .join('، '),
            icon: LucideIcons.target,
            isMultiline: true,
          ),
        if (_profile?['medical_conditions'] != null &&
            (_profile!['medical_conditions'] as List).isNotEmpty)
          _buildInfoRow(
            isDark: isDark,
            label: 'شرایط پزشکی',
            value: (_profile!['medical_conditions'] as List)
                .map((e) => e.toString())
                .join('، '),
            icon: LucideIcons.heart,
            isMultiline: true,
          ),
        if (_profile?['dietary_preferences'] != null &&
            (_profile!['dietary_preferences'] as List).isNotEmpty)
          _buildInfoRow(
            isDark: isDark,
            label: 'ترجیحات غذایی',
            value: (_profile!['dietary_preferences'] as List)
                .map((e) => e.toString())
                .join('، '),
            icon: LucideIcons.utensils,
            isMultiline: true,
          ),
        if (_profile?['bio'] != null && _profile!['bio'].toString().isNotEmpty)
          _buildInfoRow(
            isDark: isDark,
            label: 'بیوگرافی',
            value: _profile!['bio'].toString(),
            icon: LucideIcons.fileText,
            isMultiline: true,
          ),
        if (_profile?['activity_level'] != null)
          _buildInfoRow(
            isDark: isDark,
            label: 'میزان فعالیت',
            value: _getActivityLevelLabel(
              _profile!['activity_level'].toString(),
            ),
            icon: LucideIcons.activity,
          ),
      ],
    );
  }

  Widget _buildConfidentialInfoContent(bool isDark) {
    final children = <Widget>[];

    if (_confidentialData == null) {
      return Padding(
        padding: EdgeInsets.only(bottom: 12.h),
        child: Text(
          'اطلاعات محرمانه‌ای ثبت نشده است',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: isDark
                ? AppTheme.goldColor.withValues(alpha: 0.7)
                : context.textColor.withValues(alpha: 0.7),
            fontSize: 14.sp,
          ),
        ),
      );
    }

    // اندازه‌گیری‌های بدن
    final bodyMeasurements = _confidentialData!['body_measurements'];
    Map<String, dynamic>? bm;
    if (bodyMeasurements != null) {
      if (bodyMeasurements is Map) {
        bm = bodyMeasurements as Map<String, dynamic>;
      } else if (bodyMeasurements is String) {
        // اگر JSONB به صورت string برگردد
        try {
          final decoded = jsonDecode(bodyMeasurements);
          if (decoded is Map) {
            bm = Map<String, dynamic>.from(decoded);
          }
          debugPrint('body_measurements parsed from String');
        } catch (e) {
          debugPrint('خطا در parse body_measurements: $e');
        }
      }
    }
    if (bm != null && bm.isNotEmpty) {
      children.addAll([
        if (bm['height'] != null)
          _buildInfoRow(
            isDark: isDark,
            label: 'قد',
            value: '${bm['height']} سانتی‌متر',
            icon: LucideIcons.ruler,
          ),
        if (bm['weight'] != null)
          _buildInfoRow(
            isDark: isDark,
            label: 'وزن',
            value: '${bm['weight']} کیلوگرم',
            icon: LucideIcons.scale,
          ),
        if (bm['body_fat_percentage'] != null)
          _buildInfoRow(
            isDark: isDark,
            label: 'درصد چربی بدن',
            value: '${bm['body_fat_percentage']}%',
            icon: LucideIcons.percent,
          ),
        if (bm['muscle_mass'] != null)
          _buildInfoRow(
            isDark: isDark,
            label: 'توده عضلانی',
            value: '${bm['muscle_mass']} کیلوگرم',
            icon: LucideIcons.dumbbell,
          ),
        if (bm['chest_circumference'] != null)
          _buildInfoRow(
            isDark: isDark,
            label: 'دور سینه',
            value: '${bm['chest_circumference']} سانتی‌متر',
            icon: LucideIcons.ruler,
          ),
        if (bm['waist_circumference'] != null)
          _buildInfoRow(
            isDark: isDark,
            label: 'دور کمر',
            value: '${bm['waist_circumference']} سانتی‌متر',
            icon: LucideIcons.ruler,
          ),
        if (bm['hip_circumference'] != null)
          _buildInfoRow(
            isDark: isDark,
            label: 'دور باسن',
            value: '${bm['hip_circumference']} سانتی‌متر',
            icon: LucideIcons.ruler,
          ),
        if (bm['arm_circumference'] != null)
          _buildInfoRow(
            isDark: isDark,
            label: 'دور بازو',
            value: '${bm['arm_circumference']} سانتی‌متر',
            icon: LucideIcons.ruler,
          ),
        if (bm['thigh_circumference'] != null)
          _buildInfoRow(
            isDark: isDark,
            label: 'دور ران',
            value: '${bm['thigh_circumference']} سانتی‌متر',
            icon: LucideIcons.ruler,
          ),
        if (bm['neck_circumference'] != null)
          _buildInfoRow(
            isDark: isDark,
            label: 'دور گردن',
            value: '${bm['neck_circumference']} سانتی‌متر',
            icon: LucideIcons.ruler,
          ),
      ]);
    }

    // اطلاعات سلامت - از lifestyle_preferences خوانده می‌شود
    // (این بخش بعد از parse کردن lifestyle_preferences اضافه می‌شود)

    // یادداشت‌های محرمانه
    if (_confidentialData!['notes'] != null &&
        _confidentialData!['notes'].toString().isNotEmpty) {
      children.add(
        _buildInfoRow(
          isDark: isDark,
          label: 'یادداشت‌های محرمانه',
          value: _confidentialData!['notes'].toString(),
          icon: LucideIcons.fileText,
          isMultiline: true,
        ),
      );
    }

    // تنظیمات سبک زندگی و اطلاعات سلامت و اهداف تناسب اندام
    // همه این اطلاعات در lifestyle_preferences ذخیره می‌شوند
    final lifestylePrefs = _confidentialData!['lifestyle_preferences'];
    Map<String, dynamic>? lp;
    if (lifestylePrefs != null) {
      if (lifestylePrefs is Map) {
        lp = lifestylePrefs as Map<String, dynamic>;
      } else if (lifestylePrefs is String) {
        try {
          final decoded = jsonDecode(lifestylePrefs);
          if (decoded is Map) {
            lp = Map<String, dynamic>.from(decoded);
          }
          debugPrint('lifestyle_preferences parsed from String');
        } catch (e) {
          debugPrint('خطا در parse lifestyle_preferences: $e');
        }
      }
    }
    if (lp != null && lp.isNotEmpty) {
      // اطلاعات سلامت
      if (lp['medical_conditions'] != null &&
          lp['medical_conditions'].toString().isNotEmpty) {
        // اگر string است که با ویرگول جدا شده، split می‌کنیم
        final medicalConditions = lp['medical_conditions'].toString();
        children.add(
          _buildInfoRow(
            isDark: isDark,
            label: 'شرایط پزشکی',
            value: medicalConditions,
            icon: LucideIcons.heart,
            isMultiline: true,
          ),
        );
      }
      if (lp['medications'] != null &&
          lp['medications'].toString().isNotEmpty) {
        children.add(
          _buildInfoRow(
            isDark: isDark,
            label: 'داروهای مصرفی',
            value: lp['medications'].toString(),
            icon: LucideIcons.pill,
            isMultiline: true,
          ),
        );
      }
      if (lp['allergies'] != null && lp['allergies'].toString().isNotEmpty) {
        children.add(
          _buildInfoRow(
            isDark: isDark,
            label: 'آلرژی‌ها',
            value: lp['allergies'].toString(),
            icon: LucideIcons.alertCircle,
            isMultiline: true,
          ),
        );
      }
      if (lp['emergency_contact'] != null &&
          lp['emergency_contact'].toString().isNotEmpty) {
        children.add(
          _buildInfoRow(
            isDark: isDark,
            label: 'تماس اضطراری',
            value: lp['emergency_contact'].toString(),
            icon: LucideIcons.phone,
          ),
        );
      }
      if (lp['doctor_name'] != null &&
          lp['doctor_name'].toString().isNotEmpty) {
        children.add(
          _buildInfoRow(
            isDark: isDark,
            label: 'نام پزشک',
            value: lp['doctor_name'].toString(),
            icon: LucideIcons.user,
          ),
        );
      }
      if (lp['doctor_phone'] != null &&
          lp['doctor_phone'].toString().isNotEmpty) {
        children.add(
          _buildInfoRow(
            isDark: isDark,
            label: 'تلفن پزشک',
            value: lp['doctor_phone'].toString(),
            icon: LucideIcons.phone,
          ),
        );
      }
      if (lp['health_notes'] != null &&
          lp['health_notes'].toString().isNotEmpty) {
        children.add(
          _buildInfoRow(
            isDark: isDark,
            label: 'یادداشت‌های سلامت',
            value: lp['health_notes'].toString(),
            icon: LucideIcons.fileText,
            isMultiline: true,
          ),
        );
      }

      // اهداف تناسب اندام
      if (lp['primary_goals'] != null &&
          lp['primary_goals'].toString().isNotEmpty) {
        children.add(
          _buildInfoRow(
            isDark: isDark,
            label: 'اهداف اصلی',
            value: lp['primary_goals'].toString(),
            icon: LucideIcons.target,
            isMultiline: true,
          ),
        );
      }
      if (lp['secondary_goals'] != null &&
          lp['secondary_goals'].toString().isNotEmpty) {
        children.add(
          _buildInfoRow(
            isDark: isDark,
            label: 'اهداف فرعی',
            value: lp['secondary_goals'].toString(),
            icon: LucideIcons.target,
            isMultiline: true,
          ),
        );
      }
      if (lp['target_weight'] != null &&
          lp['target_weight'].toString().isNotEmpty) {
        children.add(
          _buildInfoRow(
            isDark: isDark,
            label: 'وزن هدف',
            value: lp['target_weight'].toString(),
            icon: LucideIcons.scale,
          ),
        );
      }
      if (lp['target_body_fat'] != null &&
          lp['target_body_fat'].toString().isNotEmpty) {
        children.add(
          _buildInfoRow(
            isDark: isDark,
            label: 'درصد چربی هدف',
            value: lp['target_body_fat'].toString(),
            icon: LucideIcons.percent,
          ),
        );
      }
      if (lp['motivation'] != null && lp['motivation'].toString().isNotEmpty) {
        children.add(
          _buildInfoRow(
            isDark: isDark,
            label: 'انگیزه/چالش‌ها',
            value: lp['motivation'].toString(),
            icon: LucideIcons.heart,
            isMultiline: true,
          ),
        );
      }

      // تنظیمات سبک زندگی
      if (lp['life_conditions'] != null &&
          lp['life_conditions'].toString().isNotEmpty) {
        children.add(
          _buildInfoRow(
            isDark: isDark,
            label: 'شرایط زندگی',
            value: lp['life_conditions'].toString(),
            icon: LucideIcons.home,
            isMultiline: true,
          ),
        );
      }
      if (lp['food_preferences'] != null &&
          lp['food_preferences'].toString().isNotEmpty) {
        children.add(
          _buildInfoRow(
            isDark: isDark,
            label: 'ترجیحات غذایی',
            value: lp['food_preferences'].toString(),
            icon: LucideIcons.utensils,
            isMultiline: true,
          ),
        );
      }
      if (lp['sleep_pattern'] != null &&
          lp['sleep_pattern'].toString().isNotEmpty) {
        children.add(
          _buildInfoRow(
            isDark: isDark,
            label: 'الگوی خواب',
            value: lp['sleep_pattern'].toString(),
            icon: LucideIcons.moon,
          ),
        );
      }
      if (lp['smoking'] != null && lp['smoking'].toString().isNotEmpty) {
        children.add(
          _buildInfoRow(
            isDark: isDark,
            label: 'مصرف سیگار',
            value: lp['smoking'].toString(),
            icon: LucideIcons.cigarette,
          ),
        );
      }
      if (lp['alcohol'] != null && lp['alcohol'].toString().isNotEmpty) {
        children.add(
          _buildInfoRow(
            isDark: isDark,
            label: 'مصرف الکل',
            value: lp['alcohol'].toString(),
            icon: LucideIcons.wine,
          ),
        );
      }
      if (lp['additional_info'] != null &&
          lp['additional_info'].toString().isNotEmpty) {
        children.add(
          _buildInfoRow(
            isDark: isDark,
            label: 'اطلاعات اضافی',
            value: lp['additional_info'].toString(),
            icon: LucideIcons.info,
            isMultiline: true,
          ),
        );
      }
    }

    // تنظیمات عکس
    if (_confidentialData!['photos_visible_to_trainer'] != null) {
      children.add(
        _buildInfoRow(
          isDark: isDark,
          label: 'نمایش عکس‌ها برای مربی',
          value: _confidentialData!['photos_visible_to_trainer'] == true
              ? 'بله'
              : 'خیر',
          icon: LucideIcons.camera,
        ),
      );
    }

    if (_confidentialData!['last_photo_at'] != null) {
      final lastPhotoDate = DateTime.tryParse(
        _confidentialData!['last_photo_at'].toString(),
      );
      if (lastPhotoDate != null) {
        children.add(
          _buildInfoRow(
            isDark: isDark,
            label: 'آخرین عکس ثبت شده',
            value: _formatDate(lastPhotoDate),
            icon: LucideIcons.calendar,
          ),
        );
      }
    }

    // وضعیت رضایت
    if (_confidentialData!['has_consented'] != null) {
      children.add(
        _buildInfoRow(
          isDark: isDark,
          label: 'وضعیت رضایت',
          value: _confidentialData!['has_consented'] == true
              ? 'رضایت داده شده'
              : 'رضایت داده نشده',
          icon: LucideIcons.checkCircle,
        ),
      );
    }

    if (_confidentialData!['consented_at'] != null) {
      final consentedDate = DateTime.tryParse(
        _confidentialData!['consented_at'].toString(),
      );
      if (consentedDate != null) {
        children.add(
          _buildInfoRow(
            isDark: isDark,
            label: 'تاریخ رضایت',
            value: _formatDate(consentedDate),
            icon: LucideIcons.calendar,
          ),
        );
      }
    }

    // همیشه بخش اطلاعات محرمانه را نمایش می‌دهیم، حتی اگر خالی باشد
    if (children.isEmpty) {
      children.add(
        Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: Text(
            'اطلاعات محرمانه ثبت شده اما فیلدی پر نشده است',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: isDark
                  ? AppTheme.goldColor.withValues(alpha: 0.7)
                  : context.textColor.withValues(alpha: 0.7),
              fontSize: 14.sp,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildInfoRow({
    required bool isDark,
    required String label,
    required String value,
    required IconData icon,
    bool isMultiline = false,
  }) {
    if (value == '-' || value.isEmpty || value == 'null') {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: isMultiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 96.w,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: isDark
                    ? AppTheme.goldColor.withValues(alpha: 0.6)
                    : context.textColor.withValues(alpha: 0.5),
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: isDark ? AppTheme.goldColor : context.textColor,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
              maxLines: isMultiline ? null : 2,
              overflow: isMultiline ? null : TextOverflow.ellipsis,
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  String _getGenderLabel(String? gender) {
    switch (gender) {
      case 'male':
        return 'مرد';
      case 'female':
        return 'زن';
      case 'other':
        return 'سایر';
      default:
        return '-';
    }
  }

  String _getActivityLevelLabel(String? level) {
    switch (level) {
      case 'sedentary':
        return 'بی‌تحرک';
      case 'light':
        return 'کم';
      case 'moderate':
        return 'متوسط';
      case 'active':
        return 'فعال';
      case 'very_active':
        return 'خیلی فعال';
      default:
        return level ?? '-';
    }
  }

  String _getExperienceLevelLabel(String? level) {
    switch (level) {
      case 'beginner':
        return 'مبتدی';
      case 'intermediate':
        return 'متوسط';
      case 'advanced':
        return 'پیشرفته';
      case 'expert':
        return 'حرفه‌ای';
      default:
        return level ?? '-';
    }
  }

  // تابع برای ساخت بخش expandable
  Widget _buildExpandableSection({
    required bool isDark,
    required String key,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final isExpanded = _expansionStates[key] ?? false;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: DecoratedBox(
        decoration: _surfaceDecoration(isDark),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: isExpanded,
            iconColor: AppTheme.goldColor,
            collapsedIconColor: AppTheme.goldColor.withValues(alpha: 0.7),
            tilePadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 2.h),
            childrenPadding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 12.h),
            title: Row(
              children: [
                Icon(
                  icon,
                  color: AppTheme.goldColor,
                  size: 16.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: isDark ? AppTheme.goldColor : context.textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
            children: [child],
            onExpansionChanged: (expanded) {
              setState(() {
                _expansionStates[key] = expanded;
              });
            },
          ),
        ),
      ),
    );
  }

  // تابع برای ساخت بخش ابزار مربی
  Widget _buildTrainerToolsSection(bool isDark) {
    final firstName = _profile?['first_name']?.toString() ?? '';
    final lastName = _profile?['last_name']?.toString() ?? '';
    final displayName = [
      firstName,
      lastName,
    ].where((n) => n.isNotEmpty).join(' ').trim();
    final finalName = displayName.isNotEmpty ? displayName : widget.userName;

    // محاسبات
    final height = _profile?['height'] != null
        ? double.tryParse(_profile!['height'].toString())
        : null;
    final weight = _profile?['weight'] != null
        ? double.tryParse(_profile!['weight'].toString())
        : null;
    final birthDateStr = _profile?['birth_date']?.toString();
    final isMale = (_profile?['gender']?.toString() ?? 'male') == 'male';
    final activityLevelStr =
        _profile?['activity_level']?.toString() ?? 'moderate';

    // محاسبه سن
    int age = 25;
    if (birthDateStr != null && birthDateStr.isNotEmpty) {
      try {
        final birthDate = DateTime.tryParse(birthDateStr);
        if (birthDate != null) {
          final now = DateTime.now();
          age =
              now.year -
              birthDate.year -
              ((now.month < birthDate.month ||
                      (now.month == birthDate.month && now.day < birthDate.day))
                  ? 1
                  : 0);
        }
      } catch (_) {}
    }

    // محاسبات BMI و TDEE
    double? bmi;
    double? bmr;
    double? tdee;
    String? bmiCategory;

    if (height != null && weight != null && height > 0 && weight > 0) {
      bmi = FitnessCalculator.calculateBMI(weight, height);
      bmiCategory = FitnessCalculator.getBMICategory(bmi);

      if (age > 0) {
        bmr = FitnessCalculator.calculateBMR(weight, height, age, isMale);
        final activityLevel = activityLevelStr.toActivityLevel();
        tdee = FitnessCalculator.calculateTDEE(bmr, activityLevel);
      }
    }

    // محاسبه وزن ایده‌آل
    double? idealWeight;
    if (height != null && height > 0) {
      // فرمول ساده: (قد - 100) برای مردان و (قد - 110) برای زنان
      idealWeight = isMale ? (height - 100) * 0.9 : (height - 110) * 0.9;
    }

    // محاسبه نیاز به کاهش/افزایش وزن
    double? weightDifference;
    String? weightRecommendation;
    if (weight != null && idealWeight != null) {
      weightDifference = weight - idealWeight;
      if (weightDifference > 5) {
        weightRecommendation =
            '${isMale ? 'آقای' : 'خانم'} $finalName نیاز به کاهش وزن به مقدار ${weightDifference.toStringAsFixed(1)} کیلوگرم دارد';
      } else if (weightDifference < -5) {
        weightRecommendation =
            '${isMale ? 'آقای' : 'خانم'} $finalName نیاز به افزایش وزن به مقدار ${(-weightDifference).toStringAsFixed(1)} کیلوگرم دارد';
      } else {
        weightRecommendation =
            'وزن ${isMale ? 'آقای' : 'خانم'} $finalName در محدوده مناسب قرار دارد';
      }
    }

    // محاسبه Waist-to-Hip Ratio (WHR) - شاخص مهم برای سلامت
    final waist = _profile?['waist_circumference'] != null
        ? double.tryParse(_profile!['waist_circumference'].toString())
        : null;
    final hip = _profile?['hip_circumference'] != null
        ? double.tryParse(_profile!['hip_circumference'].toString())
        : null;
    double? whr;
    String? whrAnalysis;
    if (waist != null && hip != null && waist > 0 && hip > 0) {
      whr = waist / hip;
      if (isMale) {
        if (whr > 0.95) {
          whrAnalysis =
              'نسبت دور کمر به باسن ${isMale ? 'آقای' : 'خانم'} $finalName بالا است (${whr.toStringAsFixed(2)}) - خطر بیماری‌های قلبی و متابولیک افزایش یافته';
        } else if (whr > 0.90) {
          whrAnalysis =
              'نسبت دور کمر به باسن ${isMale ? 'آقای' : 'خانم'} $finalName در مرز خطر است (${whr.toStringAsFixed(2)}) - نیاز به نظارت';
        } else {
          whrAnalysis =
              'نسبت دور کمر به باسن ${isMale ? 'آقای' : 'خانم'} $finalName در محدوده سالم است (${whr.toStringAsFixed(2)})';
        }
      } else {
        // برای زنان
        if (whr > 0.85) {
          whrAnalysis =
              'نسبت دور کمر به باسن خانم $finalName بالا است (${whr.toStringAsFixed(2)}) - خطر بیماری‌های قلبی و متابولیک افزایش یافته';
        } else if (whr > 0.80) {
          whrAnalysis =
              'نسبت دور کمر به باسن خانم $finalName در مرز خطر است (${whr.toStringAsFixed(2)}) - نیاز به نظارت';
        } else {
          whrAnalysis =
              'نسبت دور کمر به باسن خانم $finalName در محدوده سالم است (${whr.toStringAsFixed(2)})';
        }
      }
    }

    // محاسبه درصد چربی بدن (Body Fat Percentage)
    final neck = _profile?['neck_circumference'] != null
        ? double.tryParse(_profile!['neck_circumference'].toString()) ??
              (isMale ? 35.0 : 32.0)
        : (isMale ? 35.0 : 32.0); // مقدار پیش‌فرض
    double? bodyFatPercentage;
    String? bodyFatAnalysis;
    if (waist != null &&
        waist > 0 &&
        height != null &&
        height > 0) {
      final calculatedBodyFat = FitnessCalculator.calculateBodyFatPercentage(
        waist,
        neck,
        height,
        isMale,
        hip ?? 0,
      );
      if (calculatedBodyFat > 0) {
        bodyFatPercentage = calculatedBodyFat;
        if (isMale) {
          if (bodyFatPercentage < 6) {
            bodyFatAnalysis =
                'درصد چربی بدن ${isMale ? 'آقای' : 'خانم'} $finalName بسیار پایین است (${bodyFatPercentage.toStringAsFixed(1)}%) - نیاز به افزایش چربی ضروری';
          } else if (bodyFatPercentage < 14) {
            bodyFatAnalysis =
                'درصد چربی بدن ${isMale ? 'آقای' : 'خانم'} $finalName عالی است (${bodyFatPercentage.toStringAsFixed(1)}%) - سطح ورزشکار';
          } else if (bodyFatPercentage < 18) {
            bodyFatAnalysis =
                'درصد چربی بدن ${isMale ? 'آقای' : 'خانم'} $finalName خوب است (${bodyFatPercentage.toStringAsFixed(1)}%) - سطح مناسب';
          } else if (bodyFatPercentage < 25) {
            bodyFatAnalysis =
                'درصد چربی بدن ${isMale ? 'آقای' : 'خانم'} $finalName متوسط است (${bodyFatPercentage.toStringAsFixed(1)}%) - نیاز به کاهش';
          } else {
            bodyFatAnalysis =
                'درصد چربی بدن ${isMale ? 'آقای' : 'خانم'} $finalName بالا است (${bodyFatPercentage.toStringAsFixed(1)}%) - نیاز به کاهش فوری';
          }
        } else {
          // برای زنان
          if (bodyFatPercentage < 16) {
            bodyFatAnalysis =
                'درصد چربی بدن خانم $finalName بسیار پایین است (${bodyFatPercentage.toStringAsFixed(1)}%) - نیاز به افزایش چربی ضروری';
          } else if (bodyFatPercentage < 24) {
            bodyFatAnalysis =
                'درصد چربی بدن خانم $finalName عالی است (${bodyFatPercentage.toStringAsFixed(1)}%) - سطح ورزشکار';
          } else if (bodyFatPercentage < 30) {
            bodyFatAnalysis =
                'درصد چربی بدن خانم $finalName خوب است (${bodyFatPercentage.toStringAsFixed(1)}%) - سطح مناسب';
          } else if (bodyFatPercentage < 35) {
            bodyFatAnalysis =
                'درصد چربی بدن خانم $finalName متوسط است (${bodyFatPercentage.toStringAsFixed(1)}%) - نیاز به کاهش';
          } else {
            bodyFatAnalysis =
                'درصد چربی بدن خانم $finalName بالا است (${bodyFatPercentage.toStringAsFixed(1)}%) - نیاز به کاهش فوری';
          }
        }
      }
    }

    // محاسبه Lean Body Mass (LBM) و Muscle Mass
    double? lbm;
    double? muscleMass;
    String? muscleMassAnalysis;
    if (weight != null && bodyFatPercentage != null && bodyFatPercentage > 0) {
      final fatMass = weight * (bodyFatPercentage / 100);
      lbm = weight - fatMass;
      muscleMass = lbm * 0.5; // تقریباً 50% از LBM عضله است
      if (isMale) {
        final idealMuscleMass = weight * 0.45; // 45% وزن برای مردان
        if (muscleMass < idealMuscleMass * 0.9) {
          muscleMassAnalysis =
              'توده عضلانی ${isMale ? 'آقای' : 'خانم'} $finalName پایین است (${muscleMass.toStringAsFixed(1)} کیلوگرم) - نیاز به تمرینات مقاومتی';
        } else if (muscleMass > idealMuscleMass * 1.1) {
          muscleMassAnalysis =
              'توده عضلانی ${isMale ? 'آقای' : 'خانم'} $finalName عالی است (${muscleMass.toStringAsFixed(1)} کیلوگرم)';
        } else {
          muscleMassAnalysis =
              'توده عضلانی ${isMale ? 'آقای' : 'خانم'} $finalName در محدوده مناسب است (${muscleMass.toStringAsFixed(1)} کیلوگرم)';
        }
      } else {
        final idealMuscleMass = weight * 0.35; // 35% وزن برای زنان
        if (muscleMass < idealMuscleMass * 0.9) {
          muscleMassAnalysis =
              'توده عضلانی خانم $finalName پایین است (${muscleMass.toStringAsFixed(1)} کیلوگرم) - نیاز به تمرینات مقاومتی';
        } else if (muscleMass > idealMuscleMass * 1.1) {
          muscleMassAnalysis =
              'توده عضلانی خانم $finalName عالی است (${muscleMass.toStringAsFixed(1)} کیلوگرم)';
        } else {
          muscleMassAnalysis =
              'توده عضلانی خانم $finalName در محدوده مناسب است (${muscleMass.toStringAsFixed(1)} کیلوگرم)';
        }
      }
        }

    // محاسبه نیاز پروتئین (بر اساس وزن و سطح فعالیت)
    double? proteinRequirement;
    String? proteinAnalysis;
    if (weight != null && weight > 0) {
      // برای افراد عادی: 1.2-1.6 گرم به ازای هر کیلوگرم
      // برای ورزشکاران: 1.6-2.2 گرم به ازای هر کیلوگرم
      final activityLevel = activityLevelStr.toActivityLevel();
      double proteinPerKg;
      if (activityLevel == ActivityLevel.sedentary ||
          activityLevel == ActivityLevel.lightlyActive) {
        proteinPerKg = 1.2;
      } else if (activityLevel == ActivityLevel.moderatelyActive) {
        proteinPerKg = 1.6;
      } else {
        proteinPerKg = 2.0;
      }
      proteinRequirement = weight * proteinPerKg;
      proteinAnalysis =
          'نیاز روزانه پروتئین ${isMale ? 'آقای' : 'خانم'} $finalName: ${proteinRequirement.toStringAsFixed(0)} گرم (${proteinPerKg.toStringAsFixed(1)} گرم به ازای هر کیلوگرم وزن)';
    }

    // محاسبه نیاز آب (بر اساس وزن و سطح فعالیت)
    double? waterRequirement;
    String? waterAnalysis;
    if (weight != null && weight > 0) {
      // فرمول پایه: 35 میلی‌لیتر به ازای هر کیلوگرم
      // برای افراد فعال: 40-45 میلی‌لیتر
      final activityLevel = activityLevelStr.toActivityLevel();
      double mlPerKg = 35;
      if (activityLevel == ActivityLevel.veryActive ||
          activityLevel == ActivityLevel.extraActive) {
        mlPerKg = 45;
      } else if (activityLevel == ActivityLevel.moderatelyActive) {
        mlPerKg = 40;
      }
      waterRequirement = weight * mlPerKg;
      waterAnalysis =
          'نیاز روزانه آب ${isMale ? 'آقای' : 'خانم'} $finalName: ${(waterRequirement / 1000).toStringAsFixed(1)} لیتر (${mlPerKg.toStringAsFixed(0)} میلی‌لیتر به ازای هر کیلوگرم)';
    }

    // محاسبه کالری مورد نیاز برای کاهش/افزایش وزن
    String? calorieGoalAnalysis;
    if (tdee != null && weightDifference != null) {
      if (weightDifference > 5) {
        // برای کاهش وزن: 500-750 کالری کمتر از TDEE
        const deficit = 500.0;
        final targetCalories = tdee - deficit;
        calorieGoalAnalysis =
            'برای کاهش وزن ${weightDifference.toStringAsFixed(1)} کیلوگرم، ${isMale ? 'آقای' : 'خانم'} $finalName باید ${targetCalories.toStringAsFixed(0)} کالری در روز مصرف کند (${deficit.toStringAsFixed(0)} کالری کمتر از TDEE)';
      } else if (weightDifference < -5) {
        // برای افزایش وزن: 300-500 کالری بیشتر از TDEE
        const surplus = 300.0;
        final targetCalories = tdee + surplus;
        calorieGoalAnalysis =
            'برای افزایش وزن ${(-weightDifference).toStringAsFixed(1)} کیلوگرم، ${isMale ? 'آقای' : 'خانم'} $finalName باید ${targetCalories.toStringAsFixed(0)} کالری در روز مصرف کند (${surplus.toStringAsFixed(0)} کالری بیشتر از TDEE)';
      }
    }

    // بررسی شرایط پزشکی
    final lifestylePrefs = _confidentialData?['lifestyle_preferences'];
    Map<String, dynamic>? lp;
    if (lifestylePrefs != null) {
      if (lifestylePrefs is Map) {
        lp = lifestylePrefs as Map<String, dynamic>;
      } else if (lifestylePrefs is String) {
        try {
          final decoded = jsonDecode(lifestylePrefs);
          if (decoded is Map) {
            lp = Map<String, dynamic>.from(decoded);
          }
        } catch (_) {}
      }
    }

    final medicalConditions = lp?['medical_conditions']?.toString() ?? '';
    final medications = lp?['medications']?.toString() ?? '';
    final allergies = lp?['allergies']?.toString() ?? '';

    // ساخت توصیه‌ها (به صورت سوم شخص برای مربی)
    final recommendations = <String>[];

    // تحلیل BMI
    if (bmi != null) {
      if (bmi < 18.5) {
        recommendations.add(
          '${isMale ? 'آقای' : 'خانم'} $finalName در دسته کم‌وزن قرار دارد (BMI: ${bmi.toStringAsFixed(1)}) - نیاز به افزایش وزن تدریجی و سالم',
        );
      } else if (bmi < 25) {
        recommendations.add(
          '${isMale ? 'آقای' : 'خانم'} $finalName در محدوده وزن سالم قرار دارد (BMI: ${bmi.toStringAsFixed(1)}) - حفظ وزن و بهبود ترکیب بدنی توصیه می‌شود',
        );
      } else if (bmi < 30) {
        recommendations.add(
          '${isMale ? 'آقای' : 'خانم'} $finalName اضافه وزن دارد (BMI: ${bmi.toStringAsFixed(1)}) - نیاز به کاهش وزن تدریجی',
        );
      } else {
        recommendations.add(
          '${isMale ? 'آقای' : 'خانم'} $finalName در دسته چاقی قرار دارد (BMI: ${bmi.toStringAsFixed(1)}) - نیاز به کاهش وزن فوری و برنامه‌ریزی دقیق',
        );
      }
    }

    if (weightRecommendation != null) {
      recommendations.add(weightRecommendation);
    }

    // تحلیل Waist-to-Hip Ratio
    if (whrAnalysis != null) {
      recommendations.add(whrAnalysis);
    }

    // تحلیل درصد چربی بدن
    if (bodyFatAnalysis != null) {
      recommendations.add(bodyFatAnalysis);
    }

    // تحلیل توده عضلانی
    if (muscleMassAnalysis != null) {
      recommendations.add(muscleMassAnalysis);
    }

    // تحلیل نیاز پروتئین
    if (proteinAnalysis != null) {
      recommendations.add(proteinAnalysis);
    }

    // تحلیل نیاز آب
    if (waterAnalysis != null) {
      recommendations.add(waterAnalysis);
    }

    // تحلیل کالری هدف
    if (calorieGoalAnalysis != null) {
      recommendations.add(calorieGoalAnalysis);
    }

    // تحلیل BMR
    if (bmr != null && age > 0) {
      // BMR طبیعی برای مردان: حدود 1600-1800، برای زنان: حدود 1400-1600
      final expectedBMR = isMale ? 1700.0 : 1500.0;
      final bmrRatio = bmr / expectedBMR;
      if (bmrRatio < 0.9) {
        recommendations.add(
          'متابولیسم پایه ${isMale ? 'آقای' : 'خانم'} $finalName پایین است (${bmr.toStringAsFixed(0)} کالری) - ممکن است نیاز به افزایش فعالیت بدنی یا بررسی تیروئید باشد',
        );
      } else if (bmrRatio > 1.1) {
        recommendations.add(
          'متابولیسم پایه ${isMale ? 'آقای' : 'خانم'} $finalName بالا است (${bmr.toStringAsFixed(0)} کالری) - نشان‌دهنده توده عضلانی خوب یا فعالیت متابولیک بالا',
        );
      }
    }

    // تحلیل سطح فعالیت
    final activityLevel = activityLevelStr.toActivityLevel();
    if (activityLevel == ActivityLevel.sedentary) {
      recommendations.add(
        '${isMale ? 'آقای' : 'خانم'} $finalName سبک زندگی کم‌تحرکی دارد - افزایش فعالیت بدنی ضروری است',
      );
    } else if (activityLevel == ActivityLevel.veryActive ||
        activityLevel == ActivityLevel.extraActive) {
      recommendations.add(
        '${isMale ? 'آقای' : 'خانم'} $finalName سطح فعالیت بالایی دارد - نیاز به تغذیه مناسب و ریکاوری کافی',
      );
    }

    // شرایط پزشکی
    if (medicalConditions.isNotEmpty) {
      recommendations.add(
        '${isMale ? 'آقای' : 'خانم'} $finalName شرایط پزشکی دارد: $medicalConditions - در طراحی برنامه احتیاط بیشتری به خرج دهید و در صورت نیاز با پزشک مشورت کنید',
      );
    }

    // داروها
    if (medications.isNotEmpty) {
      recommendations.add(
        '${isMale ? 'آقای' : 'خانم'} $finalName در حال مصرف دارو است: $medications - تداخل دارویی و عوارض جانبی را در نظر بگیرید',
      );
    }

    // آلرژی‌ها
    if (allergies.isNotEmpty) {
      recommendations.add(
        '${isMale ? 'آقای' : 'خانم'} $finalName آلرژی دارد: $allergies - از این موارد در برنامه غذایی کاملاً پرهیز کنید',
      );
    }

    // سطح تجربه
    final experienceLevel = _profile?['experience_level']?.toString();
    if (experienceLevel != null) {
      if (experienceLevel == 'beginner') {
        recommendations.add(
          '${isMale ? 'آقای' : 'خانم'} $finalName در سطح مبتدی است - برنامه باید ساده و قابل فهم باشد، با تمرکز بر فرم صحیح حرکات',
        );
      } else if (experienceLevel == 'intermediate') {
        recommendations.add(
          '${isMale ? 'آقای' : 'خانم'} $finalName در سطح متوسط است - می‌توانید برنامه پیشرفته‌تری طراحی کنید',
        );
      } else if (experienceLevel == 'advanced' || experienceLevel == 'expert') {
        recommendations.add(
          '${isMale ? 'آقای' : 'خانم'} $finalName در سطح پیشرفته/حرفه‌ای است - می‌توانید برنامه‌های تخصصی و چالش‌برانگیز طراحی کنید',
        );
      }
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 14.h),
        decoration: _surfaceDecoration(isDark),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.activity,
                  color: AppTheme.goldColor,
                  size: 16.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  'شاخص‌های مربی',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: isDark ? AppTheme.goldColor : context.textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            // محاسبات
            if (bmi == null && bmr == null && tdee == null && idealWeight == null)
              Text(
                'قد و وزن ثبت نشده — شاخصی برای محاسبه نیست.',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: isDark
                      ? AppTheme.goldColor.withValues(alpha: 0.65)
                      : context.textColor.withValues(alpha: 0.55),
                  fontSize: 12.sp,
                ),
              ),
            if (bmi != null || bmr != null || tdee != null || idealWeight != null)
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  if (bmi != null)
                    _buildMetricChip(
                      isDark: isDark,
                      label: 'BMI',
                      value: bmi.toStringAsFixed(1),
                      hint: bmiCategory,
                      color: FitnessCalculator.getBMIColor(bmi),
                    ),
                  if (bmr != null)
                    _buildMetricChip(
                      isDark: isDark,
                      label: 'BMR',
                      value: bmr.toStringAsFixed(0),
                      hint: 'kcal',
                      color: AppTheme.goldColor,
                    ),
                  if (tdee != null)
                    _buildMetricChip(
                      isDark: isDark,
                      label: 'TDEE',
                      value: tdee.toStringAsFixed(0),
                      hint: 'kcal',
                      color: AppTheme.goldColor,
                    ),
                  if (idealWeight != null && weight != null)
                    _buildMetricChip(
                      isDark: isDark,
                      label: 'وزن ایده‌آل',
                      value: idealWeight.toStringAsFixed(1),
                      hint: 'kg',
                      color: AppTheme.goldColor,
                    ),
                ],
              ),
            if (recommendations.isNotEmpty) ...[
              SizedBox(height: 12.h),
              Divider(
                color: AppTheme.goldColor.withValues(alpha: 0.15),
                height: 1,
              ),
              SizedBox(height: 10.h),
              Text(
                'نکات مهم',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: isDark ? AppTheme.goldColor : context.textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.sp,
                ),
              ),
              SizedBox(height: 8.h),
              ...recommendations.take(4).map(
                (rec) => Padding(
                  padding: EdgeInsets.only(bottom: 6.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: EdgeInsets.only(top: 6.h, left: 8.w),
                        width: 5.w,
                        height: 5.h,
                        decoration: const BoxDecoration(
                          color: AppTheme.goldColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          rec,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            color: isDark
                                ? AppTheme.goldColor.withValues(alpha: 0.9)
                                : context.textColor.withValues(alpha: 0.8),
                            fontSize: 12.sp,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricChip({
    required bool isDark,
    required String label,
    required String value,
    required Color color,
    String? hint,
  }) {
    return Container(
      width: 104.w,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: isDark
                  ? AppTheme.goldColor.withValues(alpha: 0.7)
                  : context.textColor.withValues(alpha: 0.55),
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: isDark ? AppTheme.goldColor : context.textColor,
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (hint != null && hint.isNotEmpty)
            Text(
              hint,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: color,
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

}
