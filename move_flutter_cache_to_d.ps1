# Move Flutter Cache to D: Drive
# Run as Administrator: powershell -ExecutionPolicy Bypass -File move_flutter_cache_to_d.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  MOVE FLUTTER CACHE TO D: DRIVE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "⚠️  Please run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell → Run as Administrator" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit
}

Write-Host "This script will:" -ForegroundColor Yellow
Write-Host "  1. Create cache folders on D: drive"
Write-Host "  2. Move existing cache from C: to D:"
Write-Host "  3. Set environment variables"
Write-Host "  4. Clean old cache on C: drive"
Write-Host ""

$confirmation = Read-Host "Continue? (Y/N)"
if ($confirmation -ne 'Y' -and $confirmation -ne 'y') {
    Write-Host "Cancelled." -ForegroundColor Yellow
    exit
}

Write-Host ""

# Step 1: Create folders on D:
Write-Host "========================================" -ForegroundColor Green
Write-Host "Step 1: Create Cache Folders on D:" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

$folders = @{
    "D:\gradle_cache" = "Gradle Cache"
    "D:\pub_cache" = "Pub Cache"
    "D:\Android\Sdk" = "Android SDK"
    "D:\flutter_temp" = "Flutter Temp"
}

foreach ($folder in $folders.Keys) {
    if (-not (Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
        Write-Host "✅ Created: $folder ($($folders[$folder]))" -ForegroundColor Green
    } else {
        Write-Host "✓ Already exists: $folder" -ForegroundColor Gray
    }
}

Write-Host ""

# Step 2: Move existing cache
Write-Host "========================================" -ForegroundColor Green
Write-Host "Step 2: Move Existing Cache" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Move Gradle cache
$gradleSource = "$env:USERPROFILE\.gradle"
if (Test-Path $gradleSource) {
    Write-Host "Moving Gradle cache from C: to D:..." -ForegroundColor Cyan
    $size = (Get-ChildItem -Path $gradleSource -Recurse -ErrorAction SilentlyContinue | 
             Measure-Object -Property Length -Sum).Sum
    Write-Host "  Size: $([math]::Round($size / 1GB, 2)) GB" -ForegroundColor Yellow
    
    try {
        Get-ChildItem -Path $gradleSource -ErrorAction SilentlyContinue | ForEach-Object {
            Move-Item -Path $_.FullName -Destination "D:\gradle_cache\" -Force -ErrorAction SilentlyContinue
        }
        Write-Host "  ✅ Moved Gradle cache" -ForegroundColor Green
    } catch {
        Write-Host "  ⚠️  Some files couldn't be moved (in use)" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ⚠️  Gradle cache not found" -ForegroundColor Gray
}

# Move Pub cache
$pubSource = "$env:LOCALAPPDATA\Pub\Cache"
if (Test-Path $pubSource) {
    Write-Host "Moving Pub cache from C: to D:..." -ForegroundColor Cyan
    $size = (Get-ChildItem -Path $pubSource -Recurse -ErrorAction SilentlyContinue | 
             Measure-Object -Property Length -Sum).Sum
    Write-Host "  Size: $([math]::Round($size / 1GB, 2)) GB" -ForegroundColor Yellow
    
    try {
        Get-ChildItem -Path $pubSource -ErrorAction SilentlyContinue | ForEach-Object {
            Move-Item -Path $_.FullName -Destination "D:\pub_cache\" -Force -ErrorAction SilentlyContinue
        }
        Write-Host "  ✅ Moved Pub cache" -ForegroundColor Green
    } catch {
        Write-Host "  ⚠️  Some files couldn't be moved (in use)" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ⚠️  Pub cache not found" -ForegroundColor Gray
}

Write-Host ""

# Step 3: Set environment variables
Write-Host "========================================" -ForegroundColor Green
Write-Host "Step 3: Set Environment Variables" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

$envVars = @{
    "GRADLE_USER_HOME" = "D:\gradle_cache"
    "PUB_CACHE" = "D:\pub_cache"
    "ANDROID_HOME" = "D:\Android\Sdk"
    "ANDROID_SDK_ROOT" = "D:\Android\Sdk"
    "TEMP" = "D:\flutter_temp"
    "TMP" = "D:\flutter_temp"
}

foreach ($varName in $envVars.Keys) {
    try {
        [System.Environment]::SetEnvironmentVariable($varName, $envVars[$varName], 'User')
        Write-Host "✅ Set $varName = $($envVars[$varName])" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  Failed to set $varName" -ForegroundColor Red
    }
}

Write-Host ""

# Step 4: Clean old cache on C:
Write-Host "========================================" -ForegroundColor Green
Write-Host "Step 4: Clean Old Cache on C:" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

$confirmation = Read-Host "Delete old cache on C: drive? (Y/N)"
if ($confirmation -eq 'Y' -or $confirmation -eq 'y') {
    if (Test-Path $gradleSource) {
        Remove-Item -Path $gradleSource -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "✅ Deleted old Gradle cache on C:" -ForegroundColor Green
    }
    
    if (Test-Path $pubSource) {
        Remove-Item -Path $pubSource -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "✅ Deleted old Pub cache on C:" -ForegroundColor Green
    }
    
    $androidCache = "$env:USERPROFILE\.android\build-cache"
    if (Test-Path $androidCache) {
        Remove-Item -Path $androidCache -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "✅ Deleted Android build cache on C:" -ForegroundColor Green
    }
} else {
    Write-Host "Skipped cleaning C: drive" -ForegroundColor Yellow
}

Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ✅ MIGRATION COMPLETED!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Flutter cache has been moved to D: drive!" -ForegroundColor Green
Write-Host ""
Write-Host "Cache locations:" -ForegroundColor Yellow
Write-Host "  - Gradle: D:\gradle_cache"
Write-Host "  - Pub: D:\pub_cache"
Write-Host "  - Android SDK: D:\Android\Sdk"
Write-Host ""
Write-Host "⚠️  IMPORTANT: RESTART REQUIRED!" -ForegroundColor Red
Write-Host "  1. Close all terminals/PowerShell/CMD"
Write-Host "  2. Close VSCode/Android Studio"
Write-Host "  3. Restart your computer (recommended)"
Write-Host ""
Write-Host "After restart, run:" -ForegroundColor Yellow
Write-Host "  cd D:\your_flutter_project"
Write-Host "  flutter clean"
Write-Host "  flutter pub get"
Write-Host "  flutter build apk --release"
Write-Host ""
Write-Host "Future builds will use D: drive! 🎉" -ForegroundColor Green
Write-Host ""

Read-Host "Press Enter to exit"
