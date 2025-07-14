class Food {
  final int id;
  final String title;
  final String content;
  final String imageUrl;
  final String slug;
  final DateTime date;
  final DateTime modified;
  final String status;
  final String type;
  final String link;
  final int featuredMedia;
  final FoodNutrition nutrition;
  final List<int> foodCategories;
  final List<String> classList;
  bool isFavorite;
  int likes;
  bool isLikedByUser;

  Food({
    required this.id,
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.slug,
    required this.date,
    required this.modified,
    required this.status,
    required this.type,
    required this.link,
    required this.featuredMedia,
    required this.nutrition,
    required this.foodCategories,
    required this.classList,
    this.isFavorite = false,
    this.likes = 0,
    this.isLikedByUser = false,
  });

  factory Food.fromJson(Map<String, dynamic> json) {
    // Get image from _embedded if available
    String imageUrl = '';
    if (json.containsKey('_embedded') &&
        json['_embedded'] != null &&
        json['_embedded']['wp:featuredmedia'] != null &&
        (json['_embedded']['wp:featuredmedia'] as List).isNotEmpty &&
        json['_embedded']['wp:featuredmedia'][0]['source_url'] != null) {
      imageUrl = json['_embedded']['wp:featuredmedia'][0]['source_url'];
    } else if (json['meta']?['sample_image_forapp'] != null) {
      imageUrl = json['meta']['sample_image_forapp'];
    }

    // Filter classList for display (remove post-xxxx, type-foods, status-publish, foods, hentry, ...)
    List<String> filteredClassList = [];
    if (json['class_list'] != null) {
      filteredClassList = List<String>.from(json['class_list'])
          .where((c) =>
              !c.startsWith('post-') &&
              !c.startsWith('type-') &&
              !c.startsWith('status-') &&
              c != 'foods' &&
              c != 'hentry' &&
              !c.startsWith('has-post-thumbnail'))
          .toList();
    }

    return Food(
      id: json['id'] ?? 0,
      title: json['title']?['rendered'] ?? '',
      content: json['content']?['rendered'] ?? '',
      imageUrl: imageUrl,
      slug: json['slug'] ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      modified: DateTime.tryParse(json['modified'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? '',
      type: json['type'] ?? '',
      link: json['link'] ?? '',
      featuredMedia: json['featured_media'] ?? 0,
      nutrition: FoodNutrition.fromJson(json['meta'] ?? {}),
      foodCategories: List<int>.from(json['food-categories'] ?? []),
      classList: filteredClassList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'slug': slug,
      'date': date.toIso8601String(),
      'modified': modified.toIso8601String(),
      'status': status,
      'type': type,
      'link': link,
      'featuredMedia': featuredMedia,
      'nutrition': nutrition.toJson(),
      'foodCategories': foodCategories,
      'classList': classList,
      'isFavorite': isFavorite,
      'likes': likes,
      'isLikedByUser': isLikedByUser,
    };
  }
}

class FoodNutrition {
  final String protein;
  final String calories;
  final String carbohydrates;
  final String fat;
  final String saturatedFat;
  final String fiber;
  final String sugar;
  final String cholesterol;
  final String sodium;
  final String potassium;

  FoodNutrition({
    required this.protein,
    required this.calories,
    required this.carbohydrates,
    required this.fat,
    required this.saturatedFat,
    required this.fiber,
    required this.sugar,
    required this.cholesterol,
    required this.sodium,
    required this.potassium,
  });

  factory FoodNutrition.fromJson(Map<String, dynamic> json) {
    return FoodNutrition(
      protein: json['protein']?.toString() ?? '0',
      calories: json['calories']?.toString() ?? '0',
      carbohydrates: json['carbohydrates']?.toString() ?? '0',
      fat: json['fat']?.toString() ?? '0',
      saturatedFat: json['saturated_fat']?.toString() ?? '0',
      fiber: json['fiber']?.toString() ?? '0',
      sugar: json['sugar']?.toString() ?? '0',
      cholesterol: json['cholesterol']?.toString() ?? '0',
      sodium: json['sodium']?.toString() ?? '0',
      potassium: json['potassium']?.toString() ?? '0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'protein': protein,
      'calories': calories,
      'carbohydrates': carbohydrates,
      'fat': fat,
      'saturated_fat': saturatedFat,
      'fiber': fiber,
      'sugar': sugar,
      'cholesterol': cholesterol,
      'sodium': sodium,
      'potassium': potassium,
    };
  }
}
