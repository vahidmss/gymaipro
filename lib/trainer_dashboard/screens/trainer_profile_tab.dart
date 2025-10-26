import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/profile/models/user_profile.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_dashboard/screens/certificate_upload_screen.dart';
import 'package:gymaipro/trainer_ranking/models/certificate.dart';
import 'package:gymaipro/trainer_ranking/services/certificate_service.dart';
import 'package:gymaipro/trainer_ranking/widgets/certificate_carousel.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('پروفایل مربی با موفقیت ذخیره شد'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا در ذخیره پروفایل: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.goldColor),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderPreview(),
            const SizedBox(height: 12),
            _buildTextArea(
              controller: _bioCtr,
              label: 'بایو (نمایش در لیست مربیان)',
              hint: 'در چند خط کوتاه خودت را معرفی کن...',
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            _buildChips(),
            const SizedBox(height: 12),
            _buildNumberField(
              controller: _experienceYearsCtr,
              label: 'سال‌های تجربه',
              icon: LucideIcons.badgeCheck,
              validator: (v) => v!.isEmpty
                  ? null
                  : (int.tryParse(v) == null ? 'عدد نامعتبر' : null),
            ),
            const SizedBox(height: 16),

            // بخش مدارک
            _buildCertificatesSection(),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.goldColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                icon: const Icon(LucideIcons.save),
                label: const Text('ذخیره پروفایل مربی'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderPreview() {
    final name = (_profile?.fullName.isNotEmpty ?? false)
        ? _profile!.fullName
        : _profile?.username ?? '';
    final avatarUrl = _profile?.avatarUrl;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppTheme.goldColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppTheme.goldColor,
            backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                ? NetworkImage(avatarUrl)
                : null,
            child: (avatarUrl == null || avatarUrl.isEmpty)
                ? Text(
                    (name.isNotEmpty ? name[0] : 'T').toUpperCase(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _bioCtr.text.isNotEmpty
                      ? _bioCtr.text
                      : 'بایو نمایش داده می‌شود...',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
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
    return Wrap(
      spacing: 6,
      runSpacing: 6,
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
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: selected
                  ? AppTheme.goldColor.withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.06),
              border: Border.all(
                color: selected
                    ? AppTheme.goldColor
                    : Colors.white.withValues(alpha: 0.2),
              ),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? LucideIcons.badgeCheck : LucideIcons.plus,
                  size: 12.sp,
                  color: selected ? Colors.black : AppTheme.goldColor,
                ),
                const SizedBox(width: 4),
                Text(
                  s,
                  style: TextStyle(
                    color: selected ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 11.sp,
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
      style: const TextStyle(color: Colors.white),
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
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: _inputDecoration(label: label, icon: icon),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    IconData? icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: const TextStyle(color: Colors.white54),
      prefixIcon: icon != null
          ? Icon(icon, color: AppTheme.goldColor, size: 18)
          : null,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: AppTheme.goldColor),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12),
    );
  }

  Widget _buildCertificatesSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppTheme.goldColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.award, color: AppTheme.goldColor, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                'مدارک و گواهینامه‌ها',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => const CertificateUploadScreen(),
                    ),
                  );
                },
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('افزودن مدرک'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.goldColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'مدارک خود را آپلود کنید تا در پروفایل عمومی نمایش داده شوند',
            style: TextStyle(color: Colors.white70, fontSize: 12.sp),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Certificate>>(
            future: _loadCertificates(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.goldColor),
                );
              }

              if (snapshot.hasError) {
                return Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.alertCircle,
                        color: Colors.red,
                        size: 16.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'خطا در بارگذاری مدارک',
                          style: TextStyle(color: Colors.red, fontSize: 12.sp),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final certificates = snapshot.data ?? [];

              if (certificates.isEmpty) {
                return Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(LucideIcons.award, color: Colors.grey, size: 32.sp),
                      SizedBox(height: 8.h),
                      Text(
                        'هنوز مدرکی ثبت نشده',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'برای شروع، اولین مدرک خود را آپلود کنید',
                        style: TextStyle(
                          color: Colors.grey[600],
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
                  return CertificateCarousel(
                    title: _getCertificateTypeTitle(entry.key),
                    certificates: entry.value,
                    onCertificateTap: (certificate) {
                      if (certificate.certificateUrl != null) {
                        _showImageDialog(certificate.certificateUrl!);
                      }
                    },
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
                    maxWidth: MediaQuery.of(context).size.width * 0.9,
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        padding: EdgeInsets.all(32.w),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported,
                                color: Colors.grey[400],
                                size: 64.sp,
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                'خطا در بارگذاری تصویر',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 16.sp,
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
    );
  }

  Future<List<Certificate>> _loadCertificates() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return [];

      return await CertificateService.getAllTrainerCertificates(user.id);
    } catch (e) {
      throw Exception('خطا در بارگذاری مدارک: $e');
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
