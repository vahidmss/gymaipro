import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/utils/date_utils.dart' as du;
import 'package:supabase_flutter/supabase_flutter.dart';

class TrainerRequestsTab extends StatefulWidget {
  const TrainerRequestsTab({super.key});

  @override
  State<TrainerRequestsTab> createState() => _TrainerRequestsTabState();
}

class _TrainerRequestsTabState extends State<TrainerRequestsTab> {
  final SupabaseClient _client = Supabase.instance.client;
  bool _loading = true;
  List<Map<String, dynamic>> _items = const [];
  Map<String, Map<String, dynamic>> _userProfiles = const {};

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

      final res = await _client
          .from('trainer_subscriptions')
          .select(
            'id,user_id,service_type,status,program_status,created_at,metadata,payment_transaction_id',
          )
          .eq('trainer_id', current.id)
          // نمایش درخواست‌های در انتظار + پرداخت‌شده/فعال که هنوز برنامه ندارند یا تاخیردارند
          .or('status.eq.pending,status.eq.paid,status.eq.active')
          .or('program_status.eq.not_started,program_status.eq.delayed')
          .order('created_at', ascending: false);

      final items = List<Map<String, dynamic>>.from(res as List);

      final userIds = items
          .map((e) => e['user_id'] as String?)
          .whereType<String>()
          .toSet()
          .toList();

      final Map<String, Map<String, dynamic>> profilesById = {};
      if (userIds.isNotEmpty) {
        try {
          // Supabase dart: به‌جای in_ از or استفاده می‌کنیم برای سازگاری
          final orExpr = userIds.map((id) => 'id.eq.$id').join(',');
          final profs = await _client
              .from('profiles')
              .select('id, first_name, last_name, username, avatar_url')
              .or(orExpr);
          for (final p in (profs as List)) {
            final id = p['id'] as String?;
            if (id != null) {
              profilesById[id] = Map<String, dynamic>.from(
                p as Map<dynamic, dynamic>,
              );
            }
          }
        } catch (_) {}
      }

      _items = items;
      _userProfiles = profilesById;
    } catch (_) {
      _items = const [];
      _userProfiles = const {};
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openBuilder(Map<String, dynamic> row) {
    final String userId = row['user_id'] as String;
    final String serviceType = row['service_type'] as String? ?? 'training';
    final String? buyerName = row['metadata']?['buyer_name'] as String?;
    final String? paymentTxId = row['payment_transaction_id'] as String?;
    final String? subscriptionId = row['id'] as String?; // خود اشتراک

    if (serviceType == 'diet') {
      Navigator.of(context).pushNamed(
        '/meal-plan-builder',
        arguments: {
          'planId': null,
          'targetUserId': userId,
          'targetUserName': buyerName,
          'subscriptionId': subscriptionId,
          'paymentTransactionId': paymentTxId,
        },
      );
    } else {
      Navigator.of(context).pushNamed(
        '/workout-program-builder',
        arguments: {
          'programId': null,
          'targetUserId': userId,
          'targetUserName': buyerName,
          'subscriptionId': subscriptionId,
          'paymentTransactionId': paymentTxId,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_items.isEmpty) {
      return const Center(
        child: Text(
          'درخواستی یافت نشد',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(12.w),
        itemBuilder: (ctx, i) {
          final row = _items[i];
          final service = row['service_type'] as String? ?? 'training';
          final buyerNameMeta = row['metadata']?['buyer_name'] as String? ?? '';
          final uid = row['user_id'] as String?;
          final prof = uid != null ? _userProfiles[uid] : null;
          final displayName = (() {
            final first = (prof?['first_name'] as String?)?.trim() ?? '';
            final last = (prof?['last_name'] as String?)?.trim() ?? '';
            final combined = '$first $last'.trim();
            if (combined.isNotEmpty) return combined;
            final meta = buyerNameMeta.trim();
            if (meta.isNotEmpty) return meta;
            return (prof?['username'] as String?)?.trim() ?? 'کاربر';
          })();
          final avatarUrl = (prof?['avatar_url'] as String?)?.trim();
          final createdAt = DateTime.tryParse(
            row['created_at'] as String? ?? '',
          );
          final subtitle = createdAt != null ? du.toJalali(createdAt) : '';

          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18.r),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1C1F26),
                  Color(0xFF212733),
                  Color(0xFF1A1F27),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x66000000),
                  blurRadius: 12.r,
                  offset: Offset(0.w, 6.h),
                ),
              ],
              border: Border.all(color: const Color(0x22FFFFFF)),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18.r),
                onTap: () => _openBuilder(row),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Avatar(
                            avatarUrl: avatarUrl,
                            displayName: displayName,
                          ),
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
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16.sp,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10.w,
                                        vertical: 4.h,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: service == 'diet'
                                              ? [
                                                  const Color(0xFF27402A),
                                                  const Color(0xFF1E2F22),
                                                ]
                                              : [
                                                  const Color(0xFF233248),
                                                  const Color(0xFF1B2637),
                                                ],
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        service == 'diet'
                                            ? 'برنامه غذایی'
                                            : 'برنامه تمرینی',
                                        style: TextStyle(
                                          color: service == 'diet'
                                              ? const Color(0xFF9CD67A)
                                              : const Color(0xFF76B6FF),
                                          fontSize: 12.sp,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                if (subtitle.isNotEmpty)
                                  Text(
                                    'در تاریخ $subtitle',
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Divider(height: 1.h, color: const Color(0x22FFFFFF)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pushNamed(
                                  '/trainer-profile',
                                  arguments: row['user_id'] as String,
                                );
                              },
                              icon: const Icon(Icons.person_outline, size: 18),
                              label: const Text('پروفایل'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pushNamed(
                                  '/chat',
                                  arguments: {
                                    'otherUserId': row['user_id'] as String,
                                    'otherUserName': displayName,
                                  },
                                );
                              },
                              icon: Icon(
                                Icons.chat_bubble_outline,
                                size: 18.sp,
                              ),
                              label: const Text('گفتگو'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _openBuilder(row),
                              icon: Icon(
                                service == 'diet'
                                    ? Icons.restaurant_outlined
                                    : Icons.fitness_center,
                                size: 18.sp,
                              ),
                              label: Text(
                                service == 'diet' ? 'ساخت رژیم' : 'ساخت تمرین',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemCount: _items.length,
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(999.r),
      child: Container(
        width: 40.w,
        height: 40.h,
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
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
