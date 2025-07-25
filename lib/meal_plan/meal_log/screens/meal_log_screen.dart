import 'package:flutter/material.dart';
import 'package:gymaipro/models/meal_plan.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../models/food.dart';
import '../../../services/food_service.dart';

import '../../meal_plan_builder/services/meal_plan_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// [STEP 1] Extract all meal log-specific widgets to lib/meal_plan/meal_log/widgets/ and import them here.
import '../widgets/meal_log_widgets.dart';
import '../widgets/nutrition_chart.dart';
import '../widgets/add_item_menu.dart';
import '../widgets/meal_type_selector_overlay.dart';
import '../widgets/meal_type_card.dart';
import '../widgets/session_selector.dart';
import '../widgets/empty_state_guide.dart';

// [STEP 2] Extract all meal log-specific dialogs to lib/meal_plan/meal_log/dialogs/ and import them here.
import '../dialogs/add_food_dialog.dart';

import '../dialogs/substitute_food_dialog.dart';
import '../dialogs/persian_food_log_date_picker_dialog.dart';

// [STEP 3] Extract all meal log-specific utils to lib/meal_plan/meal_log/utils/ and import them here.
import '../utils/meal_log_utils.dart';

// [STEP 4] Extract all meal log-specific models to lib/meal_plan/meal_log/models/ and import them here.
import '../models/logged_supplement.dart';
import '../models/food_log_item.dart';
import '../models/food_meal_log.dart';
import '../models/food_log.dart';

// [STEP 5] Extract all meal log-specific services to lib/meal_plan/meal_log/services/ and import them here.
import '../services/meal_log_service.dart';

class FoodLogScreen extends StatefulWidget {
  const FoodLogScreen({Key? key}) : super(key: key);

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
  int? _selectedPlanIndex;
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
    setState(() => _isLoading = true);
    try {
      _allFoods = await _foodService.getFoods();
      _availablePlans = await _mealPlanService.getPlans();
      await _loadCurrentLog();
      setState(() => _isLoading = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در بارگذاری: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCurrentLog() async {
    try {
      _currentLog = await _foodLogService.getLogForDate(_selectedDate);
      if (_currentLog == null) {
        // اگر از سرور نبود، از لوکال بخوان
        _currentLog = await _foodLogService.loadLogLocal(_selectedDate);
      }
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
      final lastSession =
          await _foodLogService.loadLastSessionLocal(_selectedDate);
      if (lastPlanId != null) {
        final planIndex = _availablePlans.indexWhere((p) => p.id == lastPlanId);
        if (planIndex != -1) {
          _selectedPlan = _availablePlans[planIndex];
          _selectedPlanIndex = planIndex;
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
        final planIndex =
            _availablePlans.indexWhere((p) => p.id == planFood!.mealPlanId);
        if (planIndex != -1) {
          _selectedPlan = _availablePlans[planIndex];
          _selectedPlanIndex = planIndex;
          // سشن را پیدا کن (بر اساس نام وعده و روز هفته)
          final mealTitles = _currentLog!.meals
              .where((m) =>
                  m.foods.any((f) => f.mealPlanId == planFood!.mealPlanId))
              .map((m) => m.title)
              .toList();
          int? session;
          for (final day in _selectedPlan!.days) {
            final planMealTitles =
                day.items.whereType<MealItem>().map((m) => m.title).toList();
            if (mealTitles.any((t) => planMealTitles.contains(t))) {
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
            freeFoodsByMeal.putIfAbsent(meal.title, () => []).add(isFree
                    ? food
                    : food.copyWith(
                        mealPlanId: null,
                        plannedAmount:
                            null) // برنامه‌ای قبلی به آزاد تبدیل می‌شود (تگ آزاد)
                );
          }
        }
      }
      try {
        final planDay = _selectedPlan!.days
            .firstWhere((d) => d.dayOfWeek == _selectedSession!);
        // ساخت وعده‌های برنامه
        final planMeals = planDay.items.whereType<MealItem>().map((meal) {
          // غذاهای آزاد مرتبط با این وعده را پیدا کن
          final freeFoods = freeFoodsByMeal[meal.title] ?? [];
          // لیست غذاهای برنامه‌ای جدید
          final planFoods = meal.foods
              .map((f) => FoodLogItem(
                    foodId: f.foodId,
                    amount:
                        0.0, // Start with 0, user needs to log actual consumption
                    plannedAmount: f.amount, // Set planned amount for tracking
                    mealPlanId: _selectedPlan!.id,
                    followedPlan: false, // Initially not completed
                    alternatives: f.alternatives,
                  ))
              .toList();

          // ادغام غذاهای آزاد و برنامه‌ای قبلی با برنامه جدید (بر اساس foodId و mealTitle)
          for (final freeFood in freeFoods) {
            final idx =
                planFoods.indexWhere((pf) => pf.foodId == freeFood.foodId);
            if (idx != -1) {
              // اگر غذا در برنامه هست، مقدار مصرفی را جمع بزن
              final planFood = planFoods[idx];
              planFoods[idx] = planFood.copyWith(
                amount: planFood.amount + freeFood.amount,
              );
            } else {
              // اگر نبود، به عنوان غذای آزاد اضافه کن (حتماً mealPlanId و plannedAmount را null کن)
              planFoods.add(
                  freeFood.copyWith(mealPlanId: null, plannedAmount: null));
            }
          }

          return FoodMealLog(
            title: meal.title,
            foods: planFoods,
          );
        }).toList();

        // اگر وعده‌ای از غذاهای آزاد وجود دارد که در برنامه نیست، آن وعده را هم اضافه کن
        for (final entry in freeFoodsByMeal.entries) {
          final mealTitle = entry.key;
          final alreadyInPlan = planMeals.any((m) => m.title == mealTitle);
          if (!alreadyInPlan) {
            // هنگام اضافه کردن وعده آزاد، همه غذاها را به صورت آزاد (mealPlanId/plannedAmount=null) اضافه کن
            planMeals.add(FoodMealLog(
                title: mealTitle,
                foods: entry.value
                    .map((f) =>
                        f.copyWith(mealPlanId: null, plannedAmount: null))
                    .toList()));
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
      final totals =
          MealLogUtils.calculateTotals(_currentLog!.meals, _allFoods);
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
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: MealLogAppBar(
        selectedDate: _selectedDate,
        onSave: null, // حذف دکمه سیو
        onDateSelected: (date) async {
          // قبل از بارگذاری روز جدید، لاگ لوکال روز قبلی را سینک کن
          await _foodLogService.syncAllLocalLogsToDatabase();
          setState(() {
            _selectedDate = date;
            _selectedPlan = null;
            _selectedPlanIndex = null;
            _selectedSession = null;
            _userSelectedSession = false; // Reset user selection
          });
          await _loadCurrentLog();
          setState(() {}); // Force UI refresh after loading new log
        },
        onSync: null, // حذف دکمه سینک
      ),
      floatingActionButton: _selectedPlan == null
          ? Container(
              margin: const EdgeInsets.only(bottom: 80),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.amber[600]!,
                      Colors.amber[700]!,
                      Colors.amber[800]!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber[700]!.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: FloatingActionButton(
                  onPressed: () => _showAddItemMenu(context),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  tooltip: 'افزودن آیتم',
                  child: const Icon(
                    LucideIcons.plus,
                    color: Color(0xFF1A1A1A),
                    size: 28,
                  ),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.amber))
                      : _buildContent(),
                ),
                _buildBottomInfoBar(),
              ],
            ),
            if (_showMealTypeSelectorOverlay)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.7),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF2C1810),
                            Color(0xFF3D2317),
                            Color(0xFF4A2C1A),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.amber[700]!.withOpacity(0.4),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.amber[700]?.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  LucideIcons.utensils,
                                  color: Colors.amber[700],
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'انتخاب نوع وعده',
                                  style: TextStyle(
                                    color: Colors.amber[200],
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.amber[700]?.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.amber[700]!.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    LucideIcons.x,
                                    color: Colors.amber[700],
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _showMealTypeSelectorOverlay = false;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Meal type cards
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.2,
                            children: [
                              MealTypeCard(
                                title: 'صبحانه',
                                icon: LucideIcons.sunrise,
                                color: Colors.orange[400]!,
                                onTap: () => _addMealWithType('صبحانه'),
                              ),
                              MealTypeCard(
                                title: 'ناهار',
                                icon: LucideIcons.sun,
                                color: Colors.yellow[400]!,
                                onTap: () => _addMealWithType('ناهار'),
                              ),
                              MealTypeCard(
                                title: 'شام',
                                icon: LucideIcons.moon,
                                color: Colors.indigo[400]!,
                                onTap: () => _addMealWithType('شام'),
                              ),
                              MealTypeCard(
                                title: 'میان‌وعده',
                                icon: LucideIcons.coffee,
                                color: Colors.green[400]!,
                                onTap: () => _addMealWithType('میان‌وعده'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (_showNutritionChart)
              Positioned(
                left: 16,
                right: 16,
                bottom: 80, // بالاتر از bottom bar
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
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
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // Mode selector (Free vs Plan)
          ModeSelector(
            selectedPlan: _selectedPlan,
            selectedPlanIndex: _selectedPlanIndex,
            availablePlans: _availablePlans,
            onFreeModeSelected: () {
              setState(() {
                _selectedPlan = null;
                _selectedPlanIndex = null;
                _selectedSession = null;
                _userSelectedSession = false; // Reset user selection
              });
              // Reload log to clear any plan data
              _loadCurrentLog().then((_) {
                setState(() {}); // Force UI rebuild
              });
            },
            onPlanSelected: (plan, index) {
              setState(() {
                _selectedPlan = plan;
                _selectedPlanIndex = index;
                _selectedSession = null;
                _userSelectedSession = false; // Reset user selection
              });
              _foodLogService.saveLastPlanLocal(
                  _selectedDate, plan.id); // ذخیره انتخاب برنامه
              // Reload log to apply plan data
              _loadCurrentLog().then((_) {
                setState(() {}); // Force UI rebuild
              });
            },
          ),
          const SizedBox(height: 20),
          // Session selector (if plan is selected)
          if (_selectedPlan != null) ...[
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
                      _selectedDate, _selectedPlan!.id);
                }
                if (_currentLog == null) {
                  _currentLog = FoodLog(
                    id: '',
                    userId: Supabase.instance.client.auth.currentUser?.id ?? '',
                    logDate: _selectedDate,
                    meals: [],
                    supplements: [],
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                }
                await _mapPlanToLogIfNeeded();
                setState(() {}); // Force UI rebuild after mapping
              },
            ),
            const SizedBox(height: 20),
          ],
          // Show supplements above meals if any
          if (_currentLog != null && _currentLog!.supplements.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('مکمل‌ها',
                      style: TextStyle(
                          color: Colors.purple[200],
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ..._currentLog!.supplements
                      .asMap()
                      .entries
                      .map((entry) => SupplementCard(
                            supplement: entry.value,
                            index: entry.key,
                            isFromPlan: _selectedPlan != null,
                            followedPlan: entry.value.followedPlan,
                            onToggleFollowedPlan: (checked) {
                              setState(() {
                                final updated = entry.value
                                    .copyWith(followedPlan: checked ?? false);
                                _currentLog!.supplements[entry.key] = updated;
                              });
                              _saveLogLocal();
                            },
                          )),
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
          .map((meal) => Column(
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
              ))
          .toList();
    } else {
      return _buildDefaultMeals();
    }
  }

  List<Widget> _buildDefaultMeals() {
    return [
      const EmptyStateGuide(),
    ];
  }

  IconData _getMealIcon(String title) {
    if (title.contains('صبحانه')) return LucideIcons.sunrise;
    if (title.contains('ناهار')) return LucideIcons.sun;
    if (title.contains('شام')) return LucideIcons.moon;
    if (title.contains('میان‌وعده')) return LucideIcons.coffee;
    return LucideIcons.utensils;
  }

  void _showAddItemMenu(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => AddItemMenu(
        onMealSelected: () {
          setState(() {
            _showMealTypeSelectorOverlay = true;
          });
        },
        onSupplementSelected: () {
          _showAddSupplementDialog();
        },
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
    for (var meal in _currentLog!.meals) {
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
      _currentLog!.meals.add(
        FoodMealLog(
          title: title,
          foods: [],
        ),
      );
      _showMealTypeSelectorOverlay = false;
    });
    _saveLogLocal();
  }

  void _showMealTypeSelector() {
    setState(() {
      _showMealTypeSelectorOverlay = true;
    });
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
        final unit = result['unit'] as String?;

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
        final newFoodItem = FoodLogItem(
          foodId: food.id,
          amount: amount,
          plannedAmount: null, // No planned amount for manual foods
          mealPlanId: null, // Not from a meal plan
          followedPlan: false, // Manual foods are not following a plan
          alternatives: null, // No alternatives for manual foods
        );
        meal.foods.add(newFoodItem);
      });
      _calculateTotals();
      _saveLogLocal();
    }
  }

  void _removeFoodFromMeal(FoodLogItem foodItem, String mealTitle) {
    setState(() {
      final meal = _currentLog?.meals.firstWhere(
        (m) => m.title == mealTitle,
      );
      if (meal != null) {
        meal.foods.remove(foodItem);
        _calculateTotals();
      }
    });
    _saveLogLocal();
  }

  Future<void> _saveLog() async {
    if (_currentLog == null) return;

    try {
      await _foodLogService.saveLog(_currentLog!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ثبت تغذیه با موفقیت ذخیره شد')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در ذخیره: $e')),
      );
    }
  }

  Future<void> _showEditAmountDialog(
      FoodLogItem foodItem, String mealTitle) async {
    final TextEditingController controller = TextEditingController(
      text: foodItem.amount.toStringAsFixed(0),
    );

    final result = await showDialog<double>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2C1810),
                Color(0xFF3D2317),
                Color(0xFF4A2C1A),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.amber[700]!.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ویرایش مقدار مصرفی',
                style: TextStyle(
                  color: Colors.amber[200],
                  fontSize: 18,
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
                    borderSide:
                        BorderSide(color: Colors.amber[700]!.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.amber[700]!),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('انصراف',
                          style: TextStyle(color: Colors.grey[400])),
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
      String action, FoodLogItem foodItem, String mealTitle) {
    switch (action) {
      case 'complete':
        _markFoodAsComplete(foodItem, mealTitle);
        break;
      case 'substitute':
        _showSubstituteFoodDialog(foodItem, mealTitle);
        break;
      case 'delete':
        _removeFoodFromMeal(foodItem, mealTitle);
        break;
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
      FoodLogItem foodItem, String mealTitle) async {
    final alternatives = foodItem.alternatives ?? [];
    if (alternatives.isEmpty) return;
    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2C1810),
                Color(0xFF3D2317),
                Color(0xFF4A2C1A),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.amber[700]!.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('انتخاب جایگزین',
                  style: TextStyle(
                      color: Colors.amber[200],
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ...alternatives.map((alt) {
                final altFood = _allFoods.firstWhere(
                    (f) => f.id == alt['food_id'],
                    orElse: () =>
                        MealLogUtils.createDefaultFood(alt['food_id']));
                return GestureDetector(
                  onTap: () => Navigator.of(context).pop(alt),
                  child: Card(
                    color: const Color(0xFF3D2317),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: altFood.imageUrl.isNotEmpty
                                ? Image.network(altFood.imageUrl,
                                    width: 44, height: 44, fit: BoxFit.cover)
                                : Container(
                                    width: 44,
                                    height: 44,
                                    color: Colors.amber[100]
                                        ?.withValues(alpha: 0.1),
                                    child: Icon(Icons.fastfood,
                                        color: Colors.amber[300], size: 28)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(altFood.title,
                                    style: TextStyle(
                                        color: Colors.amber[100],
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text('${alt['amount']} گرم',
                                    style: TextStyle(
                                        color: Colors.amber[300],
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                          const Icon(Icons.swap_horiz,
                              color: Colors.amber, size: 22),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
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
          newAlternatives
              .removeWhere((alt) => alt['food_id'] == selected['food_id']);
          newAlternatives.add({
            'food_id': foodItem.foodId,
            'amount': foodItem.plannedAmount ?? foodItem.amount,
          });
          meal.foods[index] = FoodLogItem(
            foodId: selected['food_id'],
            amount: 0.0,
            plannedAmount: selected['amount']?.toDouble() ?? 0.0,
            mealPlanId: foodItem.mealPlanId,
            followedPlan: false,
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2C1810),
              Color(0xFF3D2317),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: Colors.amber[700]!.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(LucideIcons.flame, color: Colors.amber[400], size: 20),
                const SizedBox(width: 6),
                Text('کالری: ${_totalCalories.toStringAsFixed(0)}',
                    style: TextStyle(color: Colors.amber[200], fontSize: 14)),
                const SizedBox(width: 16),
                Icon(LucideIcons.dumbbell, color: Colors.green[300], size: 20),
                const SizedBox(width: 6),
                Text('پروتئین: ${_totalProtein.toStringAsFixed(0)}',
                    style: TextStyle(color: Colors.green[100], fontSize: 14)),
                const SizedBox(width: 16),
                Icon(LucideIcons.wheat, color: Colors.blue[300], size: 20),
                const SizedBox(width: 6),
                Text('کربو: ${_totalCarbs.toStringAsFixed(0)}',
                    style: TextStyle(color: Colors.blue[100], fontSize: 14)),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber[700]?.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _showNutritionChart
                    ? LucideIcons.chevronDown
                    : LucideIcons.chevronUp,
                color: Colors.amber[300],
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
