@echo off
setlocal enabledelayedexpansion

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
choice /C YN /M "Do you want to continue"
if errorlevel 2 goto :EOF
echo.

echo ========================================
echo   Step 1: Clean Gradle Cache (Biggest!)
echo ========================================
echo.
set "GRADLE_HOME=%USERPROFILE%\.gradle"
if exist "%GRADLE_HOME%\caches\" (
    echo Found Gradle cache at: %GRADLE_HOME%\caches\
    echo.
    echo Deleting Gradle caches...
    rd /s /q "%GRADLE_HOME%\caches\" 2>nul
    if not exist "%GRADLE_HOME%\caches\" (
        echo ✅ Successfully deleted Gradle caches
    ) else (
        echo ⚠️  Some files may still remain (in use)
    )
) else (
    echo ⚠️  Gradle cache not found
)

if exist "%GRADLE_HOME%\wrapper\dists\" (
    echo.
    echo Deleting Gradle wrapper distributions...
    rd /s /q "%GRADLE_HOME%\wrapper\dists\" 2>nul
    echo ✅ Deleted Gradle wrapper dists
)
echo.
pause

echo ========================================
echo   Step 2: Clean Pub Cache
echo ========================================
echo.
set "PUB_CACHE=%LOCALAPPDATA%\Pub\Cache"
if exist "%PUB_CACHE%\" (
    echo Found Pub cache at: %PUB_CACHE%\
    echo.
    echo Deleting Pub cache...
    rd /s /q "%PUB_CACHE%\" 2>nul
    if not exist "%PUB_CACHE%\" (
        echo ✅ Successfully deleted Pub cache
    ) else (
        echo ⚠️  Some files may still remain (in use)
    )
) else (
    echo ⚠️  Pub cache not found
)
echo.
pause

echo ========================================
echo   Step 3: Clean Android Build Cache
echo ========================================
echo.
set "ANDROID_HOME=%USERPROFILE%\.android\build-cache"
if exist "%ANDROID_HOME%\" (
    echo Found Android cache at: %ANDROID_HOME%\
    echo.
    echo Deleting Android build cache...
    rd /s /q "%ANDROID_HOME%\" 2>nul
    if not exist "%ANDROID_HOME%\" (
        echo ✅ Successfully deleted Android build cache
    ) else (
        echo ⚠️  Some files may still remain (in use)
    )
) else (
    echo ⚠️  Android build cache not found
)
echo.
pause

echo ========================================
echo   Step 4: Clean Flutter Temp Files
echo ========================================
echo.
set "found_temp=0"
for /d %%i in ("%TEMP%\flutter_tools*") do (
    echo Deleting: %%i
    rd /s /q "%%i" 2>nul
    set "found_temp=1"
)
if !found_temp!==1 (
    echo ✅ Deleted Flutter temp files
) else (
    echo ⚠️  Flutter temp files not found
)
echo.
pause

echo ========================================
echo   Step 5: Clean Dart Pub Cache (Alt)
echo ========================================
echo.
set "DART_PUB=%APPDATA%\Pub\Cache"
if exist "%DART_PUB%\" (
    echo Found Dart Pub cache at: %DART_PUB%\
    echo.
    echo Deleting Dart Pub cache...
    rd /s /q "%DART_PUB%\" 2>nul
    if not exist "%DART_PUB%\" (
        echo ✅ Successfully deleted Dart Pub cache
    ) else (
        echo ⚠️  Some files may still remain (in use)
    )
) else (
    echo ⚠️  Dart Pub cache not found
)
echo.
pause

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
echo The caches will be rebuilt automatically.
echo.
pause
