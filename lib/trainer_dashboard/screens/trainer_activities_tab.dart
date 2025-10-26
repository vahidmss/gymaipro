import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/date_utils.dart' as du;
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final current = _client.auth.currentUser;
      if (current == null) {
        setState(() {
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

          final Map<String, Map<String, dynamic>> profilesById = {};
          if (userIds.isNotEmpty) {
            try {
              final orExpr = userIds.map((id) => 'id.eq.$id').join(',');
              final profs = await _client
                  .from('profiles')
                  .select('id, first_name, last_name, username, avatar_url')
                  .or(orExpr);
              for (final p in (profs as List)) {
                final id = p['id'] as String?;
                if (id != null) {
                  final map = Map<String, dynamic>.from(
                    p as Map<dynamic, dynamic>,
                  );
                  final raw = (map['avatar_url'] as String?)?.trim();
                  final resolved = await _resolveAvatarUrl(raw);
                  map['avatar_resolved_url'] = resolved ?? raw;
                  profilesById[id] = map;
                }
              }
            } catch (_) {}
          }

          // Optional: resolve any avatar present on items themselves
          final resolvedItems = <Map<String, dynamic>>[];
          for (final it in vitems) {
            final raw = (it['avatar_url'] as String?)?.trim();
            final resolved = await _resolveAvatarUrl(raw);
            final merged = Map<String, dynamic>.from(it);
            merged['avatar_resolved_url'] = resolved ?? raw;
            resolvedItems.add(merged);
          }

          setState(() {
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

      // 2) دریافت پروفایل‌ها به صورت جدا برای پرهیز از مشکلات RLS در join
      final Map<String, Map<String, dynamic>> profilesById = {};
      final userIds = items
          .map((e) => e['user_id'] as String?)
          .whereType<String>()
          .toSet()
          .toList();
      if (userIds.isNotEmpty) {
        try {
          final orExpr = userIds.map((id) => 'id.eq.$id').join(',');
          final profs = await _client
              .from('profiles')
              .select('id, first_name, last_name, username, avatar_url')
              .or(orExpr);
          for (final p in (profs as List)) {
            final id = p['id'] as String?;
            if (id != null) {
              final map = Map<String, dynamic>.from(p as Map<dynamic, dynamic>);
              final raw = (map['avatar_url'] as String?)?.trim();
              final resolved = await _resolveAvatarUrl(raw);
              map['avatar_resolved_url'] = resolved ?? raw;
              profilesById[id] = map;
            }
          }
        } catch (_) {}
      }

      setState(() {
        _items = items;
        _profilesById = profilesById;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _items = const [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Center(child: Text('فعلاً برنامه ارائه‌شده‌ای وجود ندارد')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: EdgeInsets.all(12.w),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
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
          final expiryAt = DateTime.tryParse(
            it['expiry_date'] as String? ?? '',
          );
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

          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              color: AppTheme.cardColor,
              border: Border.all(
                color: AppTheme.goldColor.withValues(alpha: 0.12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 14.r,
                  offset: Offset(0.w, 8.h),
                ),
              ],
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A1A1A),
                  Color(0xFF1F1F1F),
                  Color(0xFF232323),
                ],
              ),
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
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16.sp,
                                      letterSpacing: 0.1,
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
                                      ? const Color(0xFFB4E197)
                                      : AppTheme.goldColor,
                                  bg1: serviceType == 'diet'
                                      ? const Color(0xFF284029)
                                      : const Color(0xFF3A2E12),
                                  bg2: serviceType == 'diet'
                                      ? const Color(0xFF213321)
                                      : const Color(0xFF2B2310),
                                ),
                                const SizedBox(width: 6),
                                _Chip(
                                  text: programStatus == 'completed'
                                      ? 'تکمیل شده'
                                      : 'در حال انجام',
                                  fg: programStatus == 'completed'
                                      ? AppTheme.goldColor
                                      : Colors.white70,
                                  bg1: programStatus == 'completed'
                                      ? const Color(0xFF3B3320)
                                      : const Color(0xFF2A2A2A),
                                  bg2: programStatus == 'completed'
                                      ? const Color(0xFF2A2417)
                                      : const Color(0xFF222222),
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
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14.sp,
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
                                        color: Colors.white60,
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
                                          color: Colors.white38,
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
                                        color: Colors.white38,
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
      child: Text(text, style: TextStyle(color: fg, fontSize: 12)),
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(999.r),
      child: Container(
        width: 44.w,
        height: 44.h,
        color: const Color(0xFF222222),
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
                          ),
                        ),
                      ),
              )
            : _Initials(initials: initials),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.initials});
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
