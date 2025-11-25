# PowerShell Script to Check Flutter Cache Sizes
# Run as: powershell -ExecutionPolicy Bypass -File check_flutter_cache.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   FLUTTER CACHE SIZE CHECKER" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Function to get folder size in human-readable format
function Get-FolderSize {
    param (
        [string]$Path
    )
    
    if (Test-Path $Path) {
        $size = (Get-ChildItem -Path $Path -Recurse -ErrorAction SilentlyContinue | 
                 Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
        
        if ($size -eq $null) { $size = 0 }
        
        # Convert to human readable
        if ($size -gt 1GB) {
            return "{0:N2} GB" -f ($size / 1GB)
        } elseif ($size -gt 1MB) {
            return "{0:N2} MB" -f ($size / 1MB)
        } elseif ($size -gt 1KB) {
            return "{0:N2} KB" -f ($size / 1KB)
        } else {
            return "$size Bytes"
        }
    } else {
        return "NOT FOUND"
    }
}

# Environment paths
$userProfile = $env:USERPROFILE
$localAppData = $env:LOCALAPPDATA
$appData = $env:APPDATA
$temp = $env:TEMP

Write-Host "User Profile: $userProfile" -ForegroundColor Yellow
Write-Host ""

# 1. Gradle Cache
Write-Host "========================================" -ForegroundColor Green
Write-Host "1. GRADLE CACHE (Usually Biggest!)" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
$gradlePath = "$userProfile\.gradle"
$gradleCachesPath = "$userProfile\.gradle\caches"
$gradleWrapperPath = "$userProfile\.gradle\wrapper"

Write-Host "Location: $gradlePath"
Write-Host "Total Size: " -NoNewline
Write-Host (Get-FolderSize $gradlePath) -ForegroundColor Red
if (Test-Path $gradleCachesPath) {
    Write-Host "  - caches: " -NoNewline
    Write-Host (Get-FolderSize $gradleCachesPath) -ForegroundColor Yellow
}
if (Test-Path $gradleWrapperPath) {
    Write-Host "  - wrapper: " -NoNewline
    Write-Host (Get-FolderSize $gradleWrapperPath) -ForegroundColor Yellow
}
Write-Host ""

# 2. Pub Cache
Write-Host "========================================" -ForegroundColor Green
Write-Host "2. PUB CACHE (Flutter Packages)" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
$pubCachePath = "$localAppData\Pub\Cache"
$pubHostedPath = "$localAppData\Pub\Cache\hosted"
$pubGitPath = "$localAppData\Pub\Cache\git"

Write-Host "Location: $pubCachePath"
Write-Host "Total Size: " -NoNewline
Write-Host (Get-FolderSize $pubCachePath) -ForegroundColor Red
if (Test-Path $pubHostedPath) {
    Write-Host "  - hosted (pub.dev): " -NoNewline
    Write-Host (Get-FolderSize $pubHostedPath) -ForegroundColor Yellow
}
if (Test-Path $pubGitPath) {
    Write-Host "  - git packages: " -NoNewline
    Write-Host (Get-FolderSize $pubGitPath) -ForegroundColor Yellow
}
Write-Host ""

# 3. Android Build Cache
Write-Host "========================================" -ForegroundColor Green
Write-Host "3. ANDROID BUILD CACHE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
$androidCachePath = "$userProfile\.android"
$androidBuildCachePath = "$userProfile\.android\build-cache"

Write-Host "Location: $androidCachePath"
Write-Host "Total Size: " -NoNewline
Write-Host (Get-FolderSize $androidCachePath) -ForegroundColor Red
if (Test-Path $androidBuildCachePath) {
    Write-Host "  - build-cache: " -NoNewline
    Write-Host (Get-FolderSize $androidBuildCachePath) -ForegroundColor Yellow
}
Write-Host ""

# 4. Dart Pub Cache (Alternative)
Write-Host "========================================" -ForegroundColor Green
Write-Host "4. DART PUB CACHE (Alternative Location)" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
$dartPubPath = "$appData\Pub\Cache"

Write-Host "Location: $dartPubPath"
Write-Host "Total Size: " -NoNewline
Write-Host (Get-FolderSize $dartPubPath) -ForegroundColor Red
Write-Host ""

# 5. Flutter Temp Files
Write-Host "========================================" -ForegroundColor Green
Write-Host "5. FLUTTER TEMP FILES" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
$flutterTempPath = "$temp\flutter_tools*"

Write-Host "Location: $temp\flutter_tools*"
$flutterTempFolders = Get-ChildItem -Path $temp -Filter "flutter_tools*" -Directory -ErrorAction SilentlyContinue
if ($flutterTempFolders) {
    $totalTempSize = 0
    foreach ($folder in $flutterTempFolders) {
        $size = (Get-ChildItem -Path $folder.FullName -Recurse -ErrorAction SilentlyContinue | 
                 Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
        if ($size) { $totalTempSize += $size }
    }
    if ($totalTempSize -gt 1MB) {
        Write-Host "Total Size: {0:N2} MB" -f ($totalTempSize / 1MB) -ForegroundColor Yellow
    } else {
        Write-Host "Total Size: {0:N2} KB" -f ($totalTempSize / 1KB) -ForegroundColor Yellow
    }
} else {
    Write-Host "NOT FOUND" -ForegroundColor Gray
}
Write-Host ""

# 6. Android SDK
Write-Host "========================================" -ForegroundColor Green
Write-Host "6. ANDROID SDK" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
$androidSdkPath = "$localAppData\Android\Sdk"

Write-Host "Location: $androidSdkPath"
Write-Host "Total Size: " -NoNewline
Write-Host (Get-FolderSize $androidSdkPath) -ForegroundColor Red
if (Test-Path $androidSdkPath) {
    Write-Host "  Components:"
    Get-ChildItem -Path $androidSdkPath -Directory | ForEach-Object {
        Write-Host "    - $($_.Name): " -NoNewline
        Write-Host (Get-FolderSize $_.FullName) -ForegroundColor Yellow
    }
}
Write-Host ""

# 7. Flutter SDK on C:
Write-Host "========================================" -ForegroundColor Green
Write-Host "7. FLUTTER SDK (on C: drive)" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
$flutterLocations = @(
    "C:\src\flutter",
    "$userProfile\flutter",
    "C:\flutter"
)

$foundFlutter = $false
foreach ($location in $flutterLocations) {
    if (Test-Path $location) {
        Write-Host "Found at: $location"
        Write-Host "Size: " -NoNewline
        Write-Host (Get-FolderSize $location) -ForegroundColor Red
        $foundFlutter = $true
    }
}
if (-not $foundFlutter) {
    Write-Host "NOT FOUND on C: drive" -ForegroundColor Gray
}
Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   SUMMARY - TOTAL CACHE SIZE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$totalSize = 0
$paths = @{
    "Gradle Cache" = $gradlePath
    "Pub Cache" = $pubCachePath
    "Android Cache" = $androidCachePath
    "Dart Pub Cache" = $dartPubPath
}

foreach ($name in $paths.Keys) {
    $path = $paths[$name]
    if (Test-Path $path) {
        $size = (Get-ChildItem -Path $path -Recurse -ErrorAction SilentlyContinue | 
                 Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
        if ($size) { 
            $totalSize += $size
            Write-Host "$name : " -NoNewline
            if ($size -gt 1GB) {
                Write-Host ("{0:N2} GB" -f ($size / 1GB)) -ForegroundColor Red
            } else {
                Write-Host ("{0:N2} MB" -f ($size / 1MB)) -ForegroundColor Yellow
            }
        }
    }
}

Write-Host ""
Write-Host "TOTAL CACHE SIZE: " -NoNewline -ForegroundColor Cyan
if ($totalSize -gt 1GB) {
    Write-Host ("{0:N2} GB" -f ($totalSize / 1GB)) -ForegroundColor Red -BackgroundColor Black
} else {
    Write-Host ("{0:N2} MB" -f ($totalSize / 1MB)) -ForegroundColor Red -BackgroundColor Black
}
Write-Host ""

# Disk Space
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   C: DRIVE SPACE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
$drive = Get-PSDrive C
$freeSpace = $drive.Free / 1GB
$usedSpace = $drive.Used / 1GB
$totalSpace = ($drive.Free + $drive.Used) / 1GB

Write-Host "Total Space: {0:N2} GB" -f $totalSpace
Write-Host "Used Space:  {0:N2} GB" -f $usedSpace -ForegroundColor Red
Write-Host "Free Space:  {0:N2} GB" -f $freeSpace -ForegroundColor Green
Write-Host ""

# Recommendations
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "   RECOMMENDATIONS" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "🔥 SAFE TO DELETE:" -ForegroundColor Green
Write-Host "  1. $gradleCachesPath"
Write-Host "  2. $pubCachePath"
Write-Host "  3. $androidBuildCachePath"
Write-Host ""
Write-Host "Estimated space to recover: {0:N2} GB" -f ($totalSize / 1GB) -ForegroundColor Cyan
Write-Host ""
Write-Host "To clean, run: clean_c_drive_flutter.bat" -ForegroundColor Yellow
Write-Host ""

Read-Host "Press Enter to exit"
