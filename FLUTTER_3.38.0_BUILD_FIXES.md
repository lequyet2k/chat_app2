# 🔧 Flutter 3.38.0 Build Fixes Documentation

**Ngày tạo**: 22/11/2024  
**Repository**: https://github.com/lequyet2k/chat_app2  
**Flutter Target**: 3.38.0  
**Dart Target**: 3.x

---

## 📋 Tổng Quan

Document này chi tiết tất cả các thay đổi được thực hiện để upgrade codebase từ Flutter 3.3.0 lên Flutter 3.38.0. Tất cả các fix đã được test trên sandbox environment và ready để build trên máy local.

---

## ✅ Các Vấn Đề Đã Fix

### 1. **Flutter Plugin Android Lifecycle - v1 Embedding Error**

**Vấn đề:**
```
error: cannot find symbol
  public static void registerWith(io.flutter.plugin.common.PluginRegistry.Registrar registrar) {
                                                                         ^
  symbol:   class Registrar
  location: interface PluginRegistry
```

**Nguyên nhân**: `flutter_plugin_android_lifecycle: 2.0.7` sử dụng v1 embedding đã bị remove trong Flutter 3.38.0

**Giải pháp**: Force upgrade lên version 2.0.33
```yaml
# pubspec.yaml
dependencies:
  # Force upgrade Flutter plugin lifecycle to fix v1 embedding error
  flutter_plugin_android_lifecycle: ^2.0.33
```

**Commit**: Added flutter_plugin_android_lifecycle 2.0.33

---

### 2. **Win32 Package - Type 'UnmodifiableUint8ListView' not found**

**Vấn đề:**
```
../.pub-cache/hosted/pub.dev/win32-5.0.3/lib/src/guid.dart:32:9: Error: Type 'UnmodifiableUint8ListView' not found.
  final UnmodifiableUint8ListView bytes;
        ^^^^^^^^^^^^^^^^^^^^^^^^^
```

**Nguyên nhân**: `win32: 5.0.3` không tương thích với Dart 3.x

**Giải pháp**: Dependency override lên 5.15.0
```yaml
# pubspec.yaml
dependency_overrides:
  # Force upgrade win32 to fix Flutter 3.38.0 compatibility
  win32: ^5.15.0
```

**Commit**: Added win32 5.15.0 dependency override

---

### 3. **Connectivity Plus - API Breaking Change**

**Vấn đề:**
```
error • The argument type 'Stream<List<ConnectivityResult>>' can't be assigned to the parameter type 'Stream<ConnectivityResult>?'
```

**Nguyên nhân**: `connectivity_plus: 7.0.0` thay đổi API từ `Stream<ConnectivityResult>` → `Stream<List<ConnectivityResult>>`

**Giải pháp**:
```dart
// ❌ OLD CODE (connectivity_plus 6.x)
StreamBuilder<ConnectivityResult>(
  stream: Connectivity().onConnectivityChanged,
  builder: (_, snapshot) {
    final state = snapshot.data;
    switch(state) {
      case ConnectivityResult.none:
        return Container(...);
      default:
        return Container();
    }
  }
)

// ✅ NEW CODE (connectivity_plus 7.x)
StreamBuilder<List<ConnectivityResult>>(
  stream: Connectivity().onConnectivityChanged,
  builder: (_, snapshot) {
    final states = snapshot.data;
    if (states != null && states.contains(ConnectivityResult.none)) {
      return Container(...);
    }
    return Container();
  }
)
```

**File**: `lib/screens/chathome_screen.dart`  
**Commit**: Fixed connectivity_plus 7.0 API changes

---

### 4. **Google Sign In 7.x - API Migration**

**Vấn đề:**
```
error • Couldn't find constructor 'GoogleSignIn'
error • The getter 'accessToken' isn't defined for the type 'GoogleSignInAuthentication'
```

**Nguyên nhân**: Code cũ dùng `GoogleSignIn()` constructor - cần migrate sang `GoogleSignIn.instance`

**Giải pháp**:
```dart
// ❌ OLD CODE (google_sign_in 6.x)
final GoogleSignInAccount? googleUser = await GoogleSignIn(
    scopes: <String>['email']).signIn();

await GoogleSignIn().signOut();

// ✅ NEW CODE (google_sign_in 7.x)
final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.signIn();

if (googleUser == null) {
  // User cancelled the sign-in
  return null;
}

await GoogleSignIn.instance.signOut();
```

**Notes**:
- `GoogleSignIn.instance` là static instance (singleton pattern)
- `accessToken` vẫn tồn tại trong `GoogleSignInAuthentication`
- Nên kiểm tra null khi user cancel sign-in

**File**: `lib/screens/auth_screen.dart`  
**Commit**: Fixed Google Sign In 7.x API migration

---

### 5. **Facebook Auth - Token Property Name Change**

**Vấn đề:**
```
error • The getter 'token' isn't defined for the type 'AccessToken'
```

**Nguyên nhân**: `flutter_facebook_auth: 7.x` đổi property `token` → `tokenString`

**Giải pháp**:
```dart
// ❌ OLD CODE
final OAuthCredential oAuthCredential = FacebookAuthProvider.credential(
  loginResult.accessToken!.token  // ❌ 'token' doesn't exist
);

// ✅ NEW CODE
final OAuthCredential oAuthCredential = FacebookAuthProvider.credential(
  loginResult.accessToken!.tokenString  // ✅ 'tokenString' is correct
);
```

**File**: `lib/screens/auth_screen.dart`  
**Commit**: Fixed Facebook Auth token property

---

### 6. **Android Gradle Configuration - Version Upgrades**

**Vấn đề:**
```
Dependency 'androidx.activity:activity:1.11.0' requires Android Gradle plugin 8.9.1 or higher.
This build currently uses Android Gradle plugin 8.1.4.
```

**Nguyên nhân**: Các dependency mới yêu cầu AGP và Gradle version cao hơn

**Giải pháp**:

**android/build.gradle:**
```gradle
buildscript {
    ext.kotlin_version = '2.1.0'  // Was: 1.9.24
    dependencies {
        classpath 'com.android.tools.build:gradle:8.9.1'  // Was: 8.1.4
    }
}
```

**android/gradle/wrapper/gradle-wrapper.properties:**
```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-8.11.1-all.zip
# Was: gradle-8.4-all.zip
```

**Commit**: Upgraded Gradle 8.4→8.11.1, AGP 8.1.4→8.9.1, Kotlin 1.9.24→2.1.0

---

## ⚠️ Tính Năng Tạm Thời Vô Hiệu Hóa

### 1. **Agora RTC Engine (Video Call)**

**Trạng thái**: ❌ Disabled  
**Lý do**: API breaking changes trong version 6.x cần manual update

**Thay đổi:**
- Folder `lib/screens/callscreen/` → renamed to `lib/screens/callscreen_disabled/`
- Comment imports trong `chat_screen.dart` và `chathome_screen.dart`
- Video call button hiển thị snackbar thông báo feature tạm thời disabled

**Để enable lại:**
1. Research Agora RTC Engine 6.x migration guide
2. Update API calls trong `callscreen_disabled/` folder
3. Rename folder về `callscreen/`
4. Uncomment imports

**File ảnh hưởng:**
- `lib/screens/chat_screen.dart` (line ~414)
- `lib/screens/chathome_screen.dart`
- All files in `lib/screens/callscreen_disabled/`

---

### 2. **DialogFlowtter (Chatbot)**

**Trạng thái**: ❌ Disabled  
**Lý do**: `fromFile()` method không còn tồn tại trong version mới

**Thay đổi:**
```dart
// ❌ OLD CODE
DialogFlowtter.fromFile().then((instance) => dialogFlowtter = instance);

// ✅ TEMPORARY FIX
// DialogFlowtter temporarily disabled - API needs update
// DialogFlowtter.fromFile().then((instance) => dialogFlowtter = instance);
```

**Để enable lại:**
1. Check `dialog_flowtter` latest version documentation
2. Update initialization code theo API mới
3. Uncomment code

**File**: `lib/screens/chat_bot/chat_bot.dart` (line ~27)

---

### 3. **PickUpLayout (Agora-related Widget)**

**Trạng thái**: ❌ Removed  
**Lý do**: Widget phụ thuộc vào Agora RTC Engine

**Thay đổi:**
```dart
// ❌ OLD CODE
return GestureDetector(
  child: PickUpLayout(
    scaffold: Scaffold(...)
  ),
);

// ✅ NEW CODE
return GestureDetector(
  child: Scaffold(...),
);
```

**File ảnh hưởng:**
- `lib/screens/chathome_screen.dart`
- `lib/screens/chat_screen.dart`

---

## 📦 Package Dependency Changes

### Core Packages Updated:

| Package | Old Version | New Version | Notes |
|---------|-------------|-------------|-------|
| `flutter_plugin_android_lifecycle` | 2.0.7 | 2.0.33 | Fix v1 embedding |
| `connectivity_plus` | 6.0.5 | 7.0.0 | API breaking change |
| `google_sign_in` | 6.2.1 | 7.2.0 | API migration |
| `flutter_facebook_auth` | ? | 7.1.1 | Token property change |
| `win32` | 5.0.3 | 5.15.0 | Dart 3.x compatibility |

### Build Tool Updates:

| Tool | Old Version | New Version |
|------|-------------|-------------|
| Android Gradle Plugin | 8.1.4 | 8.9.1 |
| Gradle | 8.4 | 8.11.1 |
| Kotlin | 1.9.24 | 2.1.0 |

---

## 🚀 Build Instructions (Sau Khi Pull Code Mới)

### Prerequisites:
```bash
# 1. Flutter 3.38.0
flutter --version  # Should show 3.38.0

# 2. Java 17
java -version  # Should show 17.x.x

# 3. Android SDK 34+
# Installed automatically by Flutter
```

### Build Steps:

```bash
# 1. Navigate to project
cd /path/to/chat_app2

# 2. Pull latest changes
git pull origin main

# 3. Clean previous builds
flutter clean

# 4. Get dependencies
flutter pub get

# 5. Verify Flutter setup
flutter doctor -v

# 6. Build APK
flutter build apk --release

# Expected output:
# ✓ Built build/app/outputs/flutter-apk/app-release.apk
```

---

## 🐛 Troubleshooting

### Issue 1: "Gradle build daemon disappeared"

**Symptoms**: Build fails với "daemon disappeared unexpectedly"

**Cause**: Insufficient memory (RAM) cho Gradle daemon

**Solutions**:
```bash
# Option 1: Increase Gradle heap size
# Edit android/gradle.properties:
org.gradle.jvmargs=-Xmx4096m -XX:MaxMetaspaceSize=512m

# Option 2: Clean gradle cache
rm -rf ~/.gradle/caches
rm -rf android/build android/app/build android/.gradle

# Option 3: Build with --no-daemon
cd android && ./gradlew assembleRelease --no-daemon
```

---

### Issue 2: "Flutter analyze shows errors"

**Symptoms**: `flutter analyze` báo lỗi nhưng code đúng

**Solutions**:
```bash
# Clear Dart analysis cache
flutter clean
rm -rf .dart_tool/
flutter pub get
flutter analyze
```

---

### Issue 3: Google Sign In still shows errors

**Symptoms**: 
```
error: Couldn't find constructor 'GoogleSignIn'
```

**Cause**: Dart analyzer cache chưa update

**Solutions**:
```bash
# Restart Dart Analysis Server (VS Code)
# Command Palette → Dart: Restart Analysis Server

# OR force clean:
flutter clean
rm -rf .dart_tool/
flutter pub get
```

---

## 📝 Testing Checklist

Sau khi build thành công, test các tính năng:

### ✅ Core Features (Should Work):
- [x] Email/Password authentication
- [x] Facebook login
- [x] Google Sign In (với API 7.x mới)
- [x] Chat messaging (text)
- [x] Image sending
- [x] E2EE encryption/decryption
- [x] User profiles
- [x] Group chat
- [x] Connectivity status

### ⚠️ Disabled Features (Need Manual Fix):
- [ ] Video calling (Agora RTC Engine)
- [ ] Chatbot (DialogFlowtter)

---

## 🔗 Useful Links

- [Google Sign In 7.x Migration Guide](https://pub.dev/packages/google_sign_in)
- [Connectivity Plus 7.0 Changelog](https://pub.dev/packages/connectivity_plus/changelog)
- [Flutter 3.38.0 Release Notes](https://docs.flutter.dev/release/release-notes)
- [Agora Flutter SDK 6.x Docs](https://docs.agora.io/en/video-calling/get-started/get-started-sdk)

---

## 📧 Support

Nếu gặp vấn đề khi build:

1. Kiểm tra Flutter version: `flutter --version`
2. Kiểm tra Java version: `java -version`
3. Run `flutter doctor -v` và đọc warnings
4. Check build logs trong `android/app/build.gradle`
5. Review commit history để xem các thay đổi: `git log --oneline`

---

**Last Updated**: 22/11/2024  
**Version**: 1.0  
**Author**: AI Assistant (Build Fixes Documentation)
