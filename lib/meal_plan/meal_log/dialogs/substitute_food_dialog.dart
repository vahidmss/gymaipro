import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/food_log_item.dart';
import '../../../models/food.dart';
import '../../../widgets/gold_button.dart';

class SubstituteFoodDialog extends StatelessWidget {
  final FoodLogItem foodItem;
  final String mealTitle;
  final List<Food> allFoods;

  const SubstituteFoodDialog({
    super.key,
    required this.foodItem,
    required this.mealTitle,
    required this.allFoods,
  });

  @override
  Widget build(BuildContext context) {
    final alternatives = foodItem.alternatives ?? [];
    if (alternatives.isEmpty) {
      return Dialog(
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
              Icon(
                LucideIcons.alertCircle,
                color: Colors.amber[400],
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'جایگزینی موجود نیست',
                style: TextStyle(
                  color: Colors.amber[200],
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'برای این غذا جایگزینی تعریف نشده است',
                style: TextStyle(
                  color: Colors.amber[200]?.withOpacity(0.7),
                  fontSize: 14,
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
                    Icons.swap_horiz,
                    color: Colors.amber[700],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'انتخاب جایگزین',
                    style: TextStyle(
                      color: Colors.amber[200],
                      fontSize: 18,
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
                    (f) => f.id == alt['food_id'],
                    orElse: () => _createDefaultFood(alt['food_id']),
                  );
                  return GestureDetector(
                    onTap: () => Navigator.of(context).pop(alt),
                    child: Card(
                      color: const Color(0xFF3D2317),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: altFood.imageUrl.isNotEmpty
                                  ? Image.network(
                                      altFood.imageUrl,
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 44,
                                      height: 44,
                                      color:
                                          Colors.amber[100]?.withOpacity(0.1),
                                      child: Icon(
                                        Icons.fastfood,
                                        color: Colors.amber[300],
                                        size: 28,
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
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${alt['amount']} گرم',
                                    style: TextStyle(
                                      color: Colors.amber[300],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.swap_horiz,
                              color: Colors.amber,
                              size: 22,
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
              child: Text(
                'انصراف',
                style: TextStyle(color: Colors.grey[400]),
              ),
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
