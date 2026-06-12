// import removed: fl_chart now used via DailyNutritionChartMealPlanBuilder
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// دیالوگ‌ها
import 'package:gymaipro/meal_plan_builder/screens/add_food_screen.dart';
import 'package:gymaipro/meal_plan_builder/screens/user_details_screen.dart';
import 'package:gymaipro/meal_plan_builder/dialogs/confirm_delete_food_dialog.dart';
import 'package:gymaipro/meal_plan_builder/dialogs/copy_day_dialog.dart';
import 'package:gymaipro/meal_plan_builder/dialogs/day_comment_dialog.dart';
import 'package:gymaipro/meal_plan_builder/dialogs/meal_note_dialog.dart';
import 'package:gymaipro/meal_plan_builder/services/meal_plan_service.dart';
import 'package:gymaipro/meal_plan_builder/utils/meal_plan_utils.dart';
// ویجت‌های ماژولار meal plan builder
import 'package:gymaipro/meal_plan_builder/widgets/widgets.dart';
// مدل‌ها و سرویس‌ها
import 'package:gymaipro/models/food.dart';
import 'package:gymaipro/models/meal_plan.dart';
import 'package:gymaipro/services/fitness_calculator.dart';
import 'package:gymaipro/services/food_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/user_profile/services/user_profile_service.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:gymaipro/utils/date_utils.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MealPlanBuilderScreen extends StatefulWidget {
  const MealPlanBuilderScreen({
    super.key,
    this.planId,
    this.targetUserId,
    this.targetUserName,
    this.subscriptionId,
    this.paymentTransactionId,
  });
  final String? planId;
  final String? targetUserId; // برای ترنرها - ساخت برنامه برای کاربر دیگر
  final String? targetUserName; // برای ترنرها - نام کاربر هدف
  final String? subscriptionId; // اتصال مستقیم به اشتراک
  final String? paymentTransactionId;

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
  bool _isAutoSaving = false;
  List<Food> _allFoods = [];
  List<MealPlan> _savedPlans = []; // لیست برنامه‌های ذخیره شده
  int _selectedDay = 0; // 0=شنبه ... 6=جمعه
  bool _showMealTypeSelector = false;
  final Map<String, bool> _collapsedMeals =
      {}; // Track collapsed state for each meal
  double? _dailyCalorieTarget; // TDEE کاربر هدف
  String? _targetUserName; // نام کاربر هدف برای ساخت نام برنامه
  DateTime? _editableUntil; // تاریخ پایان مهلت ویرایش

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // بررسی و اضافه کردن وعده‌های پیش‌فرض به یک روز
  void _ensureDefaultMealsForDay(int dayIndex) {
    final day = _mealPlan.days[dayIndex];
    final defaultMealTitles = [
      'صبحانه',
      'میان‌وعده 1',
      'ناهار',
      'میان‌وعده 2',
      'شام',
      'میان‌وعده 3',
    ];

    // بررسی اینکه آیا همه وعده‌های پیش‌فرض وجود دارند
    final existingTitles = day.items
        .whereType<MealItem>()
        .map((meal) => meal.title)
        .toSet();

    // اضافه کردن وعده‌های پیش‌فرض که وجود ندارند
    for (final title in defaultMealTitles) {
      if (!existingTitles.contains(title)) {
        final mealType = title.startsWith('میان‌وعده') ? 'snack' : 'main';
        day.items.add(MealItem(mealType: mealType, title: title, foods: []));
      }
    }

    // مرتب‌سازی وعده‌ها بر اساس ترتیب پیش‌فرض
    day.items.sort((a, b) {
      if (a is MealItem && b is MealItem) {
        final aIndex = defaultMealTitles.indexOf(a.title);
        final bIndex = defaultMealTitles.indexOf(b.title);
        if (aIndex == -1) return 1;
        if (bIndex == -1) return -1;
        return aIndex.compareTo(bIndex);
      }
      return 0;
    });
  }

  Future<void> _loadData() async {
    SafeSetState.call(this, () => _isLoading = true);
    try {
      _allFoods = await _foodService.getFoods();

      final user = Supabase.instance.client.auth.currentUser;
      final userId = widget.targetUserId ?? user?.id ?? '';

      // بارگذاری برنامه‌های ذخیره شده توسط مربی فعلی
      if (user != null && user.id.isNotEmpty) {
        _savedPlans = await _mealPlanService.getPlansCreatedByTrainer(user.id);
      } else {
        _savedPlans = [];
      }

      // اگر planId مشخص شده باشد، برنامه را از ID بارگذاری کن
      if (widget.planId != null && widget.planId!.isNotEmpty) {
        final plan = await _mealPlanService.getPlanById(widget.planId!);
        if (plan != null) {
          _mealPlan = plan;
        } else {
          // اگر برنامه پیدا نشد، برنامه جدید بساز
          final planName = await _generatePlanName();
          _mealPlan = MealPlan(
            id: '',
            userId: userId,
            planName: planName,
            days: List.generate(7, (i) => MealPlanDay(dayOfWeek: i, items: [])),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }
      } else if (widget.targetUserId != null && user != null) {
        // اگر مربی برای کاربر دیگری برنامه می‌سازد، بررسی کن آیا برنامه موجودی وجود دارد
        final existingPlan = await _mealPlanService
            .getExistingPlanForTrainerAndUser(widget.targetUserId!, user.id);

        if (existingPlan != null) {
          // برنامه موجود را بارگذاری کن
          SafeSetState.call(this, () {
            _mealPlan = existingPlan;
          });
          // خواندن editable_until از دیتابیس
          print('📥 برنامه موجود بارگذاری شد، در حال خواندن editable_until...');
          await _loadEditableUntil();
        } else {
          // برنامه جدید بساز با نام خودکار
          final planName = await _generatePlanName();
          _mealPlan = MealPlan(
            id: '',
            userId: userId,
            planName: planName,
            days: List.generate(7, (i) => MealPlanDay(dayOfWeek: i, items: [])),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }
      } else {
        // حالت عادی: کاربر برای خودش برنامه می‌سازد
        if (_mealPlan.days.isEmpty) {
          final planName = await _generatePlanName();
          _mealPlan = MealPlan(
            id: '',
            userId: userId,
            planName: planName,
            days: List.generate(7, (i) => MealPlanDay(dayOfWeek: i, items: [])),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }
      }

      // اضافه کردن وعده‌های پیش‌فرض به همه روزها
      for (int i = 0; i < _mealPlan.days.length; i++) {
        _ensureDefaultMealsForDay(i);
      }

      // محاسبه TDEE کاربر هدف
      await _calculateDailyCalorieTarget();

      SafeSetState.call(this, () => _isLoading = false);
    } catch (e) {
      WidgetSafetyUtils.safeShowSnackBar(
        context,
        'خطا در بارگذاری: $e',
      );
      SafeSetState.call(this, () => _isLoading = false);
    }
  }

  // خواندن editable_until از دیتابیس
  Future<void> _loadEditableUntil() async {
    if (_mealPlan.id.isEmpty || widget.targetUserId == null) {
      print(
        '⚠️ _loadEditableUntil: برنامه ID خالی است یا targetUserId null است',
      );
      return;
    }

    try {
      final client = Supabase.instance.client;
      print('🔍 در حال خواندن editable_until برای برنامه: ${_mealPlan.id}');
      final planData = await client
          .from('meal_plans')
          .select('editable_until, sent_at')
          .eq('id', _mealPlan.id)
          .maybeSingle();

      print('📊 داده‌های خوانده شده: $planData');

      if (planData != null && planData['editable_until'] != null) {
        final editableUntilStr = planData['editable_until'] as String;
        print('✅ editable_until پیدا شد: $editableUntilStr');
        SafeSetState.call(this, () {
          _editableUntil = DateTime.parse(editableUntilStr);
          print('✅ _editableUntil تنظیم شد: $_editableUntil');
        });
      } else {
        // editable_until و expiry_date فقط بعد از ارسال برنامه (sendPlan) ثبت می‌شوند
        // تا زمانی که مربی روی دکمه ارسال نزده، این فیلدها null هستند
        print('⚠️ برنامه هنوز ارسال نشده است (editable_until null)');
        SafeSetState.call(this, () {
          _editableUntil = null;
        });
      }
    } catch (e) {
      // اگر ستون editable_until وجود نداشت، خطا را gracefully handle می‌کنیم
      final errorStr = e.toString();
      if (errorStr.contains('editable_until') ||
          errorStr.contains('does not exist') ||
          errorStr.contains('42703')) {
        print('⚠️ ستون editable_until در دیتابیس وجود ندارد.');
        print(
          '📄 لطفاً فایل SQL را اجرا کنید: sql/add_all_meal_plan_columns.sql',
        );
        SafeSetState.call(this, () {
          _editableUntil = null;
        });
      } else {
        print('❌ خطا در خواندن editable_until: $e');
        SafeSetState.call(this, () {
          _editableUntil = null;
        });
      }
    }
  }

  // محاسبه ساعت‌های باقیمانده تا editable_until
  int? _getRemainingHours() {
    if (_editableUntil == null) {
      print('⚠️ _getRemainingHours: _editableUntil null است');
      return null;
    }
    final now = DateTime.now();
    if (now.isAfter(_editableUntil!)) {
      print('⏰ زمان ویرایش به پایان رسیده است');
      return 0;
    }
    final difference = _editableUntil!.difference(now);
    // محاسبه دقیق ساعت‌ها: فقط ساعت‌های کامل (بدون رند کردن)
    final hours = difference.inHours;
    print(
      '⏳ ساعت‌های باقیمانده: $hours (از ${difference.inDays} روز و ${(difference.inHours % 24)} ساعت)',
    );
    return hours;
  }

  // ساخت خودکار نام برنامه: "رژیم غذایی-نام کاربر"
  Future<String> _generatePlanName() async {
    final dateStr = toJalali(DateTime.now());
    
    if (widget.targetUserId == null) {
      return 'رژیم غذایی-$dateStr';
    }

    try {
      final userProfile = await UserProfileService.fetchProfile(
        widget.targetUserId!,
      );
      if (userProfile != null) {
        final firstName = userProfile['first_name']?.toString() ?? '';
        final lastName = userProfile['last_name']?.toString() ?? '';
        final userName = '$firstName $lastName'.trim();

        if (userName.isNotEmpty) {
          _targetUserName = userName;
          return 'رژیم غذایی-$userName-$dateStr';
        }
      }
    } catch (e) {
      print('خطا در دریافت اطلاعات کاربر برای ساخت نام: $e');
    }

    // در صورت خطا، از نام کاربر از widget استفاده کن
    final userName = widget.targetUserName ?? 'کاربر';
    _targetUserName = userName;
    return 'رژیم غذایی-$userName-$dateStr';
  }

  // ذخیره خودکار برنامه (real-time)
  Future<void> _autoSavePlan() async {
    if (_isAutoSaving || widget.targetUserId == null) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    SafeSetState.call(this, () => _isAutoSaving = true);

    try {
      // ساخت نام برنامه اگر وجود نداشت
      if (_mealPlan.planName.isEmpty) {
        final planName = await _generatePlanName();
        _mealPlan = MealPlan(
          id: _mealPlan.id,
          userId: _mealPlan.userId,
          planName: planName,
          days: _mealPlan.days,
          createdAt: _mealPlan.createdAt,
          updatedAt: DateTime.now(),
          sentAt: _mealPlan.sentAt,
        );
      }

      // بررسی اینکه آیا برنامه در دیتابیس ذخیره شده است یا نه
      final isPlanSaved = _savedPlans.any((p) => p.id == _mealPlan.id && p.id.isNotEmpty);

      // ذخیره برنامه جدید یا به‌روزرسانی برنامه موجود
      if (isPlanSaved) {
        // به‌روزرسانی برنامه موجود
        final updatedPlan = await _mealPlanService.updatePlan(
          _mealPlan,
          trainerId: user.id,
        );
        SafeSetState.call(this, () {
          _mealPlan = updatedPlan;
        });
        // خواندن editable_until از دیتابیس
        print(
          '🔄 برنامه موجود به‌روزرسانی شد، در حال خواندن editable_until...',
        );
        await _loadEditableUntil();
      } else {
        // ایجاد یک برنامه جدید
        final newPlan = await _mealPlanService.createPlan(
          _mealPlan,
          trainerId: user.id,
          targetUserId: widget.targetUserId,
          subscriptionId: widget.subscriptionId,
          paymentTransactionId: widget.paymentTransactionId,
        );
        SafeSetState.call(this, () {
          _mealPlan = newPlan;
        });
        
        // به‌روزرسانی لیست برنامه‌های ذخیره شده
        final updatedSavedPlans = await _mealPlanService
            .getPlansCreatedByTrainer(user.id);
        SafeSetState.call(this, () {
          _savedPlans = updatedSavedPlans;
        });
        
        // خواندن editable_until از دیتابیس
        print('💾 برنامه جدید ذخیره شد، در حال خواندن editable_until...');
        await _loadEditableUntil();
      }
    } catch (e) {
      print('خطا در ذخیره خودکار برنامه: $e');
    } finally {
      SafeSetState.call(this, () => _isAutoSaving = false);
    }
  }

  // نمایش دیالوگ تأیید ارسال برنامه
  Future<void> _showConfirmDialog() async {
    final userName = _targetUserName ?? widget.targetUserName ?? 'کاربر';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? context.backgroundColor
              : context.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
            side: BorderSide(color: AppTheme.goldColor.withValues(alpha: 0.3)),
          ),
          title: Text(
            'تأیید ارسال برنامه',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.goldColor
                  : context.textColor,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'مطمئن هستید می‌خواهید برنامه برای کاربر $userName فرستاده بشه؟\n\nاز ثبت این تاریخ تا مدت 3 روز وقت ویرایش برنامه و تطبیق بیشتر آن را دارید.',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.goldColor.withValues(alpha: 0.9)
                  : context.textColor.withValues(alpha: 0.9),
              fontSize: 14.sp,
              height: 1.6,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(foregroundColor: AppTheme.goldColor),
              child: Text(
                'انصراف',
                style: TextStyle(fontFamily: AppTheme.fontFamily),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                'تأیید و ارسال',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      // ذخیره نهایی
      await _autoSavePlan();

      // ارسال برنامه (تنظیم sent_at، editable_until و expiry_date)
      if (_mealPlan.id.isNotEmpty) {
        try {
          await _mealPlanService.sendPlan(
            _mealPlan.id,
            subscriptionId: widget.subscriptionId,
          );
          // بارگذاری مجدد برنامه برای دریافت sentAt
          final updatedPlan = await _mealPlanService.getPlanById(_mealPlan.id);
          if (updatedPlan != null) {
            SafeSetState.call(this, () {
              _mealPlan = updatedPlan;
            });
            // خواندن editable_until از دیتابیس
            await _loadEditableUntil();
          }
        } catch (e) {
          print('خطا در ارسال برنامه: $e');
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('خطا در ارسال برنامه: $e')));
          }
          return;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('برنامه با موفقیت ارسال شد')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  // محاسبه TDEE کاربر هدف
  Future<void> _calculateDailyCalorieTarget() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final targetUserId = widget.targetUserId ?? user?.id;
      if (targetUserId == null) return;

      final profile = await UserProfileService.fetchProfile(targetUserId);
      if (profile == null) return;

      final height = profile['height'] != null
          ? double.tryParse(profile['height'].toString())
          : null;
      final weight = profile['weight'] != null
          ? double.tryParse(profile['weight'].toString())
          : null;
      final birthDateStr = profile['birth_date']?.toString();
      final isMale = (profile['gender']?.toString() ?? 'male') == 'male';
      final activityLevelStr =
          (profile['activity_level']?.toString() ?? 'moderate');

      if (height == null || weight == null || height <= 0 || weight <= 0) {
        return;
      }

      // محاسبه سن
      int age = 25;
      if (birthDateStr != null && birthDateStr.isNotEmpty) {
        try {
          final birthDate = DateTime.tryParse(birthDateStr);
          if (birthDate != null) {
            final now = DateTime.now();
            age =
                now.year -
                birthDate.year -
                ((now.month < birthDate.month ||
                        (now.month == birthDate.month &&
                            now.day < birthDate.day))
                    ? 1
                    : 0);
          }
        } catch (_) {}
      }

      if (age <= 0) return;

      // محاسبه BMR و TDEE
      final bmr = FitnessCalculator.calculateBMR(weight, height, age, isMale);
      final activityLevel = activityLevelStr.toActivityLevel();
      _dailyCalorieTarget = FitnessCalculator.calculateTDEE(bmr, activityLevel);
    } catch (e) {
      print('خطا در محاسبه TDEE: $e');
    }
  }

  void _removeMeal(int dayIndex, int mealIndex) {
    setState(() {
      _mealPlan.days[dayIndex].items.removeAt(mealIndex);
    });
    // ذخیره خودکار
    _autoSavePlan();
  }

  Future<void> _removeFood(int dayIndex, int itemIndex, int foodIndex) async {
    final item = _mealPlan.days[dayIndex].items[itemIndex];
    if (item is! MealItem) return;

    final food = item.foods[foodIndex];
    final foodData = _allFoods.firstWhere(
      (f) => f.id == food.foodId,
      orElse: () => defaultFood(food.foodId),
    );

    final confirmed = await ConfirmDeleteFoodDialogMealPlanBuilder.show(
      context,
      foodTitle: foodData.title,
      isSupplement: foodData.type == 'supplement',
    );

    if (confirmed == true && mounted) {
      setState(() {
        item.foods.removeAt(foodIndex);
      });
      // ذخیره خودکار
      _autoSavePlan();
    }
  }

  Future<void> _addFood(int dayIndex, int itemIndex) async {
    final item = _mealPlan.days[dayIndex].items[itemIndex];
    if (item is! MealItem) return;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (context) => AddFoodScreenMealPlanBuilder(
        foods: _allFoods,
        initialMealTitle: item.title,
      ),
    );
    if (result != null && mounted) {
      // اگر از تب مکمل‌ها برگشته باشد، مکمل را به عنوان آیتم غذا در همین وعده ثبت کن
      if (result.containsKey('supplement')) {
        final SupplementEntry supp = result['supplement'] as SupplementEntry;
        setState(() {
          // ساخت Food موقت برای نمایش در کارت وعده
          final int tempFoodId = -DateTime.now().millisecondsSinceEpoch;
          final double protein = supp.protein ?? 0;
          final double carbs = supp.carbs ?? 0;
          final double fat = 0; // فعلاً بدون چربی
          // فقط اگر کالری وارد شده باشد استفاده می‌شود، در غیر این صورت 0
          final double calories = supp.calories ?? 0;
          // ذخیره یادداشت در content
          _allFoods.add(
            Food(
              id: tempFoodId,
              title: supp.name,
              content: (supp.note != null && supp.note!.isNotEmpty)
                  ? 'SUPPLEMENT_NOTE:${supp.note}'
                  : '',
              imageUrl: '',
              slug: '',
              date: DateTime.now(),
              modified: DateTime.now(),
              status: '',
              type: 'supplement',
              link: '',
              featuredMedia: 0,
              nutrition: FoodNutrition(
                protein: protein.toStringAsFixed(1),
                calories: calories.toStringAsFixed(0),
                carbohydrates: carbs.toStringAsFixed(1),
                fat: fat.toStringAsFixed(1),
                saturatedFat: '0',
                fiber: '0',
                sugar: '0',
                cholesterol: '0',
                sodium: '0',
                potassium: '0',
              ),
              foodCategories: const [],
              classList: const [],
            ),
          );
          final double usedAmount = supp.amount ?? 1;
          final String? usedUnit = supp.unit;
          item.foods.add(
            MealFood(foodId: tempFoodId, amount: usedAmount, unit: usedUnit),
          );
        });
        // ذخیره خودکار
        _autoSavePlan();
        return;
      }
      setState(() {
        final food = result['food'] as Food;
        final amount = result['amount'] as double;
        final unit = result['unit'] as String;
        item.foods.add(MealFood(foodId: food.id, amount: amount, unit: unit));
      });
      // ذخیره خودکار
      _autoSavePlan();
    }
  }

  double _calcMealNutrition(MealItem meal, String field) {
    double sum = 0;
    for (final mf in meal.foods) {
      final food = _allFoods.firstWhere(
        (f) => f.id == mf.foodId,
        orElse: () => defaultFood(mf.foodId),
      );
      final nutrition = food.nutrition;
      final factor = mf.amount / 100.0;
      switch (field) {
        case 'calories':
          sum += (double.tryParse(nutrition.calories) ?? 0) * factor;
        case 'protein':
          sum += (double.tryParse(nutrition.protein) ?? 0) * factor;
        case 'carbs':
          sum += (double.tryParse(nutrition.carbohydrates) ?? 0) * factor;
        case 'fat':
          sum += (double.tryParse(nutrition.fat) ?? 0) * factor;
      }
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    final bool hasDays =
        _mealPlan.days.isNotEmpty && _selectedDay < _mealPlan.days.length;
    final day = hasDays ? _mealPlan.days[_selectedDay] : null;
    final theme = Theme.of(context);
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
          child: Scaffold(
            backgroundColor: Colors.transparent,
            // نوار بالای صفحه
            appBar: AppBarMealPlanBuilder(
              onConfirm: _showConfirmDialog,
              showConfirmButton:
                  widget.targetUserId != null &&
                  _mealPlan.id.isNotEmpty &&
                  (_mealPlan.sentAt == null),
            ),
            body: SizedBox.expand(
              child: Stack(
                children: [
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    !hasDays
                        ? const Center(
                            child: Text(
                              'برنامه غذایی یافت نشد یا مشکلی رخ داده است.',
                            ),
                          )
                        : SingleChildScrollView(
                            padding: EdgeInsets.only(bottom: 32.h),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (widget.targetUserId != null)
                                  Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      16.w,
                                      12.h,
                                      16.w,
                                      8.h,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            // Badge مینیمال برای نمایش کاربر
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 12.w,
                                                vertical: 6.h,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppTheme.goldColor
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(20.r),
                                                border: Border.all(
                                                  color: AppTheme.goldColor
                                                      .withValues(
                                                        alpha: isDark
                                                            ? 0.4
                                                            : 0.5,
                                                      ),
                                                  width: 1.w,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    width: 6.w,
                                                    height: 6.h,
                                                    decoration: BoxDecoration(
                                                      color: AppTheme.goldColor,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  SizedBox(width: 6.w),
                                                  Text(
                                                    'در حال ساخت برنامه برای ${widget.targetUserName ?? 'کاربر'}',
                                                    style: TextStyle(
                                                      fontFamily:
                                                          AppTheme.fontFamily,
                                                      color: isDark
                                                          ? AppTheme.goldColor
                                                          : context.textColor,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 11.sp,
                                                      letterSpacing: 0.1,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Spacer(),
                                            // دکمه مشخصات به صورت icon button مینیمال
                                            Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: () {
                                                  showModalBottomSheet<void>(
                                                    context: context,
                                                    isScrollControlled: true,
                                                    backgroundColor:
                                                        Colors.transparent,
                                                    builder: (context) =>
                                                        UserDetailsScreenMealPlanBuilder(
                                                          userId: widget
                                                              .targetUserId!,
                                                          userName:
                                                              widget
                                                                  .targetUserName ??
                                                              'کاربر',
                                                        ),
                                                  );
                                                },
                                                borderRadius:
                                                    BorderRadius.circular(12.r),
                                                child: Container(
                                                  padding: EdgeInsets.all(8.w),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.goldColor
                                                        .withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12.r,
                                                        ),
                                                    border: Border.all(
                                                      color: AppTheme.goldColor
                                                          .withValues(
                                                            alpha: isDark
                                                                ? 0.3
                                                                : 0.4,
                                                          ),
                                                      width: 1.w,
                                                    ),
                                                  ),
                                                  child: Icon(
                                                    LucideIcons.user,
                                                    color: isDark
                                                        ? AppTheme.goldColor
                                                        : context.textColor,
                                                    size: 16.sp,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        // نمایش ساعت‌های باقیمانده زیر Badge
                                        Builder(
                                          builder: (context) {
                                            // اگر برنامه ارسال شده و editable_until وجود دارد
                                            if (_mealPlan.sentAt != null &&
                                                _editableUntil != null) {
                                              final remainingHours =
                                                  _getRemainingHours();
                                              if (remainingHours != null) {
                                                return Padding(
                                                  padding: EdgeInsets.only(
                                                    top: 8.h,
                                                    right: 0.w,
                                                  ),
                                                  child: Text(
                                                    'تا $remainingHours ساعت دیگر مجاز به ویرایش برنامه هستید',
                                                    style: TextStyle(
                                                      fontFamily:
                                                          AppTheme.fontFamily,
                                                      color: isDark
                                                          ? AppTheme.goldColor
                                                                .withValues(
                                                                  alpha: 0.7,
                                                                )
                                                          : context.textColor
                                                                .withValues(
                                                                  alpha: 0.7,
                                                                ),
                                                      fontSize: 12.sp,
                                                    ),
                                                  ),
                                                );
                                              }
                                            }
                                            // اگر برنامه ارسال شده اما editable_until هنوز بارگذاری نشده
                                            if (_mealPlan.sentAt != null &&
                                                _editableUntil == null) {
                                              return Padding(
                                                padding: EdgeInsets.only(
                                                  top: 8.h,
                                                  right: 0.w,
                                                ),
                                                child: Text(
                                                  'در حال بارگذاری اطلاعات...',
                                                  style: TextStyle(
                                                    fontFamily:
                                                        AppTheme.fontFamily,
                                                    color: Colors.orange
                                                        .withValues(alpha: 0.7),
                                                    fontSize: 11.sp,
                                                  ),
                                                ),
                                              );
                                            }
                                            return const SizedBox.shrink();
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                // Day selector
                                DaySelectorCardMealPlanBuilder(
                                  selectedDay: _selectedDay,
                                  mealPlan: _mealPlan,
                                  onDaySelected: (idx) {
                                    setState(() {
                                      _selectedDay = idx;
                                      _ensureDefaultMealsForDay(idx);
                                    });
                                  },
                                  onCopyDay: _showCopyDayDialog,
                                ),
                                SizedBox(height: 8.h),
                                // Day comment section
                                if (hasDays && day != null)
                                  _buildDayCommentSection(isDark, day),
                                SizedBox(height: 8.h),
                                // Daily calorie target summary
                                if (hasDays &&
                                    day != null &&
                                    _dailyCalorieTarget != null)
                                  _buildDailyCalorieTargetCard(isDark, day),
                                SizedBox(height: 8.h),
                                // Meal cards - همیشه وعده‌های پیش‌فرض نمایش داده می‌شوند
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                  ),
                                  child: Column(
                                    children: [
                                      for (
                                        int itemIdx = 0;
                                        itemIdx < day!.items.length;
                                        itemIdx++
                                      )
                                        day.items[itemIdx] is MealItem
                                            ? MealCardMealPlanBuilder(
                                                key: ValueKey(
                                                  'meal_${(day.items[itemIdx] as MealItem).id}_$itemIdx',
                                                ),
                                                meal:
                                                    day.items[itemIdx]
                                                        as MealItem,
                                                itemIdx: itemIdx,
                                                theme: theme,
                                                isCollapsed:
                                                    _collapsedMeals[(day
                                                                .items[itemIdx]
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
                                                        !(_collapsedMeals[mealKey] ??
                                                            false);
                                                  });
                                                },
                                                onDelete: () => _removeMeal(
                                                  _selectedDay,
                                                  itemIdx,
                                                ),
                                                onNote: () =>
                                                    _showMealNoteDialog(
                                                      itemIdx,
                                                    ),
                                                onAddAlternative: (foodIdx) =>
                                                    _showFoodAlternativesDialog(
                                                      itemIdx,
                                                      foodIdx,
                                                    ),
                                                onDeleteAlternative:
                                                    (foodIdx, altFoodId) =>
                                                        _removeAlternative(
                                                          itemIdx,
                                                          foodIdx,
                                                          altFoodId,
                                                        ),
                                                onDeleteFood: (foodIdx) async =>
                                                    await _removeFood(
                                                      _selectedDay,
                                                      itemIdx,
                                                      foodIdx,
                                                    ),
                                                onAddFood: () => _addFood(
                                                  _selectedDay,
                                                  itemIdx,
                                                ),
                                                allFoods: _allFoods,
                                                calcMealNutrition:
                                                    _calcMealNutrition,
                                                dailyCalorieTarget:
                                                    _dailyCalorieTarget,
                                                onMoveUp: itemIdx > 0
                                                    ? () {
                                                        setState(() {
                                                          final item = day.items
                                                              .removeAt(
                                                                itemIdx,
                                                              );
                                                          day.items.insert(
                                                            itemIdx - 1,
                                                            item,
                                                          );
                                                        });
                                                      }
                                                    : null,
                                                onMoveDown:
                                                    itemIdx <
                                                        day.items.length - 1
                                                    ? () {
                                                        setState(() {
                                                          final item = day.items
                                                              .removeAt(
                                                                itemIdx,
                                                              );
                                                          day.items.insert(
                                                            itemIdx + 1,
                                                            item,
                                                          );
                                                        });
                                                      }
                                                    : null,
                                              )
                                            : day.items[itemIdx]
                                                  is SupplementEntry
                                            ? SupplementCardMealPlanBuilder(
                                                key: ValueKey(
                                                  'supplement_$itemIdx',
                                                ),
                                                supplement:
                                                    day.items[itemIdx]
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
                                                key: ValueKey('empty_$itemIdx'),
                                              ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                SizedBox(height: 32.h),
                              ],
                            ),
                          ),
                  // Meal Type Selector Overlay
                  if (_showMealTypeSelector)
                    MealTypeSelectorOverlayMealPlanBuilder(
                      onSelectType: _addMealWithType,
                      onClose: () {
                        setState(() {
                          _showMealTypeSelector = false;
                        });
                      },
                    ),
                ],
              ),
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
    for (final item in _mealPlan.days[_selectedDay].items) {
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

    final newMeal = MealItem(mealType: type, title: title, foods: []);

    setState(() {
      _mealPlan.days[_selectedDay].items.add(newMeal);
      _showMealTypeSelector = false;
    });
    // ذخیره خودکار
    _autoSavePlan();
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
      'روز ۷',
    ];
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) =>
          CopyDayDialog(days: daysFa, currentDayIndex: sourceDayIndex),
    );
    if (result != null && result['to'] != null) {
      final List<dynamic> targetsDynamic = result['to'] as List<dynamic>;

      // کپی کردن تمام روزها
      for (final dynamic target in targetsDynamic) {
        final int targetDayIndex = (target as num).toInt();
        _copyDay(sourceDayIndex, targetDayIndex, showSnackBar: false);
      }

      // نمایش یک اسنک‌بار برای تمام کپی‌ها
      if (mounted && targetsDynamic.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.check, color: AppTheme.textColor),
                SizedBox(width: 8.w),
                const Text('کپی شد'),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        );
      }
    }
  }

  // Copy day items (including comment)
  void _copyDay(
    int sourceDayIndex,
    int targetDayIndex, {
    bool showSnackBar = true,
  }) {
    final sourceDay = _mealPlan.days[sourceDayIndex];
    final copiedItems = <DayItem>[];
    // Deep copy all items
    for (final item in sourceDay.items) {
      if (item is MealItem) {
        final copiedMeal = MealItem(
          mealType: item.mealType,
          title: item.title,
          foods: List.from(
            item.foods.map(
              (f) => MealFood(
                foodId: f.foodId,
                amount: f.amount,
                unit: f.unit,
                alternatives: f.alternatives,
              ),
            ),
          ),
          note: item.note,
        ); // id will be auto-generated
        copiedItems.add(copiedMeal);
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
        copiedItems.add(copiedSupplement);
      }
    }
    // Create new day with copied items and comment
    setState(() {
      _mealPlan.days[targetDayIndex] = MealPlanDay(
        dayOfWeek: targetDayIndex,
        items: copiedItems,
        comment: sourceDay.comment, // کپی کامنت هم
      );
      _selectedDay = targetDayIndex;
    });
    // ذخیره خودکار
    _autoSavePlan();
    // Show success message only if requested
    if (showSnackBar && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.check, color: AppTheme.textColor),
              SizedBox(width: 8.w),
              Text('${sourceDay.items.length} آیتم با موفقیت کپی شد'),
            ],
          ),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      );
    }
  }

  void _removeAlternative(int mealIdx, int foodIdx, int altFoodId) {
    final item = _mealPlan.days[_selectedDay].items[mealIdx] as MealItem;
    final food = item.foods[foodIdx];

    setState(() {
      final currentAlternatives = food.alternatives ?? <Map<String, dynamic>>[];
      final newAlternatives = currentAlternatives
          .where((alt) => (alt['food_id'] as num).toInt() != altFoodId)
          .toList();

      item.foods[foodIdx] = MealFood(
        foodId: food.foodId,
        amount: food.amount,
        unit: food.unit,
        alternatives: newAlternatives,
      );
    });
    // ذخیره خودکار
    _autoSavePlan();
  }

  Future<void> _showFoodAlternativesDialog(int mealIdx, int foodIdx) async {
    final item = _mealPlan.days[_selectedDay].items[mealIdx] as MealItem;
    final food = item.foods[foodIdx];
    final currentFood = _allFoods.firstWhere(
      (f) => f.id == food.foodId,
      orElse: () => defaultFood(food.foodId),
    );

    // فیلتر کردن غذاهایی که قبلاً به عنوان جایگزین انتخاب شده‌اند
    final existingAltIds = (food.alternatives ?? <Map<String, dynamic>>[])
        .map((alt) => (alt['food_id'] as num).toInt())
        .toSet();
    final availableFoods = _allFoods
        .where((f) => f.id != food.foodId && !existingAltIds.contains(f.id))
        .toList();

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (context) => AddFoodScreenMealPlanBuilder(
        foods: availableFoods,
        initialMealTitle: item.title,
        customTitle: 'انتخاب غذای جایگزین برای ${currentFood.title}',
      ),
    );

    if (result != null && mounted && result.containsKey('food')) {
      final selectedFood = result['food'] as Food;
      final amount = result['amount'] as double;

      setState(() {
        final currentAlternatives =
            food.alternatives ?? <Map<String, dynamic>>[];
        final newAlternatives = List<Map<String, dynamic>>.from(
          currentAlternatives,
        );
        newAlternatives.add({'food_id': selectedFood.id, 'amount': amount});

        item.foods[foodIdx] = MealFood(
          foodId: food.foodId,
          amount: food.amount,
          unit: food.unit,
          alternatives: newAlternatives,
        );
      });
      // ذخیره خودکار
      _autoSavePlan();
    }
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
      // ذخیره خودکار
      _autoSavePlan();
    }
  }

  // نمایش و ویرایش کامنت روز
  Future<void> _showDayCommentDialog() async {
    final day = _mealPlan.days[_selectedDay];
    final dayName = 'روز ${_selectedDay + 1}';
    final result = await showDialog<String>(
      context: context,
      builder: (context) => DayCommentDialogMealPlanBuilder(
        initialComment: day.comment,
        dayName: dayName,
      ),
    );
    if (result != null) {
      setState(() {
        final currentDay = _mealPlan.days[_selectedDay];
        _mealPlan.days[_selectedDay] = MealPlanDay(
          dayOfWeek: currentDay.dayOfWeek,
          items: currentDay.items,
          comment: result.isEmpty ? null : result,
        );
      });
      // ذخیره خودکار
      _autoSavePlan();
    }
  }

  // ویجت نمایش هدف کالری روزانه
  Widget _buildDailyCalorieTargetCard(bool isDark, MealPlanDay day) {
    // محاسبه کالری کل روز
    double totalCalories = 0;

    for (final item in day.items) {
      if (item is MealItem) {
        totalCalories += _calcMealNutrition(item, 'calories');
      }
    }

    final target = _dailyCalorieTarget ?? 0;
    final progress = target > 0
        ? (totalCalories / target).clamp(0.0, 1.0)
        : 0.0;
    final remaining = (target - totalCalories).clamp(0.0, double.infinity);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          gradient: isDark
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.goldColor.withValues(alpha: 0.15),
                    context.cardColor,
                    AppTheme.goldColor.withValues(alpha: 0.1),
                  ],
                ),
          color: isDark ? context.backgroundColor : null,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: AppTheme.goldColor.withValues(alpha: isDark ? 0.3 : 0.5),
            width: 1.5.w,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.goldColor.withValues(alpha: isDark ? 0.15 : 0.35),
              blurRadius: 16.r,
              offset: Offset(0.w, 6.h),
              spreadRadius: 1.r,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ردیف اول: کالری مجاز و باقیمانده
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.target,
                      color: AppTheme.goldColor,
                      size: 16.sp,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'هدف کالری روزانه: ',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: context.textColor.withValues(alpha: 0.7),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      target.toStringAsFixed(0),
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: context.textColor,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'کالری باقیمانده: ',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: context.textColor.withValues(alpha: 0.7),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      remaining.toStringAsFixed(0),
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: context.textColor,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12.h),
            // Progress bar
            LayoutBuilder(
              builder: (context, constraints) {
                final barWidth = constraints.maxWidth;
                final clampedProgress = progress.clamp(0.0, 1.0);
                final progressWidth = barWidth * clampedProgress;

                return Stack(
                  children: [
                    Container(
                      height: 8.h,
                      width: barWidth,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.darkGreySeparator
                            : AppTheme.lightDividerColor,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        height: 8.h,
                        width: progressWidth,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.goldColor, AppTheme.darkGold],
                          ),
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(8.r),
                            bottomRight: Radius.circular(8.r),
                            topLeft: clampedProgress < 1.0
                                ? Radius.zero
                                : Radius.circular(8.r),
                            bottomLeft: clampedProgress < 1.0
                                ? Radius.zero
                                : Radius.circular(8.r),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: 10.h),
            // مقدار مصرف شده
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppTheme.goldColor.withValues(
                      alpha: isDark ? 0.2 : 0.1,
                    ),
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(
                      color: AppTheme.goldColor.withValues(alpha: 0.3),
                      width: 1.w,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.flame,
                        size: 14.sp,
                        color: AppTheme.goldColor,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'کالری برنامه: ',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: context.textColor.withValues(alpha: 0.7),
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        totalCalories.toStringAsFixed(0),
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: context.textColor,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
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
  }

  // ویجت نمایش کامنت روز
  Widget _buildDayCommentSection(bool isDark, MealPlanDay day) {
    final hasComment = day.comment != null && day.comment!.isNotEmpty;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showDayCommentDialog,
          borderRadius: BorderRadius.circular(16.r),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: hasComment
                      ? AppTheme.goldColor.withValues(alpha: 0.15)
                      : AppTheme.goldColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: AppTheme.goldColor.withValues(
                      alpha: hasComment
                          ? (isDark ? 0.4 : 0.5)
                          : (isDark ? 0.2 : 0.3),
                    ),
                    width: 1.5.w,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      hasComment
                          ? LucideIcons.messageSquare
                          : LucideIcons.messageSquarePlus,
                      color: hasComment
                          ? AppTheme.goldColor
                          : AppTheme.goldColor.withValues(alpha: 0.6),
                      size: 18.sp,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: hasComment
                          ? Text(
                              day.comment!,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color: isDark
                                    ? AppTheme.goldColor
                                    : context.textColor,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            )
                          : Text(
                              'کامنت روز را اضافه کنید (مثال: انقدر آب بخور، روز آزاد است...)',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color: isDark
                                    ? AppTheme.goldColor.withValues(alpha: 0.6)
                                    : context.textColor.withValues(alpha: 0.6),
                                fontSize: 12.sp,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                    ),
                    SizedBox(width: 8.w),
                    Icon(
                      LucideIcons.edit2,
                      color: AppTheme.goldColor.withValues(
                        alpha: hasComment ? 0.8 : 0.5,
                      ),
                      size: 16.sp,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
