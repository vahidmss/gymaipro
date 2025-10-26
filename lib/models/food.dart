class Food {
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
      imageUrl =
          json['_embedded']['wp:featuredmedia'][0]['source_url'] as String;
    } else if (json['meta']?['sample_image_forapp'] != null) {
      imageUrl = json['meta']['sample_image_forapp'] as String;
    }

    // Filter classList for display (remove post-xxxx, type-foods, status-publish, foods, hentry, ...)
    List<String> filteredClassList = [];
    if (json['class_list'] != null) {
      filteredClassList =
          List<String>.from(json['class_list'] as Iterable<dynamic>)
              .where(
                (c) =>
                    !c.startsWith('post-') &&
                    !c.startsWith('type-') &&
                    !c.startsWith('status-') &&
                    c != 'foods' &&
                    c != 'hentry' &&
                    !c.startsWith('has-post-thumbnail'),
              )
              .toList();
    }

    // Clean title by removing trailing numbers and years
    final String cleanTitle = _cleanFoodTitle(
      (json['title']?['rendered'] ?? '') as String,
    );

    return Food(
      id: (json['id'] as int?) ?? 0,
      title: cleanTitle,
      content: (json['content']?['rendered'] ?? '') as String,
      imageUrl: imageUrl,
      slug: (json['slug'] ?? '') as String,
      date: DateTime.tryParse((json['date'] ?? '') as String) ?? DateTime.now(),
      modified:
          DateTime.tryParse((json['modified'] ?? '') as String) ??
          DateTime.now(),
      status: (json['status'] ?? '') as String,
      type: (json['type'] ?? '') as String,
      link: (json['link'] ?? '') as String,
      featuredMedia: (json['featured_media'] as int?) ?? 0,
      nutrition: FoodNutrition.fromJson(
        (json['meta'] ?? <String, dynamic>{}) as Map<String, dynamic>,
      ),
      foodCategories: List<int>.from(
        (json['food-categories'] ?? <dynamic>[]) as Iterable<dynamic>,
      ),
      classList: filteredClassList,
    );
  }

  /// Create an empty food instance
  factory Food.empty() {
    return Food(
      id: 0,
      title: '',
      content: '',
      imageUrl: '',
      slug: '',
      date: DateTime.now(),
      modified: DateTime.now(),
      status: '',
      type: '',
      link: '',
      featuredMedia: 0,
      nutrition: FoodNutrition.empty(),
      foodCategories: [],
      classList: [],
    );
  }
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

  /// Clean food title by removing trailing numbers, years, and unnecessary characters
  static String _cleanFoodTitle(String title) {
    if (title.isEmpty) return title;

    // Remove HTML entities and decode them
    String cleanedTitle = title
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#8217;', "'")
        .replaceAll('&#8220;', '"')
        .replaceAll('&#8221;', '"');

    // Remove trailing numbers in parentheses like (2024), (2025), (123), etc.
    cleanedTitle = cleanedTitle.replaceAll(RegExp(r'\(\d+\)$'), '');

    // Remove trailing years like 2024, 2025, etc.
    cleanedTitle = cleanedTitle.replaceAll(RegExp(r'\b20\d{2}\b$'), '');

    // Remove trailing numbers at the end
    cleanedTitle = cleanedTitle.replaceAll(RegExp(r'\d+$'), '');

    // Remove trailing dashes, spaces, and other unwanted characters
    cleanedTitle = cleanedTitle.replaceAll(RegExp(r'[-\s]+$'), '');

    // Remove leading and trailing whitespace
    cleanedTitle = cleanedTitle.trim();

    return cleanedTitle;
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

  /// Create an empty nutrition instance
  factory FoodNutrition.empty() {
    return FoodNutrition(
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
    );
  }
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
