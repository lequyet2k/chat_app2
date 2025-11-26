@echo off
echo ========================================
echo   FIX ALL UNDEFINED ERRORS
echo ========================================
echo.

cd /d "%~dp0"
echo Working in: %CD%
echo.

echo ========================================
echo   STEP 1: DEEP CLEAN
echo ========================================
echo.

echo Cleaning Flutter...
call flutter clean
echo.

echo Deleting cache folders...
if exist ".dart_tool" rmdir /s /q ".dart_tool"
if exist "build" rmdir /s /q "build"
if exist ".flutter-plugins" del /f /q ".flutter-plugins"
if exist ".flutter-plugins-dependencies" del /f /q ".flutter-plugins-dependencies"
if exist "pubspec.lock" del /f /q "pubspec.lock"
if exist "android\build" rmdir /s /q "android\build"
if exist "android\app\build" rmdir /s /q "android\app\build"
if exist "android\.gradle" rmdir /s /q "android\.gradle"
echo Done!
echo.

echo ========================================
echo   STEP 2: REINSTALL DEPENDENCIES
echo ========================================
echo.

echo Running: flutter pub get
call flutter pub get
echo.

echo ========================================
echo   STEP 3: ANALYZE CODE
echo ========================================
echo.

echo Running: flutter analyze
call flutter analyze
echo.

echo ========================================
echo   CRITICAL: RESTART YOUR IDE!
echo ========================================
echo.
echo VSCode:
echo   1. Press Ctrl+Shift+P
echo   2. Type: Reload Window
echo   3. Press Enter
echo.
echo Android Studio:
echo   1. File - Invalidate Caches / Restart
echo   2. Click 'Invalidate and Restart'
echo.
echo After restart, run: flutter run
echo.
pause
