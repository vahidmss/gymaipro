import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/profile/models/user_profile.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_dashboard/screens/certificate_upload_screen.dart';
import 'package:gymaipro/trainer_ranking/models/certificate.dart';
import 'package:gymaipro/trainer_ranking/services/certificate_service.dart';
import 'package:gymaipro/trainer_ranking/widgets/certificate_carousel.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrainerProfileTab extends StatefulWidget {
  const TrainerProfileTab({super.key});

  @override
  State<TrainerProfileTab> createState() => _TrainerProfileTabState();
}

class _TrainerProfileTabState extends State<TrainerProfileTab> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _bioCtr = TextEditingController();
  final TextEditingController _experienceYearsCtr = TextEditingController();

  final List<String> _allSpecializations = const [
    'بدنسازی',
    'رژیم غذایی',
    'مشاوره',
  ];
  final Set<String> _selectedSpecs = <String>{};

  bool _isLoading = true;
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _bioCtr.dispose();
    _experienceYearsCtr.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profMap = await SimpleProfileService.getCurrentProfile();
      final prof = profMap != null ? UserProfile.fromJson(profMap) : null;
      if (!mounted) return;
      setState(() {
        _profile = prof;
        _bioCtr.text = prof?.bio ?? '';
        _experienceYearsCtr.text = prof?.experienceYears?.toString() ?? '';
        _selectedSpecs
          ..clear()
          ..addAll(prof?.specializations ?? const []);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final data = {
      'bio': _bioCtr.text.trim(),
      'experience_years': int.tryParse(_experienceYearsCtr.text.trim()),
      'specializations': _selectedSpecs.toList(),
      'role': 'trainer',
    };

    setState(() => _isLoading = true);
    try {
      await SimpleProfileService.updateProfile(data);
      if (!mounted) return;
      final isDark = Theme.of(context).brightness == Brightness.dark;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'پروفایل مربی با موفقیت ذخیره شد',
            style: TextStyle(
              color: context.textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: isDark
              ? AppTheme.successColor.withValues(alpha: 0.2)
              : AppTheme.successColor.withValues(alpha: 0.15),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
            side: BorderSide(
              color: AppTheme.successColor.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      WidgetSafetyUtils.safeShowSnackBar(
        context,
        'خطا در ذخیره پروفایل: $e',
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.errorColor.withValues(alpha: 0.2)
            : AppTheme.errorColor.withValues(alpha: 0.15),
      );
    } finally {
      WidgetSafetyUtils.safeSetState(this, () => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppTheme.goldColor,
          strokeWidth: 3,
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderPreview(),
            SizedBox(height: 20.h),
            _buildTextArea(
              controller: _bioCtr,
              label: 'بایو (نمایش در لیست مربیان)',
              hint: 'در چند خط کوتاه خودت را معرفی کن...',
              maxLines: 4,
            ),
            SizedBox(height: 16.h),
            _buildSectionTitle('تخصص‌ها'),
            SizedBox(height: 8.h),
            _buildChips(),
            SizedBox(height: 20.h),
            _buildNumberField(
              controller: _experienceYearsCtr,
              label: 'سال‌های تجربه',
              icon: LucideIcons.badgeCheck,
              validator: (v) => v!.isEmpty
                  ? null
                  : (int.tryParse(v) == null ? 'عدد نامعتبر' : null),
            ),
            SizedBox(height: 24.h),
            _buildCertificatesSection(),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.goldColor,
                  foregroundColor: AppTheme.onGoldColor,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  elevation: isDark ? 4 : 2,
                  shadowColor: AppTheme.goldColor.withValues(alpha: 0.3),
                ),
                icon: Icon(
                  LucideIcons.save,
                  size: 20.sp,
                ),
                label: Text(
                  'ذخیره پروفایل مربی',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: context.textColor,
        fontSize: 14.sp,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildHeaderPreview() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = (_profile?.fullName.isNotEmpty ?? false)
        ? _profile!.fullName
        : _profile?.username ?? 'مربی';
    final avatarUrl = _profile?.avatarUrl;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: isDark ? 0.3 : 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : AppTheme.goldColor.withValues(alpha: 0.08),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.goldColor.withValues(alpha: 0.5),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.goldColor.withValues(alpha: 0.2),
                  blurRadius: 8.r,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 32.r,
              backgroundColor: AppTheme.goldColor.withValues(alpha: 0.2),
              backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                  ? NetworkImage(avatarUrl)
                  : null,
              child: (avatarUrl == null || avatarUrl.isEmpty)
                  ? Text(
                      (name.isNotEmpty ? name[0] : 'T').toUpperCase(),
                      style: TextStyle(
                        color: AppTheme.onGoldColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20.sp,
                      ),
                    )
                  : null,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: context.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  _bioCtr.text.isNotEmpty
                      ? _bioCtr.text
                      : 'بایو نمایش داده می‌شود...',
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 13.sp,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChips() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: _allSpecializations.map((s) {
        final selected = _selectedSpecs.contains(s);
        return InkWell(
          onTap: () {
            setState(() {
              if (selected) {
                _selectedSpecs.remove(s);
              } else {
                _selectedSpecs.add(s);
              }
            });
          },
          borderRadius: BorderRadius.circular(18.r),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: selected
                  ? AppTheme.goldColor
                  : (isDark
                      ? context.cardColor.withValues(alpha: 0.6)
                      : context.separatorColor.withValues(alpha: 0.3)),
              border: Border.all(
                color: selected
                    ? AppTheme.goldColor
                    : (isDark
                        ? context.separatorColor
                        : AppTheme.goldColor.withValues(alpha: 0.3)),
                width: selected ? 0 : 1.5,
              ),
              borderRadius: BorderRadius.circular(18.r),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppTheme.goldColor.withValues(alpha: 0.3),
                        blurRadius: 8.r,
                        offset: Offset(0, 2.h),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? LucideIcons.check : LucideIcons.plus,
                  size: 14.sp,
                  color: selected
                      ? AppTheme.onGoldColor
                      : AppTheme.goldColor,
                ),
                SizedBox(width: 6.w),
                Text(
                  s,
                  style: TextStyle(
                    color: selected
                        ? AppTheme.onGoldColor
                        : context.textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.sp,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextArea({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 3,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(
        color: context.textColor,
        fontSize: 14.sp,
        height: 1.5,
      ),
      decoration: _inputDecoration(
        label: label,
        hint: hint,
        icon: LucideIcons.fileText,
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: TextStyle(
        color: context.textColor,
        fontSize: 14.sp,
      ),
      validator: validator,
      decoration: _inputDecoration(label: label, icon: icon),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    IconData? icon,
    String? hint,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(
        color: context.textSecondary,
        fontSize: 13.sp,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: TextStyle(
        color: context.textSecondary.withValues(alpha: 0.7),
        fontSize: 13.sp,
      ),
      prefixIcon: icon != null
          ? Icon(
              icon,
              color: AppTheme.goldColor,
              size: 20.sp,
            )
          : null,
      filled: true,
      fillColor: isDark
          ? context.cardColor.withValues(alpha: 0.5)
          : context.cardColor,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: BorderSide(
          color: isDark
              ? context.separatorColor
              : AppTheme.goldColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: BorderSide(
          color: AppTheme.goldColor,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: BorderSide(
          color: AppTheme.errorColor.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: BorderSide(
          color: AppTheme.errorColor,
          width: 2,
        ),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
    );
  }

  Widget _buildCertificatesSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: isDark ? 0.3 : 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : AppTheme.goldColor.withValues(alpha: 0.08),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppTheme.goldColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  LucideIcons.award,
                  color: AppTheme.goldColor,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'مدارک و گواهینامه‌ها',
                  style: TextStyle(
                    color: context.textColor,
                    fontSize: 17.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => const CertificateUploadScreen(),
                    ),
                  );
                },
                icon: Icon(
                  LucideIcons.plus,
                  size: 16.sp,
                ),
                label: Text(
                  'افزودن',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.goldColor,
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    side: BorderSide(
                      color: AppTheme.goldColor.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            'مدارک خود را آپلود کنید تا در پروفایل عمومی نمایش داده شوند',
            style: TextStyle(
              color: context.textSecondary,
              fontSize: 13.sp,
              height: 1.5,
            ),
          ),
          SizedBox(height: 16.h),
          FutureBuilder<List<Certificate>>(
            future: _loadCertificates(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.h),
                    child: CircularProgressIndicator(
                      color: AppTheme.goldColor,
                      strokeWidth: 3,
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppTheme.errorColor.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.alertCircle,
                        color: AppTheme.errorColor,
                        size: 20.sp,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          'خطا در بارگذاری مدارک',
                          style: TextStyle(
                            color: AppTheme.errorColor,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final certificates = snapshot.data ?? [];

              if (certificates.isEmpty) {
                return Container(
                  padding: EdgeInsets.symmetric(vertical: 32.h, horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: isDark
                        ? context.cardColor.withValues(alpha: 0.5)
                        : context.separatorColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: isDark
                          ? context.separatorColor
                          : AppTheme.goldColor.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.award,
                        color: context.textSecondary,
                        size: 48.sp,
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'هنوز مدرکی ثبت نشده',
                        style: TextStyle(
                          color: context.textColor,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'برای شروع، اولین مدرک خود را آپلود کنید',
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 12.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              // Group certificates by type
              final Map<CertificateType, List<Certificate>>
                  groupedCertificates = {};
              for (final certificate in certificates) {
                if (!groupedCertificates.containsKey(certificate.type)) {
                  groupedCertificates[certificate.type] = [];
                }
                groupedCertificates[certificate.type]!.add(certificate);
              }

              return Column(
                children: groupedCertificates.entries.map((entry) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 16.h),
                    child: CertificateCarousel(
                      title: _getCertificateTypeTitle(entry.key),
                      certificates: entry.value,
                      onCertificateTap: (certificate) {
                        if (certificate.certificateUrl != null) {
                          _showImageDialog(certificate.certificateUrl!);
                        }
                      },
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // Show image dialog
  void _showImageDialog(String imageUrl) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(16.w),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.transparent,
            child: Center(
              child: GestureDetector(
                onTap: () {}, // Prevent closing when tapping on image
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.95,
                    maxHeight: MediaQuery.of(context).size.height * 0.85,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 20.r,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20.r),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: context.cardColor,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.goldColor,
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          padding: EdgeInsets.all(32.w),
                          decoration: BoxDecoration(
                            color: context.cardColor,
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_not_supported,
                                  color: context.textSecondary,
                                  size: 64.sp,
                                ),
                                SizedBox(height: 16.h),
                                Text(
                                  'خطا در بارگذاری تصویر',
                                  style: TextStyle(
                                    color: context.textColor,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<List<Certificate>> _loadCertificates() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return [];

      return await CertificateService.getAllTrainerCertificates(user.id);
    } catch (e) {
      // به جای throw کردن، لیست خالی برمی‌گردانیم تا برنامه کرش نکند
      debugPrint('_loadCertificates error: $e');
      return [];
    }
  }

  String _getCertificateTypeTitle(CertificateType type) {
    switch (type) {
      case CertificateType.coaching:
        return 'گواهینامه‌های مربیگری';
      case CertificateType.championship:
        return 'قهرمانی‌ها و مدال‌ها';
      case CertificateType.education:
        return 'تحصیلات و مدارک علمی';
      case CertificateType.specialization:
        return 'تخصص‌ها و مهارت‌ها';
      case CertificateType.achievement:
        return 'دستاوردها';
      case CertificateType.other:
        return 'سایر مدارک';
    }
  }
}
