# ✅ E2EE Chat App Migration Checklist

**Project**: E2EE Chat Application  
**Target**: Flutter 3.3.0 (Dart 2.18.0)  
**Platform**: Android  
**Date Started**: _______________

---

## 📋 Phase 1: Prerequisites

**Before You Begin** (check each):

- [ ] Flutter 3.3.0 installed
  - Command: `flutter --version`
  - Expected: `Flutter 3.3.0 • Dart 2.18.0`

- [ ] Android Studio installed with Flutter plugin
  - Open Android Studio
  - Check: `File > Settings > Plugins > Flutter`

- [ ] Git installed
  - Command: `git --version`
  - Expected: `git version 2.x.x`

- [ ] Java 11 JDK installed
  - Command: `java -version`
  - Expected: `java version "11.0.x"`

- [ ] Old project files accessible
  - [ ] `lib/` folder
  - [ ] `assets/` folder
  - [ ] `pubspec.yaml`
  - [ ] `android/app/google-services.json`

---

## 📦 Phase 2: Create Fresh Project

**Location**: _______________________________________________

- [ ] Open Command Prompt
- [ ] Navigate to desired location: `cd C:\Users\...\Documents`
- [ ] Run: `flutter create -t app chat_app_e2ee_clean`
- [ ] Navigate into project: `cd chat_app_e2ee_clean`
- [ ] Test clean build: `flutter run`
- [ ] **CHECKPOINT**: Clean project builds successfully ✅

**Time Completed**: _______________

---

## 📝 Phase 3: Copy Dependencies

**File**: `pubspec.yaml`

- [ ] Open old project's `pubspec.yaml`
- [ ] Open new project's `pubspec.yaml`
- [ ] Copy `dependencies` section (except keep new project name)
- [ ] Copy `dev_dependencies` section
- [ ] Copy `flutter.assets` section
- [ ] Save file
- [ ] Run: `flutter pub get`
- [ ] **CHECKPOINT**: Dependencies installed without errors ✅

**Critical Package Versions**:
- [ ] `encrypt: ^5.0.0`
- [ ] `crypto: ^3.0.1`
- [ ] `pointycastle: ^3.5.2`
- [ ] `flutter_secure_storage: ^7.0.1`
- [ ] `rive: 0.9.1` (MUST be exactly 0.9.1)

**Time Completed**: _______________

---

## 🎨 Phase 4: Copy Assets

- [ ] Copy entire `assets/` folder from old project
- [ ] Paste into new project root
- [ ] Verify assets exist: `dir assets`
- [ ] **CHECKPOINT**: Assets folder copied ✅

**Time Completed**: _______________

---

## 💻 Phase 5: Copy Dart Code

- [ ] Delete `lib/main.dart` in new project
- [ ] Copy entire `lib/` folder from old project
- [ ] Paste into new project (overwrite)
- [ ] Verify structure:
  - [ ] `lib/main.dart`
  - [ ] `lib/screens/` folder
  - [ ] `lib/services/` folder
  - [ ] `lib/widgets/` folder (if exists)
- [ ] **CHECKPOINT**: Code structure complete ✅

**Time Completed**: _______________

---

## 🔥 Phase 6: Firebase Configuration

### **Step 6.1: Copy google-services.json**

- [ ] Locate `android/app/google-services.json` in old project
- [ ] Copy to new project: `android/app/google-services.json`
- [ ] Verify file exists: `dir android\app\google-services.json`

### **Step 6.2: Extract Package Name**

- [ ] Open `android/app/google-services.json`
- [ ] Find: `"package_name": "com.example.XXXXX"`
- [ ] Write package name here: _____________________________________

### **Step 6.3: Update Android Config Files**

**File 1**: `android/app/build.gradle`

- [ ] Find `defaultConfig` section (line ~35)
- [ ] Change `applicationId` to match package name
- [ ] Add `ndkVersion "25.1.8937393"` (line ~30)
- [ ] Add `multiDexEnabled true` inside `defaultConfig`
- [ ] Add dependency: `implementation 'androidx.multidex:multidex:2.0.1'`

**File 2**: `android/app/src/main/AndroidManifest.xml`

- [ ] Find `<manifest>` tag (line ~1)
- [ ] Change `package` attribute to match package name

**File 3**: `MainActivity.kt` location and content

- [ ] Navigate to: `android/app/src/main/kotlin/com/example/`
- [ ] Rename folder to match your package name
- [ ] Open `MainActivity.kt` inside
- [ ] Change first line: `package com.example.YOUR_PACKAGE`

- [ ] **CHECKPOINT**: All 3 files have matching package name ✅

**Package Name Verification**:
```
google-services.json: _____________________________________
build.gradle:         _____________________________________
AndroidManifest.xml:  _____________________________________
MainActivity.kt:      _____________________________________
```
**All match?** [ ] YES [ ] NO (if NO, fix before continuing)

**Time Completed**: _______________

---

## 🔧 Phase 7: Gradle Configuration

### **Step 7.1: Update `android/build.gradle`**

- [ ] Open `android/build.gradle`
- [ ] Find `buildscript > dependencies` section
- [ ] Add: `classpath 'com.google.gms:google-services:4.3.15'`
- [ ] Save file

### **Step 7.2: Update `android/app/build.gradle`**

- [ ] Open `android/app/build.gradle`
- [ ] Find `plugins` section at TOP of file
- [ ] Add: `id "com.google.gms.google-services"`
- [ ] Save file

- [ ] **CHECKPOINT**: Gradle configuration complete ✅

**Time Completed**: _______________

---

## 🧪 Phase 8: Build Testing

### **Step 8.1: Clean Build**

- [ ] Run: `flutter clean`
- [ ] Run: `flutter pub get`

### **Step 8.2: Run Analysis**

- [ ] Run: `flutter analyze`
- [ ] **Expected**: No errors (warnings OK)
- [ ] If errors, check TROUBLESHOOTING_FLUTTER_3.3.0.md

### **Step 8.3: Build APK**

- [ ] Run: `flutter build apk --release`
- [ ] **Expected**: `Built build/app/outputs/flutter-apk/app-release.apk`
- [ ] Note APK size: _____________ MB

- [ ] **CHECKPOINT**: APK builds successfully ✅

**Time Completed**: _______________

---

## 📱 Phase 9: Device Testing

### **Step 9.1: Install APK**

- [ ] Connect Android device via USB
- [ ] Enable USB debugging on device
- [ ] Run: `adb devices` (verify device detected)
- [ ] Run: `adb install build\app\outputs\flutter-apk\app-release.apk`
- [ ] **Expected**: Success message

### **Step 9.2: Launch App**

- [ ] Open app on device
- [ ] **Expected**: App launches without crashes
- [ ] Check logcat for errors: `adb logcat | findstr Flutter`

### **Step 9.3: Test E2EE Features**

**Authentication**:
- [ ] Can create account with email/password
- [ ] Can login successfully
- [ ] Keys generated (check console logs for "✅ Encryption keys ready")

**Messaging**:
- [ ] Can search for another user
- [ ] Can start chat
- [ ] Can send encrypted message
- [ ] Message shows 🔒 lock icon
- [ ] Message bubble is green
- [ ] Can decrypt received message

**Firebase**:
- [ ] Check Firestore: User document has `publicKey` field
- [ ] Check Firestore: User document has `encryptionEnabled: true`

- [ ] **CHECKPOINT**: All E2EE features working ✅

**Time Completed**: _______________

---

## 🔄 Phase 10: Git & GitHub Setup

### **Step 10.1: Initialize Git**

- [ ] Navigate to project root
- [ ] Run: `git init`
- [ ] Create `.gitignore` (copy from GITHUB_SETUP_GUIDE.md)
- [ ] Run: `git add .`
- [ ] Run: `git commit -m "Initial commit: E2EE Chat App - Flutter 3.3.0"`

### **Step 10.2: Create GitHub Repository**

- [ ] Go to: https://github.com/new
- [ ] Repository name: _____________________________________
- [ ] Visibility: [ ] Private (recommended) [ ] Public
- [ ] **DO NOT** initialize with README
- [ ] Click "Create repository"
- [ ] Copy repository URL: _____________________________________

### **Step 10.3: Connect to GitHub**

- [ ] Run: `git remote add origin YOUR_GITHUB_URL`
- [ ] Run: `git branch -M main`
- [ ] Run: `git push -u origin main`
- [ ] **Expected**: Code uploaded to GitHub
- [ ] Verify: Refresh GitHub page, see files

### **Step 10.4: Setup update.bat**

- [ ] Copy `update.bat` to project root
- [ ] Verify location: Same folder as `pubspec.yaml`
- [ ] Test: Double-click `update.bat`
- [ ] **Expected**: Pulls updates and builds APK

- [ ] **CHECKPOINT**: GitHub sync working ✅

**Time Completed**: _______________

---

## 🎉 Phase 11: Final Verification

### **Complete System Test**

- [ ] `flutter --version` shows 3.3.0
- [ ] `git status` shows clean working tree
- [ ] `git pull origin main` works
- [ ] `flutter build apk --release` succeeds
- [ ] APK installs on device
- [ ] App launches without crashes
- [ ] E2EE messages encrypt/decrypt correctly
- [ ] `update.bat` pulls and builds successfully

### **Documentation Check**

- [ ] `MIGRATION_GUIDE_FLUTTER_3.3.0.md` in project
- [ ] `GITHUB_SETUP_GUIDE.md` in project
- [ ] `TROUBLESHOOTING_FLUTTER_3.3.0.md` in project
- [ ] `README_E2EE_FLUTTER_3.3.0.md` in project
- [ ] `update.bat` in project root

### **Backup**

- [ ] Create ZIP of entire project folder
- [ ] Backup filename: _____________________________________
- [ ] Backup location: _____________________________________

---

## ✅ MIGRATION COMPLETE!

**Total Time**: _____________ minutes

**Final Checklist**:
- [x] Fresh Flutter 3.3.0 project created
- [x] All code and assets migrated
- [x] Firebase configured correctly
- [x] APK builds successfully
- [x] E2EE features working
- [x] GitHub integration complete
- [x] update.bat script functional
- [x] Project backed up

---

## 📊 Migration Statistics

**Project Name**: _____________________________________  
**Package Name**: _____________________________________  
**APK Size**: _____________ MB  
**Dependencies**: _____________ packages  
**Build Time**: _____________ seconds  
**GitHub Repo**: _____________________________________  

---

## 🆘 Troubleshooting Reference

**If build fails**, check:
- [ ] TROUBLESHOOTING_FLUTTER_3.3.0.md for your error
- [ ] Package name matches in all 3 Android files
- [ ] NDK 25.1.8937393 installed
- [ ] google-services.json in correct location

**If E2EE fails**, check:
- [ ] KeyManager.initializeKeys() called in auth methods
- [ ] Public keys exist in Firestore users collection
- [ ] flutter_secure_storage permissions in AndroidManifest.xml

**If GitHub fails**, check:
- [ ] Git initialized (`.git` folder exists)
- [ ] Remote URL correct (`git remote -v`)
- [ ] .gitignore excludes google-services.json

---

## 📞 Quick Commands Reference

```cmd
# Build & Test
flutter clean
flutter pub get
flutter analyze
flutter build apk --release
flutter run

# Git Sync
git status
git pull origin main
git add .
git commit -m "message"
git push origin main

# Automated Update
update.bat
```

---

**✨ Congratulations!**  
Your E2EE Chat App is now running on Flutter 3.3.0 with automated GitHub sync! 🎉

**Next Steps**:
1. Test thoroughly on multiple devices
2. Use `update.bat` for daily syncing
3. Add new features to your clean Flutter 3.3.0 project
4. Distribute APK to users

---

**Migration Package Version**: 1.0  
**Prepared for**: User with Flutter 3.3.0 local environment  
**Last Updated**: Current session
