@echo off
echo ========================================
echo   CLEAN FLUTTER CACHE ON C: DRIVE
echo ========================================
echo.
echo This will clean Flutter caches on C: drive
echo even if your project is on D: or other drives
echo.
echo WILL DELETE:
echo   - Gradle cache (~1-5GB)
echo   - Pub cache (~500MB-2GB)
echo   - Android build tools cache
echo   - Flutter temp files
echo.
echo ⚠️  WARNING: You will need to rebuild your project after this!
echo.
pause

echo.
echo ========================================
echo   Step 1: Clean Gradle Cache (Biggest!)
echo ========================================
echo.
set GRADLE_HOME=%USERPROFILE%\.gradle
if exist "%GRADLE_HOME%\caches\" (
    echo Found Gradle cache at: %GRADLE_HOME%\caches\
    dir "%GRADLE_HOME%\caches\" /s 2>nul | find "File(s)"
    echo.
    echo Deleting Gradle caches...
    rmdir /s /q "%GRADLE_HOME%\caches"
    echo ✅ Deleted Gradle caches
) else (
    echo ⚠️  Gradle cache not found
)

echo.
echo ========================================
echo   Step 2: Clean Pub Cache
echo ========================================
echo.
set PUB_CACHE=%LOCALAPPDATA%\Pub\Cache
if exist "%PUB_CACHE%\" (
    echo Found Pub cache at: %PUB_CACHE%\
    dir "%PUB_CACHE%" /s 2>nul | find "File(s)"
    echo.
    echo Deleting Pub cache...
    rmdir /s /q "%PUB_CACHE%"
    echo ✅ Deleted Pub cache
) else (
    echo ⚠️  Pub cache not found
)

echo.
echo ========================================
echo   Step 3: Clean Android Build Tools Cache
echo ========================================
echo.
set ANDROID_HOME=%USERPROFILE%\.android\build-cache
if exist "%ANDROID_HOME%\" (
    echo Found Android cache at: %ANDROID_HOME%\
    dir "%ANDROID_HOME%" /s 2>nul | find "File(s)"
    echo.
    echo Deleting Android build cache...
    rmdir /s /q "%ANDROID_HOME%"
    echo ✅ Deleted Android build cache
) else (
    echo ⚠️  Android build cache not found
)

echo.
echo ========================================
echo   Step 4: Clean Flutter Temp Files
echo ========================================
echo.
set FLUTTER_TEMP=%TEMP%\flutter_tools*
if exist "%TEMP%\flutter_tools" (
    echo Deleting Flutter temp files...
    rmdir /s /q "%TEMP%\flutter_tools*" 2>nul
    echo ✅ Deleted Flutter temp files
) else (
    echo ⚠️  Flutter temp files not found
)

echo.
echo ========================================
echo   Step 5: Clean Dart Pub Cache
echo ========================================
echo.
set DART_PUB=%APPDATA%\Pub\Cache
if exist "%DART_PUB%\" (
    echo Found Dart Pub cache at: %DART_PUB%\
    dir "%DART_PUB%" /s 2>nul | find "File(s)"
    echo.
    echo Deleting Dart Pub cache...
    rmdir /s /q "%DART_PUB%"
    echo ✅ Deleted Dart Pub cache
) else (
    echo ⚠️  Dart Pub cache not found
)

echo.
echo ========================================
echo   ✅ CLEANUP COMPLETED!
echo ========================================
echo.
echo Estimated space freed: 2GB - 10GB
echo.
echo 📝 NEXT STEPS:
echo   1. Go to your project folder (D:\your_project\)
echo   2. Run: flutter clean
echo   3. Run: flutter pub get
echo   4. Run: flutter build apk --release
echo.
echo The caches will be rebuilt automatically
echo but much cleaner and smaller.
echo.
pause
