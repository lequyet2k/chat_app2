# Quick Flutter Cache Cleaner for C: Drive
# Run: powershell -ExecutionPolicy Bypass -File quick_clean_c_drive.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   FLUTTER CACHE CLEANER" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Function to check and delete folder
function Remove-CacheFolder {
    param(
        [string]$Path,
        [string]$Name
    )
    
    if (Test-Path $Path) {
        $size = (Get-ChildItem -Path $Path -Recurse -ErrorAction SilentlyContinue | 
                 Measure-Object -Property Length -Sum).Sum
        $sizeGB = [math]::Round($size / 1GB, 2)
        
        Write-Host "Found: $Name" -ForegroundColor Green
        Write-Host "  Location: $Path"
        Write-Host "  Size: $sizeGB GB" -ForegroundColor Yellow
        Write-Host "  Deleting..." -ForegroundColor Cyan
        
        try {
            Remove-Item -Path $Path -Recurse -Force -ErrorAction Stop
            Write-Host "  ✅ Deleted successfully" -ForegroundColor Green
        } catch {
            Write-Host "  ⚠️  Error: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "Not found: $Name" -ForegroundColor Gray
    }
    Write-Host ""
}

# Clean caches
Write-Host "Starting cleanup..." -ForegroundColor Cyan
Write-Host ""

Remove-CacheFolder -Path "$env:USERPROFILE\.gradle\caches" -Name "Gradle Caches"
Remove-CacheFolder -Path "$env:USERPROFILE\.gradle\wrapper\dists" -Name "Gradle Wrapper"
Remove-CacheFolder -Path "$env:LOCALAPPDATA\Pub\Cache" -Name "Pub Cache"
Remove-CacheFolder -Path "$env:USERPROFILE\.android\build-cache" -Name "Android Build Cache"
Remove-CacheFolder -Path "$env:APPDATA\Pub\Cache" -Name "Dart Pub Cache"

# Clean Flutter temp files
Write-Host "Cleaning Flutter temp files..." -ForegroundColor Cyan
$tempCount = 0
Get-ChildItem -Path $env:TEMP -Filter "flutter_tools*" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
    $tempCount++
}
Write-Host "  ✅ Deleted $tempCount Flutter temp folders" -ForegroundColor Green
Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Green
Write-Host "   ✅ CLEANUP COMPLETED!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Estimated space freed: 2-10 GB" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. cd D:\your_flutter_project"
Write-Host "  2. flutter clean"
Write-Host "  3. flutter pub get"
Write-Host "  4. flutter build apk --release"
Write-Host ""

# Show disk space
Write-Host "C: Drive Space:" -ForegroundColor Cyan
$drive = Get-PSDrive C
Write-Host "  Free: " -NoNewline
Write-Host ("{0:N2} GB" -f ($drive.Free / 1GB)) -ForegroundColor Green
Write-Host "  Used: " -NoNewline
Write-Host ("{0:N2} GB" -f ($drive.Used / 1GB)) -ForegroundColor Yellow
Write-Host ""

Read-Host "Press Enter to exit"
