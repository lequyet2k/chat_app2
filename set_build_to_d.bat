@echo off
echo ========================================
echo   SET BUILD LOCATIONS TO D: DRIVE
echo ========================================
echo.

REM Create directories on D:
echo Creating directories on D: drive...
if not exist "D:\Temp" mkdir "D:\Temp"
if not exist "D:\gradle_cache" mkdir "D:\gradle_cache"
if not exist "D:\pub_cache" mkdir "D:\pub_cache"
if not exist "D:\android_build_cache" mkdir "D:\android_build_cache"
echo Done!
echo.

REM Set environment variables
echo Setting environment variables...
setx TEMP "D:\Temp"
setx TMP "D:\Temp"
setx GRADLE_USER_HOME "D:\gradle_cache"
setx PUB_CACHE "D:\pub_cache"
echo Done!
echo.

echo ========================================
echo   CONFIGURATION COMPLETED!
echo ========================================
echo.
echo Environment variables set:
echo   TEMP = D:\Temp
echo   TMP = D:\Temp
echo   GRADLE_USER_HOME = D:\gradle_cache
echo   PUB_CACHE = D:\pub_cache
echo.
echo ========================================
echo   RESTART REQUIRED!
echo ========================================
echo.
echo You MUST:
echo   1. Close this terminal
echo   2. Close Android Studio/VSCode
echo   3. Restart your computer (recommended)
echo.
echo After restart:
echo   cd D:\test1\chat_app2
echo   flutter clean
echo   flutter pub get
echo   flutter build apk --debug
echo.
echo All builds will now use D: drive!
echo.
pause
