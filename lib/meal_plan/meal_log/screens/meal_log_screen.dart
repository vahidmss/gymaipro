import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// [STEP 2] Extract all meal log-specific dialogs to lib/meal_plan/meal_log/dialogs/ and import them here.
import 'package:gymaipro/meal_plan/meal_log/dialogs/add_food_dialog.dart';
import 'package:gymaipro/meal_plan/meal_log/models/food_log.dart';
import 'package:gymaipro/meal_plan/meal_log/models/food_log_item.dart';
import 'package:gymaipro/meal_plan/meal_log/models/food_meal_log.dart';
// [STEP 4] Extract all meal log-specific models to lib/meal_plan/meal_log/models/ and import them here.
import 'package:gymaipro/meal_plan/meal_log/models/logged_supplement.dart';
// [STEP 5] Extract all meal log-specific services to lib/meal_plan/meal_log/services/ and import them here.
import 'package:gymaipro/meal_plan/meal_log/services/meal_log_service.dart';
// [STEP 3] Extract all meal log-specific utils to lib/meal_plan/meal_log/utils/ and import them here.
import 'package:gymaipro/meal_plan/meal_log/utils/meal_log_utils.dart';
import 'package:gymaipro/meal_plan/meal_log/widgets/add_item_menu.dart';
// [STEP 1] Extract all meal log-specific widgets to lib/meal_plan/meal_log/widgets/ and import them here.
import 'package:gymaipro/meal_plan/meal_log/widgets/meal_log_widgets.dart';
import 'package:gymaipro/meal_plan/meal_log/widgets/meal_type_selector_overlay.dart';
import 'package:gymaipro/meal_plan/meal_log/widgets/no_active_plan_card.dart';
import 'package:gymaipro/meal_plan/meal_log/widgets/nutrition_chart.dart';
import 'package:gymaipro/meal_plan/meal_plan_builder/services/meal_plan_service.dart';
import 'package:gymaipro/models/food.dart';
import 'package:gymaipro/models/meal_plan.dart';
import 'package:gymaipro/services/food_service.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FoodLogScreen extends StatefulWidget {
  const FoodLogScreen({super.key});

  @override
  State<FoodLogScreen> createState() => _FoodLogScreenState();
}

class _FoodLogScreenState extends State<FoodLogScreen> {
  final FoodService _foodService = FoodService();
  final MealLogService _foodLogService = MealLogService();
  final MealPlanService _mealPlanService = MealPlanService();

  List<Food> _allFoods = [];
  List<MealPlan> _availablePlans = [];
  bool _isLoading = true;
  FoodLog? _currentLog;
  DateTime _selectedDate = DateTime.now();
  MealPlan? _selectedPlan;
  int? _selectedSession;
  bool _showNutritionChart = false;
  bool _showMealTypeSelectorOverlay = false;
  // اضافه کردن متغیر جدید:
  bool _userSelectedSession = false;

  // Nutrition totals
  double _totalCalories = 0;
  double _totalProtein = 0;
  double _totalCarbs = 0;
  double _totalFat = 0;

  @override
  void initState() {
    super.initState();
    _syncAllLocalLogsAndLoad();
  }

  Future<void> _syncAllLocalLogsAndLoad() async {
    await _foodLogService.syncAllLocalLogsToDatabase();
    _loadData();
  }

  Future<void> _loadData() async {
    SafeSetState.call(this, () => _isLoading = true);
    try {
      _allFoods = await _foodService.getFoods();
      _availablePlans = await _mealPlanService.getPlans();
      await _loadCurrentLog();
      SafeSetState.call(this, () => _isLoading = false);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطا در بارگذاری: $e')));
      SafeSetState.call(this, () => _isLoading = false);
    }
  }

  Future<void> _loadCurrentLog() async {
    try {
      _currentLog = await _foodLogService.getLogForDate(_selectedDate);
      _currentLog ??= await _foodLogService.loadLogLocal(_selectedDate);
    } catch (e) {
      // Log doesn't exist yet, create empty one
      _currentLog = await _foodLogService.loadLogLocal(_selectedDate);
      _currentLog ??= FoodLog(
        id: '',
        userId: Supabase.instance.client.auth.currentUser?.id ?? '',
        logDate: _selectedDate,
        meals: [],
        supplements: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    // اگر لاگ وجود دارد، آخرین برنامه و سشن ذخیره‌شده را به عنوان پیش‌فرض ست کن (قابل تغییر توسط کاربر)
    if (_currentLog != null) {
      final lastPlanId = await _foodLogService.loadLastPlanLocal(_selectedDate);
      final lastSession = await _foodLogService.loadLastSessionLocal(
        _selectedDate,
      );
      if (lastPlanId != null) {
        final planIndex = _availablePlans.indexWhere((p) => p.id == lastPlanId);
        if (planIndex != -1) {
          _selectedPlan = _availablePlans[planIndex];
        }
      }
      if (lastSession != null) {
        _selectedSession = lastSession;
        _userSelectedSession = true;
      }
    }

    // اگر لاگ برای این روز وجود داشت و حداقل یک غذا mealPlanId داشت، برنامه و سشن را ست کن
    if (_currentLog != null &&
        _currentLog!.meals.isNotEmpty &&
        !_userSelectedSession) {
      // پیدا کردن اولین غذای برنامه‌ای (nullable)
      FoodLogItem? planFood;
      for (final meal in _currentLog!.meals) {
        for (final f in meal.foods) {
          if (f.mealPlanId != null) {
            planFood = f;
            break;
          }
        }
        if (planFood != null) break;
      }
      if (planFood != null && planFood.mealPlanId != null) {
        // برنامه را پیدا کن
        final planIndex = _availablePlans.indexWhere(
          (p) => p.id == planFood!.mealPlanId,
        );
        if (planIndex != -1) {
          _selectedPlan = _availablePlans[planIndex];
          // سشن را پیدا کن (بر اساس نام وعده و روز هفته)
          final mealTitles = _currentLog!.meals
              .where(
                (m) => m.foods.any((f) => f.mealPlanId == planFood!.mealPlanId),
              )
              .map((m) => m.title)
              .toList();
          int? session;
          for (final day in _selectedPlan!.days) {
            final planMealTitles = day.items
                .whereType<MealItem>()
                .map((m) => m.title)
                .toList();
            if (mealTitles.any(planMealTitles.contains)) {
              session = day.dayOfWeek;
              break;
            }
          }
          if (session != null) {
            _selectedSession = session;
          }
        }
      }
    }

    // Always try to map plan data if plan is selected and log is empty
    await _mapPlanToLogIfNeeded();
    _calculateTotals();
  }

  Future<void> _mapPlanToLogIfNeeded() async {
    // Only map if we're in plan mode (both plan and session selected)
    if (_selectedPlan != null &&
        _selectedSession != null &&
        _currentLog != null) {
      // استخراج غذاهای آزاد (غیر برنامه‌ای) و غذاهای برنامه‌ای قبلی که مصرف شده‌اند
      final freeFoodsByMeal = <String, List<FoodLogItem>>{};
      for (final meal in _currentLog!.meals) {
        for (final food in meal.foods) {
          // غذای آزاد یا برنامه‌ای قبلی که مصرف شده (amount > 0)
          final isFree = food.mealPlanId == null;
          final isPrevPlan = food.mealPlanId != null;
          if (isFree || (isPrevPlan && food.amount > 0)) {
            freeFoodsByMeal
                .putIfAbsent(meal.title, () => [])
                .add(
                  isFree
                      ? food
                      : food.copyWith(
                          mealPlanId: null,
                        ), // برنامه‌ای قبلی به آزاد تبدیل می‌شود (تگ آزاد)
                );
          }
        }
      }
      try {
        final planDay = _selectedPlan!.days.firstWhere(
          (d) => d.dayOfWeek == _selectedSession!,
        );
        // ساخت وعده‌های برنامه
        final planMeals = planDay.items.whereType<MealItem>().map((meal) {
          // غذاهای آزاد مرتبط با این وعده را پیدا کن
          final freeFoods = freeFoodsByMeal[meal.title] ?? [];
          // لیست غذاهای برنامه‌ای جدید
          final planFoods = meal.foods
              .map(
                (f) => FoodLogItem(
                  foodId: f.foodId,
                  amount:
                      0, // Start with 0, user needs to log actual consumption
                  plannedAmount: f.amount, // Set planned amount for tracking
                  mealPlanId: _selectedPlan!.id,
                  alternatives: f.alternatives,
                ),
              )
              .toList();

          // ادغام غذاهای آزاد و برنامه‌ای قبلی با برنامه جدید (بر اساس foodId و mealTitle)
          for (final freeFood in freeFoods) {
            final idx = planFoods.indexWhere(
              (pf) => pf.foodId == freeFood.foodId,
            );
            if (idx != -1) {
              // اگر غذا در برنامه هست، مقدار مصرفی را جمع بزن
              final planFood = planFoods[idx];
              planFoods[idx] = planFood.copyWith(
                amount: planFood.amount + freeFood.amount,
              );
            } else {
              // اگر نبود، به عنوان غذای آزاد اضافه کن (حتماً mealPlanId و plannedAmount را null کن)
              planFoods.add(freeFood.copyWith(mealPlanId: null));
            }
          }

          return FoodMealLog(title: meal.title, foods: planFoods);
        }).toList();

        // اگر وعده‌ای از غذاهای آزاد وجود دارد که در برنامه نیست، آن وعده را هم اضافه کن
        for (final entry in freeFoodsByMeal.entries) {
          final mealTitle = entry.key;
          final alreadyInPlan = planMeals.any((m) => m.title == mealTitle);
          if (!alreadyInPlan) {
            // هنگام اضافه کردن وعده آزاد، همه غذاها را به صورت آزاد (mealPlanId/plannedAmount=null) اضافه کن
            planMeals.add(
              FoodMealLog(
                title: mealTitle,
                foods: entry.value
                    .map((f) => f.copyWith(mealPlanId: null))
                    .toList(),
              ),
            );
          }
        }

        // مکمل‌های برنامه
        final supplements = planDay.items.whereType<SupplementEntry>().map((s) {
          return LoggedSupplement(
            name: s.name,
            amount: s.amount,
            unit: s.unit,
            time: s.time,
            note: s.note,
            supplementType: s.supplementType,
            protein: s.protein,
            carbs: s.carbs,
          );
        }).toList();

        _currentLog = FoodLog(
          id: _currentLog!.id,
          userId: _currentLog!.userId,
          logDate: _currentLog!.logDate,
          meals: planMeals,
          supplements: supplements,
          createdAt: _currentLog!.createdAt,
          updatedAt: DateTime.now(),
        );
      } catch (e) {}
    } else {}
  }

  void _calculateTotals() {
    if (_currentLog != null) {
      final totals = MealLogUtils.calculateTotals(
        _currentLog!.meals,
        _allFoods,
      );
      _totalCalories = totals['calories'] ?? 0;
      _totalProtein = totals['protein'] ?? 0;
      _totalCarbs = totals['carbs'] ?? 0;
      _totalFat = totals['fat'] ?? 0;
    } else {
      _totalCalories = 0;
      _totalProtein = 0;
      _totalCarbs = 0;
      _totalFat = 0;
    }
  }

  // هر بار که لاگ تغییر کرد، لوکال ذخیره کن
  void _saveLogLocal() {
    if (_currentLog != null) {
      _foodLogService.saveLogLocal(_currentLog!);
    }
  }

  // هر بار که سشن تغییر کرد، لوکال ذخیره کن
  void _saveSessionLocal() {
    if (_selectedSession != null) {
      _foodLogService.saveLastSessionLocal(_selectedDate, _selectedSession!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0E0E0E),
        appBar: MealLogAppBar(
          selectedDate: _selectedDate,
          onSave: null, // حذف دکمه سیو
          onDateSelected: (date) async {
            // قبل از بارگذاری روز جدید، لاگ لوکال روز قبلی را سینک کن
            await _foodLogService.syncAllLocalLogsToDatabase();
            setState(() {
              _selectedDate = date;
              _selectedPlan = null;
              _selectedSession = null;
              _userSelectedSession = false; // Reset user selection
            });
            await _loadCurrentLog();
            setState(() {}); // Force UI refresh after loading new log
          },
        ),
        floatingActionButton: _selectedPlan == null
            ? Container(
                margin: EdgeInsets.only(bottom: 80.h),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFD4AF37).withValues(alpha: 0.95),
                        const Color(0xFFB8860B).withValues(alpha: 0.90),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                        blurRadius: 12.r,
                        offset: Offset(0, 6.h),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8.r,
                        offset: Offset(0, 3.h),
                      ),
                    ],
                  ),
                  child: FloatingActionButton(
                    onPressed: () => _showAddItemMenu(context),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    tooltip: 'افزودن آیتم',
                    child: Icon(
                      LucideIcons.plus,
                      color: const Color(0xFF1A1A1A),
                      size: 28.sp,
                    ),
                  ),
                ),
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A0A0A), Color(0xFF1A1A1A), Color(0xFF2A2A2A)],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.amber,
                                strokeWidth: 3,
                              ),
                            )
                          : _buildContent(),
                    ),
                    _buildBottomInfoBar(),
                  ],
                ),
                if (_showMealTypeSelectorOverlay)
                  MealTypeSelectorOverlay(
                    onClose: () {
                      setState(() {
                        _showMealTypeSelectorOverlay = false;
                      });
                    },
                    onMealTypeSelected: (title) {
                      setState(() {
                        _showMealTypeSelectorOverlay = false;
                      });
                      _addMealWithType(title);
                    },
                  ),
                if (_showNutritionChart)
                  Positioned(
                    left: 16.w,
                    right: 16.w,
                    bottom: 80.h, // بالاتر از bottom bar
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 20.r,
                            offset: Offset(0.w, 8.h),
                          ),
                        ],
                      ),
                      child: NutritionChart(
                        totalProtein: _totalProtein,
                        totalCarbs: _totalCarbs,
                        totalFat: _totalFat,
                        totalCalories: _totalCalories,
                        showChart: _showNutritionChart,
                        onToggle: () {
                          setState(() {
                            _showNutritionChart = !_showNutritionChart;
                          });
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // When no plan selected and no meals exist: show empty-state card like workout log
          if (_selectedPlan == null &&
              (_currentLog?.meals.isEmpty ?? true)) ...[
            NoActivePlanCard(
              onOpenMyPrograms: () {
                Navigator.of(context).pushNamed('/my-programs');
              },
              onCreatePlan: () {
                Navigator.of(context).pushNamed('/meal-plan-builder');
              },
            ),
            const SizedBox(height: 16),
          ] else ...[
            // Session selector (if plan is selected)
            SessionSelector(
              selectedPlan: _selectedPlan,
              selectedSession: _selectedSession,
              onSessionSelected: (index) async {
                setState(() {
                  _selectedSession = index;
                  _userSelectedSession = true;
                });
                _saveSessionLocal();
                if (_selectedPlan != null) {
                  await _foodLogService.saveLastPlanLocal(
                    _selectedDate,
                    _selectedPlan!.id,
                  );
                }
                _currentLog ??= FoodLog(
                  id: '',
                  userId: Supabase.instance.client.auth.currentUser?.id ?? '',
                  logDate: _selectedDate,
                  meals: [],
                  supplements: [],
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                await _mapPlanToLogIfNeeded();
                setState(() {}); // Force UI rebuild after mapping
              },
            ),
          ],
          const SizedBox(height: 20),
          // Session selector (was duplicated) — removed second instance
          // Show supplements above meals if any
          if (_currentLog != null && _currentLog!.supplements.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مکمل‌ها',
                    style: TextStyle(
                      color: Colors.purple[200],
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._currentLog!.supplements.asMap().entries.map(
                    (entry) => SupplementCard(
                      supplement: entry.value,
                      index: entry.key,
                      isFromPlan: _selectedPlan != null,
                      followedPlan: entry.value.followedPlan,
                      onToggleFollowedPlan: (checked) {
                        setState(() {
                          final updated = entry.value.copyWith(
                            followedPlan: checked ?? false,
                          );
                          _currentLog!.supplements[entry.key] = updated;
                        });
                        _saveLogLocal();
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
          // Meals list
          ..._buildMealsList(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  List<Widget> _buildMealsList() {
    // Always show meals from _currentLog (whether from plan or manually added)
    if (_currentLog != null && _currentLog!.meals.isNotEmpty) {
      // Remove duplicates by title
      final uniqueMeals = <String, FoodMealLog>{};
      for (final meal in _currentLog!.meals) {
        if (!uniqueMeals.containsKey(meal.title)) {
          uniqueMeals[meal.title] = meal;
        }
      }

      return uniqueMeals.values
          .map(
            (meal) => Column(
              children: [
                MealSection(
                  title: meal.title,
                  icon: _getMealIcon(meal.title),
                  foodItems: _currentLog!.meals
                      .where((m) => m.title == meal.title)
                      .take(1)
                      .expand((m) => m.foods)
                      .toList(),
                  allFoods: _allFoods,
                  onAddFood: () => _addFoodToMeal(meal.title),
                  onEditAmount: _showEditAmountDialog,
                  onFoodAction: _handleFoodAction,
                ),
                const SizedBox(height: 16),
              ],
            ),
          )
          .toList();
    } else {
      return _buildDefaultMeals();
    }
  }

  List<Widget> _buildDefaultMeals() {
    return [const EmptyStateGuide()];
  }

  IconData _getMealIcon(String title) {
    if (title.contains('صبحانه')) return LucideIcons.sunrise;
    if (title.contains('ناهار')) return LucideIcons.sun;
    if (title.contains('شام')) return LucideIcons.moon;
    if (title.contains('میان‌وعده')) return LucideIcons.coffee;
    return LucideIcons.utensils;
  }

  void _showAddItemMenu(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => AddItemMenu(
        onMealSelected: () {
          setState(() {
            _showMealTypeSelectorOverlay = true;
          });
        },
        onSupplementSelected: _showAddSupplementDialog,
      ),
    );
  }

  void _addMealWithType(String mealType) {
    // Initialize log if needed
    _currentLog ??= FoodLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: Supabase.instance.client.auth.currentUser?.id ?? '',
      logDate: _selectedDate,
      meals: [],
      supplements: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Check if meal already exists (for non-snack meals)
    if (mealType != 'میان‌وعده') {
      final existingMeal = _currentLog!.meals.firstWhere(
        (meal) => meal.title == mealType,
        orElse: () => FoodMealLog(title: '', foods: []),
      );

      if (existingMeal.title.isNotEmpty) {
        setState(() {
          _showMealTypeSelectorOverlay = false;
        });
        return;
      }
    }

    // Count existing snacks to generate next number
    int snackCount = 0;
    for (final meal in _currentLog!.meals) {
      if (meal.title.startsWith('میان‌وعده')) {
        snackCount++;
      }
    }

    String title;
    if (mealType == 'میان‌وعده') {
      title = 'میان‌وعده ${snackCount + 1}';
    } else {
      title = mealType;
    }

    setState(() {
      _currentLog!.meals.add(FoodMealLog(title: title, foods: []));
      _showMealTypeSelectorOverlay = false;
    });
    _saveLogLocal();
  }

  Future<void> _showAddSupplementDialog() async {
    // TODO: Implement supplement dialog similar to meal plan builder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('قابلیت افزودن مکمل به زودی اضافه می‌شود')),
    );
  }

  Future<void> _addFoodToMeal(String mealTitle) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddFoodDialog(foods: _allFoods),
    );
    if (result != null) {
      setState(() {
        final food = result['food'] as Food;
        final amount = result['amount'] as double;

        // Find or create meal
        FoodMealLog? meal = _currentLog?.meals.firstWhere(
          (m) => m.title == mealTitle,
          orElse: () => FoodMealLog(title: mealTitle, foods: []),
        );

        if (meal == null) {
          meal = FoodMealLog(title: mealTitle, foods: []);
          _currentLog?.meals.add(meal);
        }

        // Add the food to the meal
        final newFoodItem = FoodLogItem(foodId: food.id, amount: amount);
        meal.foods.add(newFoodItem);
      });
      _calculateTotals();
      _saveLogLocal();
    }
  }

  void _removeFoodFromMeal(FoodLogItem foodItem, String mealTitle) {
    setState(() {
      final meal = _currentLog?.meals.firstWhere((m) => m.title == mealTitle);
      if (meal != null) {
        meal.foods.remove(foodItem);
        _calculateTotals();
      }
    });
    _saveLogLocal();
  }

  Future<void> _showEditAmountDialog(
    FoodLogItem foodItem,
    String mealTitle,
  ) async {
    final TextEditingController controller = TextEditingController(
      text: foodItem.amount.toStringAsFixed(0),
    );

    final result = await showDialog<double>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          margin: EdgeInsets.all(20.w),
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2C1810), Color(0xFF3D2317), Color(0xFF4A2C1A)],
            ),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: Colors.amber[700]!.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ویرایش مقدار مصرفی',
                style: TextStyle(
                  color: Colors.amber[200],
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: TextStyle(color: Colors.amber[200]),
                decoration: InputDecoration(
                  labelText: 'مقدار (گرم)',
                  labelStyle: TextStyle(color: Colors.amber[300]),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.amber[700]!.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.amber[700]!),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'انصراف',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[700],
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () {
                        final newAmount = double.tryParse(controller.text);
                        Navigator.of(context).pop(newAmount);
                      },
                      child: const Text('تأیید'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null) {
      setState(() {
        final meal = _currentLog?.meals.firstWhere(
          (m) => m.title == mealTitle,
          orElse: () => FoodMealLog(title: mealTitle, foods: []),
        );
        if (meal != null) {
          final index = meal.foods.indexOf(foodItem);
          if (index != -1) {
            meal.foods[index] = foodItem.copyWith(amount: result);
          }
        }
        _calculateTotals();
      });
      _saveLogLocal();
    }
  }

  void _handleFoodAction(
    String action,
    FoodLogItem foodItem,
    String mealTitle,
  ) {
    switch (action) {
      case 'complete':
        _markFoodAsComplete(foodItem, mealTitle);
      case 'substitute':
        _showSubstituteFoodDialog(foodItem, mealTitle);
      case 'delete':
        _removeFoodFromMeal(foodItem, mealTitle);
    }
  }

  void _markFoodAsComplete(FoodLogItem foodItem, String mealTitle) {
    final plannedAmount = foodItem.plannedAmount ?? foodItem.amount;
    setState(() {
      final meal = _currentLog?.meals.firstWhere(
        (m) => m.title == mealTitle,
        orElse: () => FoodMealLog(title: mealTitle, foods: []),
      );
      if (meal != null) {
        final index = meal.foods.indexOf(foodItem);
        if (index != -1) {
          meal.foods[index] = FoodLogItem(
            foodId: foodItem.foodId,
            amount: plannedAmount,
            plannedAmount: foodItem.plannedAmount,
            mealPlanId: foodItem.mealPlanId,
            followedPlan: true, // Mark as completed
            alternatives: foodItem.alternatives,
          );
        }
        _calculateTotals();
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('غذا به عنوان تکمیل شده علامت‌گذاری شد'),
        backgroundColor: Colors.green[700],
      ),
    );
    _saveLogLocal();
  }

  Future<void> _showSubstituteFoodDialog(
    FoodLogItem foodItem,
    String mealTitle,
  ) async {
    final alternatives = foodItem.alternatives ?? [];
    if (alternatives.isEmpty) return;
    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          margin: EdgeInsets.all(20.w),
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2C1810), Color(0xFF3D2317), Color(0xFF4A2C1A)],
            ),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: Colors.amber[700]!.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'انتخاب جایگزین',
                style: TextStyle(
                  color: Colors.amber[200],
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ...alternatives.map((alt) {
                final altFood = _allFoods.firstWhere(
                  (f) => f.id == (alt['food_id'] as int),
                  orElse: () =>
                      MealLogUtils.createDefaultFood(alt['food_id'] as int),
                );
                return GestureDetector(
                  onTap: () => Navigator.of(context).pop(alt),
                  child: Card(
                    color: const Color(0xFF3D2317),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 10.h,
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: altFood.imageUrl.isNotEmpty
                                ? Image.network(
                                    altFood.imageUrl,
                                    width: 44.w,
                                    height: 44.h,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 44.w,
                                    height: 44.h,
                                    color: Colors.amber[100]?.withValues(
                                      alpha: 0.1,
                                    ),
                                    child: Icon(
                                      Icons.fastfood,
                                      color: Colors.amber[300],
                                      size: 28.sp,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  altFood.title,
                                  style: TextStyle(
                                    color: Colors.amber[100],
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${alt['amount']} گرم',
                                  style: TextStyle(
                                    color: Colors.amber[300],
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.swap_horiz,
                            color: Colors.amber,
                            size: 22.sp,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
    if (selected != null) {
      setState(() {
        if (_currentLog == null) return;
        final meal = _currentLog!.meals.firstWhere(
          (m) => m.title == mealTitle,
          orElse: () => FoodMealLog(title: mealTitle, foods: []),
        );
        final index = meal.foods.indexOf(foodItem);
        if (index != -1) {
          // منطق جابجایی جایگزین
          final newAlternatives = List<Map<String, dynamic>>.from(alternatives);
          newAlternatives.removeWhere(
            (alt) => alt['food_id'] == selected['food_id'],
          );
          newAlternatives.add({
            'food_id': foodItem.foodId,
            'amount': foodItem.plannedAmount ?? foodItem.amount,
          });
          meal.foods[index] = FoodLogItem(
            foodId: selected['food_id'] as int,
            amount: 0,
            plannedAmount: (selected['amount'] as num?)?.toDouble() ?? 0.0,
            mealPlanId: foodItem.mealPlanId,
            alternatives: newAlternatives,
          );
        }
        _calculateTotals();
      });
      _saveLogLocal();
    }
  }

  Widget _buildBottomInfoBar() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showNutritionChart = !_showNutritionChart;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.flame,
                  color: const Color(0xFFFFD580),
                  size: 20.sp,
                ),
                const SizedBox(width: 6),
                Text(
                  'کالری: ${_totalCalories.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(width: 16),
                Icon(
                  LucideIcons.dumbbell,
                  color: const Color(0xFF9AD0F5),
                  size: 20.sp,
                ),
                const SizedBox(width: 6),
                Text(
                  'پروتئین: ${_totalProtein.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(width: 16),
                Icon(
                  LucideIcons.wheat,
                  color: const Color(0xFFF6C08B),
                  size: 20.sp,
                ),
                const SizedBox(width: 6),
                Text(
                  'کربو: ${_totalCarbs.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
            Icon(
              LucideIcons.chevronUp,
              color: const Color(0xFFD4AF37),
              size: 22.sp,
            ),
          ],
        ),
      ),
    );
  }
}
