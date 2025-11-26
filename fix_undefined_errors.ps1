# Fix Flutter "Undefined" Errors After Cache Clean
# Run: powershell -ExecutionPolicy Bypass -File fix_undefined_errors.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  FIX FLUTTER UNDEFINED ERRORS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get project path from user
$projectPath = Read-Host "Enter your Flutter project path (e.g., D:\my_flutter_project)"

if (-not (Test-Path $projectPath)) {
    Write-Host "⚠️  Project path not found: $projectPath" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}

Set-Location $projectPath
Write-Host "Working in: $projectPath" -ForegroundColor Green
Write-Host ""

# Step 1: Clean everything
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "Step 1: Deep Clean" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""

Write-Host "Running flutter clean..." -ForegroundColor Cyan
flutter clean 2>&1 | Out-Null
Write-Host "✅ Flutter clean completed" -ForegroundColor Green

Write-Host "Deleting .dart_tool..." -ForegroundColor Cyan
if (Test-Path ".dart_tool") {
    Remove-Item -Path ".dart_tool" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "✅ Deleted .dart_tool" -ForegroundColor Green
}

Write-Host "Deleting build folder..." -ForegroundColor Cyan
if (Test-Path "build") {
    Remove-Item -Path "build" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "✅ Deleted build folder" -ForegroundColor Green
}

Write-Host "Deleting .flutter-plugins-dependencies..." -ForegroundColor Cyan
if (Test-Path ".flutter-plugins-dependencies") {
    Remove-Item -Path ".flutter-plugins-dependencies" -Force -ErrorAction SilentlyContinue
    Write-Host "✅ Deleted .flutter-plugins-dependencies" -ForegroundColor Green
}

Write-Host ""

# Step 2: Delete pubspec.lock
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "Step 2: Reset Dependencies Lock" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""

if (Test-Path "pubspec.lock") {
    Write-Host "Deleting pubspec.lock..." -ForegroundColor Cyan
    Remove-Item -Path "pubspec.lock" -Force -ErrorAction SilentlyContinue
    Write-Host "✅ Deleted pubspec.lock (will be regenerated)" -ForegroundColor Green
} else {
    Write-Host "⚠️  pubspec.lock not found" -ForegroundColor Gray
}

Write-Host ""

# Step 3: Get dependencies
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "Step 3: Reinstall Dependencies" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""

Write-Host "Running flutter pub get..." -ForegroundColor Cyan
$pubGetOutput = flutter pub get 2>&1
Write-Host $pubGetOutput
Write-Host "✅ Dependencies installed" -ForegroundColor Green

Write-Host ""

# Step 4: Run pub upgrade (optional but recommended)
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "Step 4: Upgrade Compatible Packages" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""

$upgrade = Read-Host "Run 'flutter pub upgrade' to update packages? (Y/N)"
if ($upgrade -eq 'Y' -or $upgrade -eq 'y') {
    Write-Host "Running flutter pub upgrade..." -ForegroundColor Cyan
    flutter pub upgrade 2>&1 | Out-Null
    Write-Host "✅ Packages upgraded" -ForegroundColor Green
} else {
    Write-Host "Skipped pub upgrade" -ForegroundColor Gray
}

Write-Host ""

# Step 5: Analyze for errors
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "Step 5: Check for Errors" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""

Write-Host "Running flutter analyze..." -ForegroundColor Cyan
$analyzeOutput = flutter analyze 2>&1
$errors = $analyzeOutput | Select-String -Pattern "error •"
$warnings = $analyzeOutput | Select-String -Pattern "warning •"

if ($errors.Count -gt 0) {
    Write-Host "⚠️  Found $($errors.Count) error(s):" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
} else {
    Write-Host "✅ No errors found!" -ForegroundColor Green
}

if ($warnings.Count -gt 0) {
    Write-Host "⚠️  Found $($warnings.Count) warning(s) (warnings are OK)" -ForegroundColor Yellow
} else {
    Write-Host "✅ No warnings found!" -ForegroundColor Green
}

Write-Host ""

# Step 6: Clean Android build (if exists)
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "Step 6: Clean Android Build" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""

if (Test-Path "android") {
    Write-Host "Cleaning Android build folders..." -ForegroundColor Cyan
    
    if (Test-Path "android\build") {
        Remove-Item -Path "android\build" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "✅ Deleted android\build" -ForegroundColor Green
    }
    
    if (Test-Path "android\app\build") {
        Remove-Item -Path "android\app\build" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "✅ Deleted android\app\build" -ForegroundColor Green
    }
    
    if (Test-Path "android\.gradle") {
        Remove-Item -Path "android\.gradle" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "✅ Deleted android\.gradle" -ForegroundColor Green
    }
} else {
    Write-Host "⚠️  Android folder not found" -ForegroundColor Gray
}

Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Green
Write-Host "  ✅ FIX COMPLETED!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

if ($errors.Count -eq 0) {
    Write-Host "✅ No errors found! Your project is ready." -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. flutter run (to test on emulator/device)"
    Write-Host "  2. flutter build web --release (for web)"
    Write-Host "  3. flutter build apk --release (for Android APK)"
} else {
    Write-Host "⚠️  There are still $($errors.Count) error(s) to fix." -ForegroundColor Red
    Write-Host ""
    Write-Host "Common solutions:" -ForegroundColor Yellow
    Write-Host "  1. Check if all imports are correct"
    Write-Host "  2. Verify pubspec.yaml dependencies"
    Write-Host "  3. Run: flutter doctor -v"
    Write-Host "  4. Restart your IDE (VSCode/Android Studio)"
}

Write-Host ""
Read-Host "Press Enter to exit"
