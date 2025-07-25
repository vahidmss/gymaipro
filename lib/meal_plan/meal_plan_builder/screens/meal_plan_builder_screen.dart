import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// مدل‌ها و سرویس‌ها
import '../../../models/food.dart';
import '../../../models/meal_plan.dart';
import '../../../services/food_service.dart';
import '../services/meal_plan_service.dart';
import '../utils/meal_plan_utils.dart';

// ویجت‌های ماژولار meal plan builder
import '../widgets/widgets.dart';

// دیالوگ‌ها
import '../dialogs/add_food_dialog.dart';
import '../dialogs/add_supplement_dialog.dart';
import '../dialogs/copy_day_dialog.dart';
import '../dialogs/meal_note_dialog.dart';
import '../dialogs/food_alternatives_dialog.dart';

class MealPlanBuilderScreen extends StatefulWidget {
  final String? planId;

  const MealPlanBuilderScreen({Key? key, this.planId}) : super(key: key);

  @override
  State<MealPlanBuilderScreen> createState() => _MealPlanBuilderScreenState();
}

class _MealPlanBuilderScreenState extends State<MealPlanBuilderScreen> {
  final FoodService _foodService = FoodService();
  final MealPlanService _mealPlanService = MealPlanService();
  MealPlan _mealPlan = MealPlan(
    id: '',
    userId: '',
    planName: '',
    days: [],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
  bool _isLoading = true;
  bool _isSaving = false;
  List<Food> _allFoods = [];
  List<MealPlan> _savedPlans = [];
  final TextEditingController _planNameController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedDay = 0; // 0=شنبه ... 6=جمعه
  bool _showDrawer = false;
  bool _showMealTypeSelector = false;
  bool _showNutritionChart = false;
  final Map<String, bool> _collapsedMeals =
      {}; // Track collapsed state for each meal

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _allFoods = await _foodService.getFoods();
      _savedPlans = await _mealPlanService.getPlans();
      if (_mealPlan.days.isEmpty) {
        final user = Supabase.instance.client.auth.currentUser;
        final userId = user?.id ?? '';
        _mealPlan = MealPlan(
          id: '',
          userId: userId,
          planName: '',
          days: List.generate(7, (i) => MealPlanDay(dayOfWeek: i, items: [])),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
      _planNameController.text = _mealPlan.planName;
      setState(() => _isLoading = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در بارگذاری: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  void _removeMeal(int dayIndex, int mealIndex) {
    setState(() {
      _mealPlan.days[dayIndex].items.removeAt(mealIndex);
    });
  }

  void _removeFood(int dayIndex, int itemIndex, int foodIndex) {
    setState(() {
      final item = _mealPlan.days[dayIndex].items[itemIndex];
      if (item is MealItem) {
        item.foods.removeAt(foodIndex);
      }
    });
  }

  Future<void> _addFood(int dayIndex, int itemIndex) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddFoodDialog(foods: _allFoods),
    );
    if (result != null) {
      setState(() {
        final food = result['food'] as Food;
        final amount = result['amount'] as double;
        final unit = result['unit'] as String?;
        final item = _mealPlan.days[dayIndex].items[itemIndex];
        if (item is MealItem) {
          item.foods.add(MealFood(foodId: food.id, amount: amount, unit: unit));
        }
      });
    }
  }

  double _calcMealNutrition(MealItem meal, String field) {
    double sum = 0;
    for (final mf in meal.foods) {
      final food = _allFoods.firstWhere((f) => f.id == mf.foodId,
          orElse: () => defaultFood(mf.foodId));
      final nutrition = food.nutrition;
      final factor = mf.amount / 100.0;
      switch (field) {
        case 'calories':
          sum += double.tryParse(nutrition.calories) ?? 0 * factor;
          break;
        case 'protein':
          sum += double.tryParse(nutrition.protein) ?? 0 * factor;
          break;
        case 'carbs':
          sum += double.tryParse(nutrition.carbohydrates) ?? 0 * factor;
          break;
        case 'fat':
          sum += double.tryParse(nutrition.fat) ?? 0 * factor;
          break;
      }
    }
    return sum;
  }

  double _calcDayNutrition(MealPlanDay day, String field) {
    double sum = 0;
    for (final item in day.items) {
      if (item is MealItem) {
        sum += _calcMealNutrition(item, field);
      } else if (item is SupplementEntry) {
        // Add supplement nutrition
        switch (field) {
          case 'protein':
            sum += item.protein ?? 0;
            break;
          case 'carbs':
            sum += item.carbs ?? 0;
            break;
          // Supplements don't contribute to calories for now
        }
      }
    }
    return sum;
  }

  // Calculate daily nutrition totals
  Map<String, double> _calcDailyNutrition() {
    final day = _mealPlan.days[_selectedDay];
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (var item in day.items) {
      if (item is MealItem) {
        totalCalories += _calcMealNutrition(item, 'calories');
        totalProtein += _calcMealNutrition(item, 'protein');
        totalCarbs += _calcMealNutrition(item, 'carbs');
        totalFat += _calcMealNutrition(item, 'fat');
      } else if (item is SupplementEntry) {
        // Add supplement nutrition if available
        if (item.protein != null) totalProtein += item.protein!;
        if (item.carbs != null) totalCarbs += item.carbs!;
      }
    }

    return {
      'calories': totalCalories,
      'protein': totalProtein,
      'carbs': totalCarbs,
      'fat': totalFat,
    };
  }

  // Build nutrition summary chart widget
  Widget _buildDailyNutritionChart() {
    final nutrition = _calcDailyNutrition();
    final totalCalories = nutrition['calories']!;
    final totalProtein = nutrition['protein']!;
    final totalCarbs = nutrition['carbs']!;
    final totalFat = nutrition['fat']!;

    // Calculate percentages for pie chart
    final proteinCalories = totalProtein * 4; // 4 calories per gram
    final carbsCalories = totalCarbs * 4; // 4 calories per gram
    final fatCalories = totalFat * 9; // 9 calories per gram

    final totalMacroCalories = proteinCalories + carbsCalories + fatCalories;

    if (totalMacroCalories == 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Icon(LucideIcons.pieChart, color: Colors.grey[400], size: 48),
            const SizedBox(height: 12),
            Text(
              'هیچ غذایی اضافه نشده',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    final proteinPercent = (proteinCalories / totalMacroCalories) * 100;
    final carbsPercent = (carbsCalories / totalMacroCalories) * 100;
    final fatPercent = (fatCalories / totalMacroCalories) * 100;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber[50]!,
            Colors.amber[100]!.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.amber[200]!.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber[700]?.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  LucideIcons.pieChart,
                  color: Colors.amber[700],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'خلاصه تغذیه روزانه',
                  style: TextStyle(
                    color: Colors.amber[800],
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Chart and stats row
          Row(
            children: [
              // Pie Chart
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 150,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          color: Colors.green[600],
                          value: proteinPercent,
                          title: '${proteinPercent.toStringAsFixed(1)}%',
                          radius: 50,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          color: Colors.blue[600],
                          value: carbsPercent,
                          title: '${carbsPercent.toStringAsFixed(1)}%',
                          radius: 50,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          color: Colors.orange[600],
                          value: fatPercent,
                          title: '${fatPercent.toStringAsFixed(1)}%',
                          radius: 50,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                      centerSpaceRadius: 30,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Nutrition details
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Total calories
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber[700]?.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.amber[700]!.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            totalCalories.toStringAsFixed(0),
                            style: TextStyle(
                              color: Colors.amber[800],
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'کالری کل',
                            style: TextStyle(
                              color: Colors.amber[700],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Macros breakdown (ماژولار)
                    Row(
                      children: [
                        Expanded(
                          child: MacroCardMealPlanBuilder(
                            title: 'پروتئین',
                            amount: '${totalProtein.toStringAsFixed(1)}g',
                            percent: proteinPercent.toStringAsFixed(1),
                            color: Colors.green[600]!,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: MacroCardMealPlanBuilder(
                            title: 'کربوهیدرات',
                            amount: '${totalCarbs.toStringAsFixed(1)}g',
                            percent: carbsPercent.toStringAsFixed(1),
                            color: Colors.blue[600]!,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: MacroCardMealPlanBuilder(
                            title: 'چربی',
                            amount: '${totalFat.toStringAsFixed(1)}g',
                            percent: fatPercent.toStringAsFixed(1),
                            color: Colors.orange[600]!,
                          ),
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
    );
  }

  Future<void> _savePlan() async {
    if (_planNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً نام برنامه را وارد کنید')),
      );
      return;
    }
    // گرفتن user_id از Supabase
    final user = Supabase.instance.client.auth.currentUser;
    final userId = user?.id ?? '';

    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('خطا: کاربر وارد نشده است!')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      _mealPlan = MealPlan(
        id: _mealPlan.id,
        userId: userId, // مقدار صحیح user_id
        planName: _planNameController.text,
        days: _mealPlan.days,
        createdAt: _mealPlan.createdAt,
        updatedAt: DateTime.now(),
      );
      await _mealPlanService.savePlan(_mealPlan);
      _savedPlans = await _mealPlanService.getPlans();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('برنامه غذایی با موفقیت ذخیره شد')),
      );
      setState(() => _isSaving = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در ذخیره برنامه: $e')),
      );
      setState(() => _isSaving = false);
    }
  }

  // Drawer مدیریت برنامه‌های غذایی
  void _openDrawer() => setState(() => _showDrawer = true);
  void _closeDrawer() => setState(() => _showDrawer = false);
  void _selectPlan(MealPlan plan) {
    setState(() {
      _mealPlan = plan;
      _planNameController.text = plan.planName;
      _showDrawer = false;
    });
  }

  Future<void> _deletePlanById(String id) async {
    await _mealPlanService.deletePlan(id);
    await _loadData();
    setState(() => _showDrawer = false);
  }

  @override
  Widget build(BuildContext context) {
    final bool hasDays =
        _mealPlan.days.isNotEmpty && _selectedDay < _mealPlan.days.length;
    final day = hasDays ? _mealPlan.days[_selectedDay] : null;
    final theme = Theme.of(context);
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF1A1A1A),
      // نوار بالای صفحه
      appBar: AppBarMealPlanBuilder(
        isSaving: _isSaving,
        onSave: _savePlan,
        onOpenDrawer: _openDrawer,
        onBack: () => Navigator.of(context).pop(),
      ),
      floatingActionButton: day != null
          ? Container(
              margin: const EdgeInsets.only(bottom: 60),
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
      body: SizedBox.expand(
        child: Stack(
          children: [
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : !hasDays
                    ? const Center(
                        child:
                            Text('برنامه غذایی یافت نشد یا مشکلی رخ داده است.'))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 140),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Plan name field
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF2C1810),
                                      Color(0xFF3D2317),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.amber[700]!.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: _planNameController,
                                  style: TextStyle(
                                    color: Colors.amber[100],
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'نام برنامه',
                                    labelStyle: TextStyle(
                                      color: Colors.amber[300],
                                      fontSize: 14,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.transparent,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Day selector
                            Container(
                              height: 60,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: 7,
                                itemBuilder: (context, idx) {
                                  final daysFa = [
                                    'روز ۱',
                                    'روز ۲',
                                    'روز ۳',
                                    'روز ۴',
                                    'روز ۵',
                                    'روز ۶',
                                    'روز ۷'
                                  ];
                                  final isSelected = _selectedDay == idx;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    child: Row(
                                      children: [
                                        AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 300),
                                          child: ChoiceChip(
                                            label: Text(
                                              daysFa[idx],
                                              style: TextStyle(
                                                color: isSelected
                                                    ? const Color(0xFF1A1A1A)
                                                    : Colors.amber[200],
                                                fontWeight: isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.w500,
                                                fontSize: 14,
                                              ),
                                            ),
                                            selected: isSelected,
                                            onSelected: (selected) {
                                              if (selected) {
                                                setState(
                                                    () => _selectedDay = idx);
                                              }
                                            },
                                            selectedColor: Colors.amber[700],
                                            backgroundColor:
                                                const Color(0xFF2C1810),
                                          ),
                                        ),
                                        if (_mealPlan
                                            .days[idx].items.isNotEmpty)
                                          Container(
                                            margin:
                                                const EdgeInsets.only(left: 4),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: () =>
                                                    _showCopyDayDialog(idx),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: Colors.amber[700]
                                                        ?.withOpacity(0.15),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    border: Border.all(
                                                      color: Colors.amber[700]!
                                                          .withOpacity(0.3),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Icon(
                                                    LucideIcons.copy,
                                                    color: Colors.amber[700],
                                                    size: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Nutrition summary (optional)
                            // ... (add your summary widgets here if needed)
                            // Meal cards
                            if (day!.items.isEmpty)
                              Center(
                                child: Container(
                                  margin: const EdgeInsets.all(32),
                                  padding: const EdgeInsets.all(40),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF2C1810),
                                        Color(0xFF3D2317),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color:
                                          Colors.amber[700]!.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.amber[700]
                                              ?.withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Icon(
                                          LucideIcons.utensils,
                                          size: 64,
                                          color: Colors.amber[700],
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      Text(
                                          'هیچ وعده‌ای برای این روز ثبت نشده است',
                                          style: TextStyle(
                                              color: Colors.amber[200],
                                              fontSize: 16)),
                                    ],
                                  ),
                                ),
                              )
                            else
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Column(
                                  children: [
                                    for (int itemIdx = 0;
                                        itemIdx < day.items.length;
                                        itemIdx++)
                                      day.items[itemIdx] is MealItem
                                          ? MealCardMealPlanBuilder(
                                              key: ValueKey(
                                                  'meal_${(day.items[itemIdx] as MealItem).id}_${itemIdx}'),
                                              meal: day.items[itemIdx]
                                                  as MealItem,
                                              itemIdx: itemIdx,
                                              theme: theme,
                                              isCollapsed: _collapsedMeals[
                                                      (day.items[itemIdx]
                                                              as MealItem)
                                                          .id] ??
                                                  false,
                                              onToggleCollapse: () {
                                                setState(() {
                                                  final mealKey =
                                                      (day.items[itemIdx]
                                                              as MealItem)
                                                          .id;
                                                  _collapsedMeals[mealKey] =
                                                      !(_collapsedMeals[
                                                              mealKey] ??
                                                          false);
                                                });
                                              },
                                              onDelete: () => _removeMeal(
                                                  _selectedDay, itemIdx),
                                              onNote: () =>
                                                  _showMealNoteDialog(itemIdx),
                                              onAddAlternative: (foodIdx) =>
                                                  _showFoodAlternativesDialog(
                                                      itemIdx, foodIdx),
                                              onDeleteFood: (foodIdx) =>
                                                  _removeFood(_selectedDay,
                                                      itemIdx, foodIdx),
                                              onAddFood: () => _addFood(
                                                  _selectedDay, itemIdx),
                                              allFoods: _allFoods,
                                              calcMealNutrition:
                                                  _calcMealNutrition,
                                              onMoveUp: itemIdx > 0
                                                  ? () {
                                                      setState(() {
                                                        final item = day.items
                                                            .removeAt(itemIdx);
                                                        day.items.insert(
                                                            itemIdx - 1, item);
                                                      });
                                                    }
                                                  : null,
                                              onMoveDown: itemIdx <
                                                      day.items.length - 1
                                                  ? () {
                                                      setState(() {
                                                        final item = day.items
                                                            .removeAt(itemIdx);
                                                        day.items.insert(
                                                            itemIdx + 1, item);
                                                      });
                                                    }
                                                  : null,
                                            )
                                          : day.items[itemIdx]
                                                  is SupplementEntry
                                              ? SupplementCardMealPlanBuilder(
                                                  key: ValueKey(
                                                      'supplement_${itemIdx}'),
                                                  supplement: day.items[itemIdx]
                                                      as SupplementEntry,
                                                  itemIdx: itemIdx,
                                                  theme: theme,
                                                  onDelete: () {
                                                    setState(() {
                                                      _mealPlan
                                                          .days[_selectedDay]
                                                          .items
                                                          .removeAt(itemIdx);
                                                    });
                                                  },
                                                )
                                              : SizedBox.shrink(
                                                  key: ValueKey(
                                                      'empty_$itemIdx')),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 8),
                            const SizedBox(height: 120),
                          ],
                        ),
                      ),
            // Bottom info bar (clickable)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showNutritionChart = !_showNutritionChart;
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                    border: Border.all(
                      color: Colors.amber[700]!.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            NutritionTagMealPlanBuilder(
                              label: 'کالری:',
                              value: day != null
                                  ? _calcDayNutrition(day, 'calories')
                                      .toStringAsFixed(0)
                                  : '0',
                              color: Colors.red[300]!,
                            ),
                            NutritionTagMealPlanBuilder(
                              label: 'پروتئین:',
                              value: day != null
                                  ? _calcDayNutrition(day, 'protein')
                                      .toStringAsFixed(1)
                                  : '0',
                              color: Colors.blue[300]!,
                            ),
                            NutritionTagMealPlanBuilder(
                              label: 'کربو:',
                              value: day != null
                                  ? _calcDayNutrition(day, 'carbs')
                                      .toStringAsFixed(1)
                                  : '0',
                              color: Colors.orange[300]!,
                            ),
                          ],
                        ),
                      ),
                      // Chart toggle icon
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
              ),
            ),
            // Nutrition Chart Overlay
            if (_showNutritionChart)
              Positioned(
                left: 16,
                right: 16,
                bottom: 100,
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
                  child: _buildDailyNutritionChart(),
                ),
              ),
            // Drawer
            if (_showDrawer)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closeDrawer,
                  child: Container(
                    color: Colors.black.withOpacity(0.2),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        width: 320,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF2C1810),
                              Color(0xFF3D2317),
                            ],
                          ),
                          borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(24)),
                          border: Border.all(
                            color: Colors.amber[700]!.withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(-6, 0),
                            ),
                          ],
                        ),
                        child: SafeArea(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'برنامه‌های ذخیره‌شده',
                                      style: TextStyle(
                                        color: Colors.amber[200],
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.amber[700]
                                            ?.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.amber[700]!
                                              .withOpacity(0.3),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: IconButton(
                                        icon: Icon(
                                          LucideIcons.x,
                                          color: Colors.amber[700],
                                        ),
                                        onPressed: _closeDrawer,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: _savedPlans.isEmpty
                                    ? Center(
                                        child: Text(
                                          'برنامه‌ای ذخیره نشده',
                                          style: TextStyle(
                                            color: Colors.amber[300],
                                            fontSize: 16,
                                          ),
                                        ),
                                      )
                                    : ListView.separated(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12),
                                        itemCount: _savedPlans.length,
                                        separatorBuilder: (_, __) =>
                                            const Divider(),
                                        itemBuilder: (context, idx) {
                                          final plan = _savedPlans[idx];
                                          return Container(
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.amber[700]
                                                  ?.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.amber[700]!
                                                    .withOpacity(0.2),
                                                width: 1,
                                              ),
                                            ),
                                            child: ListTile(
                                              title: Text(
                                                plan.planName,
                                                style: TextStyle(
                                                  color: Colors.amber[100],
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              subtitle: Text(
                                                'تاریخ: ${plan.createdAt.toString().substring(0, 10)}',
                                                style: TextStyle(
                                                  color: Colors.amber[300],
                                                  fontSize: 12,
                                                ),
                                              ),
                                              onTap: () => _selectPlan(plan),
                                              trailing: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.red[100]
                                                      ?.withOpacity(0.3),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: Colors.red[300]!,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: IconButton(
                                                  icon: Icon(
                                                    LucideIcons.trash2,
                                                    color: Colors.red[300],
                                                    size: 18,
                                                  ),
                                                  onPressed: () =>
                                                      _deletePlanById(plan.id),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.amber[600]!,
                                        Colors.amber[700]!,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.amber[700]!.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton.icon(
                                    icon: const Icon(
                                      LucideIcons.plus,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                    label: const Text(
                                      'برنامه جدید',
                                      style: TextStyle(
                                        color: Color(0xFF1A1A1A),
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        final user = Supabase
                                            .instance.client.auth.currentUser;
                                        final userId = user?.id ?? '';
                                        _mealPlan = MealPlan(
                                          id: '',
                                          userId: userId,
                                          planName: '',
                                          days: List.generate(
                                              7,
                                              (i) => MealPlanDay(
                                                  dayOfWeek: i, items: [])),
                                          createdAt: DateTime.now(),
                                          updatedAt: DateTime.now(),
                                        );
                                        _planNameController.text = '';
                                        _showDrawer = false;
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
                  ),
                ),
              ),
            // Meal Type Selector Overlay
            if (_showMealTypeSelector)
              MealTypeSelectorOverlayMealPlanBuilder(
                onSelectType: (type) {
                  _addMealWithType(type);
                },
                onClose: () {
                  setState(() {
                    _showMealTypeSelector = false;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  // Show popup menu for adding items
  void _showAddItemMenu(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.all(20),
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
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber[700]?.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        LucideIcons.plus,
                        color: Colors.amber[700],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'افزودن آیتم جدید',
                        style: TextStyle(
                          color: Colors.amber[200],
                          fontSize: 13,
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
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Meal option
                MenuOptionMealPlanBuilder(
                  icon: LucideIcons.utensils,
                  title: 'وعده غذایی',
                  subtitle: 'صبحانه، ناهار، شام، میان‌وعده',
                  color: Colors.green[400]!,
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _showMealTypeSelector = true;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Supplement option
                MenuOptionMealPlanBuilder(
                  icon: LucideIcons.pill,
                  title: 'مکمل/دارو',
                  subtitle: 'مکمل غذایی، ویتامین، دارو',
                  color: Colors.purple[400]!,
                  onTap: () {
                    Navigator.of(context).pop();
                    _showAddSupplementDialog();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Add meal with selected type
  void _addMealWithType(String mealType) {
    // Count existing snacks to generate next number
    int snackCount = 0;
    for (var item in _mealPlan.days[_selectedDay].items) {
      if (item is MealItem && item.title.startsWith('میان وعده')) {
        snackCount++;
      }
    }

    String title;
    String type;

    if (mealType == 'میان وعده') {
      title = 'میان وعده ${snackCount + 1}';
      type = 'snack';
    } else {
      title = mealType;
      type = 'main';
    }

    final newMeal = MealItem(
      mealType: type,
      title: title,
      foods: [],
    );

    setState(() {
      _mealPlan.days[_selectedDay].items.add(newMeal);
      _showMealTypeSelector = false;
    });
  }

  // Show dialog for adding a supplement
  Future<void> _showAddSupplementDialog() async {
    final result = await showDialog<SupplementEntry>(
      context: context,
      builder: (context) => AddSupplementDialog(),
    );
    if (result != null) {
      setState(() {
        _mealPlan.days[_selectedDay].items.add(result);
      });
    }
  }

  // Show dialog for copying a day
  Future<void> _showCopyDayDialog(int sourceDayIndex) async {
    final daysFa = [
      'روز ۱',
      'روز ۲',
      'روز ۳',
      'روز ۴',
      'روز ۵',
      'روز ۶',
      'روز ۷'
    ];
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => CopyDayDialog(
        days: daysFa,
        currentDayIndex: sourceDayIndex,
      ),
    );
    if (result != null && result['to'] != null) {
      for (final targetDayIndex in result['to']) {
        _copyDay(sourceDayIndex, targetDayIndex);
      }
    }
  }

  // Show confirmation dialog for copying to non-empty day
  Future<void> _showCopyConfirmationDialog(
      int sourceDayIndex, int targetDayIndex) async {
    final daysFa = [
      'روز ۱',
      'روز ۲',
      'روز ۳',
      'روز ۴',
      'روز ۵',
      'روز ۶',
      'روز ۷'
    ];
    final targetDay = _mealPlan.days[targetDayIndex];

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C1810),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(LucideIcons.alertTriangle, color: Colors.orange[400]),
            const SizedBox(width: 8),
            Text(
              'توجه',
              style: TextStyle(color: Colors.amber[200]),
            ),
          ],
        ),
        content: Text(
          '${daysFa[targetDayIndex]} دارای ${targetDay.items.length} آیتم است. آیا می‌خواهید آیتم‌های ${daysFa[sourceDayIndex]} را به آن اضافه کنید؟',
          style: TextStyle(color: Colors.amber[200]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('انصراف', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[700],
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('تایید', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      Navigator.of(context).pop(); // Close the main dialog
      _copyDay(sourceDayIndex, targetDayIndex);
    }
  }

  // Copy day items
  void _copyDay(int sourceDayIndex, int targetDayIndex) {
    final targetDay = _mealPlan.days[targetDayIndex];
    final sourceDay = _mealPlan.days[sourceDayIndex];
    targetDay.items.clear();
    // Deep copy all items
    for (var item in sourceDay.items) {
      if (item is MealItem) {
        final copiedMeal = MealItem(
          mealType: item.mealType,
          title: item.title,
          foods: List.from(item.foods.map((f) => MealFood(
                foodId: f.foodId,
                amount: f.amount,
                unit: f.unit,
                alternatives: f.alternatives,
              ))),
          note: item.note,
        ); // id will be auto-generated
        targetDay.items.add(copiedMeal);
      } else if (item is SupplementEntry) {
        final copiedSupplement = SupplementEntry(
          name: item.name,
          amount: item.amount,
          unit: item.unit,
          time: item.time,
          note: item.note,
          supplementType: item.supplementType,
          protein: item.protein,
          carbs: item.carbs,
        ); // id will be auto-generated
        targetDay.items.add(copiedSupplement);
      }
    }
    setState(() {
      _selectedDay = targetDayIndex;
    });
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.check, color: Colors.white),
            const SizedBox(width: 8),
            Text('${sourceDay.items.length} آیتم با موفقیت کپی شد'),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _showFoodAlternativesDialog(int mealIdx, int foodIdx) async {
    final item = _mealPlan.days[_selectedDay].items[mealIdx] as MealItem;
    final food = item.foods[foodIdx];
    final List<Food> options =
        _allFoods.where((f) => f.id != food.foodId).toList();
    final Map<int, double> selectedWithAmounts = {};
    for (final alt in (food.alternatives ?? [])) {
      selectedWithAmounts[alt['food_id'] as int] =
          (alt['amount'] as num).toDouble();
    }

    await showDialog(
      context: context,
      builder: (context) => FoodAlternativesDialog(
        foods: options,
        selectedFood: _allFoods.firstWhere((f) => f.id == food.foodId,
            orElse: () => defaultFood(food.foodId)),
        selectedAlternatives: selectedWithAmounts,
        onConfirm: (alts) {
          setState(() {
            item.foods[foodIdx] = MealFood(
              foodId: food.foodId,
              amount: food.amount,
              unit: food.unit,
              alternatives: alts.entries
                  .map((e) => {'food_id': e.key, 'amount': e.value})
                  .toList(),
            );
          });
          Navigator.of(context).pop();
        },
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  Future<void> _showMealNoteDialog(int mealIdx) async {
    final item = _mealPlan.days[_selectedDay].items[mealIdx] as MealItem;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => MealNoteDialog(initialNote: item.note),
    );
    if (result != null) {
      setState(() {
        final item = _mealPlan.days[_selectedDay].items[mealIdx] as MealItem;
        _mealPlan.days[_selectedDay].items[mealIdx] = MealItem(
          mealType: item.mealType,
          title: item.title,
          foods: item.foods,
          note: result,
        );
      });
    }
  }
}
