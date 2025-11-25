@echo off
echo ========================================
echo   CHECK FLUTTER CACHE SIZES
echo ========================================
echo.
echo Your USERPROFILE: %USERPROFILE%
echo Your LOCALAPPDATA: %LOCALAPPDATA%
echo Your APPDATA: %APPDATA%
echo Your TEMP: %TEMP%
echo.
pause
echo.

echo ========================================
echo   1. GRADLE CACHE (Usually Biggest!)
echo ========================================
echo Location: %USERPROFILE%\.gradle\
echo.
if exist "%USERPROFILE%\.gradle\" (
    echo ✅ Found Gradle cache folder
    echo Calculating size... (this may take a moment)
    dir "%USERPROFILE%\.gradle" /s /a 2>nul | find "File(s)"
    echo.
    echo Detailed breakdown:
    if exist "%USERPROFILE%\.gradle\caches\" (
        echo   - caches\ folder:
        dir "%USERPROFILE%\.gradle\caches" /s /a 2>nul | find "File(s)"
    )
    if exist "%USERPROFILE%\.gradle\wrapper\" (
        echo   - wrapper\ folder:
        dir "%USERPROFILE%\.gradle\wrapper" /s /a 2>nul | find "File(s)"
    )
) else (
    echo ⚠️  Gradle cache NOT FOUND
)
echo.
pause

echo ========================================
echo   2. PUB CACHE (Flutter Packages)
echo ========================================
echo Location: %LOCALAPPDATA%\Pub\Cache\
echo.
if exist "%LOCALAPPDATA%\Pub\Cache\" (
    echo ✅ Found Pub cache folder
    echo Calculating size...
    dir "%LOCALAPPDATA%\Pub\Cache" /s /a 2>nul | find "File(s)"
    echo.
    echo Detailed breakdown:
    if exist "%LOCALAPPDATA%\Pub\Cache\hosted\" (
        echo   - hosted\ (pub.dev packages):
        dir "%LOCALAPPDATA%\Pub\Cache\hosted" /s /a 2>nul | find "File(s)"
    )
    if exist "%LOCALAPPDATA%\Pub\Cache\git\" (
        echo   - git\ (git packages):
        dir "%LOCALAPPDATA%\Pub\Cache\git" /s /a 2>nul | find "File(s)"
    )
) else (
    echo ⚠️  Pub cache NOT FOUND
)
echo.
pause

echo ========================================
echo   3. ANDROID BUILD CACHE
echo ========================================
echo Location: %USERPROFILE%\.android\
echo.
if exist "%USERPROFILE%\.android\" (
    echo ✅ Found Android cache folder
    echo Calculating size...
    dir "%USERPROFILE%\.android" /s /a 2>nul | find "File(s)"
    echo.
    if exist "%USERPROFILE%\.android\build-cache\" (
        echo   - build-cache\ folder:
        dir "%USERPROFILE%\.android\build-cache" /s /a 2>nul | find "File(s)"
    )
) else (
    echo ⚠️  Android cache NOT FOUND
)
echo.
pause

echo ========================================
echo   4. DART PUB CACHE (Alternative Location)
echo ========================================
echo Location: %APPDATA%\Pub\Cache\
echo.
if exist "%APPDATA%\Pub\Cache\" (
    echo ✅ Found Dart Pub cache folder
    echo Calculating size...
    dir "%APPDATA%\Pub\Cache" /s /a 2>nul | find "File(s)"
) else (
    echo ⚠️  Dart Pub cache NOT FOUND
)
echo.
pause

echo ========================================
echo   5. FLUTTER TEMP FILES
echo ========================================
echo Location: %TEMP%\flutter*
echo.
if exist "%TEMP%\flutter_tools*" (
    echo ✅ Found Flutter temp files
    dir "%TEMP%\flutter_tools*" /s /a 2>nul | find "File(s)"
) else (
    echo ⚠️  Flutter temp files NOT FOUND
)
echo.
pause

echo ========================================
echo   6. ANDROID SDK (If Installed)
echo ========================================
echo Common locations:
echo   - %LOCALAPPDATA%\Android\Sdk\
echo   - %USERPROFILE%\AppData\Local\Android\Sdk\
echo.
if exist "%LOCALAPPDATA%\Android\Sdk\" (
    echo ✅ Found Android SDK
    echo Location: %LOCALAPPDATA%\Android\Sdk\
    echo Calculating size... (this may take a while)
    dir "%LOCALAPPDATA%\Android\Sdk" /s /a 2>nul | find "File(s)"
    echo.
    echo SDK Components:
    dir "%LOCALAPPDATA%\Android\Sdk" /b 2>nul
) else (
    echo ⚠️  Android SDK NOT FOUND in default location
)
echo.
pause

echo ========================================
echo   7. FLUTTER SDK (If Installed on C:)
echo ========================================
echo Common locations:
echo   - C:\src\flutter\
echo   - %USERPROFILE%\flutter\
echo   - C:\flutter\
echo.
set FOUND_FLUTTER=0
if exist "C:\src\flutter\" (
    echo ✅ Found Flutter SDK at: C:\src\flutter\
    dir "C:\src\flutter" /s /a 2>nul | find "File(s)"
    set FOUND_FLUTTER=1
)
if exist "%USERPROFILE%\flutter\" (
    echo ✅ Found Flutter SDK at: %USERPROFILE%\flutter\
    dir "%USERPROFILE%\flutter" /s /a 2>nul | find "File(s)"
    set FOUND_FLUTTER=1
)
if exist "C:\flutter\" (
    echo ✅ Found Flutter SDK at: C:\flutter\
    dir "C:\flutter" /s /a 2>nul | find "File(s)"
    set FOUND_FLUTTER=1
)
if %FOUND_FLUTTER%==0 (
    echo ⚠️  Flutter SDK NOT FOUND on C: drive
)
echo.
pause

echo ========================================
echo   SUMMARY - RECOMMENDED ACTIONS
echo ========================================
echo.
echo Based on findings above, you can delete:
echo.
echo 🔥 SAFE TO DELETE (Rebuild automatically):
echo   1. %USERPROFILE%\.gradle\caches\        (Usually BIGGEST!)
echo   2. %LOCALAPPDATA%\Pub\Cache\            (Can be large)
echo   3. %USERPROFILE%\.android\build-cache\  (Temporary)
echo   4. %TEMP%\flutter_tools*                (Temporary)
echo.
echo ⚠️  CAREFUL (Only if needed):
echo   5. Android SDK old build-tools versions
echo   6. Unused Flutter SDK versions
echo.
echo ❌ DO NOT DELETE:
echo   - Flutter SDK main installation
echo   - Android SDK (unless reinstalling)
echo   - Your project files!
echo.
echo To clean, run: clean_c_drive_flutter.bat
echo.
pause

echo ========================================
echo   DISK SPACE CHECK
echo ========================================
echo.
echo C: Drive Free Space:
wmic logicaldisk where "DeviceID='C:'" get FreeSpace,Size /format:list 2>nul
echo.
pause
