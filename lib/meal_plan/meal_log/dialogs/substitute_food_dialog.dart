import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/meal_plan/meal_log/models/food_log_item.dart';
import 'package:gymaipro/models/food.dart';
import 'package:gymaipro/widgets/gold_button.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SubstituteFoodDialog extends StatelessWidget {
  const SubstituteFoodDialog({
    required this.foodItem,
    required this.mealTitle,
    required this.allFoods,
    super.key,
  });
  final FoodLogItem foodItem;
  final String mealTitle;
  final List<Food> allFoods;

  @override
  Widget build(BuildContext context) {
    final alternatives = foodItem.alternatives ?? [];
    if (alternatives.isEmpty) {
      return Dialog(
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
              Icon(LucideIcons.alertCircle, color: Colors.amber[400], size: 48),
              const SizedBox(height: 16),
              Text(
                'جایگزینی موجود نیست',
                style: TextStyle(
                  color: Colors.amber[200],
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'برای این غذا جایگزینی تعریف نشده است',
                style: TextStyle(
                  color: Colors.amber[200]?.withValues(alpha: 0.7),
                  fontSize: 14.sp,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              GoldButton(
                text: 'باشه',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      );
    }

    return Dialog(
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
          border: Border.all(color: Colors.amber[700]!.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.amber[700]?.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Icon(
                    Icons.swap_horiz,
                    color: Colors.amber[700],
                    size: 24.sp,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'انتخاب جایگزین',
                    style: TextStyle(
                      color: Colors.amber[200],
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Alternatives list
            Container(
              constraints: const BoxConstraints(maxHeight: 400),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: alternatives.length,
                itemBuilder: (context, index) {
                  final alt = alternatives[index];
                  final altFood = allFoods.firstWhere(
                    (f) => f.id == (alt['food_id'] as int),
                    orElse: () => _createDefaultFood(alt['food_id'] as int),
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
                },
              ),
            ),
            const SizedBox(height: 20),

            // Cancel button
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('انصراف', style: TextStyle(color: Colors.grey[400])),
            ),
          ],
        ),
      ),
    );
  }

  Food _createDefaultFood(int id) {
    return Food(
      id: id,
      title: 'نامشخص',
      content: '',
      imageUrl: '',
      slug: '',
      date: DateTime.now(),
      modified: DateTime.now(),
      status: '',
      type: '',
      link: '',
      featuredMedia: 0,
      nutrition: FoodNutrition(
        protein: '0',
        calories: '0',
        carbohydrates: '0',
        fat: '0',
        saturatedFat: '0',
        fiber: '0',
        sugar: '0',
        cholesterol: '0',
        sodium: '0',
        potassium: '0',
      ),
      foodCategories: [],
      classList: [],
    );
  }
}
