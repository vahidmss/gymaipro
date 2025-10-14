# Network Connectivity Troubleshooting Guide

## Problem
`AuthRetryableFetchException` with `SocketException: Failed host lookup: 'oaztoennovtcfcxvnswa.supabase.co'`

## Root Cause
DNS resolution failure preventing the Flutter app from connecting to Supabase backend.

## Solutions (Try in Order)

### 1. **Immediate Network Fixes**
- **Check internet connection** - Ensure stable internet
- **Switch networks** - Try WiFi vs Mobile data
- **Restart router/modem** if using WiFi
- **Try different location** - Test from different network

### 2. **Flutter App Fixes**
```bash
# Clear Flutter cache
flutter clean
flutter pub get

# Restart the app completely
# Close app and restart
```

### 3. **DNS Resolution Fixes**
- **Change DNS servers** to 8.8.8.8 or 1.1.1.1
- **Check corporate firewall** - May block Supabase
- **Try VPN** - Test if regional DNS issue
- **Flush DNS cache** (Windows: `ipconfig /flushdns`)

### 4. **Android-Specific Fixes**
- **Check network permissions** in AndroidManifest.xml
- **Clear app data** in Android settings
- **Restart device**
- **Check airplane mode** is off

### 5. **Code Improvements Added**
The app now includes:
- **Retry mechanism** for network failures (3 attempts with exponential backoff)
- **Enhanced error logging** for better debugging
- **Improved connection testing** with fallback strategies

### 6. **Testing Steps**
1. **Run the app** and check console logs
2. **Look for retry attempts** in debug output
3. **Test offline/online transitions** using the offline banner
4. **Monitor connectivity service** status

### 7. **Debug Information**
The app will now log:
- Connection test attempts
- Retry attempts with delays
- Detailed error messages
- Network status changes

### 8. **If Problem Persists**
- **Check Supabase status** at status.supabase.com
- **Verify Supabase URL** in app_config.dart
- **Test with different Supabase project**
- **Contact network administrator** if on corporate network

## Prevention
- App now handles network failures gracefully
- Retry mechanisms reduce temporary failures
- Better error messages for debugging
- Offline mode support for better UX

## Monitoring
Watch for these log messages:
- `Supabase connection test successful`
- `Supabase connection test failed (attempt X)`
- `Database connection: OK`
- `Database connection failed after X attempts`
