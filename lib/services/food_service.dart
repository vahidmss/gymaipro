import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/food.dart';

class FoodService {
  static final FoodService _instance = FoodService._internal();

  factory FoodService() {
    return _instance;
  }

  FoodService._internal();

  // Use _embed for images
  final String apiUrl =
      "https://gymaipro.ir/wp-json/wp/v2/foods?_embed=true&per_page=100";
  final SupabaseClient _client = Supabase.instance.client;

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

    // Create food tables if they don't exist
    await _createFoodTables();
  }

  Future<void> _createFoodTables() async {
    try {
      // Create food_likes table
      await _client.rpc('exec_sql', params: {
        'sql': '''
          CREATE TABLE IF NOT EXISTS public.food_likes (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
            food_id INTEGER NOT NULL,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
            UNIQUE (user_id, food_id)
          );
        '''
      });

      // Create food_bookmarks table
      await _client.rpc('exec_sql', params: {
        'sql': '''
          CREATE TABLE IF NOT EXISTS public.food_bookmarks (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
            food_id INTEGER NOT NULL,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
            UNIQUE (user_id, food_id)
          );
        '''
      });

      // Enable RLS
      await _client.rpc('exec_sql', params: {
        'sql': 'ALTER TABLE public.food_likes ENABLE ROW LEVEL SECURITY;'
      });
      await _client.rpc('exec_sql', params: {
        'sql': 'ALTER TABLE public.food_bookmarks ENABLE ROW LEVEL SECURITY;'
      });

      // Create policies
      await _createFoodPolicies();
    } catch (e) {
      print('Error creating food tables: $e');
    }
  }

  Future<void> _createFoodPolicies() async {
    try {
      // Food likes policies
      await _client.rpc('exec_sql', params: {
        'sql': '''
          DROP POLICY IF EXISTS "Users can view all food likes" ON public.food_likes;
          CREATE POLICY "Users can view all food likes" 
          ON public.food_likes FOR SELECT 
          USING (true);
        '''
      });

      await _client.rpc('exec_sql', params: {
        'sql': '''
          DROP POLICY IF EXISTS "Users can insert their own likes" ON public.food_likes;
          CREATE POLICY "Users can insert their own likes" 
          ON public.food_likes FOR INSERT 
          WITH CHECK (auth.uid() = user_id);
        '''
      });

      await _client.rpc('exec_sql', params: {
        'sql': '''
          DROP POLICY IF EXISTS "Users can delete their own likes" ON public.food_likes;
          CREATE POLICY "Users can delete their own likes" 
          ON public.food_likes FOR DELETE 
          USING (auth.uid() = user_id);
        '''
      });

      // Food bookmarks policies
      await _client.rpc('exec_sql', params: {
        'sql': '''
          DROP POLICY IF EXISTS "Users can view their own bookmarks" ON public.food_bookmarks;
          CREATE POLICY "Users can view their own bookmarks" 
          ON public.food_bookmarks FOR SELECT 
          USING (auth.uid() = user_id);
        '''
      });

      await _client.rpc('exec_sql', params: {
        'sql': '''
          DROP POLICY IF EXISTS "Users can insert their own bookmarks" ON public.food_bookmarks;
          CREATE POLICY "Users can insert their own bookmarks" 
          ON public.food_bookmarks FOR INSERT 
          WITH CHECK (auth.uid() = user_id);
        '''
      });

      await _client.rpc('exec_sql', params: {
        'sql': '''
          DROP POLICY IF EXISTS "Users can delete their own bookmarks" ON public.food_bookmarks;
          CREATE POLICY "Users can delete their own bookmarks" 
          ON public.food_bookmarks FOR DELETE 
          USING (auth.uid() = user_id);
        '''
      });
    } catch (e) {
      print('Error creating food policies: $e');
    }
  }

  Future<List<Food>> getFoods() async {
    if (_cachedFoods != null) {
      return await _applyUserData(_cachedFoods!);
    }
    try {
      final response = await http.get(Uri.parse(apiUrl), headers: {
        'Content-Type': 'application/json',
      });
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final foods = data.map((json) => Food.fromJson(json)).toList();
        _cachedFoods = foods;
        return await _applyUserData(foods);
      } else {
        throw Exception('Failed to load foods: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching foods: $e');
    }
  }

  // --- Like/Favorite logic is identical to ExerciseService ---
  Future<List<Food>> _applyUserData(List<Food> foods) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return foods;
    }
    try {
      final bookmarksResponse = await _client
          .from('food_bookmarks')
          .select('food_id')
          .eq('user_id', user.id);
      final Set<int> favoriteIds = Set<int>.from(
          (bookmarksResponse as List<dynamic>)
              .map((item) => item['food_id'] as int));
      final likesResponse = await _client
          .from('food_likes')
          .select('food_id')
          .eq('user_id', user.id);
      final Set<int> likedIds = Set<int>.from((likesResponse as List<dynamic>)
          .map((item) => item['food_id'] as int));
      // Get like counts for each food
      Map<int, int> likesCount = {};
      for (var food in foods) {
        final countResponse = await _client.rpc(
          'get_food_likes_count',
          params: {'food_id_param': food.id},
        );
        likesCount[food.id] = countResponse ?? 0;
      }
      for (var food in foods) {
        food.isFavorite = favoriteIds.contains(food.id);
        food.isLikedByUser = likedIds.contains(food.id);
        food.likes = likesCount[food.id] ?? 0;
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
              (category) => category.toLowerCase().contains(lowerCaseQuery));
    }).toList();
  }

  Future<List<Food>> filterByCategory(String category) async {
    if (category.isEmpty) return getFoods();

    final foods = await getFoods();
    final lowerCaseCategory = category.toLowerCase();

    return foods.where((food) {
      return food.classList
          .any((cat) => cat.toLowerCase().contains(lowerCaseCategory));
    }).toList();
  }

  Future<List<String>> getFoodCategories() async {
    final foods = await getFoods();
    final Set<String> categories = {};

    for (var food in foods) {
      for (var category in food.classList) {
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
      final existingResponse = await _client
          .from('food_bookmarks')
          .select()
          .eq('user_id', user.id)
          .eq('food_id', foodId)
          .maybeSingle();
      if (existingResponse != null) {
        await _client
            .from('food_bookmarks')
            .delete()
            .eq('user_id', user.id)
            .eq('food_id', foodId);
        final food = _cachedFoods?.firstWhere((f) => f.id == foodId);
        if (food != null) {
          food.isFavorite = false;
        }
      } else {
        await _client.from('food_bookmarks').insert({
          'user_id': user.id,
          'food_id': foodId,
          'created_at': DateTime.now().toIso8601String(),
        });
        final food = _cachedFoods?.firstWhere((f) => f.id == foodId);
        if (food != null) {
          food.isFavorite = true;
        }
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
      final existingResponse = await _client
          .from('food_likes')
          .select()
          .eq('user_id', user.id)
          .eq('food_id', foodId)
          .maybeSingle();
      if (existingResponse != null) {
        await _client
            .from('food_likes')
            .delete()
            .eq('user_id', user.id)
            .eq('food_id', foodId);
        final food = _cachedFoods?.firstWhere((f) => f.id == foodId);
        if (food != null) {
          food.isLikedByUser = false;
          food.likes = (food.likes - 1).clamp(0, double.infinity).toInt();
        }
      } else {
        await _client.from('food_likes').insert({
          'user_id': user.id,
          'food_id': foodId,
          'created_at': DateTime.now().toIso8601String(),
        });
        final food = _cachedFoods?.firstWhere((f) => f.id == foodId);
        if (food != null) {
          food.isLikedByUser = true;
          food.likes = food.likes + 1;
        }
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
}
