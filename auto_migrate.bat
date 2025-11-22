@echo off
REM ============================================
REM Auto Migration Script - Flutter 3.3.0
REM Tự động migrate project từ Flutter 3.35.4 sang 3.3.0
REM ============================================

echo.
echo ============================================
echo 🔄 AUTO MIGRATION SCRIPT
echo ============================================
echo.
echo Script này sẽ tự động:
echo 1. Tạo project Flutter 3.3.0 mới
echo 2. Copy code, assets, config
echo 3. Cập nhật Android configuration
echo 4. Build APK
echo.
echo ⚠️  CHÚ Ý:
echo - Cần chạy script này từ thư mục PROJECT CŨ
echo - Đảm bảo Flutter 3.3.0 đã được cài đặt
echo - Project mới sẽ được tạo ở thư mục cha
echo.
pause

REM ============================================
REM Bước 1: Kiểm tra môi trường
REM ============================================
echo.
echo ============================================
echo Bước 1/7: Kiểm tra môi trường
echo ============================================

REM Lấy thư mục hiện tại (project cũ)
set "OLD_PROJECT_DIR=%CD%"
echo 📁 Project cũ: %OLD_PROJECT_DIR%

REM Kiểm tra Flutter
flutter --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Flutter chưa được cài đặt hoặc không có trong PATH
    echo Vui lòng cài đặt Flutter 3.3.0
    pause
    exit /b 1
)

REM Kiểm tra Flutter version
echo 🔍 Đang kiểm tra Flutter version...
flutter --version | findstr "3.3.0" >nul
if errorlevel 1 (
    echo.
    echo ⚠️  CẢNH BÁO: Có thể bạn không dùng Flutter 3.3.0
    echo Current Flutter version:
    flutter --version | findstr "Flutter"
    echo.
    echo Để migration hoạt động đúng, bạn cần Flutter 3.3.0
    echo Bạn có muốn tiếp tục không? (y/n)
    set /p continue=
    if /i not "%continue%"=="y" exit /b 1
)

echo ✅ Flutter đã sẵn sàng
echo.

REM ============================================
REM Bước 2: Kiểm tra files cần thiết
REM ============================================
echo ============================================
echo Bước 2/7: Kiểm tra files cần thiết
echo ============================================

if not exist "pubspec.yaml" (
    echo ❌ Không tìm thấy pubspec.yaml
    echo Vui lòng chạy script từ thư mục project!
    pause
    exit /b 1
)

if not exist "lib\main.dart" (
    echo ❌ Không tìm thấy lib\main.dart
    pause
    exit /b 1
)

if not exist "android\app\google-services.json" (
    echo ⚠️  CẢNH BÁO: Không tìm thấy google-services.json
    echo Firebase có thể không hoạt động!
    set "HAS_FIREBASE=false"
) else (
    echo ✅ Tìm thấy google-services.json
    set "HAS_FIREBASE=true"
)

echo ✅ Các files cần thiết đã sẵn sàng
echo.

REM ============================================
REM Bước 3: Extract package name từ google-services.json
REM ============================================
echo ============================================
echo Bước 3/7: Lấy package name
echo ============================================

if "%HAS_FIREBASE%"=="true" (
    REM Đọc package name từ google-services.json
    for /f "tokens=2 delims=:," %%a in ('findstr "package_name" android\app\google-services.json') do (
        set "PACKAGE_NAME=%%a"
    )
    REM Xóa khoảng trắng và dấu ngoặc kép
    set "PACKAGE_NAME=%PACKAGE_NAME:"=%"
    set "PACKAGE_NAME=%PACKAGE_NAME: =%"
    echo 📦 Package name: %PACKAGE_NAME%
) else (
    set "PACKAGE_NAME=com.example.chat_app_migrated"
    echo 📦 Package name mặc định: %PACKAGE_NAME%
)
echo.

REM ============================================
REM Bước 4: Tạo project mới
REM ============================================
echo ============================================
echo Bước 4/7: Tạo project Flutter 3.3.0 mới
echo ============================================

REM Lên thư mục cha
cd ..
set "PARENT_DIR=%CD%"

REM Tên project mới
set "NEW_PROJECT_NAME=chat_app_e2ee_migrated"
set "NEW_PROJECT_DIR=%PARENT_DIR%\%NEW_PROJECT_NAME%"

echo 📁 Project mới sẽ được tạo tại: %NEW_PROJECT_DIR%
echo.

REM Kiểm tra nếu project đã tồn tại
if exist "%NEW_PROJECT_DIR%" (
    echo ⚠️  Project mới đã tồn tại!
    echo Bạn có muốn XÓA và tạo lại không? (y/n)
    set /p recreate=
    if /i "%recreate%"=="y" (
        echo Đang xóa project cũ...
        rmdir /S /Q "%NEW_PROJECT_DIR%"
    ) else (
        echo ❌ Hủy migration
        cd "%OLD_PROJECT_DIR%"
        pause
        exit /b 1
    )
)

echo 🔨 Đang tạo project mới với Flutter 3.3.0...
flutter create -t app "%NEW_PROJECT_NAME%"
if errorlevel 1 (
    echo ❌ Lỗi khi tạo project!
    cd "%OLD_PROJECT_DIR%"
    pause
    exit /b 1
)

echo ✅ Project mới đã được tạo
echo.

REM ============================================
REM Bước 5: Copy files
REM ============================================
echo ============================================
echo Bước 5/7: Copy code và assets
echo ============================================

echo 📂 Copy thư mục lib...
xcopy /E /I /Y "%OLD_PROJECT_DIR%\lib" "%NEW_PROJECT_DIR%\lib"

echo 📂 Copy pubspec.yaml...
copy /Y "%OLD_PROJECT_DIR%\pubspec.yaml" "%NEW_PROJECT_DIR%\pubspec.yaml"

REM Copy assets nếu có
if exist "%OLD_PROJECT_DIR%\assets" (
    echo 📂 Copy thư mục assets...
    xcopy /E /I /Y "%OLD_PROJECT_DIR%\assets" "%NEW_PROJECT_DIR%\assets"
)

REM Copy google-services.json nếu có
if "%HAS_FIREBASE%"=="true" (
    echo 📂 Copy google-services.json...
    copy /Y "%OLD_PROJECT_DIR%\android\app\google-services.json" "%NEW_PROJECT_DIR%\android\app\google-services.json"
)

echo ✅ Files đã được copy
echo.

REM ============================================
REM Bước 6: Cấu hình Android
REM ============================================
echo ============================================
echo Bước 6/7: Cấu hình Android
echo ============================================

cd "%NEW_PROJECT_DIR%"

echo 🔧 Đang cài đặt dependencies...
call flutter pub get
if errorlevel 1 (
    echo ❌ Lỗi khi cài đặt dependencies!
    pause
    exit /b 1
)

echo.
echo 📝 Cần cập nhật thủ công các file Android:
echo.
echo 1. android/app/build.gradle:
echo    - Đổi applicationId thành: %PACKAGE_NAME%
echo    - Thêm: ndkVersion "25.1.8937393"
echo    - Thêm: multiDexEnabled true
echo    - Thêm dependency: implementation 'androidx.multidex:multidex:2.0.1'
echo.
echo 2. android/build.gradle:
echo    - Thêm: classpath 'com.google.gms:google-services:4.3.15'
echo.
echo 3. android/app/build.gradle (plugins):
echo    - Thêm: id "com.google.gms.google-services"
echo.
echo 4. android/app/src/main/AndroidManifest.xml:
echo    - Đổi package thành: %PACKAGE_NAME%
echo.
echo 5. MainActivity.kt:
echo    - Đổi package thành: %PACKAGE_NAME%
echo    - Di chuyển file vào đúng thư mục theo package name
echo.
echo ⚠️  Các file này CẦN SỬA THỦ CÔNG vì mỗi project có cấu hình khác nhau
echo.
echo 📖 Xem chi tiết trong MIGRATION_GUIDE_FLUTTER_3.3.0.md
echo.
echo Bạn đã sửa xong các file Android chưa? (y/n)
set /p android_done=
if /i not "%android_done%"=="y" (
    echo.
    echo 💡 Hãy sửa các file Android theo hướng dẫn, sau đó chạy lại:
    echo    cd %NEW_PROJECT_DIR%
    echo    flutter clean
    echo    flutter pub get
    echo    flutter build apk --release
    echo.
    pause
    exit /b 0
)

echo.

REM ============================================
REM Bước 7: Build APK
REM ============================================
echo ============================================
echo Bước 7/7: Build APK
echo ============================================

echo 🧹 Cleaning build cache...
call flutter clean

echo 📦 Installing dependencies...
call flutter pub get

echo 🔨 Building APK release...
call flutter build apk --release

if errorlevel 1 (
    echo.
    echo ❌ Build thất bại!
    echo.
    echo 🔍 Các bước kiểm tra:
    echo 1. Đảm bảo đã sửa đúng package name trong 3 file Android
    echo 2. Đảm bảo đã thêm NDK version
    echo 3. Đảm bảo đã thêm MultiDex support
    echo 4. Xem chi tiết lỗi ở trên
    echo.
    echo 📖 Xem TROUBLESHOOTING_FLUTTER_3.3.0.md để biết thêm chi tiết
    echo.
    pause
    exit /b 1
)

echo.
echo ============================================
echo ✅ MIGRATION HOÀN TẤT!
echo ============================================
echo.
echo 📱 APK đã được build tại:
echo    %NEW_PROJECT_DIR%\build\app\outputs\flutter-apk\app-release.apk
echo.
echo 📊 Thông tin project mới:
echo    📁 Thư mục: %NEW_PROJECT_DIR%
echo    📦 Package: %PACKAGE_NAME%
echo    🔨 Flutter: 3.3.0
echo.
echo 🎯 Các bước tiếp theo:
echo    1. Test APK trên thiết bị Android
echo    2. Kiểm tra tính năng E2EE (icon 🔒)
echo    3. Setup Git cho project mới (xem GITHUB_SETUP_GUIDE.md)
echo    4. Copy update.bat vào project mới
echo.
echo ============================================
echo.
pause
