# 🔧 Troubleshooting Guide - Flutter Chat App

## Common Errors & Solutions

---

## ❌ ERR_HTTP2_PROTOCOL_ERROR

### Error Message
```
Page resource error:
  code: -1
  description: net::ERR_HTTP2_PROTOCOL_ERROR
  errorType: WebResourceErrorType.unknown
  isForMainFrame: false
```

### Root Cause
This error occurs in **Google Sign-In** or **url_launcher** when using internal WebView with HTTP/2 protocol mismatch.

### Impact Level
⚠️ **LOW** - This is a non-blocking warning
- App continues to function normally
- Google Sign-In still works
- URL links still open
- `isForMainFrame: false` means it's not affecting main UI

### Solutions

#### Option 1: Ignore (Recommended)
This is a known issue with Google SDK WebView. Since it doesn't affect functionality, you can safely ignore it.

**Error Handler**: Already implemented in `lib/utils/error_handler.dart`
- Filters non-critical errors automatically
- Only shows critical errors in production
- Logs all errors in debug mode

#### Option 2: Update Dependencies
Keep packages up to date (but our versions are already stable):
```yaml
google_sign_in: ^7.2.0  # Latest stable
firebase_auth: ^6.1.2   # Latest stable
url_launcher: ^6.3.1    # Latest stable
```

#### Option 3: Add Network Security Config
Already configured in `AndroidManifest.xml`:
```xml
<application
  android:usesCleartextTraffic="false"
  android:hardwareAccelerated="true">
```

---

## 🔐 Biometric Authentication Issues

### Error: "Biometric not available"

**Cause**: Device doesn't support biometric or not enrolled

**Solution**:
- Check device settings → Security → Biometric
- Enable fingerprint or face recognition
- App will show appropriate message

### Error: "Authentication failed"

**Causes**:
1. Wrong fingerprint/face
2. Too many attempts (locked out)
3. Biometric sensor issue

**Solution**:
- Try again with correct biometric
- Use device PIN/password as fallback
- Wait if temporarily locked out

---

## 🔥 Firebase Errors

### Error: "No Firebase App '[DEFAULT]' has been created"

**Cause**: Firebase not initialized or `firebase_options.dart` missing

**Solution**: Already configured in `lib/resources/firebase_options.dart`

### Error: "google-services.json not found"

**Cause**: Missing Firebase configuration file

**Solution**: File exists at `/opt/flutter/google-services.json`

---

## 📦 Build Errors

### Error: "Gradle build failed"

**Solution**:
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk --release
```

### Error: "Out of memory"

**Solution**:
```bash
# Increase Gradle memory
echo "org.gradle.jvmargs=-Xmx2048m" >> android/gradle.properties
```

---

## 🌐 Network Errors

### Error: "No internet connection"

**Handled by**: `showDialogInternetCheck()` in multiple screens
- Auto-detects connection status
- Shows user-friendly dialog
- Retries when online

### Error: "Connection timeout"

**Solution**: Check Firebase/Firestore rules and network

---

## 🔒 Permission Errors

### Error: "Camera/Location permission denied"

**Solution**: Request permissions properly (already implemented)
```dart
await Permission.camera.request();
await Permission.location.request();
```

### Error: "Biometric permission denied"

**Solution**: Permissions already added to `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.USE_BIOMETRIC" />
<uses-permission android:name="android.permission.USE_FINGERPRINT" />
```

---

## 🎨 UI Errors

### Error: "RenderBox overflow"

**Solution**: Already using `SafeArea` and `SingleChildScrollView`

### Error: "Bottom overflow by X pixels"

**Solution**: Use `Expanded`, `Flexible`, or adjust padding

---

## 📊 Flutter Analyze Issues

### Current Warnings (Non-Critical)
```
6 warnings found:
- include_file_not_found (1)
- body_might_complete_normally_catch_error (3)
- must_be_immutable (2)
```

**Impact**: These don't affect app functionality

**To suppress**:
```bash
flutter analyze --no-fatal-warnings
```

---

## 🚀 Quick Fixes

### App won't start
```bash
flutter clean
flutter pub get
flutter run
```

### Hot reload not working
```bash
# Restart app completely
r (in terminal)
```

### Build cache issues
```bash
rm -rf .dart_tool/build_cache
flutter pub get
```

### Git issues
```bash
# Force pull from GitHub
./force_pull.sh
# or
git fetch origin && git reset --hard origin/main && git clean -fd
```

---

## 📱 Device-Specific Issues

### Android

**Issue**: App crashes on Android 13+
**Solution**: Update target SDK in `android/app/build.gradle.kts`

**Issue**: Google Sign-In fails
**Solution**: Check SHA-1 fingerprint in Firebase Console

### Web

**Issue**: CORS errors
**Solution**: Use CORS-enabled server (already configured)

**Issue**: WebSocket connection failed
**Solution**: Check Firestore rules and browser console

---

## 🔍 Debugging Tools

### View Flutter logs
```bash
flutter logs
```

### View Android logs
```bash
adb logcat | grep flutter
```

### Check app size
```bash
flutter build apk --analyze-size
```

### Performance profiling
```bash
flutter run --profile
# Then use DevTools
```

---

## 📚 Additional Resources

- **Error Handler**: `lib/utils/error_handler.dart`
- **Git Commands**: `GIT_COMMANDS.md`
- **Force Pull Script**: `./force_pull.sh`

---

## 💡 Pro Tips

1. **Always check logs first**: `flutter logs` or `adb logcat`
2. **Clean build when in doubt**: `flutter clean && flutter pub get`
3. **Check internet connection**: Many errors are network-related
4. **Update packages carefully**: Test after each major update
5. **Use error handler**: Already catches most common errors

---

## 🆘 Getting Help

If you encounter an error not covered here:

1. Check Flutter logs: `flutter logs`
2. Check Android logs: `adb logcat`
3. Search error message on:
   - Flutter GitHub Issues
   - StackOverflow
   - Flutter Discord

---

## ✅ Error Handler Features

Our `ErrorHandler` class (in `lib/utils/error_handler.dart`) provides:

- ✅ Global error catching
- ✅ Non-critical error filtering
- ✅ User-friendly error dialogs
- ✅ Error logging (debug mode)
- ✅ Clean error widgets (release mode)
- ✅ Snackbar notifications

**Usage**:
```dart
// Show error dialog
ErrorHandler.showErrorDialog(
  context,
  title: 'Error',
  message: 'Something went wrong',
  onRetry: () => retryOperation(),
);

// Show error snackbar
ErrorHandler.showErrorSnackBar(
  context,
  message: 'Failed to load data',
);

// Handle exception
try {
  // Your code
} catch (e, stackTrace) {
  ErrorHandler.handleException(
    e,
    stackTrace: stackTrace,
    context: 'Loading user data',
  );
}
```

---

**Last Updated**: Nov 28, 2025
**App Version**: 1.0.0
**Flutter Version**: 3.35.4
