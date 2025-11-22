# 🚀 Hướng Dẫn Build APK Trên Flutter 3.3.0

## ✅ Yêu Cầu Hệ Thống

- **Flutter**: 3.3.0 (Dart 2.18.0)
- **Android Studio**: Latest version
- **JDK**: 11 hoặc 17
- **Android SDK**: API Level 33
- **Android NDK**: 25.1.8937393 (sẽ tự động download)

---

## 📥 Bước 1: Tải Code Mới Nhất

```bash
cd D:\test1\chat_app2-main
git pull origin main
```

Hoặc download lại từ GitHub:
https://github.com/lequyet2k/chat_app2

---

## 🧹 Bước 2: Clean Project

```bash
flutter clean
```

---

## 📦 Bước 3: Install Dependencies

```bash
flutter pub get
```

**⚠️ Quan trọng:** Đảm bảo `pubspec.yaml` có đúng versions:
```yaml
dependencies:
  # E2EE packages
  encrypt: ^5.0.0
  crypto: ^3.0.1
  pointycastle: ^3.5.2
  flutter_secure_storage: ^7.0.1
  rive: 0.9.1  # CRITICAL: Must be 0.9.1 for Flutter 3.3.0

environment:
  sdk: '>=2.18.0 <3.0.0'  # Flutter 3.3.0 compatible
```

---

## 🔧 Bước 4: Verify Gradle Configuration

**File `android/app/build.gradle` phải có:**
```gradle
android {
    compileSdk 33
    ndkVersion "25.1.8937393"  // CRITICAL: Required!
    
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 33
        // ...
    }
}
```

**File `android/settings.gradle` phải có:**
```gradle
plugins {
    id "dev.flutter.flutter-plugin-loader" version "1.0.0"
    id "com.android.application" version "7.4.2" apply false
    id "org.jetbrains.kotlin.android" version "1.7.10" apply false
}
```

**File `android/gradle/wrapper/gradle-wrapper.properties`:**
```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-7.6.3-all.zip
```

---

## 🏗️ Bước 5: Build APK

### **Option A: Debug APK** (Nhanh, dùng để test)
```bash
flutter build apk --debug
```

### **Option B: Release APK** (Production-ready) ⭐
```bash
flutter build apk --release
```

**Thời gian:** ~2-5 phút (lần đầu), ~1-2 phút (các lần sau)

---

## 📱 Bước 6: Tìm APK File

**Debug APK:**
```
build/app/outputs/flutter-apk/app-debug.apk
```

**Release APK:**
```
build/app/outputs/flutter-apk/app-release.apk
```

---

## 🐛 Xử Lý Lỗi Thường Gặp

### ❌ Lỗi: "One or more plugins require a higher Android NDK version"

**Giải pháp:**
```gradle
// Thêm vào android/app/build.gradle
android {
    ndkVersion "25.1.8937393"
}
```

---

### ❌ Lỗi: "Unresolved reference: mustBeOverridden"

**Nguyên nhân:** Package `rive` version mới không tương thích với Dart 2.18

**Giải pháp:**
```yaml
# Trong pubspec.yaml, lock rive version:
dependencies:
  rive: 0.9.1  # KHÔNG dùng ^0.9.1
```

Sau đó:
```bash
flutter clean
flutter pub get
```

---

### ❌ Lỗi: "Namespace not specified"

**Nguyên nhân:** AGP 8.x yêu cầu namespace, nhưng Flutter 3.3.0 dùng AGP 7.x

**Giải pháp:** Đảm bảo `settings.gradle` có:
```gradle
id "com.android.application" version "7.4.2" apply false
```

Không dùng version 8.x!

---

### ❌ Lỗi: "Execution failed for task ':app:minifyReleaseWithR8'"

**Nguyên nhân:** Proguard rules conflict

**Giải pháp:** Tạm thời disable minify:
```gradle
buildTypes {
    release {
        minifyEnabled false  // Change to false
        shrinkResources false  // Change to false
    }
}
```

---

### ❌ Lỗi: "Could not resolve firebase-bom"

**Giải pháp:** Check internet connection và:
```bash
flutter clean
flutter pub cache repair
flutter pub get
```

---

## ✅ Verify Build Thành Công

Sau khi build xong, bạn sẽ thấy:
```
✓ Built build/app/outputs/flutter-apk/app-release.apk (XX.XMB)
```

---

## 📲 Bước 7: Install APK Trên Android

### **Cách 1: Qua USB**
```bash
flutter install
```

### **Cách 2: Manual Install**
1. Copy file `app-release.apk` vào điện thoại
2. Mở file manager
3. Tap vào file APK
4. Allow "Install from unknown sources" nếu được hỏi
5. Tap "Install"

---

## 🧪 Test E2EE Trên Android

### **Test Checklist:**

1. **✅ Login với 2 tài khoản khác nhau** (2 devices)
2. **✅ Gửi tin nhắn giữa 2 accounts**
3. **✅ Kiểm tra tin nhắn có 🟢 green bubble + 🔒 lock icon**
4. **✅ Tin nhắn hiển thị đúng sau khi decrypt**
5. **✅ Keys được lưu an toàn** (clear app data → keys mất)
6. **✅ Video call hoạt động**
7. **✅ Image upload hoạt động**
8. **✅ Location sharing hoạt động**

---

## 🔑 Test Secure Storage

**Verify keys được lưu trong Android Keystore:**

1. Login vào app
2. Gửi 1 tin nhắn encrypted
3. Force stop app
4. Mở lại app
5. Tin nhắn vẫn decrypt được → ✅ Keys được lưu đúng

**Verify keys được xóa khi logout:**

1. Logout khỏi app
2. Login lại
3. Old encrypted messages → Show "Decryption failed" → ✅ Keys đã bị xóa

---

## 📊 Performance Benchmarks (Flutter 3.3.0)

| Metric | Expected Value |
|--------|----------------|
| **Key Generation** | 2-3 seconds (first time) |
| **Message Encryption** | 10-50ms |
| **Message Decryption** | 10-50ms |
| **App Startup** | 1-2 seconds |
| **APK Size** | ~50-80MB (release) |

---

## 🔗 Resources

- **GitHub Repository**: https://github.com/lequyet2k/chat_app2
- **E2EE Documentation**: E2EE_SECURITY_GUIDE.md
- **Flutter 3.3.0 Docs**: https://docs.flutter.dev/release/archive

---

## 💡 Tips

1. **Build Release APK cho production** - Nhỏ hơn và nhanh hơn debug
2. **Test trên nhiều Android versions** - Tối thiểu Android 5.0 (API 21)
3. **Test với network tốt** - E2EE cần Firebase connection
4. **Không share APK công khai** - Vẫn dùng debug signing config

---

## 🆘 Nếu Vẫn Gặp Lỗi

**Liên hệ qua GitHub Issues:**
https://github.com/lequyet2k/chat_app2/issues

**Cung cấp thông tin:**
- Flutter version: `flutter --version`
- Error message đầy đủ
- Build command đã chạy
- OS version (Windows/Mac/Linux)

---

**Last Updated**: 2024-11-22
**Flutter Version**: 3.3.0 (Dart 2.18.0)
**Status**: ✅ Tested & Working
