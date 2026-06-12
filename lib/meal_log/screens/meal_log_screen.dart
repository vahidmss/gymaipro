import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// Controllers
import 'package:gymaipro/meal_log/controllers/meal_log_controller.dart';
// Screens
import 'package:gymaipro/meal_log/screens/add_food_screen.dart';
// Models
import 'package:gymaipro/meal_log/models/food_log.dart';
import 'package:gymaipro/meal_log/models/food_log_item.dart';
import 'package:gymaipro/meal_log/models/food_meal_log.dart';
// Services
import 'package:gymaipro/meal_log/services/meal_log_service.dart';
// Utils
import 'package:gymaipro/meal_log/utils/meal_plan_mapper.dart';
import 'package:gymaipro/meal_log/utils/meal_log_utils.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:shamsi_date/shamsi_date.dart';
// Widgets
import 'package:gymaipro/meal_log/widgets/daily_calorie_summary.dart';
import 'package:gymaipro/meal_log/dialogs/persian_food_log_date_picker_dialog.dart';
import 'package:gymaipro/meal_log/widgets/date_separator_widget.dart';
import 'package:gymaipro/meal_log/widgets/amount_keypad_sheet.dart';
import 'package:gymaipro/meal_log/widgets/meal_log_app_bar.dart';
import 'package:gymaipro/meal_log/widgets/meals_list_widget.dart';
import 'package:gymaipro/meal_log/data/meal_log_guide_data.dart';
import 'package:gymaipro/guide/guide.dart';
import 'package:gymaipro/meal_log/widgets/substitute_food_dialog.dart';
import 'package:gymaipro/meal_log/widgets/supplement_card.dart';
import 'package:gymaipro/meal_log/widgets/trainer_supervision_card.dart';
import 'package:gymaipro/models/food.dart';
import 'package:gymaipro/models/meal_plan.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:gymaipro/meal_plan_builder/services/meal_plan_service.dart';
import 'package:gymaipro/services/food_service.dart';
import 'package:gymaipro/dashboard/services/dashboard_cache_service.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/services/weekly_weight_service.dart';
import 'package:gymaipro/services/active_meal_plan_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
// Theme
import 'package:gymaipro/theme/app_theme.dart';

class FoodLogScreen extends StatefulWidget {
  const FoodLogScreen({super.key, this.mealPlanId});

  final String? mealPlanId;

  @override
  State<FoodLogScreen> createState() => _FoodLogScreenState();
}

class _FoodLogScreenState extends State<FoodLogScreen> {
  final FoodService _foodService = FoodService();
  final MealLogService _foodLogService = MealLogService();
  final MealLogController _controller = MealLogController();
  final ActiveMealPlanService _activeMealPlanService = ActiveMealPlanService();

  List<Food> _allFoods = [];
  bool _isLoading = true;
  FoodLog? _currentLog;
  DateTime _selectedDate = DateTime.now();
  MealPlan? _selectedPlan;
  int? _selectedSession;
  String? _activeMealPlanId;

  // Calendar preloaded data
  Map<DateTime, bool> _preloadedFoodLogDates = {};
  Map<DateTime, double> _preloadedCaloriesByDate = {};

  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    // محتوا فقط بعد از آماده شدن داده نشون داده می‌شه (بدون کش در فریم اول)
    _syncAllLocalLogsAndLoad();
    _loadProfileData();
    _loadMealPlanIfNeeded();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _registerGuides();
        _checkAndShowTour();
      }
    });
  }

  void _registerGuides() {
    try {
      registerGuide(context, MealLogGuideData.getMealLogGuide());
    } catch (e) {
      debugPrint('Error registering meal log guides: $e');
    }
  }

  Future<void> _checkAndShowTour() async {
    try {
      final guideService = Provider.of<GuideService>(context, listen: false);

      // تاخیر برای اطمینان از render شدن ویجت‌ها
      await Future<void>.delayed(const Duration(milliseconds: 800));

      // نمایش راهنما اگر هنوز نشون داده نشده
      if (mounted && guideService.shouldShowGuide('meal_log_tour')) {
        await offerGuideTourIfEligible(
          context,
          guideId: 'meal_log_tour',
          title: 'یه تور کوتاه از کالری‌شمار بریم؟',
          description:
              'خلاصهٔ کالری، تاریخ و وعده‌ها رو با هم مرور می‌کنیم تا '
              'ثبت غذا راحت‌تر بشه.',
        );
      }
    } catch (e) {
      debugPrint('Error showing meal log tour: $e');
    }
  }

  Future<void> _loadMealPlanIfNeeded() async {
    String? mealPlanId = widget.mealPlanId;

    // اگر mealPlanId از route نیامده باشد، از active meal plan service بخوانیم
    if (mealPlanId == null || mealPlanId.isEmpty) {
      mealPlanId = await _activeMealPlanService.getActiveMealPlanId();
    }

    // ذخیره mealPlanId برای استفاده در build
    SafeSetState.call(this, () {
      _activeMealPlanId = mealPlanId;
    });

    if (mealPlanId != null && mealPlanId.isNotEmpty) {
      try {
        final mealPlanService = MealPlanService();
        final plan = await mealPlanService.getPlanById(mealPlanId);
        if (plan != null) {
          final lastSession = await _foodLogService.loadLastSessionLocal(
            _selectedDate,
          );
          SafeSetState.call(this, () {
            _selectedPlan = plan;
            // بارگذاری آخرین سشن انتخاب شده (اگر وجود داشته باشد)
            _selectedSession = lastSession ?? 0; // پیش‌فرض: جلسه اول
          });
          await _mapPlanToLogIfNeeded();
        }
      } catch (e) {
        debugPrint('خطا در بارگذاری meal plan: $e');
      }
    }
  }

  bool _shouldShowTrainerCard() {
    // اگر mealPlanId از route آمده باشد یا active meal plan وجود داشته باشد
    return (widget.mealPlanId != null && widget.mealPlanId!.isNotEmpty) ||
        _selectedPlan != null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload profile data when returning to this screen
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final cacheService = DashboardCacheService();
    try {
      // بررسی کش برای profile data
      Map<String, dynamic>? cachedProfileData = cacheService.getProfileData();
      if (cachedProfileData != null) {
        SafeSetState.call(this, () {
          _profileData = cachedProfileData;
        });
        return;
      }

      // بارگذاری از API
      final profileData = await SimpleProfileService.getCurrentProfile();

      if (profileData != null && mounted) {
        // بارگذاری آخرین وزن ثبت شده (user_id در weekly_weights به profiles.id اشاره دارد)
        double? latestWeight;
        try {
          final profileId = profileData['id'] as String?;
          if (profileId != null) {
            latestWeight = await WeeklyWeightService.getLatestWeight(profileId);
            if (latestWeight != null) {
              cacheService.setLatestWeight(latestWeight);
            }
          }
        } catch (e) {
          // Error handled silently
        }

        final builtProfileData = _buildProfileData(profileData, latestWeight);

        // ذخیره در کش
        cacheService.setProfileData(builtProfileData);

        SafeSetState.call(this, () {
          _profileData = builtProfileData;
        });
      }
    } catch (e) {
      // Error handled silently
    }
  }

  Map<String, dynamic> _buildProfileData(
    Map<String, dynamic> profileData,
    double? latestWeight,
  ) {
    return {
      'id': profileData['id'] ?? '',
      'first_name': profileData['first_name'] ?? '',
      'last_name': profileData['last_name'] ?? '',
      'height': profileData['height']?.toString() ?? '0',
      'weight': profileData['weight']?.toString() ?? '0',
      'arm_circumference': profileData['arm_circumference']?.toString() ?? '',
      'chest_circumference':
          profileData['chest_circumference']?.toString() ?? '',
      'waist_circumference':
          profileData['waist_circumference']?.toString() ?? '',
      'hip_circumference': profileData['hip_circumference']?.toString() ?? '',
      'experience_level': profileData['experience_level'] ?? '',
      'preferred_training_days':
          profileData['preferred_training_days']?.join(',') ?? '',
      'preferred_training_time': profileData['preferred_training_time'] ?? '',
      'fitness_goals': profileData['fitness_goals']?.join(',') ?? '',
      'medical_conditions': profileData['medical_conditions']?.join(',') ?? '',
      'dietary_preferences':
          profileData['dietary_preferences']?.join(',') ?? '',
      'birth_date': profileData['birth_date']?.toString() ?? '',
      'gender': profileData['gender'] ?? 'male',
      'activity_level': profileData['activity_level'] ?? 'moderate',
      'weight_history': (profileData['weight_history'] as List<dynamic>?) ?? [],
      'username': profileData['username'] ?? '',
      'phone_number': profileData['phone_number'] ?? '',
      'avatar_url': profileData['avatar_url'] ?? '',
      'role': profileData['role'] ?? 'athlete',
      'latest_weight': latestWeight,
    };
  }

  Future<void> _syncAllLocalLogsAndLoad() async {
    _foodLogService.syncAllLocalLogsToDatabase();
    await _loadData();
  }

  Future<void> _loadData() async {
    SafeSetState.call(this, () {
      _isLoading = true;
    });

    // هر دو را هم‌زمان بگیر؛ یک‌بار هر دو آماده شدند، یک‌جا یک فریم کامل نشون بده (مثل اپ‌های حرفه‌ای)
    final localLogFuture = _foodLogService.loadLogLocal(_selectedDate);
    final foodsFuture = _foodService.getFoods();

    FoodLog? localLog;
    List<Food> foods;
    try {
      localLog = await localLogFuture;
    } catch (_) {}
    try {
      foods = await foodsFuture;
    } catch (e) {
      foods = [];
    }

    final logToShow = localLog ?? _buildEmptyLogForDate(_selectedDate);
    SafeSetState.call(this, () {
      _currentLog = logToShow;
      _allFoods = foods;
      _isLoading = false;
    });

    // در پس‌زمینه از سرور به‌روزرسانی کن
    await _loadCurrentLog();
    _preloadCalendarData();
  }

  Future<void> _preloadCalendarData() async {
    try {
      final client = Supabase.instance.client;
      final profile = await SimpleProfileService.getCurrentProfile();
      final userId = (profile?['id'] as String?) ?? client.auth.currentUser?.id;
      if (userId == null) return;

      // محاسبه محدوده تاریخ ماه جاری
      final now = DateTime.now();
      final gregorian = Gregorian.fromDateTime(now);
      final jalali = gregorian.toJalali();
      final startJalali = Jalali(jalali.year, jalali.month, 1);
      final endJalali = Jalali(
        jalali.year,
        jalali.month,
        _getDaysInMonth(jalali.year, jalali.month),
      );
      final startDate = startJalali.toGregorian().toDateTime();
      final endDate = endJalali.toGregorian().toDateTime();
      final startDateString = startDate.toIso8601String().substring(0, 10);
      final endDateString = endDate.toIso8601String().substring(0, 10);

      final response = await client
          .from('food_logs')
          .select('log_date, meals')
          .eq('user_id', userId)
          .gte('log_date', startDateString)
          .lte('log_date', endDateString);

      final Map<DateTime, bool> logDates = {};
      final Map<DateTime, double> caloriesMap = {};

      for (final entry in response) {
        if (entry['log_date'] != null) {
          final date = DateTime.parse(entry['log_date'] as String);
          final dateKey = DateTime(date.year, date.month, date.day);
          logDates[dateKey] = true;

          // محاسبه کالری برای این روز
          if (entry['meals'] != null) {
            try {
              final mealsJson = entry['meals'] as List<dynamic>;
              final meals = mealsJson
                  .map((m) => FoodMealLog.fromJson(m as Map<String, dynamic>))
                  .toList();

              final totals = MealLogUtils.calculateTotals(meals, _allFoods);
              caloriesMap[dateKey] = totals['calories'] ?? 0;
            } catch (e) {
              debugPrint('Error calculating calories for date: $e');
              caloriesMap[dateKey] = 0;
            }
          }
        }
      }

      SafeSetState.call(this, () {
        _preloadedFoodLogDates = logDates;
        _preloadedCaloriesByDate = caloriesMap;
      });
    } catch (e) {
      debugPrint('Error preloading calendar data: $e');
    }
  }

  int _getDaysInMonth(int year, int month) {
    if (month <= 6) return 31;
    if (month <= 11) return 30;
    return Jalali(year).isLeapYear() ? 30 : 29;
  }

  FoodLog _buildEmptyLogForDate(DateTime date) {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    return FoodLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      logDate: date,
      meals: [
        FoodMealLog(title: 'صبحانه', foods: []),
        FoodMealLog(title: 'میان‌وعده 1', foods: []),
        FoodMealLog(title: 'ناهار', foods: []),
        FoodMealLog(title: 'میان‌وعده 2', foods: []),
        FoodMealLog(title: 'شام', foods: []),
        FoodMealLog(title: 'میان‌وعده 3', foods: []),
      ],
      supplements: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _loadCurrentLog() async {
    var log = await _foodLogService.getLogForDate(_selectedDate);

    // اگر log وجود نداشت، یک log خالی با همه وعده‌ها ایجاد کن
    if (log == null) {
      final profile = await SimpleProfileService.getCurrentProfile();
      final userId =
          (profile?['id'] as String?) ??
          Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        log = FoodLog(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: userId,
          logDate: _selectedDate,
          meals: [
            FoodMealLog(title: 'صبحانه', foods: []),
            FoodMealLog(title: 'میان‌وعده 1', foods: []),
            FoodMealLog(title: 'ناهار', foods: []),
            FoodMealLog(title: 'میان‌وعده 2', foods: []),
            FoodMealLog(title: 'شام', foods: []),
            FoodMealLog(title: 'میان‌وعده 3', foods: []),
          ],
          supplements: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _foodLogService.saveLogLocal(log);
        // سعی در sync به دیتابیس (اگر آنلاین باشیم)
        try {
          await _foodLogService.saveLog(log);
        } catch (e) {
          // اگر آنلاین نبودیم، فقط local ذخیره شده
        }
      }
    }

    SafeSetState.call(this, () {
      _currentLog = log;
    });

    // Always try to map plan data if plan is selected and log is empty
    await _mapPlanToLogIfNeeded();

    // Ensure all standard meals exist in log (even if empty)
    await _ensureStandardMeals();
  }

  Future<void> _ensureStandardMeals() async {
    if (_currentLog == null) return;

    final standardMeals = [
      'صبحانه',
      'میان‌وعده 1',
      'ناهار',
      'میان‌وعده 2',
      'شام',
      'میان‌وعده 3',
    ];

    bool hasChanges = false;
    for (final mealTitle in standardMeals) {
      final exists = _currentLog!.meals.any((m) => m.title == mealTitle);
      if (!exists) {
        _currentLog!.meals.add(FoodMealLog(title: mealTitle, foods: []));
        hasChanges = true;
      }
    }

    if (hasChanges) {
      SafeSetState.call(this, () {});
      await _foodLogService.saveLogLocal(_currentLog!);
      // سعی در sync به دیتابیس (اگر آنلاین باشیم)
      try {
        await _foodLogService.saveLog(_currentLog!);
      } catch (e) {
        // اگر آنلاین نبودیم، فقط local ذخیره شده
      }
    }
  }

  Future<void> _mapPlanToLogIfNeeded() async {
    if (_selectedPlan != null &&
        _selectedSession != null &&
        _currentLog != null) {
      final mappedLog = MealPlanMapper.mapPlanToLog(
        selectedPlan: _selectedPlan!,
        selectedSession: _selectedSession!,
        currentLog: _currentLog,
      );

      if (mappedLog != null) {
        SafeSetState.call(this, () {
          _currentLog = mappedLog;
        });
        // ذخیره log بعد از map کردن برنامه
        await _foodLogService.saveLogLocal(_currentLog!);
        // سعی در sync به دیتابیس (اگر آنلاین باشیم)
        try {
          await _foodLogService.saveLog(_currentLog!);
        } catch (e) {
          // اگر آنلاین نبودیم، فقط local ذخیره شده
        }
      }
    }
  }

  void _saveSessionLocal() {
    if (_selectedSession != null) {
      _foodLogService.saveLastSessionLocal(_selectedDate, _selectedSession!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Theme(
        data: Theme.of(context).copyWith(
          scaffoldBackgroundColor: context.backgroundColor,
          appBarTheme: AppBarTheme(
            backgroundColor: isDark
                ? context.backgroundColor
                : Colors.transparent,
            elevation: 0,
          ),
        ),
        child: Container(
          decoration: isDark
              ? null
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
          child: FeatureTourWidget(
            guideId: 'meal_log_tour',
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: MealLogAppBar(
                key: MealLogGuideData.keys['date_picker'],
                selectedDate: _selectedDate,
                isFromMealPlan: widget.mealPlanId != null,
                preloadedFoodLogDates: _preloadedFoodLogDates,
                preloadedCaloriesByDate: _preloadedCaloriesByDate,
                onDateSelected: (date) async {
                  await _foodLogService.syncAllLocalLogsToDatabase();
                  SafeSetState.call(this, () {
                    _selectedDate = date;
                    if (widget.mealPlanId == null) {
                      _selectedPlan = null;
                      _selectedSession = null;
                    } else {
                      // اگر از meal plan آمده، meal plan را دوباره بارگذاری کن
                      _loadMealPlanIfNeeded();
                    }
                  });
                  await _loadCurrentLog();
                },
              ),
              body: LayoutBuilder(
                builder: (context, constraints) {
                  // استفاده از MediaQuery برای اندازه واقعی صفحه
                  final mediaQuery = MediaQuery.of(context);
                  final screenWidth = mediaQuery.size.width;
                  final screenHeight = mediaQuery.size.height;

                  // محاسبه responsive padding بر اساس اندازه واقعی
                  final horizontalPadding = screenWidth > 600
                      ? (screenWidth * 0.1).clamp(16.0, 40.0)
                      : (screenWidth * 0.04).clamp(12.0, 20.0);
                  final verticalPadding = (screenHeight * 0.02).clamp(
                    12.0,
                    24.0,
                  );

                  // محاسبه maxWidth برای محتوا (برای تبلت و دسکتاپ)
                  final maxContentWidth = screenWidth > 600
                      ? (screenWidth * 0.85).clamp(600.0, 800.0)
                      : screenWidth;

                  return Stack(
                    children: [
                      _isLoading
                          ? Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.goldColor,
                                strokeWidth: 3.w,
                              ),
                            )
                          : SingleChildScrollView(
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding,
                                vertical: verticalPadding,
                              ),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: maxContentWidth,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // بخش کالری شماری یا کادر مربی
                                      if (!_isLoading)
                                        _shouldShowTrainerCard()
                                            ? TrainerSupervisionCard(
                                                mealPlanId:
                                                    widget.mealPlanId ??
                                                    _activeMealPlanId ??
                                                    '',
                                                selectedPlan: _selectedPlan,
                                                selectedSession:
                                                    _selectedSession,
                                                onSessionSelected:
                                                    (int session) {
                                                      setState(() {
                                                        _selectedSession =
                                                            session;
                                                      });
                                                      _saveSessionLocal();
                                                      _loadCurrentLog();
                                                    },
                                              )
                                            : DailyCalorieSummary(
                                                key: MealLogGuideData
                                                    .keys['calorie_summary'],
                                                meals: _currentLog?.meals ?? [],
                                                allFoods: _allFoods,
                                                profileData: _profileData,
                                              ),
                                      // بخش خروج به کالری شماری آزاد (فقط وقتی از meal plan آمده)
                                      if (!_isLoading &&
                                          _shouldShowTrainerCard()) ...[
                                        SizedBox(height: 12.h),
                                        OutlinedButton.icon(
                                          onPressed: () async {
                                            // غیرفعال کردن active meal plan
                                            await _activeMealPlanService
                                                .clearActiveMealPlan();
                                            Navigator.pushReplacementNamed(
                                              context,
                                              '/meal-log',
                                            );
                                          },
                                          icon: Icon(
                                            LucideIcons.arrowLeft,
                                            size: 18.sp,
                                          ),
                                          label: Text(
                                            'خروج به کالری شماری آزاد',
                                            style: TextStyle(
                                              fontFamily: AppTheme.fontFamily,
                                              fontSize: 14.sp,
                                            ),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppTheme.goldColor,
                                            side: BorderSide(
                                              color: AppTheme.goldColor
                                                  .withValues(alpha: 0.5),
                                            ),
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 16.w,
                                              vertical: 12.h,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12.r),
                                            ),
                                          ),
                                        ),
                                      ],
                                      if (!_isLoading) ...[
                                        SizedBox(height: 24.h),
                                        DateSeparatorWidget(
                                          selectedDate: _selectedDate,
                                          onTap: _openDatePicker,
                                        ),
                                        SizedBox(height: 24.h),
                                      ],
                                      MealsListWidget(
                                        currentLog: _currentLog,
                                        allFoods: _allFoods,
                                        onAddFood: _addFoodToMeal,
                                        onEditAmount: _showEditAmountDialog,
                                        onFoodAction: _handleFoodAction,
                                        profileData: _profileData,
                                      ),
                                      if (_currentLog?.supplements.isNotEmpty ??
                                          false) ...[
                                        SizedBox(height: 16.h),
                                        Text(
                                          'مکمل‌ها',
                                          style: TextStyle(
                                            fontFamily: AppTheme.fontFamily,
                                            color: AppTheme.goldColor,
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: 8.h),
                                        ..._currentLog!.supplements
                                            .asMap()
                                            .entries
                                            .map(
                                              (entry) => Padding(
                                                padding: EdgeInsets.only(
                                                  bottom: 8.h,
                                                ),
                                                child: SupplementCard(
                                                  supplement: entry.value,
                                                  index: entry.key,
                                                ),
                                              ),
                                            ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openDatePicker() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: isDark
          ? Colors.black.withValues(alpha: 0.7)
          : AppTheme.lightTextColor.withValues(alpha: 0.5),
      builder: (context) => PersianFoodLogDatePickerDialog(
        selectedDate: _selectedDate,
        onDateSelected: (date) async {
          await _foodLogService.syncAllLocalLogsToDatabase();
          SafeSetState.call(this, () {
            _selectedDate = date;
            if (widget.mealPlanId == null) {
              _selectedPlan = null;
              _selectedSession = null;
            } else {
              _loadMealPlanIfNeeded();
            }
          });
          await _loadCurrentLog();
        },
        preloadedFoodLogDates: _preloadedFoodLogDates,
        preloadedCaloriesByDate: _preloadedCaloriesByDate,
      ),
    );
  }

  Future<void> _addFoodToMeal(String mealTitle) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final result =
        await WidgetSafetyUtils.safeShowModalBottomSheet<Map<String, dynamic>>(
          context: context,
          isDismissible: true,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          barrierColor: isDark
              ? Colors.black.withValues(alpha: 0.7)
              : AppTheme.lightTextColor.withValues(alpha: 0.5),
          builder: (context) =>
              AddFoodScreen(foods: _allFoods, initialMealTitle: mealTitle),
        );
    if (result != null) {
      // Initialize log if it doesn't exist (سریع: اول auth، بعد در پس‌زمینه sync)
      if (_currentLog == null) {
        final userId = Supabase.instance.client.auth.currentUser?.id ??
            (await SimpleProfileService.getCurrentProfile())?['id'] as String? ??
            '';
        final newLog = FoodLog(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: userId,
          logDate: _selectedDate,
          meals: [],
          supplements: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        WidgetSafetyUtils.safeSetState(this, () {
          _currentLog = newLog;
        });
        _foodLogService.saveLogLocal(newLog);
        _foodLogService.saveLog(newLog).catchError((_) {});
      }

      // Get meal title from result or use the original
      final selectedMealTitle = result['mealTitle'] as String? ?? mealTitle;

      // Ensure meal exists before adding food
      final mealExists = _currentLog!.meals.any(
        (meal) => meal.title == selectedMealTitle,
      );
      if (!mealExists) {
        SafeSetState.call(this, () {
          // Create meal directly with the exact title
          _currentLog!.meals.add(
            FoodMealLog(title: selectedMealTitle, foods: []),
          );
          _foodLogService.saveLogLocal(_currentLog!);
        });
      }

      final food = result['food'] as Food;
      final amount = result['amount'] as double;
      final unit = result['unit'] as String? ?? 'گرم';
      final updatedLog = await _controller.addFoodToMeal(
        currentLog: _currentLog!,
        mealTitle: selectedMealTitle,
        food: food,
        amount: amount,
        unit: unit,
      );
      SafeSetState.call(this, () {
        _currentLog = updatedLog;
      });
    }
  }

  Future<void> _removeFoodFromMeal(
    FoodLogItem foodItem,
    String mealTitle,
  ) async {
    if (_currentLog != null) {
      final updatedLog = await _controller.removeFoodFromMeal(
        currentLog: _currentLog!,
        foodItem: foodItem,
        mealTitle: mealTitle,
      );
      SafeSetState.call(this, () {
        _currentLog = updatedLog;
      });
    }
  }

  Future<void> _showEditAmountDialog(
    FoodLogItem foodItem,
    String mealTitle,
  ) async {
    // جلوگیری از باز شدن کیبورد سیستم — فوکوس را بردار تا فقط کیبورد عددی خودمان دیده شود
    FocusManager.instance.primaryFocus?.unfocus();
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => AmountKeypadSheet(foodItem: foodItem),
    );

    if (result != null && _currentLog != null) {
      final updatedLog = await _controller.updateFoodAmount(
        currentLog: _currentLog!,
        foodItem: foodItem,
        mealTitle: mealTitle,
        newAmount: result['amount'] as double,
        unit: result['unit'] as String?,
      );
      SafeSetState.call(this, () {
        _currentLog = updatedLog;
      });
    }
  }

  Future<void> _handleFoodAction(
    String action,
    FoodLogItem foodItem,
    String mealTitle,
  ) async {
    if (_currentLog == null) return;

    switch (action) {
      case 'complete':
        final updatedLog = await _controller.markFoodAsComplete(
          currentLog: _currentLog!,
          foodItem: foodItem,
          mealTitle: mealTitle,
        );
        SafeSetState.call(this, () {
          _currentLog = updatedLog;
        });
      case 'substitute':
        _showSubstituteFoodDialog(foodItem, mealTitle);
      case 'delete':
        _removeFoodFromMeal(foodItem, mealTitle);
    }
  }

  Future<void> _showSubstituteFoodDialog(
    FoodLogItem foodItem,
    String mealTitle,
  ) async {
    final alternatives = foodItem.alternatives ?? [];
    if (alternatives.isEmpty) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected =
        await WidgetSafetyUtils.safeShowDialog<Map<String, dynamic>>(
          context: context,
          barrierDismissible: true,
          builder: (context) =>
              SubstituteFoodDialog(foodItem: foodItem, allFoods: _allFoods),
        );

    if (selected != null && _currentLog != null) {
      final updatedLog = await _controller.substituteFood(
        currentLog: _currentLog!,
        foodItem: foodItem,
        mealTitle: mealTitle,
        selectedAlternative: selected,
      );
      SafeSetState.call(this, () {
        _currentLog = updatedLog;
      });
    }
  }
}
