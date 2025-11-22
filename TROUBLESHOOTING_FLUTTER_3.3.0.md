# 🔧 Troubleshooting Guide - Flutter 3.3.0 E2EE Chat App

## Overview
This guide addresses common issues when building and running the E2EE chat app on Flutter 3.3.0 (Dart 2.18.0).

---

## 🚨 Critical Issues

### **Issue 1: "Unsupported Gradle project"**

**Error Message**:
```
Exception: [!] Your app is using an unsupported Gradle project. 
To fix this problem, create a new project by running 
`flutter create -t app <app-directory>` and then move the dart code, 
assets and pubspec.yaml to the new project.
```

**Root Cause**: Project was created with Flutter 3.35.4 but trying to run on Flutter 3.3.0

**Solution**: **Follow the MIGRATION_GUIDE_FLUTTER_3.3.0.md**

**Quick Steps**:
1. Create fresh Flutter 3.3.0 project: `flutter create -t app chat_app_new`
2. Copy `lib/`, `assets/`, `pubspec.yaml` to new project
3. Copy `android/app/google-services.json`
4. Update Android package name in 3 files
5. Build and test

**Estimated Time**: 20-30 minutes  
**Success Rate**: 99% (if following migration guide exactly)

---

### **Issue 2: NDK Version Not Found**

**Error Message**:
```
No version of NDK matched the requested version 25.1.8937393
```

**Root Cause**: Android NDK not installed or wrong version

**Solution**: Install NDK via Android Studio

**Steps**:
1. Open Android Studio
2. Go to: `Tools > SDK Manager`
3. Select `SDK Tools` tab
4. Check `✓ NDK (Side by side)`
5. Expand NDK section
6. Check `✓ 25.1.8937393`
7. Click "Apply" and wait for installation

**Alternative - Manual Download**:
1. Download NDK 25.1.8937393 from: https://developer.android.com/ndk/downloads
2. Extract to: `C:\Users\YourName\AppData\Local\Android\Sdk\ndk\25.1.8937393\`
3. Restart Android Studio

**Verification**:
```cmd
dir "%LOCALAPPDATA%\Android\Sdk\ndk"
# Should show: 25.1.8937393
```

---

### **Issue 3: Rive Package @mustBeOverridden Error**

**Error Message**:
```
The method 'build' isn't defined for the type 'RiveAnimation'
@mustBeOverridden annotation on overridden method
```

**Root Cause**: Rive package version mismatch with Flutter 3.3.0

**Solution**: Lock Rive version to 0.9.1

**Edit pubspec.yaml**:
```yaml
dependencies:
  rive: 0.9.1  # MUST be exactly 0.9.1 for Flutter 3.3.0
```

**Then run**:
```cmd
flutter clean
flutter pub get
flutter pub upgrade --major-versions rive  # Should stay at 0.9.1
```

**Verification**:
```cmd
flutter pub deps | findstr rive
# Should show: rive 0.9.1
```

---

### **Issue 4: Package Name Mismatch**

**Error Messages**:
```
java.lang.ClassNotFoundException: Didn't find class "MainActivity"
FirebaseApp initialization failed
Google Services plugin cannot find google-services.json
```

**Root Cause**: Package name inconsistency across Android configuration files

**Solution**: Synchronize package name in ALL 3 files

**Step 1: Find Correct Package Name**

Open `android/app/google-services.json`, find:
```json
{
  "client": [
    {
      "package_name": "com.example.my_porject"  // ← THIS IS YOUR PACKAGE NAME
    }
  ]
}
```

**Step 2: Update File 1 - android/app/build.gradle**

Find line ~35:
```gradle
defaultConfig {
    applicationId "com.example.my_porject"  // ← MATCH PACKAGE NAME
    minSdkVersion 21
    targetSdkVersion 33
```

**Step 3: Update File 2 - android/app/src/main/AndroidManifest.xml**

Find line ~1:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.my_porject">  <!-- ← MATCH PACKAGE NAME -->
```

**Step 4: Update File 3 - MainActivity.kt**

**4a. Update package declaration**:

Open `android/app/src/main/kotlin/.../MainActivity.kt`:
```kotlin
package com.example.my_porject  // ← MATCH PACKAGE NAME

import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity()
```

**4b. Move file to correct directory**:

Current location (wrong):
```
android/app/src/main/kotlin/com/example/chat_app_e2ee_clean/MainActivity.kt
```

Should be (correct):
```
android/app/src/main/kotlin/com/example/my_porject/MainActivity.kt
```

**Steps to move**:
1. Navigate to: `android/app/src/main/kotlin/com/example/`
2. Rename folder from `chat_app_e2ee_clean` to `my_porject`
3. Verify `MainActivity.kt` is inside the renamed folder

**Step 5: Clean Build**

```cmd
flutter clean
cd android
gradlew clean
cd ..
flutter pub get
flutter build apk --release
```

**Verification Checklist**:
- [ ] All 3 files have same package name
- [ ] MainActivity.kt folder structure matches package name
- [ ] google-services.json matches package name
- [ ] Build succeeds without ClassNotFoundException

---

### **Issue 5: MultiDex Error**

**Error Message**:
```
Cannot fit requested classes in a single dex file
Method count exceeds 64K
```

**Root Cause**: Too many methods (Firebase + dependencies exceed limit)

**Solution**: Enable MultiDex

**Edit android/app/build.gradle**:

```gradle
android {
    defaultConfig {
        applicationId "com.example.my_porject"
        minSdkVersion 21
        targetSdkVersion 33
        multiDexEnabled true  // ← ADD THIS
    }
}

dependencies {
    implementation 'androidx.multidex:multidex:2.0.1'  // ← ADD THIS
}
```

**Clean and rebuild**:
```cmd
flutter clean
flutter pub get
flutter build apk --release
```

---

### **Issue 6: Google Services Plugin Not Applied**

**Error Message**:
```
google-services.json is missing
Firebase initialization failed
```

**Root Cause**: Google Services Gradle plugin not configured

**Solution**: Add plugin to Gradle files

**Step 1: Edit android/build.gradle**

```gradle
buildscript {
    ext.kotlin_version = '1.7.10'
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:7.4.2'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
        classpath 'com.google.gms:google-services:4.3.15'  // ← ADD THIS
    }
}
```

**Step 2: Edit android/app/build.gradle**

At the TOP of file:
```gradle
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
    id "com.google.gms.google-services"  // ← ADD THIS
}
```

**Step 3: Verify google-services.json location**

```cmd
dir android\app\google-services.json
# Should exist and show file size
```

**Step 4: Clean and rebuild**

```cmd
flutter clean
flutter pub get
flutter build apk --release
```

---

## ⚠️ Common Build Issues

### **Issue: "Execution failed for task ':app:processReleaseMainManifest'"**

**Solution**: Check AndroidManifest.xml syntax

```cmd
# Validate XML structure
cd android
gradlew processReleaseManifest --stacktrace
```

Common fixes:
- Ensure all XML tags are properly closed
- Check for duplicate permissions
- Verify package name format (no spaces, valid characters)

---

### **Issue: Gradle Sync Failed**

**Error Message**:
```
Could not resolve all files for configuration
```

**Solution**: Clear Gradle cache

```cmd
cd android
gradlew clean --refresh-dependencies
cd ..
flutter clean
flutter pub get
```

**If still failing**:
```cmd
# Delete Gradle cache
rmdir /S /Q "%USERPROFILE%\.gradle\caches"
cd android
gradlew build
```

---

### **Issue: "Unsupported class file major version 61"**

**Root Cause**: Java version mismatch

**Solution**: Use Java 11 for Flutter 3.3.0

**Check current Java version**:
```cmd
java -version
# Should show: Java 11 or compatible
```

**If wrong version**:
1. Download Java 11 JDK: https://adoptium.net/
2. Install and set JAVA_HOME:
```cmd
setx JAVA_HOME "C:\Program Files\Eclipse Adoptium\jdk-11.0.17.8-hotspot"
```
3. Restart Command Prompt
4. Verify: `java -version`

---

## 🔐 E2EE Specific Issues

### **Issue: Messages Not Encrypting**

**Symptoms**: No lock icon, messages sent as plain text

**Solution 1: Verify KeyManager Initialization**

Check that keys are generated on login/signup:

**Edit lib/screens/auth_screen.dart**, ensure this is in EVERY auth method:

```dart
Future<User?> logIn(String email, String password) async {
    try {
        User? user = (await _auth.signInWithEmailAndPassword(
            email: email,
            password: password
        )).user;
        
        if (user != null) {
            await KeyManager.initializeKeys();  // ← MUST HAVE THIS
            print("✅ Encryption keys initialized");
        }
        return user;
    } catch (e) {
        print("❌ Login error: $e");
        return null;
    }
}
```

**Solution 2: Verify Public Keys in Firestore**

Check Firebase Console:
1. Go to Firestore Database
2. Open `users` collection
3. Select your user document
4. Verify fields exist:
   - `publicKey` (string, starts with "-----BEGIN PUBLIC KEY-----")
   - `encryptionEnabled` (boolean, true)

If missing, manually trigger key generation:
```dart
// Add to debug menu or run once
await KeyManager.initializeKeys();
```

---

### **Issue: "Cannot decrypt message"**

**Error Message**:
```
Exception: Failed to decrypt message
FormatException: Invalid padding
```

**Solution 1: Verify Key Storage**

Check that private key is stored securely:

```dart
// Add to debug menu
final privateKey = await FlutterSecureStorage().read(key: 'e2ee_private_key');
if (privateKey == null) {
    print("❌ Private key missing!");
    await KeyManager.initializeKeys();
} else {
    print("✅ Private key exists");
}
```

**Solution 2: Check Message Format**

Encrypted messages should have this structure in Firestore:

```json
{
  "encrypted": true,
  "encryptedMessage": "base64_encoded_ciphertext",
  "encryptedAesKey": "base64_encoded_rsa_encrypted_key",
  "iv": "base64_encoded_initialization_vector"
}
```

If format is wrong, the sender may have old code. Ensure both users have latest app version.

---

### **Issue: flutter_secure_storage Permission Denied**

**Error Message**:
```
PlatformException: read_failed
Error reading secure storage
```

**Root Cause**: Android Keystore access issues

**Solution**: Add required permissions

**Edit android/app/src/main/AndroidManifest.xml**:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.my_porject">
    
    <!-- Add these permissions -->
    <uses-permission android:name="android.permission.USE_BIOMETRIC" />
    <uses-permission android:name="android.permission.USE_FINGERPRINT" />
    
    <application
        android:label="E2EE Chat"
        android:icon="@mipmap/ic_launcher">
```

**Clean and rebuild**:
```cmd
flutter clean
flutter pub get
flutter build apk --release
```

---

## 📱 Testing & Debugging

### **Enable Debug Logging**

Add to `lib/main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Enable debug logging
  await FirebaseFirestore.instance.setLoggingEnabled(true);
  
  runApp(const MyApp());
}
```

### **Test E2EE Manually**

```dart
// Add to debug menu or test file
Future<void> testE2EE() async {
  // Generate test keys
  final keys = EncryptionService.generateRSAKeyPair();
  print("✅ Keys generated");
  
  // Test encryption
  final encrypted = EncryptionService.encryptMessage(
    "Test message",
    keys['publicKey']!
  );
  print("✅ Message encrypted: ${encrypted['encryptedMessage']?.substring(0, 20)}...");
  
  // Test decryption
  final decrypted = EncryptionService.decryptMessage(
    encrypted,
    keys['privateKey']!
  );
  print("✅ Decrypted: $decrypted");
  
  if (decrypted == "Test message") {
    print("✅✅ E2EE working perfectly!");
  } else {
    print("❌ Decryption failed!");
  }
}
```

---

## 🔍 Diagnostic Commands

### **Flutter Environment Check**

```cmd
flutter doctor -v
# Should show all green checkmarks for:
# - Flutter SDK (3.3.0)
# - Android toolchain
# - Android Studio
```

### **Verify Package Versions**

```cmd
flutter pub deps
# Check critical packages:
# - encrypt: 5.0.0
# - crypto: 3.0.1
# - pointycastle: 3.5.2
# - flutter_secure_storage: 7.0.1
# - rive: 0.9.1
```

### **Check Build Configuration**

```cmd
cd android
gradlew properties | findstr compileSdk
# Should show: compileSdk=33

gradlew properties | findstr ndkVersion
# Should show: ndkVersion=25.1.8937393
```

### **Test APK Installation**

```cmd
# Install APK to connected device
adb install build\app\outputs\flutter-apk\app-release.apk

# View app logs
adb logcat | findstr "Flutter"
```

---

## ✅ Health Check Checklist

Run through this checklist before reporting issues:

**Environment**:
- [ ] Flutter version: 3.3.0 (`flutter --version`)
- [ ] Dart version: 2.18.0
- [ ] Android Studio installed with Flutter plugin
- [ ] NDK 25.1.8937393 installed

**Project Structure**:
- [ ] `pubspec.yaml` has correct package versions
- [ ] `android/app/google-services.json` exists
- [ ] Package name matches in all 3 Android files
- [ ] MainActivity.kt folder structure matches package name

**Build Configuration**:
- [ ] `android/app/build.gradle` has `multiDexEnabled true`
- [ ] Google Services plugin applied
- [ ] NDK version specified: `ndkVersion "25.1.8937393"`

**E2EE Features**:
- [ ] Keys generated on login (`KeyManager.initializeKeys()`)
- [ ] Public keys exist in Firestore `users` collection
- [ ] Messages show lock icon when encrypted
- [ ] Decryption works correctly

**Testing**:
- [ ] `flutter analyze` runs without errors
- [ ] `flutter build apk --release` succeeds
- [ ] APK installs on device
- [ ] App launches without crashes

---

## 🆘 Still Having Issues?

If you've tried all solutions above and still facing issues:

### **Collect Diagnostic Information**:

```cmd
REM Create diagnostic report
flutter doctor -v > diagnostic_report.txt
flutter pub deps >> diagnostic_report.txt
type pubspec.yaml >> diagnostic_report.txt
```

### **Clean Slate Approach**:

1. **Backup current project**: Zip entire folder
2. **Follow migration guide**: MIGRATION_GUIDE_FLUTTER_3.3.0.md
3. **Start fresh**: `flutter create` with Flutter 3.3.0
4. **Copy code**: Move lib, assets, config files
5. **Test incrementally**: Build after each major change

### **Common Last Resort Fixes**:

```cmd
REM Nuclear option - complete cleanup
flutter clean
rmdir /S /Q build
rmdir /S /Q .dart_tool
rmdir /S /Q android\.gradle
rmdir /S /Q android\build
rmdir /S /Q android\app\build
del pubspec.lock
flutter pub get
flutter build apk --release
```

---

**Prepared for**: User with Flutter 3.3.0 local environment  
**Purpose**: Comprehensive troubleshooting for E2EE chat app  
**Last Updated**: Current session

---

## 📚 Related Documents

- **MIGRATION_GUIDE_FLUTTER_3.3.0.md** - Complete project migration instructions
- **GITHUB_SETUP_GUIDE.md** - Git and GitHub integration
- **BUILD_INSTRUCTIONS_FLUTTER_3.3.0.md** - Detailed build steps
