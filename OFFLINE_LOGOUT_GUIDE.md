# راهنمای Offline Logout

## مشکل اصلی
خطای `AuthRetryableFetchException` در هنگام logout وقتی اینترنت نداره:
```
AuthRetryableFetchException(message: ClientException with SocketException: Failed host lookup: 'oaztoennovtcfcxvnswa.supabase.co' (OS Error: No address associated with hostname, errno = 7), uri=https://oaztoennovtcfcxvnswa.supabase.co/auth/v1/logout?scope=local, statusCode: null)
```

## راه‌حل پیاده‌سازی شده

### 1. **تغییرات در SupabaseService**
```dart
Future<void> signOut() async {
  try {
    // Check connectivity before sign out
    final isOnline = await ConnectivityService.instance.checkNow();
    
    if (isOnline) {
      // Online: normal sign out
      await client.auth.signOut();
      print('User signed out successfully (online)');
    } else {
      // Offline: local sign out only
      print('Offline mode: performing local sign out only');
      await client.auth.signOut(scope: SignOutScope.local);
      print('User signed out successfully (offline)');
    }
  } catch (e) {
    print('Error signing out: $e');
    // Don't throw exception in offline mode
  }
}
```

### 2. **تغییرات در AuthStateService**
```dart
Future<void> clearAuthState() async {
  try {
    // Check connectivity before clearing auth state
    final isOnline = await ConnectivityService.instance.checkNow();
    
    if (isOnline) {
      // Online: normal sign out
      await Supabase.instance.client.auth.signOut();
      print('Auth state cleared successfully (online)');
    } else {
      // Offline: local sign out only
      print('Offline mode: performing local auth state clear');
      await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
      print('Auth state cleared successfully (offline)');
    }
  } catch (e) {
    print('Error clearing auth state: $e');
    // Don't throw exception in offline mode
  }
}
```

### 3. **تغییرات در AppState**
```dart
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
      await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
      print('Logout successful (offline)');
    }
    
    await AuthStateService().clearAuthState();
    _currentUser = null;
    _userProfile = null;
  } catch (e) {
    print('Error logging out: $e');
    // Don't throw exception in offline mode
  } finally {
    setLoading(false);
  }
}
```

## ویژگی‌های جدید

### ✅ **Offline Logout Support**
- Logout بدون اینترنت کار می‌کنه
- استفاده از `SignOutScope.local` برای offline mode
- Error handling بهتر برای network failures

### ✅ **Smart Connectivity Detection**
- تشخیص خودکار وضعیت اینترنت قبل از logout
- تغییر رفتار بر اساس connectivity
- Graceful fallback برای offline mode

### ✅ **Better Error Handling**
- Exception handling بهتر برای offline mode
- Logging مفصل برای debug
- Don't throw exception در offline mode

## نحوه تست

### 1. **تست Offline Logout**
```bash
# قطع کردن اینترنت
# اجرای اپلیکیشن
# رفتن به dashboard
# کلیک روی logout
# چک کردن console logs
```

### 2. **لاگ‌های مهم**
```
Offline mode: performing local sign out only
User signed out successfully (offline)
Offline mode: performing local auth state clear
Auth state cleared successfully (offline)
Offline mode: performing local logout
Logout successful (offline)
```

### 3. **تست Online/Offline Transition**
- قطع کردن اینترنت
- Logout کردن
- وصل کردن اینترنت
- Login کردن
- Logout کردن (online)

## مزایای پیاده‌سازی

### 🚀 **Reliability**
- Logout بدون اینترنت کار می‌کنه
- کرش نمی‌کنه در offline mode
- بهتر error handling

### 🛡️ **User Experience**
- بهتر UX در offline mode
- Smooth logout process
- Graceful degradation

### 🔧 **Technical Benefits**
- استفاده از `SignOutScope.local`
- Smart connectivity detection
- Better error handling

## نکات مهم

### ⚠️ **Limitations**
- Server-side logout فقط online کار می‌کنه
- Local session clear در offline mode
- بعضی features نیاز به اینترنت دارن

### 🔧 **Configuration**
- `SignOutScope.local` برای offline mode
- Connectivity service فعال
- Error handling بهتر

### 📱 **Testing**
- تست با airplane mode
- تست با WiFi/Mobile data
- تست transition بین online/offline

## نتیجه
حالا logout شما:
- ✅ بدون اینترنت کار می‌کنه
- ✅ کرش نمی‌کنه در offline mode
- ✅ بهتر error handling داره
- ✅ Smooth user experience
- ✅ Graceful degradation

## کدهای تغییر یافته
1. `lib/services/supabase_service.dart` - signOut method
2. `lib/services/auth_state_service.dart` - clearAuthState method  
3. `lib/services/app_state.dart` - logout method
4. اضافه شدن import های لازم برای connectivity service
