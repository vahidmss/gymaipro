import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/auth/services/supabase_service.dart';
import 'package:gymaipro/profile/models/picked_profile_image.dart';
import 'package:gymaipro/profile/widgets/profile_birth_date_widget.dart';
import 'package:gymaipro/profile/widgets/profile_form_widgets.dart';
import 'package:gymaipro/profile/widgets/profile_image_widgets.dart';
import 'package:gymaipro/profile/widgets/profile_weight_controls_widget.dart';
import 'package:gymaipro/profile/widgets/weight_widgets.dart';
import 'package:gymaipro/profile/widgets/profile_new_widgets.dart';
import 'package:gymaipro/services/avatar_refresh_notifier.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/services/weekly_weight_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/animation_utils.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:gymaipro/achievements/services/achievement_service.dart';
import 'package:gymaipro/ranking/models/ranking_score_breakdown.dart';
import 'package:gymaipro/ranking/models/user_ranking.dart';
import 'package:gymaipro/ranking/services/ranking_score_service.dart';
import 'package:gymaipro/ranking/services/ranking_service.dart';
import 'package:gymaipro/trainer_dashboard/screens/trainer_dashboard_screen.dart';
import 'package:gymaipro/trainer_ranking/services/trainer_kpi_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

/// وضعیت آپلود تصویر پروفایل برای UX حرفه‌ای
enum AvatarUploadStatus { idle, uploading, success, error }

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  PickedProfileImage? _avatarPicked;
  bool _isLoading = false;
  bool _isEditing = false;
  AvatarUploadStatus _avatarUploadStatus = AvatarUploadStatus.idle;
  String? _avatarUploadError;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final Map<String, dynamic> _profileData = {};
  final Map<String, dynamic> _originalData = {};
  Timer? _autoSaveDebounce;
  UserRanking? _userRanking;
  RankingScoreBreakdown? _scoreBreakdown;
  TrainerKpis? _trainerKpis;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(begin: Offset(0.w, 0.3.h), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.safeForward();
    _loadProfileData();
  }

  @override
  void dispose() {
    _autoSaveDebounce?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    SafeSetState.call(this, () {
      _isLoading = true;
    });

    try {
      // تست کاربر فعلی
      await SimpleProfileService.testCurrentUser();

      // استفاده از SimpleProfileService
      final profileData = await SimpleProfileService.getCurrentProfile();

      if (profileData != null) {
        if (!mounted) return;
        SafeSetState.call(this, () {
          _profileData.clear();
          _originalData.clear();
          _profileData.addAll(profileData);
          _originalData.addAll(profileData);
        });

        // بررسی دستاورد تکمیل پروفایل (عکس پروفایل)
        final avatarUrl = profileData['avatar_url'];
        if (avatarUrl != null &&
            avatarUrl is String &&
            avatarUrl.isNotEmpty &&
            mounted) {
          try {
            final achievementService = Provider.of<AchievementService>(
              context,
              listen: false,
            );
            // دستاورد profile_complete را unlock کن (targetValue = 100)
            await achievementService.updateProgress('profile_complete', 100);
          } catch (e) {
            // بی‌صدا؛ اگر AchievementService در دسترس نبود
          }
        }

        // بارگذاری آخرین وزن ثبت شده
        final userId = profileData['id'];
        if (userId != null) {
          final latestWeight = await WeeklyWeightService.getLatestWeight(
            userId as String,
          );
          if (mounted && latestWeight != null) {
            SafeSetState.call(this, () {
              _profileData['latest_weight'] = latestWeight;
            });
          }
        }

        // بارگذاری رتبه و تفکیک امتیاز برای نقش ورزشکار
        final role = (profileData['role'] ?? 'athlete').toString();
        if (role == 'athlete' && userId != null) {
          final profileId = userId as String;
          try {
            final rankingService = RankingService();
            final scoreService = RankingScoreService();
            
            // فقط ranking و breakdown رو بگیریم - بدون به‌روزرسانی سنگین
            // به‌روزرسانی امتیاز در background انجام میشه
            final ranking = await rankingService.getUserRanking(profileId);
            final breakdown = await scoreService.getScoreBreakdown(profileId);
            if (mounted) {
              SafeSetState.call(this, () {
                _userRanking = ranking;
                _scoreBreakdown = breakdown;
                _trainerKpis = null;
              });
            }
          } catch (_) {}
        } else if (role == 'trainer' && userId != null) {
          final trainerId = userId as String;
          try {
            final kpis = await TrainerKpiService().getTrainerKpis(trainerId);
            if (mounted) {
              SafeSetState.call(this, () {
                _trainerKpis = kpis;
                _userRanking = null;
                _scoreBreakdown = null;
              });
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('خطا در بارگذاری پروفایل: $e');
    } finally {
      if (!mounted) return;
      SafeSetState.call(this, () {
        _isLoading = false;
      });
    }
  }

  void _pickImage() {
    final hasImage =
        _avatarPicked != null ||
        (_profileData.containsKey('avatar_url') &&
            _profileData['avatar_url'] != null &&
            _profileData['avatar_url'] is String &&
            (_profileData['avatar_url'] as String).isNotEmpty);

    ProfileImageWidgets.showImagePickerBottomSheet(
      context,
      _pickImageFromSource,
      _removeImage,
      hasImage,
    );
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    ProfileImageWidgets.pickImageFromSource(source, context, (picked) async {
      if (!mounted) return;
      SafeSetState.call(this, () {
        _avatarPicked = picked;
        _avatarUploadStatus = AvatarUploadStatus.uploading;
        _avatarUploadError = null;
      });

      try {
        final avatarSaved = await _saveProfileData(context);
        if (!mounted) return;
        if (avatarSaved) {
          SafeSetState.call(this, () {
            _avatarUploadStatus = AvatarUploadStatus.success;
            _avatarUploadError = null;
          });
          AvatarRefreshNotifier.instance.notifyAvatarUpdated();
          // بعد از نمایش چک‌مارک، عکس از سرور نمایش داده شود و وضعیت به idle برگردد
          await Future<void>.delayed(const Duration(milliseconds: 1800));
          if (!mounted) return;
          SafeSetState.call(this, () {
            _avatarPicked = null;
            _avatarUploadStatus = AvatarUploadStatus.idle;
          });
        } else {
          SafeSetState.call(this, () {
            _avatarUploadStatus = AvatarUploadStatus.error;
            _avatarUploadError =
                'ذخیره انجام نشد. اتصال اینترنت را بررسی کنید.';
          });
        }
      } catch (e) {
        if (!mounted) return;
        SafeSetState.call(this, () {
          _avatarUploadStatus = AvatarUploadStatus.error;
          _avatarUploadError = e.toString().replaceFirst('Exception: ', '');
        });
      }
    });
  }

  Future<void> _retryAvatarUpload() async {
    if (_avatarPicked == null) return;
    SafeSetState.call(this, () {
      _avatarUploadStatus = AvatarUploadStatus.uploading;
      _avatarUploadError = null;
    });
    try {
      final avatarSaved = await _saveProfileData(context);
      if (!mounted) return;
      if (avatarSaved) {
        SafeSetState.call(this, () {
          _avatarUploadStatus = AvatarUploadStatus.success;
          _avatarUploadError = null;
        });
        AvatarRefreshNotifier.instance.notifyAvatarUpdated();
        await Future<void>.delayed(const Duration(milliseconds: 1800));
        if (!mounted) return;
        SafeSetState.call(this, () {
          _avatarPicked = null;
          _avatarUploadStatus = AvatarUploadStatus.idle;
        });
      } else {
        SafeSetState.call(this, () {
          _avatarUploadStatus = AvatarUploadStatus.error;
          _avatarUploadError =
              'ذخیره انجام نشد. اتصال اینترنت را بررسی کنید.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      SafeSetState.call(this, () {
        _avatarUploadStatus = AvatarUploadStatus.error;
        _avatarUploadError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _removeImage() {
    ProfileImageWidgets.showRemoveImageDialog(context, () async {
      SafeSetState.call(this, () {
        _avatarPicked = null;
        _profileData['avatar_url'] = null;
        _originalData['avatar_url'] = null;
      });

      try {
        await _saveProfileData(context);
        if (!mounted) return;
        AvatarRefreshNotifier.instance.notifyAvatarUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تصویر پروفایل حذف شد',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: context.textColor,
              ),
            ),
            backgroundColor: context.cardColor,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در حذف تصویر: $e'),
            backgroundColor: context.cardColor,
          ),
        );
      }
    });
  }

  void _showWeightGuidanceDialog() {
    WeightWidgets.showWeightGuidanceDialog(context, _addWeightRecord);
  }

  Future<void> _showWeightHistoryDialog() async {
    try {
      final profileData = await SimpleProfileService.getCurrentProfile();
      if (profileData == null) return;

      final userId = profileData['id'];
      if (userId == null) return;

      final weightHistory = await WeeklyWeightService.getFullWeightHistory(
        userId as String,
      );
      if (!mounted) return;
      WeightWidgets.showWeightHistoryDialog(context, weightHistory);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا در بارگذاری تاریخچه وزن: $e'),
          backgroundColor: context.cardColor,
        ),
      );
    }
  }

  Future<void> _addWeightRecord(String weightStr) async {
    try {
      final weight = double.tryParse(weightStr);
      if (weight == null) {
        return;
      }

      final profileData = await SimpleProfileService.getCurrentProfile();
      if (profileData == null) return;

      final userId = profileData['id'];
      if (userId == null) return;

      final success = await WeeklyWeightService.recordWeeklyWeight(
        userId as String,
        weight,
      );

      if (!mounted) return;
      if (success) {
        SafeSetState.call(this, () {
          _profileData['weight'] = weight;
          _profileData['latest_weight'] = weight;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'وزن با موفقیت ثبت شد',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: context.textColor,
              ),
            ),
            backgroundColor: context.cardColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'در 7 روز گذشته قبلاً وزن ثبت شده است',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: context.textColor,
              ),
            ),
            backgroundColor: context.cardColor,
          ),
        );
      }
    } catch (e) {
      // Error handling
    }
  }

  /// Returns true if a new avatar was successfully uploaded and saved.
  Future<bool> _saveProfileData([BuildContext? context]) async {
    try {
      final profileData = await SimpleProfileService.getCurrentProfile();
      if (profileData == null) return false;
      final userId = profileData['id'];
      if (userId == null) return false;

      bool avatarSaved = false;
      if (_avatarPicked != null) {
        final supabaseService = SupabaseService();
        final picked = _avatarPicked!;
        final imageUrl = await supabaseService.uploadProfileImageBytes(
          userId as String,
          picked.bytes,
          extension: picked.fileName.split('.').last,
          mimeType: picked.mimeType,
        );
        if (imageUrl != null && imageUrl.isNotEmpty) {
          _profileData['avatar_url'] = imageUrl;
          avatarSaved = true;
          if (context != null && context.mounted) {
            try {
              final achievementService = Provider.of<AchievementService>(
                context,
                listen: false,
              );
              await achievementService.updateProgress('profile_complete', 100);
            } catch (_) {}
          }
        }
      }

      final cleanData = Map<String, dynamic>.from(_profileData);
      for (final key in [
        'height',
        'weight',
        'arm_circumference',
        'chest_circumference',
        'waist_circumference',
        'hip_circumference',
      ]) {
        if (cleanData[key] == '' || cleanData[key] == null) {
          cleanData.remove(key);
        }
      }
      if (_originalData['username'] == cleanData['username']) {
        cleanData.remove('username');
      }
      final updated = await SimpleProfileService.updateProfile(cleanData);
      if (!updated) return false;
      if (!mounted) return avatarSaved;
      SafeSetState.call(this, () {
        _originalData
          ..clear()
          ..addAll(_profileData);
      });
      return avatarSaved;
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('_saveProfileData error: $e');
      }
      rethrow;
    }
  }

  void _onFieldChanged(String key, dynamic value) {
    setState(() {
      _profileData[key] = value;
    });
    _autoSaveDebounce?.cancel();
    _autoSaveDebounce = Timer(
      const Duration(milliseconds: 800),
      _saveProfileData,
    );
  }

  Future<void> _showPersianBirthDatePicker() async {
    DateTime? birthDate;
    if (_profileData['birth_date'] != null) {
      try {
        final dateStr = _profileData['birth_date'].toString();
        if (dateStr.isNotEmpty && dateStr != 'null') {
          birthDate = DateTime.parse(dateStr);
        }
      } catch (_) {}
    }

    await ProfileBirthDateWidget.showPersianBirthDatePicker(
      context,
      birthDate,
      (dateStr) => _onFieldChanged('birth_date', dateStr),
    );
  }

  Widget _buildBirthDateField() {
    return ProfileBirthDateWidget.buildBirthDateField(
      context,
      _profileData,
      _showPersianBirthDatePicker,
    );
  }

  Widget _buildProfileForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          ProfileFormWidgets.buildFormSection('اطلاعات شخصی', [
            ProfileFormWidgets.buildTextField(
              'first_name',
              'نام',
              LucideIcons.user,
              _profileData,
              (value) => _onFieldChanged('first_name', value),
            ),
            ProfileFormWidgets.buildTextField(
              'last_name',
              'نام خانوادگی',
              LucideIcons.user,
              _profileData,
              (value) => _onFieldChanged('last_name', value),
            ),
            ProfileFormWidgets.buildDropdownField(
              'gender',
              'جنسیت',
              LucideIcons.user,
              ['male', 'female', 'other'],
              _profileData,
              (value) => _onFieldChanged('gender', value),
            ),
            _buildBirthDateField(),
            ProfileFormWidgets.buildDropdownField(
              'activity_level',
              'میزان فعالیت',
              LucideIcons.activity,
              ['sedentary', 'light', 'moderate', 'active', 'very_active'],
              _profileData,
              (value) => _onFieldChanged('activity_level', value),
            ),
            ProfileFormWidgets.buildTextArea(
              'bio',
              'بیوگرافی',
              LucideIcons.fileText,
              _profileData,
              (value) => _onFieldChanged('bio', value),
            ),
          ]),

          ProfileFormWidgets.buildFormSection('اطلاعات فیزیکی', [
            ProfileWeightControlsWidget(
              onAddWeightPressed: _showWeightGuidanceDialog,
              onWeightHistoryPressed: _showWeightHistoryDialog,
            ),
            ProfileFormWidgets.buildNumberField(
              'height',
              'قد (سانتی‌متر)',
              LucideIcons.ruler,
              _profileData,
              (value) => _onFieldChanged(
                'height',
                value.isEmpty ? null : double.tryParse(value),
              ),
            ),
            ProfileFormWidgets.buildWeightField(
              'weight',
              'وزن فعلی',
              LucideIcons.scale,
              _profileData,
              () => WeightWidgets.showWeightGuidanceDialog(
                context,
                _addWeightRecord,
              ),
            ),
            ProfileFormWidgets.buildNumberField(
              'arm_circumference',
              'دور بازو (سانتی‌متر)',
              LucideIcons.circle,
              _profileData,
              (value) => _onFieldChanged(
                'arm_circumference',
                value.isEmpty ? null : double.tryParse(value),
              ),
            ),
            ProfileFormWidgets.buildNumberField(
              'chest_circumference',
              'دور سینه (سانتی‌متر)',
              LucideIcons.heart,
              _profileData,
              (value) => _onFieldChanged(
                'chest_circumference',
                value.isEmpty ? null : double.tryParse(value),
              ),
            ),
            ProfileFormWidgets.buildNumberField(
              'waist_circumference',
              'دور کمر (سانتی‌متر)',
              LucideIcons.circle,
              _profileData,
              (value) => _onFieldChanged(
                'waist_circumference',
                value.isEmpty ? null : double.tryParse(value),
              ),
            ),
            ProfileFormWidgets.buildNumberField(
              'hip_circumference',
              'دور باسن (سانتی‌متر)',
              LucideIcons.circle,
              _profileData,
              (value) => _onFieldChanged(
                'hip_circumference',
                value.isEmpty ? null : double.tryParse(value),
              ),
            ),
          ]),
          const SizedBox(height: 32),
          // دکمه خروج از حالت ویرایش
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.goldColor,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'ذخیره و بازگشت',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: CircularProgressIndicator(color: AppTheme.goldColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final role = (_profileData['role'] ?? 'athlete').toString();
    return DecoratedBox(
      decoration: isDark
          ? const BoxDecoration()
          : BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.lightGradientStart.withValues(alpha: 0.15),
                  AppTheme.lightCardColor,
                  AppTheme.lightGradientEnd.withValues(alpha: 0.1),
                ],
              ),
            ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: _isLoading && _profileData.isEmpty
            ? _buildLoadingView()
            : SingleChildScrollView(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        if (!_isEditing) ...[
                          ModernProfileHeader(
                            profileData: _profileData,
                            avatarPreviewBytes: _avatarPicked?.bytes,
                            avatarUploading: _avatarUploadStatus ==
                                AvatarUploadStatus.uploading,
                            avatarSuccess: _avatarUploadStatus ==
                                AvatarUploadStatus.success,
                            avatarError: _avatarUploadError,
                            onImageTap: (_avatarUploadStatus ==
                                        AvatarUploadStatus.uploading ||
                                    _avatarUploadStatus ==
                                        AvatarUploadStatus.success)
                                ? () {}
                                : _pickImage,
                            onRetryAvatar: _retryAvatarUpload,
                            onEditTap: () => setState(() => _isEditing = true),
                            onSettingsTap: () =>
                                Navigator.pushNamed(context, '/settings'),
                            ranking: _userRanking,
                          ),
                          // فقط برای ورزشکاران (athletes) نمایش داده می‌شود
                          if (role == 'athlete')
                            ModernProfileActions(
                              onFriendsTap: () => Navigator.pushNamed(
                                context,
                                '/my-club',
                                arguments: {'initialTab': 2},
                              ),
                              onMessagesTap: () =>
                                  Navigator.pushNamed(context, '/conversations'),
                              onRequestsTap: () => Navigator.pushNamed(
                                context,
                                '/my-club',
                                arguments: {'initialTab': 2},
                              ),
                            ),
                          // داشبورد مربی (بدون لیگ) - شبیه ModernGamificationStats
                          if (role == 'trainer') ...[
                            SizedBox(height: 20.h),
                            ModernTrainerKpiDashboard(
                              profileData: _profileData,
                              kpis: _trainerKpis,
                              onOpenTrainerRanking: () =>
                                  Navigator.pushNamed(context, '/trainer-ranking'),
                              onOpenTrainerDashboard: () => Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => const TrainerDashboardScreen(),
                                ),
                              ),
                            ),
                          ],

                          // فقط برای ورزشکاران (athletes) نمایش داده می‌شود
                          if (role == 'athlete')
                            ModernGamificationStats(
                              ranking: _userRanking,
                              breakdown: _scoreBreakdown,
                              onViewLeaderboard: () =>
                                  Navigator.pushNamed(context, '/ranking'),
                            ),
                          ModernPhysicalStats(profileData: _profileData),
                          SizedBox(height: 80.h), // Bottom padding
                        ],
                        if (_isEditing) ...[
                          SizedBox(height: 60.h), // Top padding for edit mode
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.w),
                            child: Row(
                              children: [
                                Text(
                                  'ویرایش پروفایل',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.bold,
                                    color: context.textColor,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  onPressed: () =>
                                      setState(() => _isEditing = false),
                                  icon: Icon(
                                    LucideIcons.x,
                                    color: context.textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20.h),
                          _buildProfileForm(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
