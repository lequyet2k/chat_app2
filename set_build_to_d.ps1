# Set All Build Locations to D: Drive
# Run as Administrator: powershell -ExecutionPolicy Bypass -File set_build_to_d.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SET BUILD LOCATIONS TO D: DRIVE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "⚠️  Please run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell -> Run as Administrator" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit
}

Write-Host "Setting environment variables..." -ForegroundColor Cyan
Write-Host ""

# 1. Set TEMP and TMP to D:
$tempDir = "D:\Temp"
if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    Write-Host "✅ Created: $tempDir" -ForegroundColor Green
}

[System.Environment]::SetEnvironmentVariable('TEMP', $tempDir, 'User')
[System.Environment]::SetEnvironmentVariable('TMP', $tempDir, 'User')
Write-Host "✅ Set TEMP to: $tempDir" -ForegroundColor Green
Write-Host "✅ Set TMP to: $tempDir" -ForegroundColor Green
Write-Host ""

# 2. Set Gradle cache
$gradleCache = "D:\gradle_cache"
if (-not (Test-Path $gradleCache)) {
    New-Item -ItemType Directory -Path $gradleCache -Force | Out-Null
    Write-Host "✅ Created: $gradleCache" -ForegroundColor Green
}

[System.Environment]::SetEnvironmentVariable('GRADLE_USER_HOME', $gradleCache, 'User')
Write-Host "✅ Set GRADLE_USER_HOME to: $gradleCache" -ForegroundColor Green
Write-Host ""

# 3. Set Pub cache
$pubCache = "D:\pub_cache"
if (-not (Test-Path $pubCache)) {
    New-Item -ItemType Directory -Path $pubCache -Force | Out-Null
    Write-Host "✅ Created: $pubCache" -ForegroundColor Green
}

[System.Environment]::SetEnvironmentVariable('PUB_CACHE', $pubCache, 'User')
Write-Host "✅ Set PUB_CACHE to: $pubCache" -ForegroundColor Green
Write-Host ""

# 4. Set Android build cache
$androidBuildCache = "D:\android_build_cache"
if (-not (Test-Path $androidBuildCache)) {
    New-Item -ItemType Directory -Path $androidBuildCache -Force | Out-Null
    Write-Host "✅ Created: $androidBuildCache" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  ✅ CONFIGURATION COMPLETED!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

Write-Host "Environment variables set:" -ForegroundColor Yellow
Write-Host "  TEMP = $tempDir" -ForegroundColor White
Write-Host "  TMP = $tempDir" -ForegroundColor White
Write-Host "  GRADLE_USER_HOME = $gradleCache" -ForegroundColor White
Write-Host "  PUB_CACHE = $pubCache" -ForegroundColor White
Write-Host ""

Write-Host "🔄 CRITICAL: RESTART REQUIRED!" -ForegroundColor Red
Write-Host ""
Write-Host "You MUST:" -ForegroundColor Yellow
Write-Host "  1. Close ALL terminals/PowerShell/CMD windows" -ForegroundColor White
Write-Host "  2. Close Android Studio/VSCode" -ForegroundColor White
Write-Host "  3. Restart your computer (recommended)" -ForegroundColor White
Write-Host ""
Write-Host "After restart:" -ForegroundColor Yellow
Write-Host "  cd D:\test1\chat_app2" -ForegroundColor White
Write-Host "  flutter clean" -ForegroundColor White
Write-Host "  flutter pub get" -ForegroundColor White
Write-Host "  flutter build apk --debug" -ForegroundColor White
Write-Host ""
Write-Host "All builds will now use D: drive! 🎉" -ForegroundColor Green
Write-Host ""

Read-Host "Press Enter to exit"
