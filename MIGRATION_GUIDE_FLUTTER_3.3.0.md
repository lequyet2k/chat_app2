# 🔄 Migration Guide: E2EE Chat App to Flutter 3.3.0

## Overview
This guide will help you migrate your working E2EE chat application to a fresh Flutter 3.3.0 project, resolving the "Unsupported Gradle project" error.

**Estimated Time**: 20-30 minutes  
**Difficulty**: Medium (copy-paste with careful attention to file paths)

---

## ✅ Prerequisites

Before starting, ensure you have:
- [ ] Flutter 3.3.0 installed and verified (`flutter --version`)
- [ ] Android Studio with Flutter plugin
- [ ] Access to your current project folder (even if not building)
- [ ] Firebase configuration file (`google-services.json`)
- [ ] GitHub repository URL (for later sync)

---

## 📁 Step 1: Create Fresh Flutter 3.3.0 Project

Open Command Prompt or PowerShell:

```cmd
cd C:\Users\YourName\Documents
flutter create -t app chat_app_e2ee_clean
cd chat_app_e2ee_clean
```

**Verify clean project works:**
```cmd
flutter pub get
flutter run
```

✅ **Checkpoint**: If this succeeds, you have a solid foundation!

---

## 📦 Step 2: Copy Dependencies (pubspec.yaml)

### **2.1: Replace pubspec.yaml**

Copy the entire content of your old project's `pubspec.yaml` to the new project's `pubspec.yaml`, EXCEPT keep the new project's name:

**Old project's pubspec.yaml** (copy from):
```yaml
name: my_porject  # Keep NEW project's name instead
description: A new Flutter project.

environment:
  sdk: '>=2.18.0 <3.0.0'

dependencies:
  flutter:
    sdk: flutter
  cloud_firestore: ^3.5.1
  firebase_auth: ^3.11.2
  firebase_core: ^1.24.0
  firebase_storage: ^10.3.11
  uuid: ^3.0.7
  image_picker: ^0.8.6
  google_sign_in: ^5.4.2
  flutter_facebook_auth: ^4.4.1+1
  google_fonts: ^3.0.1
  shared_preferences: ^2.0.15
  rive: 0.9.1
  # E2EE packages
  encrypt: ^5.0.0
  crypto: ^3.0.1
  pointycastle: ^3.5.2
  flutter_secure_storage: ^7.0.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/
```

**Action**: Copy everything EXCEPT change the `name:` field to match your NEW project name (probably `chat_app_e2ee_clean`).

### **2.2: Install Dependencies**

```cmd
flutter pub get
```

✅ **Checkpoint**: Should complete without errors. Warnings about deprecated features are OK.

---

## 🎨 Step 3: Copy Assets Folder

```cmd
# In Command Prompt, from new project root:
xcopy /E /I C:\Users\YourName\path\to\old_project\assets assets
```

**Manual Method**:
1. Open old project folder in File Explorer
2. Copy entire `assets` folder
3. Paste into new project root

---

## 📱 Step 4: Copy Dart Code (lib folder)

### **4.1: Copy ALL Dart Files**

**Option A - Command Line**:
```cmd
xcopy /E /I C:\Users\YourName\path\to\old_project\lib lib
```

**Option B - Manual**:
1. Delete `lib/main.dart` in new project
2. Copy entire `lib` folder from old project
3. Paste into new project (overwrite)

**Your lib structure should look like**:
```
lib/
├── main.dart
├── screens/
│   ├── auth_screen.dart
│   ├── home_screen.dart
│   ├── chat_screen.dart
│   └── search_screen.dart
├── services/
│   ├── encryption_service.dart
│   ├── key_manager.dart
│   └── encrypted_chat_service.dart
└── widgets/
    └── (any custom widgets)
```

---

## 🔥 Step 5: Firebase Configuration

### **5.1: Copy google-services.json**

```cmd
# Windows Command Prompt:
copy C:\Users\YourName\path\to\old_project\android\app\google-services.json android\app\google-services.json
```

**Manual Method**:
1. Locate `google-services.json` in old project: `old_project/android/app/`
2. Copy to new project: `new_project/android/app/`

### **5.2: Update Android Package Name**

**Extract package name from google-services.json**:
1. Open `android/app/google-services.json` in text editor
2. Find line: `"package_name": "com.example.something"`
3. Copy the package name (e.g., `com.example.my_porject`)

**Update 3 files with this package name**:

#### **File 1: android/app/build.gradle**

Find line ~35:
```gradle
defaultConfig {
    applicationId "com.flutter.example"  // CHANGE THIS
```

Change to:
```gradle
defaultConfig {
    applicationId "com.example.my_porject"  // YOUR package name
```

Also add NDK version (around line 30):
```gradle
android {
    compileSdk 33
    ndkVersion "25.1.8937393"  // ADD THIS LINE
```

And add MultiDex support (inside `defaultConfig`):
```gradle
defaultConfig {
    applicationId "com.example.my_porject"
    minSdkVersion 21
    targetSdkVersion 33
    multiDexEnabled true  // ADD THIS
```

#### **File 2: android/app/src/main/AndroidManifest.xml**

Find line ~1:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.something">  <!-- CHANGE THIS -->
```

Change to your package name.

#### **File 3: MainActivity.kt file location**

**Rename directory structure** to match package name:

Old structure:
```
android/app/src/main/kotlin/com/example/chat_app_e2ee_clean/
```

New structure (if your package is `com.example.my_porject`):
```
android/app/src/main/kotlin/com/example/my_porject/
```

**Steps**:
1. Navigate to: `android/app/src/main/kotlin/com/example/`
2. Rename folder from `chat_app_e2ee_clean` to `my_porject`
3. Open `MainActivity.kt` inside
4. Change first line:
```kotlin
package com.example.my_porject  // Match your package name
```

---

## 🔧 Step 6: Configure Android Gradle for Firebase

### **6.1: Update android/build.gradle**

Open `android/build.gradle`, find the `dependencies` block inside `buildscript`:

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
        classpath 'com.google.gms:google-services:4.3.15'  // ADD THIS LINE
    }
}
```

### **6.2: Update android/app/build.gradle**

At the TOP of the file, find the `plugins` block:

```gradle
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
}
```

Add Google Services plugin:
```gradle
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
    id "com.google.gms.google-services"  // ADD THIS LINE
}
```

At the BOTTOM of the file, add:
```gradle
dependencies {
    implementation 'androidx.multidex:multidex:2.0.1'
}
```

---

## 🧪 Step 7: Test Build

### **7.1: Clean Build**

```cmd
flutter clean
flutter pub get
```

### **7.2: Build APK**

```cmd
flutter build apk --release
```

**Expected Output**:
```
✓ Built build/app/outputs/flutter-apk/app-release.apk (XX MB).
```

✅ **Checkpoint**: If APK builds successfully, your migration is complete!

---

## 🚀 Step 8: Test on Device

### **8.1: Run on Connected Device**

```cmd
flutter run
```

### **8.2: Test E2EE Features**

**Test Checklist**:
- [ ] Create account with email/password
- [ ] Login successfully
- [ ] Search for another user
- [ ] Send encrypted message (should show 🔒 icon)
- [ ] Receive and decrypt message
- [ ] Verify green bubble for encrypted messages
- [ ] Test Google Sign-In (optional)
- [ ] Test Facebook Sign-In (optional)

---

## 🔄 Step 9: Setup Git for Easy Updates

### **9.1: Initialize Git Repository**

```cmd
git init
git add .
git commit -m "Initial commit - E2EE chat app migrated to Flutter 3.3.0"
```

### **9.2: Connect to GitHub Repository**

Replace `YOUR_GITHUB_USERNAME` and `REPO_NAME` with actual values:

```cmd
git remote add origin https://github.com/YOUR_GITHUB_USERNAME/REPO_NAME.git
git branch -M main
git pull origin main --allow-unrelated-histories
git push -u origin main
```

### **9.3: Create update.bat for Easy Syncing**

Create `update.bat` in project root:

```batch
@echo off
echo ============================================
echo 🔄 Pulling latest changes from GitHub...
echo ============================================
git pull origin main

echo.
echo ============================================
echo 📦 Installing dependencies...
echo ============================================
flutter pub get

echo.
echo ============================================
echo 🧹 Cleaning build cache...
echo ============================================
flutter clean

echo.
echo ============================================
echo 🔨 Building APK...
echo ============================================
flutter build apk --release

echo.
echo ============================================
echo ✅ Update Complete!
echo ============================================
echo APK Location: build\app\outputs\flutter-apk\app-release.apk
echo.
pause
```

**Usage**: Just double-click `update.bat` whenever you want to pull latest changes and rebuild!

---

## 🎉 Success Criteria

Your migration is successful if:
- [x] `flutter pub get` completes without errors
- [x] `flutter build apk --release` produces an APK
- [x] App runs on Android device
- [x] E2EE messages encrypt/decrypt correctly (🔒 icon visible)
- [x] All authentication methods work
- [x] Git repository syncs with GitHub

---

## 🆘 Troubleshooting

### **Issue: "package does not exist" errors**

**Solution**: Verify package name matches in all 3 files:
- `android/app/build.gradle` (applicationId)
- `android/app/src/main/AndroidManifest.xml` (package)
- `MainActivity.kt` (package statement + folder structure)

### **Issue: "MultiDex" errors**

**Solution**: Add to `android/app/build.gradle`:
```gradle
defaultConfig {
    multiDexEnabled true
}
dependencies {
    implementation 'androidx.multidex:multidex:2.0.1'
}
```

### **Issue: "NDK not found"**

**Solution**: In Android Studio, go to:
`Tools > SDK Manager > SDK Tools > NDK (Side by side) > Install version 25.1.8937393`

### **Issue: Rive animation errors**

**Solution**: Ensure `pubspec.yaml` has exact version:
```yaml
rive: 0.9.1  # MUST be 0.9.1 for Flutter 3.3.0
```

### **Issue: Firebase initialization fails**

**Solution**: 
1. Verify `google-services.json` is in `android/app/`
2. Check `com.google.gms.google-services` plugin is applied in `android/app/build.gradle`
3. Ensure package name matches across all files

---

## 📞 Support

If you encounter issues during migration:

1. **Check Flutter version**: `flutter --version` (should be 3.3.0)
2. **Check error logs**: Look for specific file/line numbers in error messages
3. **Verify file paths**: Ensure all files copied to correct locations
4. **Clean build**: `flutter clean && flutter pub get`

---

## 🎯 Next Steps After Successful Migration

1. **Backup Working Project**: Create zip of entire project folder
2. **Test on Multiple Devices**: Verify E2EE works across different Android versions
3. **Setup Automated Builds**: Use `update.bat` for regular syncing
4. **Add New Features**: Your clean Flutter 3.3.0 project is ready for enhancements!

---

**Prepared for**: User with Flutter 3.3.0 local environment  
**Migration Source**: E2EE chat app with RSA 2048 + AES 256 encryption  
**Target Environment**: Flutter 3.3.0 (Dart 2.18.0) + Android Studio  
**Last Updated**: Current session

---

## ⚡ Quick Reference Commands

```cmd
# Create new project
flutter create -t app chat_app_e2ee_clean

# Get dependencies
flutter pub get

# Clean build
flutter clean

# Build APK
flutter build apk --release

# Run on device
flutter run

# Git sync (after setup)
git pull origin main
```

