@echo off
echo ========================================
echo   CLEAN PROJECT BUILD ARTIFACTS
echo ========================================
echo.
echo Run this script IN YOUR PROJECT FOLDER
echo (e.g., D:\my_flutter_app\)
echo.
echo This will delete:
echo   - build\ folder
echo   - .dart_tool\ folder
echo   - android\build\ folders
echo   - android\.gradle\ folder
echo.
pause

cd /d "%~dp0"
echo Current directory: %CD%
echo.

echo [1/5] Cleaning build\ folder...
if exist "build\" (
    rmdir /s /q "build"
    echo ✅ Deleted build\ (~100MB)
) else (
    echo ⚠️  build\ not found
)

echo.
echo [2/5] Cleaning .dart_tool\ folder...
if exist ".dart_tool\" (
    rmdir /s /q ".dart_tool"
    echo ✅ Deleted .dart_tool\ (~200MB)
) else (
    echo ⚠️  .dart_tool\ not found
)

echo.
echo [3/5] Cleaning android\build\ folder...
if exist "android\build\" (
    rmdir /s /q "android\build"
    echo ✅ Deleted android\build\ (~300MB)
) else (
    echo ⚠️  android\build\ not found
)

echo.
echo [4/5] Cleaning android\app\build\ folder...
if exist "android\app\build\" (
    rmdir /s /q "android\app\build"
    echo ✅ Deleted android\app\build\ (~200MB)
) else (
    echo ⚠️  android\app\build\ not found
)

echo.
echo [5/5] Cleaning android\.gradle\ folder...
if exist "android\.gradle\" (
    rmdir /s /q "android\.gradle"
    echo ✅ Deleted android\.gradle\ (~500MB)
) else (
    echo ⚠️  android\.gradle\ not found
)

echo.
echo ========================================
echo   ✅ PROJECT CLEANUP COMPLETED!
echo ========================================
echo.
echo Estimated space freed in project: ~1-2GB
echo.
echo Run 'flutter clean' to ensure complete cleanup.
echo.
pause
