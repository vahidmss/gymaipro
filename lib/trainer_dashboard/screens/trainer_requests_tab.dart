import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/meal_plan_builder/services/meal_plan_service.dart';
import 'package:gymaipro/profile/repositories/profile_repository.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/date_utils.dart' as du;
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:gymaipro/workout_plan_builder/services/workout_program_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrainerRequestsTab extends StatefulWidget {
  const TrainerRequestsTab({super.key});

  @override
  State<TrainerRequestsTab> createState() => _TrainerRequestsTabState();
}

class _TrainerRequestsTabState extends State<TrainerRequestsTab> {
  final SupabaseClient _client = Supabase.instance.client;
  final MealPlanService _mealPlanService = MealPlanService();
  final WorkoutProgramService _workoutProgramService = WorkoutProgramService();
  bool _loading = true;
  List<Map<String, dynamic>> _items = const [];
  Map<String, Map<String, dynamic>> _userProfiles = const {};
  Map<String, bool> _planSentStatus = {}; // userId -> isSent
  // Map برای ذخیره اطلاعات editable_until و expiry_date
  // key: subscription_id, value: {editable_until: DateTime?, expiry_date: DateTime?}
  Map<String, Map<String, DateTime?>> _programDates = {};

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

      // نمایش درخواست‌های در انتظار + پرداخت‌شده/فعال که هنوز برنامه ندارند، در حال انجام هستند یا تاخیردارند
      // منطق: (status IN (pending, paid, active)) AND (program_status IN (not_started, in_progress, delayed))
      // در Supabase، دو .or() پشت سر هم به معنای AND است
      final res = await _client
          .from('trainer_subscriptions')
          .select(
            'id,user_id,service_type,status,program_status,created_at,metadata,payment_transaction_id',
          )
          .eq('trainer_id', current.id)
          .or('status.eq.pending,status.eq.paid,status.eq.active')
          .or('program_status.eq.not_started,program_status.eq.in_progress,program_status.eq.delayed')
          .order('created_at', ascending: false);

      final items = List<Map<String, dynamic>>.from(res as List);

      final userIds = items
          .map((e) => e['user_id'] as String?)
          .whereType<String>()
          .toSet()
          .toList();

      final Map<String, Map<String, dynamic>> profilesById =
          userIds.isEmpty
              ? {}
              : await ProfileRepository.instance.fetchProfilesByIdsMap(
                  userIds,
                  columns: 'id, first_name, last_name, username, avatar_url',
                );

      _items = items;
      _userProfiles = profilesById;

      // بررسی وضعیت ارسال برنامه‌ها و خواندن تاریخ‌های editable_until و expiry_date
      final trainerUser = _client.auth.currentUser;
      if (trainerUser != null) {
        final sentStatusMap = <String, bool>{};
        final programDatesMap = <String, Map<String, DateTime?>>{};
        
        for (final item in items) {
          final userId = item['user_id'] as String?;
          final subscriptionId = item['id'] as String?;
          final serviceType = item['service_type'] as String? ?? 'training';
          
          if (userId != null && subscriptionId != null) {
            // بررسی وضعیت ارسال برای رژیم
            if (serviceType == 'diet') {
              try {
                final existingPlan = await _mealPlanService
                    .getExistingPlanForTrainerAndUser(userId, trainerUser.id);
                sentStatusMap[userId] = existingPlan?.sentAt != null;
                
                // خواندن editable_until و expiry_date از meal_plans
                if (existingPlan != null && existingPlan.id.isNotEmpty) {
                  try {
                    final planData = await _client
                        .from('meal_plans')
                        .select('editable_until, expiry_date, created_at, sent_at')
                        .eq('id', existingPlan.id)
                        .maybeSingle();
                    
                    if (planData != null) {
                      DateTime? editableUntil;
                      DateTime? expiryDate;
                      
                      // محاسبه editable_until و expiry_date: از زمان ارسال برنامه (sent_at)
                      final sentAtStr = planData['sent_at'] as String?;
                      if (sentAtStr != null) {
                        final sentAt = DateTime.tryParse(sentAtStr);
                        if (sentAt != null) {
                          editableUntil = sentAt.add(const Duration(days: 3));
                          expiryDate = sentAt.add(const Duration(days: 33));
                        }
                      }
                      
                      programDatesMap[subscriptionId] = {
                        'editable_until': editableUntil,
                        'expiry_date': expiryDate,
                      };
                    }
                  } catch (e) {
                    debugPrint('خطا در خواندن تاریخ‌های meal_plan: $e');
                    // در صورت خطا، از program_registration_date استفاده کن (همان زمان sent_at است)
                    // این بخش فقط برای fallback است - در حالت عادی باید sent_at وجود داشته باشد
                  }
                }
              } catch (e) {
                debugPrint('خطا در بررسی وضعیت برنامه: $e');
                sentStatusMap[userId] = false;
              }
            } else if (serviceType == 'training') {
              // بررسی وضعیت ارسال برای برنامه تمرینی - دقیقاً مثل meal plan
              try {
                final existingPrograms = await _workoutProgramService
                    .getProgramsForUserByTrainer(userId, trainerUser.id);
                final existingProgram = existingPrograms.isNotEmpty ? existingPrograms.first : null;
                sentStatusMap[userId] = existingProgram?.sentAt != null;
                
                // خواندن editable_until و expiry_date از workout_programs
                if (existingProgram != null && existingProgram.id.isNotEmpty) {
                  try {
                    final programData = await _client
                        .from('workout_programs')
                        .select('editable_until, expiry_date, created_at, sent_at')
                        .eq('id', existingProgram.id)
                        .maybeSingle();
                    
                    if (programData != null) {
                      DateTime? editableUntil;
                      DateTime? expiryDate;
                      
                      // محاسبه editable_until و expiry_date: از زمان ارسال برنامه (sent_at)
                      final sentAtStr = programData['sent_at'] as String?;
                      if (sentAtStr != null) {
                        final sentAt = DateTime.tryParse(sentAtStr);
                        if (sentAt != null) {
                          editableUntil = sentAt.add(const Duration(days: 3));
                          expiryDate = sentAt.add(const Duration(days: 33));
                        }
                      }
                      
                      programDatesMap[subscriptionId] = {
                        'editable_until': editableUntil,
                        'expiry_date': expiryDate,
                      };
                    }
                  } catch (e) {
                    debugPrint('خطا در خواندن تاریخ‌های workout_program: $e');
                    // در صورت خطا، از program_registration_date استفاده کن (همان زمان sent_at است)
                    // این بخش فقط برای fallback است - در حالت عادی باید sent_at وجود داشته باشد
                  }
                }
              } catch (e) {
                debugPrint('خطا در بررسی وضعیت برنامه تمرینی: $e');
                sentStatusMap[userId] = false;
              }
            }
          }
        }
        _planSentStatus = sentStatusMap;
        _programDates = programDatesMap;
        
        // فیلتر کردن درخواست‌هایی که مهلت ویرایششان تمام شده
        // این درخواست‌ها باید به بخش فعالیت‌ها منتقل شوند
        final now = DateTime.now();
        _items = _items.where((item) {
          final subscriptionId = item['id'] as String?;
          if (subscriptionId == null) return true;
          
          final programDates = _programDates[subscriptionId];
          final editableUntil = programDates?['editable_until'];
          
          // اگر editable_until وجود دارد و گذشته است، این درخواست را فیلتر کن
          if (editableUntil != null && now.isAfter(editableUntil)) {
            return false;
          }
          
          return true;
        }).toList();
      }
    } catch (_) {
      _items = const [];
      _userProfiles = const {};
      _planSentStatus = {};
    } finally {
      WidgetSafetyUtils.safeSetState(this, () => _loading = false);
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
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.goldColor,
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppTheme.goldColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inbox_outlined,
                size: 48.sp,
                color: AppTheme.goldColor.withValues(alpha: 0.5),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'درخواستی یافت نشد',
              style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                color: context.textColor,
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'درخواست‌های جدید اینجا نمایش داده می‌شوند',
              style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                color: context.textSecondary,
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16.w),
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
          
          // دریافت اطلاعات editable_until و expiry_date
          final subscriptionId = row['id'] as String?;
          final programDates = subscriptionId != null 
              ? _programDates[subscriptionId] 
              : null;
          final editableUntil = programDates?['editable_until'];
          final expiryDate = programDates?['expiry_date'];
          
          // بررسی اینکه آیا مهلت ویرایش گذشته است
          final isEditDeadlinePassed = editableUntil != null && DateTime.now().isAfter(editableUntil);
          
          // محاسبه روزهای باقیمانده تا انقضا
          int? daysUntilExpiry;
          if (expiryDate != null) {
            final now = DateTime.now();
            final difference = expiryDate.difference(now);
            daysUntilExpiry = difference.inDays;
          }

          final isDark = Theme.of(context).brightness == Brightness.dark;
          
          return DecoratedBox(
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: AppTheme.goldColor.withValues(
                  alpha: isDark ? 0.15 : 0.1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.2)
                      : AppTheme.goldColor.withValues(alpha: 0.05),
                  blurRadius: 8.r,
                  offset: Offset(0, 2.h),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(14.w),
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
                      SizedBox(width: 12.w),
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
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15.sp,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 4.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: service == 'diet'
                                        ? const Color(0xFF9CD67A).withValues(alpha: 0.15)
                                        : AppTheme.goldColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8.r),
                                    border: Border.all(
                                      color: service == 'diet'
                                          ? const Color(0xFF9CD67A).withValues(alpha: 0.3)
                                          : AppTheme.goldColor.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    service == 'diet'
                                        ? 'برنامه غذایی'
                                        : 'برنامه تمرینی',
                                    style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                                      color: service == 'diet'
                                          ? const Color(0xFF9CD67A)
                                          : AppTheme.goldColor,
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 6.h),
                            if (subtitle.isNotEmpty)
                              Text(
                                'در تاریخ $subtitle',
                                style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                                  color: context.textSecondary,
                                  fontSize: 11.sp,
                                ),
                              ),
                            if (daysUntilExpiry != null && daysUntilExpiry >= 0)
                              Padding(
                                padding: EdgeInsets.only(top: 4.h),
                                child: Text(
                                  'اتمام اشتراک تا $daysUntilExpiry روز دیگر',
                                  style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                                    color: daysUntilExpiry <= 7
                                        ? Colors.orange
                                        : context.textSecondary,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
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
                          icon: Icon(
                            Icons.person_outline,
                            size: 16.sp,
                            color: AppTheme.goldColor,
                          ),
                          label: Text(
                            'پروفایل',
                            style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: AppTheme.goldColor.withValues(alpha: 0.4),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            foregroundColor: AppTheme.goldColor,
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
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
                            size: 16.sp,
                            color: AppTheme.goldColor,
                          ),
                          label: Text(
                            'گفتگو',
                            style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: AppTheme.goldColor.withValues(alpha: 0.4),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            foregroundColor: AppTheme.goldColor,
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ElevatedButton.icon(
                              onPressed: isEditDeadlinePassed 
                                  ? () {
                                      // هیچ کاری انجام نده وقتی قفل است
                                    }
                                  : () => _openBuilder(row),
                              icon: Icon(
                                service == 'diet'
                                    ? Icons.restaurant_outlined
                                    : Icons.fitness_center,
                                size: 16.sp,
                              ),
                              label: Text(
                                service == 'diet'
                                    ? (_planSentStatus[uid] ?? false
                                          ? 'ویرایش رژیم'
                                          : 'ساخت رژیم')
                                    : (_planSentStatus[uid] ?? false
                                          ? 'ویرایش تمرین'
                                          : 'ساخت تمرین'),
                                style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isEditDeadlinePassed
                                    ? Colors.grey[600]
                                    : AppTheme.goldColor,
                                foregroundColor: isEditDeadlinePassed
                                    ? Colors.grey[300]
                                    : AppTheme.onGoldColor,
                                elevation: isEditDeadlinePassed ? 0 : 2,
                                shadowColor: isEditDeadlinePassed
                                    ? Colors.transparent
                                    : AppTheme.goldColor.withValues(alpha: 0.2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 10.h),
                              ),
                            ),
                            if (isEditDeadlinePassed)
                              Padding(
                                padding: EdgeInsets.only(top: 4.h),
                                child: Text(
                                  'اتمام مهلت ویرایش',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                                    color: context.textSecondary.withValues(alpha: 0.7),
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
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
        separatorBuilder: (_, __) => SizedBox(height: 12.h),
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: 48.w,
      height: 48.h,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999.r),
        child: ColoredBox(
          color: isDark
              ? context.veryDarkBackground
              : AppTheme.lightSurfaceColor,
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.goldColor.withValues(alpha: 0.15),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
    fontFamily: AppTheme.fontFamily,
            color: AppTheme.goldColor,
            fontWeight: FontWeight.w600,
            fontSize: 18.sp,
          ),
        ),
      ),
    );
  }
}
