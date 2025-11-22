@echo off
REM ============================================
REM E2EE Chat App - Auto Update & Build Script
REM For Flutter 3.3.0 on Windows
REM ============================================

echo.
echo ============================================
echo 🔄 E2EE Chat App - Update Script
echo ============================================
echo.

REM Check if git repository exists
if not exist ".git" (
    echo ❌ ERROR: Not a git repository!
    echo Please run this script from the project root directory.
    echo.
    pause
    exit /b 1
)

echo Step 1/5: Pulling latest changes from GitHub...
echo --------------------------------------------
git pull origin main
if errorlevel 1 (
    echo.
    echo ❌ ERROR: Git pull failed!
    echo Please check your internet connection and repository access.
    echo.
    pause
    exit /b 1
)
echo ✅ Git pull successful!
echo.

echo Step 2/5: Installing dependencies...
echo --------------------------------------------
flutter pub get
if errorlevel 1 (
    echo.
    echo ❌ ERROR: flutter pub get failed!
    echo Please check your pubspec.yaml for errors.
    echo.
    pause
    exit /b 1
)
echo ✅ Dependencies installed!
echo.

echo Step 3/5: Cleaning build cache...
echo --------------------------------------------
flutter clean
echo ✅ Build cache cleaned!
echo.

echo Step 4/5: Running Flutter analyze...
echo --------------------------------------------
flutter analyze
REM Continue even if analyze shows warnings
echo ℹ️ Analysis complete (warnings are OK for Flutter 3.3.0)
echo.

echo Step 5/5: Building APK...
echo --------------------------------------------
flutter build apk --release
if errorlevel 1 (
    echo.
    echo ❌ ERROR: APK build failed!
    echo Please check the error messages above.
    echo.
    pause
    exit /b 1
)
echo.
echo ============================================
echo ✅ Update Complete!
echo ============================================
echo.
echo 📱 APK Location:
echo build\app\outputs\flutter-apk\app-release.apk
echo.
echo 📊 APK Size:
dir /B build\app\outputs\flutter-apk\app-release.apk 2>nul
for %%A in (build\app\outputs\flutter-apk\app-release.apk) do echo %%~zA bytes
echo.
echo ============================================
echo 🚀 Next Steps:
echo ============================================
echo 1. Transfer APK to your Android device
echo 2. Install and test E2EE features
echo 3. Verify encrypted messages work (🔒 icon)
echo ============================================
echo.
pause
