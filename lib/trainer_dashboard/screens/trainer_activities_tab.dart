import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/profile/repositories/profile_repository.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/date_utils.dart' as du;
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrainerActivitiesTab extends StatefulWidget {
  const TrainerActivitiesTab({super.key});

  @override
  State<TrainerActivitiesTab> createState() => _TrainerActivitiesTabState();
}

class _TrainerActivitiesTabState extends State<TrainerActivitiesTab> {
  final SupabaseClient _client = Supabase.instance.client;
  bool _loading = true;
  List<Map<String, dynamic>> _items = const [];
  Map<String, Map<String, dynamic>> _profilesById = const {};

  Future<String?> _resolveAvatarUrl(String? raw) async {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('http')) return trimmed;
    final normalized = trimmed
        .replaceAll(r'\', '/')
        .replaceFirst(RegExp('^/+'), '');
    final parts = normalized.split('/');
    if (parts.length < 2) return null;
    final bucket = parts.first;
    final path = parts.sublist(1).join('/');
    try {
      final publicUrl = _client.storage.from(bucket).getPublicUrl(path);
      if (publicUrl.isNotEmpty) return publicUrl;
    } catch (_) {}
    try {
      final signed = await _client.storage
          .from(bucket)
          .createSignedUrl(path, 60 * 60 * 24);
      if (signed.isNotEmpty) return signed;
    } catch (_) {}
    return null;
  }

  String _formatTomanFromRial(int? rial) {
    if (rial == null) return '-';
    final isNegative = rial < 0;
    final toman = (rial.abs() / 10).floor();
    final s = toman.toString();
    final rev = s.split('').reversed.toList();
    final grouped = StringBuffer();
    for (int i = 0; i < rev.length; i++) {
      grouped.write(rev[i]);
      if ((i + 1) % 3 == 0 && i + 1 != rev.length) grouped.write(',');
    }
    final result = grouped.toString().split('').reversed.join();
    return '${isNegative ? '-' : ''}$result تومان';
  }

  Future<Map<String, Map<String, dynamic>>> _loadProfilesByUserIds(
    List<String> userIds,
  ) async {
    if (userIds.isEmpty) return {};
    final raw = await ProfileRepository.instance.fetchProfilesByIdsMap(
      userIds,
      columns: 'id, first_name, last_name, username, avatar_url',
    );
    final profilesById = <String, Map<String, dynamic>>{};
    for (final entry in raw.entries) {
      final map = Map<String, dynamic>.from(entry.value);
      final rawAvatar = (map['avatar_url'] as String?)?.trim();
      final resolved = await _resolveAvatarUrl(rawAvatar);
      map['avatar_resolved_url'] = resolved ?? rawAvatar;
      profilesById[entry.key] = map;
    }
    return profilesById;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!WidgetSafetyUtils.isMounted(this)) return;
    WidgetSafetyUtils.safeSetState(this, () => _loading = true);
    try {
      final current = _client.auth.currentUser;
      if (current == null) {
        WidgetSafetyUtils.safeSetState(this, () {
          _items = const [];
          _loading = false;
        });
        return;
      }

      // 0) تلاش برای خواندن از ویو ساده‌شده (اگر وجود داشته باشد)
      try {
        final viewRows = await _client
            .from('trainer_active_programs_v')
            .select()
            .eq('trainer_id', current.id)
            .order('program_registration_date', ascending: false)
            .order('purchase_date', ascending: false);

        final vitems = List<Map<String, dynamic>>.from(viewRows as List);
        if (vitems.isNotEmpty) {
          // Collect user ids and fetch profiles to reliably get avatar_url
          final userIds = vitems
              .map((e) => e['user_id'] as String?)
              .whereType<String>()
              .toSet()
              .toList();

          final profilesById = await _loadProfilesByUserIds(userIds);

          // Optional: resolve any avatar present on items themselves
          final resolvedItems = <Map<String, dynamic>>[];
          for (final it in vitems) {
            final raw = (it['avatar_url'] as String?)?.trim();
            final resolved = await _resolveAvatarUrl(raw);
            final merged = Map<String, dynamic>.from(it);
            merged['avatar_resolved_url'] = resolved ?? raw;
            resolvedItems.add(merged);
          }

          WidgetSafetyUtils.safeSetState(this, () {
            _items = resolvedItems;
            _profilesById = profilesById;
            _loading = false;
          });
          return;
        }
      } catch (_) {
        // اگر ویو نیست، از جدول خام ادامه می‌دهیم
      }

      // 1) دریافت اشتراک‌هایی که برنامه برایشان ثبت/تکمیل شده است
      final subs = await _client
          .from('trainer_subscriptions')
          .select('''
            id,
            user_id,
            service_type,
            status,
            program_status,
            final_amount,
            original_amount,
            purchase_date,
            program_registration_date,
            expiry_date,
            payment_transaction_id
          ''')
          .eq('trainer_id', current.id)
          .not('program_registration_date', 'is', null)
          .or('status.eq.active,status.eq.paid')
          .order('program_registration_date', ascending: false);

      final items = List<Map<String, dynamic>>.from(subs as List);

      final userIds = items
          .map((e) => e['user_id'] as String?)
          .whereType<String>()
          .toSet()
          .toList();
      final profilesById = await _loadProfilesByUserIds(userIds);

      WidgetSafetyUtils.safeSetState(this, () {
        _items = items;
        _profilesById = profilesById;
        _loading = false;
      });
    } catch (e) {
      WidgetSafetyUtils.safeSetState(this, () {
        _items = const [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.goldColor,
        ),
      );
    }

    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        color: AppTheme.goldColor,
        child: ListView(
          children: [
            SizedBox(height: 120.h),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.list_alt_outlined,
                    size: 64.sp,
                    color: isDark
                        ? context.textColor.withValues(alpha: 0.3)
                        : context.textSecondary,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'فعلاً برنامه ارائه‌شده‌ای وجود ندارد',
                    style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                      color: isDark
                          ? context.textColor.withValues(alpha: 0.6)
                          : context.textSecondary,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.goldColor,
      child: ListView.separated(
        padding: EdgeInsets.all(16.w),
        itemCount: _items.length,
        separatorBuilder: (_, __) => SizedBox(height: 12.h),
        itemBuilder: (context, index) {
          final it = _items[index];
          final userId = it['user_id'] as String?;
          final profile = _profilesById[userId ?? ''] ?? {};
          // در صورت استفاده از ویو، first_name/last_name/username مستقیم در آیتم است
          final first =
              (it['first_name'] as String?)?.trim() ??
              (profile['first_name'] as String?)?.trim() ??
              '';
          final last =
              (it['last_name'] as String?)?.trim() ??
              (profile['last_name'] as String?)?.trim() ??
              '';
          final username =
              (it['username'] as String?)?.trim() ??
              (profile['username'] as String?)?.trim();
          final full = '$first $last'.trim();
          final displayName = full.isNotEmpty
              ? full
              : (username != null && username.isNotEmpty ? username : 'کاربر');

          final programStatus =
              (it['program_status'] as String?) ?? 'in_progress';
          final serviceType = (it['service_type'] as String?) ?? 'training';
          final purchaseAt = DateTime.tryParse(
            it['purchase_date'] as String? ?? '',
          );
          final registeredAt = DateTime.tryParse(
            it['program_registration_date'] as String? ?? '',
          );
          
          // محاسبه expiry_date: از زمان ارسال برنامه (sent_at) تا 33 روز بعد
          // اگر sent_at در دیتابیس نبود، از program_registration_date استفاده می‌کنیم (همان زمان sent_at است)
          DateTime? expiryAt;
          if (registeredAt != null) {
            // program_registration_date همان زمان sent_at است
            expiryAt = registeredAt.add(const Duration(days: 33));
          }
          final finalAmount = it['final_amount'] as int?;
          final avatarFromItem =
              ((it['avatar_resolved_url'] as String?) ??
                      (it['avatar_url'] as String?))
                  ?.trim();
          final avatarFromProfile =
              ((profile['avatar_resolved_url'] as String?) ??
                      (profile['avatar_url'] as String?))
                  ?.trim();
          final avatarUrl =
              (avatarFromProfile != null && avatarFromProfile.isNotEmpty)
              ? avatarFromProfile
              : avatarFromItem;

          String fmtDate(DateTime? d) => d == null ? '-' : du.toJalali(d);
          String fmtAmount(int? a) => _formatTomanFromRial(a);

          final isDark = Theme.of(context).brightness == Brightness.dark;
          
          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              gradient: isDark
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        context.cardColor,
                        context.cardColor.withValues(alpha: 0.95),
                        context.veryDarkBackground,
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        context.cardColor,
                        context.cardColor.withValues(alpha: 0.98),
                        AppTheme.lightGradientStart.withValues(alpha: 0.1),
                      ],
                    ),
              border: Border.all(
                color: AppTheme.goldColor.withValues(
                  alpha: isDark ? 0.2 : 0.3,
                ),
                width: 1.5.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.goldColor.withValues(
                    alpha: isDark ? 0.15 : 0.25,
                  ),
                  blurRadius: 16.r,
                  offset: Offset(0.w, 6.h),
                  spreadRadius: 1.r,
                ),
                BoxShadow(
                  color: isDark
                      ? AppTheme.veryDarkBackground.withValues(alpha: 0.3)
                      : AppTheme.lightTextColor.withValues(alpha: 0.08),
                  blurRadius: 8.r,
                  offset: Offset(0.w, 2.h),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Avatar(avatarUrl: avatarUrl, displayName: displayName),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    displayName,
                                    style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                                      color: context.textColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14.sp,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _Chip(
                                  text: serviceType == 'diet'
                                      ? 'غذایی'
                                      : 'تمرینی',
                                  fg: serviceType == 'diet'
                                      ? AppTheme.successColor
                                      : AppTheme.goldColor,
                                  bg1: serviceType == 'diet'
                                      ? AppTheme.successColor.withValues(
                                          alpha: 0.22,
                                        )
                                      : AppTheme.goldColor.withValues(
                                          alpha: 0.2,
                                        ),
                                  bg2: serviceType == 'diet'
                                      ? AppTheme.successColor.withValues(
                                          alpha: 0.14,
                                        )
                                      : AppTheme.goldColor.withValues(
                                          alpha: 0.12,
                                        ),
                                ),
                                const SizedBox(width: 6),
                                _Chip(
                                  text: programStatus == 'completed'
                                      ? 'تکمیل شده'
                                      : 'در حال انجام',
                                  fg: programStatus == 'completed'
                                      ? AppTheme.goldColor
                                      : context.textSecondary,
                                  bg1: programStatus == 'completed'
                                      ? AppTheme.goldColor.withValues(
                                          alpha: 0.2,
                                        )
                                      : AppTheme.darkCardColor,
                                  bg2: programStatus == 'completed'
                                      ? AppTheme.goldColor.withValues(
                                          alpha: 0.12,
                                        )
                                      : context.veryDarkBackground,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.payments_outlined,
                                        size: 16.sp,
                                        color: AppTheme.goldColor,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                      fmtAmount(finalAmount),
                                      style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                                        color: AppTheme.goldColor,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15.sp,
                                      ),
                                    ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.event_available_outlined,
                                      size: 16.sp,
                                      color: Colors.white60,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'ثبت: ${fmtDate(registeredAt ?? purchaseAt)}',
                                      style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                                        color: context.textSecondary,
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.shopping_bag_outlined,
                                        size: 16.sp,
                                        color: Colors.white38,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'خرید: ${fmtDate(purchaseAt)}',
                                        style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                                          color: context.textSecondary.withValues(
                                            alpha: 0.7,
                                          ),
                                          fontSize: 12.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.lock_clock,
                                      size: 16.sp,
                                      color: Colors.white38,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'انقضا: ${fmtDate(expiryAt)}',
                                      style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                                        color: context.textSecondary.withValues(
                                          alpha: 0.7,
                                        ),
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.text,
    required this.fg,
    required this.bg1,
    required this.bg2,
  });
  final String text;
  final Color fg;
  final Color bg1;
  final Color bg2;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [bg1, bg2]),
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Text(
        text,
        style: TextStyle(
    fontFamily: AppTheme.fontFamily,
          color: fg,
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.avatarUrl, required this.displayName});
  final String? avatarUrl;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    final String initials = displayName.isNotEmpty
        ? displayName.characters.first
        : 'ک';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.3),
          width: 2.w,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldColor.withValues(alpha: 0.2),
            blurRadius: 8.r,
            spreadRadius: 1.r,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999.r),
        child: Container(
          width: 52.w,
          height: 52.h,
          color: isDark
              ? context.veryDarkBackground
              : AppTheme.lightCardColor,
          child: avatarUrl != null && avatarUrl!.isNotEmpty
              ? Image.network(
                  avatarUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _Initials(initials: initials),
                  loadingBuilder: (ctx, child, progress) => progress == null
                      ? child
                      : Center(
                          child: SizedBox(
                            width: 16.w,
                            height: 16.h,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.goldColor,
                            ),
                          ),
                        ),
                )
              : _Initials(initials: initials),
        ),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.initials});
  final String initials;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Text(
        initials,
        style: TextStyle(
    fontFamily: AppTheme.fontFamily,
          color: isDark
              ? AppTheme.goldColor
              : AppTheme.lightTextColor,
          fontWeight: FontWeight.w700,
          fontSize: 18.sp,
        ),
      ),
    );
  }
}
