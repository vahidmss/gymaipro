import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymaipro/profile/services/confidential_user_info_service.dart';
import 'package:gymaipro/services/trainer_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/user_profile/services/user_profile_service.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({required this.userId, super.key});
  final String userId;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  bool _hasTrainerAccess = false;
  bool _confHasConsented = false;
  Map<String, dynamic>?
  _confidentialData; // photos_visible_to_trainer, photo_album, lifestyle_preferences
  String _selectedPhotoTypeTrainer = 'front';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Map<String, String> _photoTypeLabels() => {
    'front': 'جلو',
    'back': 'پشت',
    'side': 'کنار',
  };

  // compare/timeline helpers removed per simplified requirements

  String _formatJalali(DateTime dt) {
    final j = Jalali.fromDateTime(dt);
    return '${j.year}/${j.month.toString().padLeft(2, '0')}/${j.day.toString().padLeft(2, '0')}';
  }

  Future<void> _load() async {
    try {
      _profile = await UserProfileService.fetchProfile(widget.userId);
      // Check if current viewer is an active trainer of this user
      final viewerId = Supabase.instance.client.auth.currentUser?.id;
      if (viewerId != null && viewerId.isNotEmpty) {
        try {
          final trainerService = TrainerService();
          final isTrainer = await trainerService.isClientOfTrainer(
            widget.userId,
            viewerId,
          );
          if (isTrainer) {
            _hasTrainerAccess = true;
            // Load consent and confidential data for this profile
            _confHasConsented =
                await ConfidentialUserInfoService.getConsentStatusForProfile(
                  widget.userId,
                );
            if (_confHasConsented) {
              _confidentialData =
                  await ConfidentialUserInfoService.loadUserDataForProfile(
                    widget.userId,
                  );
            }
          }
        } catch (_) {}
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final int tabCount = _hasTrainerAccess ? 2 : 1;
    return DefaultTabController(
      length: tabCount,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.backgroundColor,
          elevation: 0,
          title: const Text(
            'پروفایل کاربر',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          bottom: _hasTrainerAccess
              ? const TabBar(
                  indicatorColor: AppTheme.goldColor,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  tabs: [
                    Tab(text: 'نمای کلی'),
                    Tab(text: 'حرفِ خودمونی'),
                  ],
                )
              : null,
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.goldColor),
              )
            : _profile == null
            ? const Center(
                child: Text(
                  'پروفایل یافت نشد',
                  style: TextStyle(color: Colors.white70),
                ),
              )
            : _hasTrainerAccess
            ? TabBarView(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.all(16.w),
                    child: _buildContent(),
                  ),
                  SingleChildScrollView(
                    padding: EdgeInsets.all(16.w),
                    child: _buildTrainerConfidentialTab(),
                  ),
                ],
              )
            : SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: _buildContent(),
              ),
      ),
    );
  }

  Widget _buildContent() {
    final firstName = (_profile?['first_name'] ?? '').toString();
    final lastName = (_profile?['last_name'] ?? '').toString();
    final username = (_profile?['username'] ?? '').toString();
    String avatarUrl = (_profile?['avatar_url'] ?? '').toString();
    if (avatarUrl.toLowerCase() == 'null') avatarUrl = '';
    final createdAt = (_profile?['created_at'] ?? '').toString();
    final isTrainer = (_profile?['role'] ?? '').toString() == 'trainer';
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final bool isSelf = currentUserId != null && currentUserId == widget.userId;

    final displayName =
        [
          firstName,
          lastName,
        ].where((e) => e.isNotEmpty).toList().join(' ').isNotEmpty
        ? [firstName, lastName].where((e) => e.isNotEmpty).toList().join(' ')
        : (username.isNotEmpty ? username : 'کاربر');

    // تاریخ عضویت شمسی + مدت عضویت
    String membershipJalali = '';
    String membershipAge = '';
    try {
      final dt = DateTime.tryParse(createdAt);
      if (dt != null) {
        final j = Jalali.fromDateTime(dt);
        membershipJalali =
            '${j.year}/${j.month.toString().padLeft(2, '0')}/${j.day.toString().padLeft(2, '0')}';
        final days = DateTime.now().difference(dt).inDays;
        membershipAge = days >= 365
            ? '${(days / 365).floor()} سال'
            : (days >= 30 ? '${(days / 30).floor()} ماه' : '$days روز');
      }
    } catch (_) {}

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF141E30), Color(0xFF243B55)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 12.r,
                offset: Offset(0.w, 6.h),
              ),
            ],
            border: Border.all(color: Colors.white10),
          ),
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (avatarUrl.isEmpty) return;
                  showDialog(
                    context: context,
                    barrierColor: Colors.black87,
                    builder: (_) => Dialog(
                      backgroundColor: Colors.transparent,
                      insetPadding: EdgeInsets.all(16.w),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16.r),
                        child: AspectRatio(
                          aspectRatio: 3 / 4,
                          child: Image.network(avatarUrl, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 34,
                  backgroundColor: AppTheme.goldColor,
                  backgroundImage:
                      (avatarUrl.isNotEmpty && avatarUrl.startsWith('http'))
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl.isEmpty
                      ? Text(
                          (displayName.isNotEmpty ? displayName[0] : 'ک'),
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 20.sp,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18.sp,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (username.isNotEmpty)
                          _chip(text: '@$username', icon: LucideIcons.atSign),
                        _chip(
                          text: isTrainer ? 'مربی' : 'کاربر',
                          icon: isTrainer
                              ? LucideIcons.badgeCheck
                              : LucideIcons.user,
                        ),
                        if (membershipJalali.isNotEmpty)
                          _chip(
                            text: 'عضویت: $membershipJalali',
                            icon: LucideIcons.calendar,
                          ),
                        if (membershipAge.isNotEmpty)
                          _chip(
                            text: membershipAge,
                            icon: LucideIcons.hourglass,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const SizedBox.shrink(),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (!isSelf)
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.white12),
            ),
            padding: EdgeInsets.all(12.w),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/workout-program-builder',
                      arguments: {
                        'targetUserId': widget.userId,
                        'targetUserName': displayName,
                      },
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.goldColor),
                    foregroundColor: AppTheme.goldColor,
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 10.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  icon: const Icon(LucideIcons.dumbbell, size: 18),
                  label: const Text('ارسال برنامه تمرینی'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/meal-plan-builder',
                      arguments: {
                        'targetUserId': widget.userId,
                        'targetUserName': displayName,
                      },
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.goldColor),
                    foregroundColor: AppTheme.goldColor,
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 10.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  icon: const Icon(LucideIcons.utensils, size: 18),
                  label: const Text('ارسال رژیم غذایی'),
                ),
              ],
            ),
          ),
        _buildStatusAndHighlights(),
      ],
    );
  }

  Widget _buildTrainerConfidentialTab() {
    if (!_confHasConsented) {
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.lock, color: Colors.white70),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'شاگرد هنوز دسترسی به اطلاعات محرمانه را تایید نکرده است.',
                style: GoogleFonts.vazirmatn(color: Colors.white70),
              ),
            ),
          ],
        ),
      );
    }

    final prefs =
        (_confidentialData?['lifestyle_preferences']
            as Map<String, dynamic>?) ??
        {};
    final photosVisible =
        (_confidentialData?['photos_visible_to_trainer'] ?? false) == true;
    final List<dynamic> album =
        (_confidentialData?['photo_album'] as List<dynamic>?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Conversational intro
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0x221F2937), Color(0x11000000)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.white12),
          ),
          child: Text(
            'سلام مربی! اینجا هرچی لازمه از من بدونی خودمونی برات نوشتم تا بتونی بهترین برنامه رو بچینی.',
            style: GoogleFonts.vazirmatn(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),

        _trainerCard(
          icon: LucideIcons.heart,
          title: 'سلامت و شرایط خاص',
          lines: [
            _kv('شرایط پزشکی', prefs['medical_conditions']),
            _kv('داروها', prefs['medications']),
            _kv('آلرژی‌ها', prefs['allergies']),
            _kv('تماس اضطراری', prefs['emergency_contact']),
            _kv('پزشک', prefs['doctor_name']),
            _kv('تلفن پزشک', prefs['doctor_phone']),
            _kv('یادداشت سلامت', prefs['health_notes']),
          ],
        ),
        const SizedBox(height: 12),
        _trainerCard(
          icon: LucideIcons.target,
          title: 'هدف‌ها و انگیزه‌ها',
          lines: [
            _kv('اهداف اصلی', prefs['primary_goals']),
            _kv('اهداف فرعی', prefs['secondary_goals']),
            _kv('وزن هدف', prefs['target_weight']),
            _kv('درصد چربی هدف', prefs['target_body_fat']),
            _kv('انگیزه/چالش‌ها', prefs['motivation']),
          ],
        ),
        const SizedBox(height: 12),
        _trainerCard(
          icon: LucideIcons.sparkles,
          title: 'سبک زندگی و علایق',
          lines: [
            _kv('شرایط زندگی', prefs['life_conditions']),
            _kv('علایق غذایی', prefs['food_preferences']),
            _kv('الگوی خواب', prefs['sleep_pattern']),
            _kv('سیگار', prefs['smoking']),
            _kv('الکل', prefs['alcohol']),
            _kv('نکات اضافه', prefs['additional_info']),
          ],
        ),
        const SizedBox(height: 12),
        if (photosVisible)
          _trainerPhotosSection(album)
        else
          _hiddenPhotosNote(),
      ],
    );
  }

  Widget _trainerCard({
    required IconData icon,
    required String title,
    required List<Widget> lines,
  }) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.goldColor, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...lines.where((w) => w != const SizedBox.shrink()),
        ],
      ),
    );
  }

  Widget _kv(String label, dynamic value) {
    final String v = (value ?? '').toString();
    if (v.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(color: Colors.white70)),
          Expanded(
            child: Text(v, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _trainerPhotosSection(List<dynamic> album) {
    if (album.isEmpty) {
      return _emptyPhotosNote();
    }

    // Normalize and sort by date desc
    final List<Map<String, dynamic>> items =
        album
            .whereType<Map<String, dynamic>>()
            .map(
              (e) => {
                'url': (e['url'] ?? '').toString(),
                'type': (e['type'] ?? 'front').toString(),
                'taken_at': DateTime.tryParse((e['taken_at'] ?? '').toString()),
              },
            )
            .where(
              (e) => e['url'].toString().isNotEmpty && e['taken_at'] != null,
            )
            .cast<Map<String, dynamic>>()
            .toList()
          ..sort(
            (a, b) => (b['taken_at'] as DateTime).compareTo(
              a['taken_at'] as DateTime,
            ),
          );

    final allTypes = <String>{...items.map((e) => e['type'] as String)};
    if (!allTypes.contains(_selectedPhotoTypeTrainer)) {
      _selectedPhotoTypeTrainer = allTypes.isNotEmpty
          ? allTypes.first
          : 'front';
    }

    final List<Map<String, dynamic>> filtered = items
        .where((e) => e['type'] == _selectedPhotoTypeTrainer)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            Icon(LucideIcons.camera, color: AppTheme.goldColor, size: 18),
            SizedBox(width: 8),
            Text(
              'آلبوم عکس‌های شاگرد',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Type filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _photoTypeLabels().entries.map((entry) {
              final type = entry.key;
              final label = entry.value;
              final bool selected = _selectedPhotoTypeTrainer == type;
              final bool enabled = allTypes.contains(type);
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ChoiceChip(
                  selected: selected,
                  onSelected: enabled
                      ? (_) => setState(() => _selectedPhotoTypeTrainer = type)
                      : null,
                  label: Text(label, style: GoogleFonts.vazirmatn()),
                  selectedColor: AppTheme.goldColor,
                  backgroundColor: const Color(0xFF111111),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : Colors.grey[300],
                  ),
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: enabled
                          ? AppTheme.goldColor.withValues(alpha: 0.5)
                          : Colors.grey.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        // Grid of selected type with date captions
        if (filtered.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.78,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final p = filtered[index];
              final dt = p['taken_at'] as DateTime;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _openTrainerPhotoPreview(p['url'] as String),
                      borderRadius: BorderRadius.circular(10.r),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10.r),
                        child: Image.network(
                          p['url'] as String,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Image.asset(
                                'images/food_placeholder.png',
                                fit: BoxFit.cover,
                              ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatJalali(dt),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.vazirmatn(
                      color: Colors.white70,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              );
            },
          )
        else
          _emptyPhotosNote(),
      ],
    );
  }

  void _openTrainerPhotoPreview(String url) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF1A1A1A),
          insetPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 24.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.98,
            height: MediaQuery.of(context).size.height * 0.9,
            padding: EdgeInsets.all(12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.image,
                      color: AppTheme.goldColor,
                      size: 18.sp,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'نمایش عکس',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(LucideIcons.x, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: ColoredBox(
                      color: const Color(0xFF111111),
                      child: InteractiveViewer(
                        maxScale: 4,
                        child: Image.network(
                          url,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.goldColor,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stack) => Image.asset(
                            'images/food_placeholder.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _hiddenPhotosNote() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.eyeOff, color: Colors.white70, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'عکس‌های پیشرفت فعلاً برای مربی قابل نمایش نیستند.',
              style: GoogleFonts.vazirmatn(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyPhotosNote() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.imageOff, color: Colors.white70, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'فعلاً عکسی در آلبوم ثبت نشده.',
              style: GoogleFonts.vazirmatn(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusAndHighlights() {
    final isTrainer = (_profile?['role'] ?? '').toString() == 'trainer';
    final bio = (_profile?['bio'] ?? '').toString();
    return Column(
      children: [
        if (bio.isNotEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0x22FFFFFF), Color(0x11000000)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.quote, color: AppTheme.goldColor, size: 18.sp),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    bio,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Row(
          children: [
            Expanded(
              child: _metricCard(
                title: 'نکات برجسته',
                icon: LucideIcons.sparkles,
                content: bio.isNotEmpty ? bio : '—',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _metricCard(
                title: isTrainer ? 'شاگردان' : 'فعالیت‌ها',
                icon: isTrainer ? LucideIcons.users : LucideIcons.activity,
                content: isTrainer ? '—' : '—',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _metricCard(
                title: 'تخصص',
                icon: LucideIcons.brain,
                content: (_profile?['specialty'] ?? '—').toString(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _metricCard({
    required String title,
    required IconData icon,
    required String content,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white10),
      ),
      padding: EdgeInsets.all(12.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.goldColor, size: 18),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _chip({required String text, required IconData icon}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.goldColor, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
