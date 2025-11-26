# Fix All Undefined Errors - Complete Solution
# Run: powershell -ExecutionPolicy Bypass -File fix_all_undefined.ps1

$ErrorActionPreference = "SilentlyContinue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  FIX ALL UNDEFINED ERRORS" -ForegroundColor Cyan
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

if (-not (Test-Path $projectPath)) {
    Write-Host "⚠️  Path not found: $projectPath" -ForegroundColor Red
    exit
}

Set-Location $projectPath
Write-Host "📁 Working in: $projectPath" -ForegroundColor Green
Write-Host ""

# Step 1: Nuclear clean
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "STEP 1: NUCLEAR CLEAN (Remove ALL cache)" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""

$itemsToDelete = @(
    ".dart_tool",
    "build",
    ".flutter-plugins",
    ".flutter-plugins-dependencies",
    ".packages",
    "pubspec.lock",
    "android\build",
    "android\app\build",
    "android\.gradle",
    "ios\build",
    "ios\Pods",
    ".idea",
    "*.iml"
)

foreach ($item in $itemsToDelete) {
    if (Test-Path $item) {
        Write-Host "  Deleting: $item" -ForegroundColor Cyan
        Remove-Item -Path $item -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "  Running flutter clean..." -ForegroundColor Cyan
flutter clean 2>&1 | Out-Null

Write-Host "✅ Deep clean completed" -ForegroundColor Green
Write-Host ""

# Step 2: Check pubspec.yaml
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "STEP 2: VERIFY PUBSPEC.YAML" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""

if (Test-Path "pubspec.yaml") {
    $pubspec = Get-Content "pubspec.yaml" -Raw
    
    $requiredPackages = @(
        "cloud_firestore",
        "firebase_core",
        "firebase_auth",
        "firebase_storage",
        "provider",
        "cached_network_image"
    )
    
    Write-Host "Checking required packages:" -ForegroundColor Cyan
    $missingPackages = @()
    
    foreach ($package in $requiredPackages) {
        if ($pubspec -match $package) {
            Write-Host "  ✅ $package" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️  $package (MISSING!)" -ForegroundColor Red
            $missingPackages += $package
        }
    }
    
    if ($missingPackages.Count -gt 0) {
        Write-Host ""
        Write-Host "⚠️  Missing packages detected!" -ForegroundColor Red
        Write-Host "Please add these to pubspec.yaml dependencies:" -ForegroundColor Yellow
        foreach ($pkg in $missingPackages) {
            Write-Host "  ${pkg}: ^latest_version" -ForegroundColor White
        }
        Write-Host ""
        Read-Host "Press Enter after adding packages to continue"
    }
} else {
    Write-Host "⚠️  pubspec.yaml not found!" -ForegroundColor Red
    exit
}

Write-Host ""

# Step 3: Get dependencies
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "STEP 3: INSTALL DEPENDENCIES" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""

Write-Host "Running: flutter pub get" -ForegroundColor Cyan
$pubGetOutput = flutter pub get 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Dependencies installed successfully" -ForegroundColor Green
} else {
    Write-Host "⚠️  Error installing dependencies:" -ForegroundColor Red
    Write-Host $pubGetOutput -ForegroundColor Red
}

Write-Host ""

# Step 4: Check imports in files
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "STEP 4: CHECK IMPORTS IN FILES" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""

$commonTypes = @{
    "QuerySnapshot" = "cloud_firestore"
    "DocumentSnapshot" = "cloud_firestore"
    "FirebaseFirestore" = "cloud_firestore"
    "FirebaseAuth" = "firebase_auth"
    "FirebaseStorage" = "firebase_storage"
    "User" = "firebase_auth"
    "Provider" = "provider"
    "ChangeNotifierProvider" = "provider"
    "CachedNetworkImage" = "cached_network_image"
}

Write-Host "Scanning Dart files for missing imports..." -ForegroundColor Cyan
$dartFiles = Get-ChildItem -Path "lib" -Recurse -Filter "*.dart" -ErrorAction SilentlyContinue

$filesWithIssues = @()

foreach ($file in $dartFiles) {
    $content = Get-Content $file.FullName -Raw
    $relativePath = (Resolve-Path -Relative $file.FullName)
    
    $hasMissingImport = $false
    
    foreach ($type in $commonTypes.Keys) {
        # Check if file uses this type
        if ($content -match "\b$type\b") {
            $package = $commonTypes[$type]
            # Check if import exists
            if ($content -notmatch "import 'package:$package/$package\.dart'") {
                if (-not $hasMissingImport) {
                    Write-Host ""
                    Write-Host "⚠️  $relativePath" -ForegroundColor Red
                    $hasMissingImport = $true
                    $filesWithIssues += $file.FullName
                }
                Write-Host "     Missing import for: $type (need: package:$package)" -ForegroundColor Yellow
            }
        }
    }
}

if ($filesWithIssues.Count -eq 0) {
    Write-Host "✅ All imports look good!" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "Found $($filesWithIssues.Count) file(s) with potential missing imports" -ForegroundColor Yellow
}

Write-Host ""

# Step 5: Analyze
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "STEP 5: RUN FLUTTER ANALYZE" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""

Write-Host "Analyzing project..." -ForegroundColor Cyan
$analyzeOutput = flutter analyze 2>&1

# Count errors and warnings
$errors = ($analyzeOutput | Select-String -Pattern "^error •").Count
$warnings = ($analyzeOutput | Select-String -Pattern "^warning •").Count
$infos = ($analyzeOutput | Select-String -Pattern "^info •").Count

Write-Host "Analysis results:" -ForegroundColor Cyan
Write-Host "  Errors: $errors" -ForegroundColor $(if ($errors -gt 0) { "Red" } else { "Green" })
Write-Host "  Warnings: $warnings" -ForegroundColor $(if ($warnings -gt 0) { "Yellow" } else { "Green" })
Write-Host "  Info: $infos" -ForegroundColor Gray

if ($errors -gt 0) {
    Write-Host ""
    Write-Host "⚠️  Errors found:" -ForegroundColor Red
    $analyzeOutput | Select-String -Pattern "^error •" | ForEach-Object { 
        Write-Host "  $_" -ForegroundColor Red 
    }
}

Write-Host ""

# Step 6: Instructions
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "STEP 6: NEXT ACTIONS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "🔄 CRITICAL: RESTART YOUR IDE!" -ForegroundColor Red
Write-Host ""
Write-Host "VSCode:" -ForegroundColor Yellow
Write-Host "  1. Press Ctrl+Shift+P" -ForegroundColor White
Write-Host "  2. Type: Reload Window" -ForegroundColor White
Write-Host "  3. Press Enter" -ForegroundColor White
Write-Host ""
Write-Host "Android Studio:" -ForegroundColor Yellow
Write-Host "  1. File → Invalidate Caches / Restart" -ForegroundColor White
Write-Host "  2. Click Invalidate and Restart" -ForegroundColor White
Write-Host ""

if ($errors -eq 0) {
    Write-Host "✅ No errors found! Your project should work now." -ForegroundColor Green
    Write-Host ""
    Write-Host "After restarting IDE, run:" -ForegroundColor Yellow
    Write-Host "  flutter run" -ForegroundColor White
} else {
    Write-Host "⚠️  Still have $errors error(s) to fix." -ForegroundColor Red
    Write-Host ""
    Write-Host "Common solutions:" -ForegroundColor Yellow
    Write-Host "  1. Check file imports (import statements at top of files)" -ForegroundColor White
    Write-Host "  2. Restart IDE (very important!)" -ForegroundColor White
    Write-Host "  3. Run: flutter pub get" -ForegroundColor White
    Write-Host "  4. Check pubspec.yaml for missing dependencies" -ForegroundColor White
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  FIX SCRIPT COMPLETED!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

Read-Host "Press Enter to exit"
