import 'package:gymaipro/models/food.dart';

// متد ساخت غذای پیش‌فرض برای مواقعی که غذا پیدا نشود
Food defaultFood(int id) {
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
