# Fix QuerySnapshot Type Error
# Run: powershell -ExecutionPolicy Bypass -File fix_querysnapshot_error.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  FIX QUERYSNAPSHOT TYPE ERROR" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get project path
if ($args.Count -gt 0) {
    $projectPath = $args[0]
} else {
    $projectPath = Read-Host "Enter Flutter project path (or press Enter for current directory)"
    if ([string]::IsNullOrWhiteSpace($projectPath)) {
        $projectPath = Get-Location
    }
}

Set-Location $projectPath
Write-Host "Working in: $projectPath" -ForegroundColor Green
Write-Host ""

# Step 1: Verify pubspec.yaml has cloud_firestore
Write-Host "Step 1: Checking pubspec.yaml..." -ForegroundColor Cyan
if (Test-Path "pubspec.yaml") {
    $pubspecContent = Get-Content "pubspec.yaml" -Raw
    if ($pubspecContent -match "cloud_firestore") {
        Write-Host "✅ cloud_firestore found in pubspec.yaml" -ForegroundColor Green
        
        # Extract version
        $version = $pubspecContent -match "cloud_firestore:\s*(.+)" | Out-Null; $Matches[1]
        Write-Host "   Version: $version" -ForegroundColor Gray
    } else {
        Write-Host "⚠️  cloud_firestore NOT found in pubspec.yaml" -ForegroundColor Red
        Write-Host "   Adding cloud_firestore to dependencies..." -ForegroundColor Yellow
        # This should be added manually
        Write-Host "   Please add to pubspec.yaml:" -ForegroundColor Yellow
        Write-Host "   cloud_firestore: ^5.4.3" -ForegroundColor White
    }
} else {
    Write-Host "⚠️  pubspec.yaml not found!" -ForegroundColor Red
    exit
}

Write-Host ""

# Step 2: Deep clean
Write-Host "Step 2: Deep cleaning project..." -ForegroundColor Cyan

Write-Host "  - Running flutter clean..." -ForegroundColor Gray
flutter clean 2>&1 | Out-Null

Write-Host "  - Deleting .dart_tool..." -ForegroundColor Gray
if (Test-Path ".dart_tool") {
    Remove-Item -Path ".dart_tool" -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "  - Deleting build..." -ForegroundColor Gray
if (Test-Path "build") {
    Remove-Item -Path "build" -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "  - Deleting pubspec.lock..." -ForegroundColor Gray
if (Test-Path "pubspec.lock") {
    Remove-Item -Path "pubspec.lock" -Force -ErrorAction SilentlyContinue
}

Write-Host "  - Deleting .flutter-plugins-dependencies..." -ForegroundColor Gray
if (Test-Path ".flutter-plugins-dependencies") {
    Remove-Item -Path ".flutter-plugins-dependencies" -Force -ErrorAction SilentlyContinue
}

Write-Host "✅ Project cleaned" -ForegroundColor Green
Write-Host ""

# Step 3: Reinstall dependencies
Write-Host "Step 3: Reinstalling dependencies..." -ForegroundColor Cyan
flutter pub get
Write-Host "✅ Dependencies installed" -ForegroundColor Green
Write-Host ""

# Step 4: Check for QuerySnapshot imports
Write-Host "Step 4: Checking QuerySnapshot imports..." -ForegroundColor Cyan

$filesWithQuerySnapshot = Get-ChildItem -Path "lib" -Recurse -Filter "*.dart" | 
    Select-String -Pattern "QuerySnapshot" -List | 
    Select-Object -ExpandProperty Path -Unique

if ($filesWithQuerySnapshot) {
    Write-Host "Files using QuerySnapshot:" -ForegroundColor Yellow
    
    foreach ($file in $filesWithQuerySnapshot) {
        $relativePath = (Resolve-Path -Relative $file)
        $content = Get-Content $file -Raw
        
        if ($content -match "import 'package:cloud_firestore/cloud_firestore.dart';") {
            Write-Host "  ✅ $relativePath (has import)" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️  $relativePath (MISSING import!)" -ForegroundColor Red
            
            # Add import automatically
            $addImport = Read-Host "    Add import automatically? (Y/N)"
            if ($addImport -eq 'Y' -or $addImport -eq 'y') {
                $lines = Get-Content $file
                $newLines = @("import 'package:cloud_firestore/cloud_firestore.dart';") + $lines
                $newLines | Set-Content $file
                Write-Host "    ✅ Import added!" -ForegroundColor Green
            }
        }
    }
} else {
    Write-Host "⚠️  No files using QuerySnapshot found" -ForegroundColor Gray
}

Write-Host ""

# Step 5: Analyze
Write-Host "Step 5: Running flutter analyze..." -ForegroundColor Cyan
$analyzeOutput = flutter analyze 2>&1
$querySnapshotErrors = $analyzeOutput | Select-String -Pattern "QuerySnapshot.*isn't a type"

if ($querySnapshotErrors) {
    Write-Host "⚠️  Still has QuerySnapshot errors:" -ForegroundColor Red
    $querySnapshotErrors | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    Write-Host ""
    Write-Host "Manual fix needed:" -ForegroundColor Yellow
    Write-Host "  1. Open each file with error"
    Write-Host "  2. Add at the top: import 'package:cloud_firestore/cloud_firestore.dart';"
    Write-Host "  3. Save and restart IDE"
} else {
    Write-Host "✅ No QuerySnapshot errors found!" -ForegroundColor Green
}

Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Green
Write-Host "  COMPLETED!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Restart your IDE (VSCode/Android Studio)" -ForegroundColor White
Write-Host "  2. Wait for Dart Analysis to complete" -ForegroundColor White
Write-Host "  3. Run: flutter run" -ForegroundColor White
Write-Host ""

Read-Host "Press Enter to exit"
