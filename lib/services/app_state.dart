import 'package:flutter/foundation.dart';
import 'package:gymaipro/auth/services/auth_state_service.dart';
import 'package:gymaipro/profile/models/user_profile.dart';
import 'package:gymaipro/services/connectivity_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppState extends ChangeNotifier {
  factory AppState() {
    return _instance;
  }

  AppState._internal();
  static final AppState _instance = AppState._internal();

  bool _isLoading = false;
  User? _currentUser;
  UserProfile? _userProfile;

  bool get isLoading => _isLoading;
  User? get currentUser => _currentUser;
  UserProfile? get userProfile => _userProfile;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> loadUserProfile() async {
    setLoading(true);
    try {
      _currentUser = Supabase.instance.client.auth.currentUser;
      if (_currentUser != null) {
        final response = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', _currentUser!.id)
            .single();
        _userProfile = UserProfile.fromJson(response);
      }
    } catch (e) {
      print('Error loading user profile: $e');
    } finally {
      setLoading(false);
    }
  }

  Future<void> logout() async {
    setLoading(true);
    try {
      // Check connectivity before logout
      final isOnline = await ConnectivityService.instance.checkNow();

      if (isOnline) {
        // Online: normal logout
        await Supabase.instance.client.auth.signOut();
        print('Logout successful (online)');
      } else {
        // Offline: local logout only
        print('Offline mode: performing local logout');
        await Supabase.instance.client.auth.signOut();
        print('Logout successful (offline)');
      }

      await AuthStateService().clearAuthState();
      _currentUser = null;
      _userProfile = null;
    } catch (e) {
      print('Error logging out: $e');
      // Don't throw exception in offline mode
      if (kDebugMode) {
        print('Logout error (may be offline): $e');
      }
    } finally {
      setLoading(false);
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    setLoading(true);
    try {
      if (_currentUser != null) {
        await Supabase.instance.client
            .from('profiles')
            .update(data)
            .eq('id', _currentUser!.id);
        await loadUserProfile();
      }
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    } finally {
      setLoading(false);
    }
  }
}
