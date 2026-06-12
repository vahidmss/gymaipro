import 'dart:convert';
import 'package:gymaipro/academy/models/workout_music.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MusicFavoriteService {
  static const String _favoritesKey = 'music_favorites';
  static final MusicFavoriteService _instance =
      MusicFavoriteService._internal();
  factory MusicFavoriteService() => _instance;
  MusicFavoriteService._internal();

  Future<void> addToFavorites(WorkoutMusic music) async {
    final favorites = await getFavorites();

    // Check if already exists
    if (!favorites.any((m) => m.id == music.id)) {
      favorites.add(music);
      await _saveFavorites(favorites);
    }
  }

  Future<void> removeFromFavorites(int musicId) async {
    final favorites = await getFavorites();
    favorites.removeWhere((m) => m.id == musicId);
    await _saveFavorites(favorites);
  }

  Future<List<WorkoutMusic>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_favoritesKey);
    if (jsonString == null) return [];

    try {
      final decoded = json.decode(jsonString) as List<dynamic>;
      return decoded
          .map((json) => WorkoutMusic.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> isFavorite(int musicId) async {
    final favorites = await getFavorites();
    return favorites.any((m) => m.id == musicId);
  }

  Future<void> toggleFavorite(WorkoutMusic music) async {
    final isFav = await isFavorite(music.id);
    if (isFav) {
      await removeFromFavorites(music.id);
    } else {
      await addToFavorites(music);
    }
  }

  Future<void> _saveFavorites(List<WorkoutMusic> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = favorites.map((m) => m.toJson()).toList();
    await prefs.setString(_favoritesKey, json.encode(jsonData));
  }

  Future<void> clearFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_favoritesKey);
  }
}
