import 'dart:convert';

import 'package:gymaipro/models/food.dart';
import 'package:gymaipro/services/connectivity_service.dart';
import 'package:gymaipro/services/user_preferences_service.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class FoodService {
  factory FoodService() {
    return _instance;
  }

  FoodService._internal();
  static final FoodService _instance = FoodService._internal();

  // Use _embed for images
  final String apiUrl =
      'https://gymaipro.ir/wp-json/wp/v2/foods?_embed=true&per_page=100';
  final SupabaseClient _client = Supabase.instance.client;
  final UserPreferencesService _preferencesService = UserPreferencesService();

  // Cached foods list
  List<Food>? _cachedFoods;
  // Map to store comments for each food (cache)
  final Map<int, List<dynamic>> _commentsCache = {};

  void clearCache() {
    _cachedFoods = null;
    _commentsCache.clear();
    print('Food cache cleared');
  }

  static Future<void> initAll() async {
    await _instance.init();
  }

  Future<void> init() async {
    print('Food service initialized successfully');

    // Clear cache to apply title cleaning changes
    clearCache();

    // Create food tables if they don't exist
    await _createFoodTables();
  }

  Future<void> _createFoodTables() async {
    try {
      // Create food_likes table
      await _client.rpc<void>(
        'exec_sql',
        params: {
          'sql': '''
          CREATE TABLE IF NOT EXISTS public.food_likes (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
            food_id INTEGER NOT NULL,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
            UNIQUE (user_id, food_id)
          );
        ''',
        },
      );

      // Create food_bookmarks table
      await _client.rpc<void>(
        'exec_sql',
        params: {
          'sql': '''
          CREATE TABLE IF NOT EXISTS public.food_bookmarks (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
            food_id INTEGER NOT NULL,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
            UNIQUE (user_id, food_id)
          );
        ''',
        },
      );

      // Enable RLS
      await _client.rpc<void>(
        'exec_sql',
        params: {
          'sql': 'ALTER TABLE public.food_likes ENABLE ROW LEVEL SECURITY;',
        },
      );
      await _client.rpc<void>(
        'exec_sql',
        params: {
          'sql': 'ALTER TABLE public.food_bookmarks ENABLE ROW LEVEL SECURITY;',
        },
      );

      // Create policies
      await _createFoodPolicies();
    } catch (e) {
      print('Error creating food tables: $e');
    }
  }

  Future<void> _createFoodPolicies() async {
    try {
      // Food likes policies
      await _client.rpc<void>(
        'exec_sql',
        params: {
          'sql': '''
          DROP POLICY IF EXISTS "Users can view all food likes" ON public.food_likes;
          CREATE POLICY "Users can view all food likes" 
          ON public.food_likes FOR SELECT 
          USING (true);
        ''',
        },
      );

      await _client.rpc<void>(
        'exec_sql',
        params: {
          'sql': '''
          DROP POLICY IF EXISTS "Users can insert their own likes" ON public.food_likes;
          CREATE POLICY "Users can insert their own likes" 
          ON public.food_likes FOR INSERT 
          WITH CHECK (auth.uid() = user_id);
        ''',
        },
      );

      await _client.rpc<void>(
        'exec_sql',
        params: {
          'sql': '''
          DROP POLICY IF EXISTS "Users can delete their own likes" ON public.food_likes;
          CREATE POLICY "Users can delete their own likes" 
          ON public.food_likes FOR DELETE 
          USING (auth.uid() = user_id);
        ''',
        },
      );

      // Food bookmarks policies
      await _client.rpc<void>(
        'exec_sql',
        params: {
          'sql': '''
          DROP POLICY IF EXISTS "Users can view their own bookmarks" ON public.food_bookmarks;
          CREATE POLICY "Users can view their own bookmarks" 
          ON public.food_bookmarks FOR SELECT 
          USING (auth.uid() = user_id);
        ''',
        },
      );

      await _client.rpc<void>(
        'exec_sql',
        params: {
          'sql': '''
          DROP POLICY IF EXISTS "Users can insert their own bookmarks" ON public.food_bookmarks;
          CREATE POLICY "Users can insert their own bookmarks" 
          ON public.food_bookmarks FOR INSERT 
          WITH CHECK (auth.uid() = user_id);
        ''',
        },
      );

      await _client.rpc<void>(
        'exec_sql',
        params: {
          'sql': '''
          DROP POLICY IF EXISTS "Users can delete their own bookmarks" ON public.food_bookmarks;
          CREATE POLICY "Users can delete their own bookmarks" 
          ON public.food_bookmarks FOR DELETE 
          USING (auth.uid() = user_id);
        ''',
        },
      );
    } catch (e) {
      print('Error creating food policies: $e');
    }
  }

  Future<List<Food>> getFoods() async {
    if (_cachedFoods != null) {
      return _applyUserData(_cachedFoods!);
    }
    try {
      final isOnline = await ConnectivityService.instance.checkNow();
      if (!isOnline) {
        // If offline and no cache, return empty (UI should handle gracefully)
        return await _applyUserData(_cachedFoods ?? []);
      }
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body) as List<dynamic>;
        final foods = data
            .map((json) => Food.fromJson(json as Map<String, dynamic>))
            .toList();
        _cachedFoods = foods;
        print(
          'Food titles cleaned: ${foods.take(3).map((f) => f.title).join(', ')}',
        ); // Debug log
        return await _applyUserData(foods);
      } else {
        throw Exception('Failed to load foods: ${response.statusCode}');
      }
    } catch (e) {
      // On error (including offline), if we have cache return it; otherwise a friendly error
      if (_cachedFoods != null) {
        return _applyUserData(_cachedFoods!);
      }
      throw Exception('عدم دسترسی به اینترنت یا خطا در دریافت خوراکی‌ها');
    }
  }

  // --- Like/Favorite logic using UserPreferencesService ---
  Future<List<Food>> _applyUserData(List<Food> foods) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return foods;
    }
    try {
      // Get user preferences for all foods
      final foodIds = foods.map((f) => f.id).toList();
      final preferences = await _preferencesService.getFoodPreferences(foodIds);

      final favoriteIds = Set<int>.from(preferences['favorites'] as List);
      final likedIds = Set<int>.from(preferences['likes'] as List);
      final globalLikes = Map<int, int>.from(
        preferences['global_likes'] as Map,
      );

      // Apply preferences to foods
      for (final food in foods) {
        food.isFavorite = favoriteIds.contains(food.id);
        food.isLikedByUser = likedIds.contains(food.id);
        food.likes = globalLikes[food.id] ?? 0; // Use global like count
      }
      return foods;
    } catch (e) {
      print('Error applying user data from database: $e');
      return foods;
    }
  }

  Future<Food?> getFoodById(int id) async {
    final foods = await getFoods();
    try {
      return foods.firstWhere((food) => food.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<List<Food>> searchFoods(String query) async {
    if (query.isEmpty) return getFoods();

    final foods = await getFoods();
    final lowerCaseQuery = query.toLowerCase();

    return foods.where((food) {
      return food.title.toLowerCase().contains(lowerCaseQuery) ||
          food.content.toLowerCase().contains(lowerCaseQuery) ||
          food.classList.any(
            (category) => category.toLowerCase().contains(lowerCaseQuery),
          );
    }).toList();
  }

  Future<List<Food>> filterByCategory(String category) async {
    if (category.isEmpty) return getFoods();

    final foods = await getFoods();
    final lowerCaseCategory = category.toLowerCase();

    return foods.where((food) {
      return food.classList.any(
        (cat) => cat.toLowerCase().contains(lowerCaseCategory),
      );
    }).toList();
  }

  Future<List<String>> getFoodCategories() async {
    final foods = await getFoods();
    final Set<String> categories = {};

    for (final food in foods) {
      for (final category in food.classList) {
        if (category.isNotEmpty && category.length > 3) {
          categories.add(category);
        }
      }
    }

    return categories.toList()..sort();
  }

  Future<void> toggleFavorite(int foodId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    try {
      final isOnline = await ConnectivityService.instance.checkNow();
      if (!isOnline) {
        throw Exception('عدم دسترسی به اینترنت. بعداً دوباره تلاش کنید');
      }
      // Find the food in cache to get its details
      final food = _cachedFoods?.firstWhere((f) => f.id == foodId);
      if (food == null) {
        throw Exception('Food not found in cache');
      }

      // Toggle favorite in database
      if (food.isFavorite) {
        await _preferencesService.removeFoodFromFavorites(foodId);
        food.isFavorite = false;
      } else {
        await _preferencesService.addFoodToFavorites(
          foodId,
          food.title,
          food.imageUrl,
        );
        food.isFavorite = true;
      }
    } catch (e) {
      throw Exception('Error toggling favorite: $e');
    }
  }

  Future<void> toggleLike(int foodId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    try {
      final isOnline = await ConnectivityService.instance.checkNow();
      if (!isOnline) {
        throw Exception('عدم دسترسی به اینترنت. بعداً دوباره تلاش کنید');
      }
      // Find the food in cache
      final food = _cachedFoods?.firstWhere((f) => f.id == foodId);
      if (food == null) {
        throw Exception('Food not found in cache');
      }

      // Toggle like in database
      if (food.isLikedByUser) {
        await _preferencesService.removeFoodLike(foodId);
        food.isLikedByUser = false;
        // Global likes will be updated by the service
        food.likes = (food.likes - 1).clamp(0, double.infinity).toInt();
      } else {
        await _preferencesService.addFoodLike(foodId);
        food.isLikedByUser = true;
        // Global likes will be updated by the service
        food.likes = food.likes + 1;
      }
    } catch (e) {
      throw Exception('Error toggling like: $e');
    }
  }

  Future<List<Food>> getFavoriteFoods() async {
    final foods = await getFoods();
    return foods.where((food) => food.isFavorite).toList();
  }

  Future<List<Food>> getFoodsByNutritionRange({
    double? minCalories,
    double? maxCalories,
    double? minProtein,
    double? maxProtein,
    double? minCarbs,
    double? maxCarbs,
    double? minFat,
    double? maxFat,
  }) async {
    final foods = await getFoods();

    return foods.where((food) {
      final calories = double.tryParse(food.nutrition.calories) ?? 0;
      final protein = double.tryParse(food.nutrition.protein) ?? 0;
      final carbs = double.tryParse(food.nutrition.carbohydrates) ?? 0;
      final fat = double.tryParse(food.nutrition.fat) ?? 0;

      if (minCalories != null && calories < minCalories) return false;
      if (maxCalories != null && calories > maxCalories) return false;
      if (minProtein != null && protein < minProtein) return false;
      if (maxProtein != null && protein > maxProtein) return false;
      if (minCarbs != null && carbs < minCarbs) return false;
      if (maxCarbs != null && carbs > maxCarbs) return false;
      if (minFat != null && fat < minFat) return false;
      if (maxFat != null && fat > maxFat) return false;

      return true;
    }).toList();
  }

  // این متدها برای جستجو و انتخاب غذا در UI استفاده می‌شوند.
  Future<List<Food>> getFoodsByQuery(String query) async {
    // TODO: پیاده‌سازی جستجو در API یا دیتابیس خوراکی‌ها
    throw UnimplementedError();
  }
}
