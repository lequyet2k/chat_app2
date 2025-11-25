# PowerShell Script to Clean Flutter Cache on C: Drive
# Run as: powershell -ExecutionPolicy Bypass -File clean_c_drive_flutter_powershell.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  CLEAN FLUTTER CACHE ON C: DRIVE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This will clean Flutter caches on C: drive" -ForegroundColor Yellow
Write-Host "even if your project is on D: or other drives" -ForegroundColor Yellow
Write-Host ""
Write-Host "WILL DELETE:" -ForegroundColor Red
Write-Host "  - Gradle cache (~1-5GB)"
Write-Host "  - Pub cache (~500MB-2GB)"
Write-Host "  - Android build tools cache"
Write-Host "  - Flutter temp files"
Write-Host ""
Write-Host "⚠️  WARNING: You will need to rebuild your project after this!" -ForegroundColor Red
Write-Host ""

$confirmation = Read-Host "Do you want to continue? (Y/N)"
if ($confirmation -ne 'Y' -and $confirmation -ne 'y') {
    Write-Host "Cancelled by user." -ForegroundColor Yellow
    exit
}

Write-Host ""

# Function to delete folder with error handling
function Remove-FolderSafely {
    param (
        [string]$Path,
        [string]$Name
    )
    
    if (Test-Path $Path) {
        Write-Host "Found $Name at: $Path" -ForegroundColor Green
        
        # Calculate size before deletion
        $size = (Get-ChildItem -Path $Path -Recurse -ErrorAction SilentlyContinue | 
                 Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
        
        if ($size -gt 1GB) {
            Write-Host "Size: {0:N2} GB" -f ($size / 1GB) -ForegroundColor Yellow
        } elseif ($size -gt 1MB) {
            Write-Host "Size: {0:N2} MB" -f ($size / 1MB) -ForegroundColor Yellow
        }
        
        Write-Host "Deleting..." -ForegroundColor Cyan
        
        try {
            Remove-Item -Path $Path -Recurse -Force -ErrorAction Stop
            Write-Host "✅ Successfully deleted $Name" -ForegroundColor Green
        } catch {
            Write-Host "⚠️  Error deleting $Name : $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "Some files may be in use. Try closing Android Studio, VSCode, etc." -ForegroundColor Yellow
        }
    } else {
        Write-Host "⚠️  $Name not found at: $Path" -ForegroundColor Gray
    }
    Write-Host ""
}

# 1. Clean Gradle Cache
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Step 1: Clean Gradle Cache (Biggest!)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$gradleCaches = "$env:USERPROFILE\.gradle\caches"
Remove-FolderSafely -Path $gradleCaches -Name "Gradle caches"

$gradleWrapper = "$env:USERPROFILE\.gradle\wrapper\dists"
Remove-FolderSafely -Path $gradleWrapper -Name "Gradle wrapper"

Read-Host "Press Enter to continue"

# 2. Clean Pub Cache
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Step 2: Clean Pub Cache" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$pubCache = "$env:LOCALAPPDATA\Pub\Cache"
Remove-FolderSafely -Path $pubCache -Name "Pub cache"

Read-Host "Press Enter to continue"

# 3. Clean Android Build Cache
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Step 3: Clean Android Build Cache" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$androidCache = "$env:USERPROFILE\.android\build-cache"
Remove-FolderSafely -Path $androidCache -Name "Android build cache"

Read-Host "Press Enter to continue"

# 4. Clean Flutter Temp Files
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Step 4: Clean Flutter Temp Files" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$flutterTempFolders = Get-ChildItem -Path $env:TEMP -Filter "flutter_tools*" -Directory -ErrorAction SilentlyContinue

if ($flutterTempFolders) {
    foreach ($folder in $flutterTempFolders) {
        Write-Host "Deleting: $($folder.FullName)" -ForegroundColor Cyan
        try {
            Remove-Item -Path $folder.FullName -Recurse -Force -ErrorAction Stop
            Write-Host "✅ Deleted $($folder.Name)" -ForegroundColor Green
        } catch {
            Write-Host "⚠️  Error deleting: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
} else {
    Write-Host "⚠️  Flutter temp files not found" -ForegroundColor Gray
}
Write-Host ""

Read-Host "Press Enter to continue"

# 5. Clean Dart Pub Cache (Alternative location)
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Step 5: Clean Dart Pub Cache" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$dartPub = "$env:APPDATA\Pub\Cache"
Remove-FolderSafely -Path $dartPub -Name "Dart Pub cache"

# Summary
Write-Host "========================================" -ForegroundColor Green
Write-Host "✅ CLEANUP COMPLETED!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Estimated space freed: 2GB - 10GB" -ForegroundColor Cyan
Write-Host ""
Write-Host "📝 NEXT STEPS:" -ForegroundColor Yellow
Write-Host "  1. Go to your project folder (D:\your_project\)"
Write-Host "  2. Run: flutter clean"
Write-Host "  3. Run: flutter pub get"
Write-Host "  4. Run: flutter build apk --release"
Write-Host ""
Write-Host "The caches will be rebuilt automatically." -ForegroundColor Green
Write-Host ""

Read-Host "Press Enter to exit"
