@echo off
echo ========================================
echo   DEEP FIX FLUTTER PROJECT
echo ========================================
echo.

cd /d "%~dp0"
echo Working in: %CD%
echo.

echo Step 1: Flutter Clean
flutter clean
echo.

echo Step 2: Delete Cache Folders
if exist ".dart_tool" rmdir /s /q ".dart_tool"
if exist "build" rmdir /s /q "build"
if exist ".flutter-plugins-dependencies" del /f /q ".flutter-plugins-dependencies"
if exist "pubspec.lock" del /f /q "pubspec.lock"
echo.

echo Step 3: Clean Android Build
if exist "android\build" rmdir /s /q "android\build"
if exist "android\app\build" rmdir /s /q "android\app\build"
if exist "android\.gradle" rmdir /s /q "android\.gradle"
echo.

echo Step 4: Reinstall Dependencies
flutter pub get
echo.

echo Step 5: Analyze Code
flutter analyze
echo.

echo ========================================
echo   FIX COMPLETED
echo ========================================
echo.
echo Try running: flutter run
echo.
pause
