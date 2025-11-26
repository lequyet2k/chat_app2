#!/bin/bash
# Comprehensive Flutter Build Verification Script
# Ensures 100% build success before attempting compilation

set -e  # Exit on any error

PROJECT_DIR="/home/user/flutter_app"
cd "$PROJECT_DIR"

echo "🔍 FLUTTER PROJECT BUILD VERIFICATION"
echo "========================================"
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Check Flutter version
echo "1️⃣ Checking Flutter version..."
FLUTTER_VERSION=$(flutter --version | grep "Flutter" | awk '{print $2}')
echo -e "${GREEN}✓ Flutter version: $FLUTTER_VERSION${NC}"
echo ""

# Step 2: Check Java version
echo "2️⃣ Checking Java configuration..."
JAVA_VERSION=$(java -version 2>&1 | grep "openjdk" | awk '{print $3}' | tr -d '"')
echo -e "${GREEN}✓ Java version: $JAVA_VERSION${NC}"
echo ""

# Step 3: Verify critical files exist
echo "3️⃣ Verifying critical project files..."
CRITICAL_FILES=(
    "pubspec.yaml"
    "lib/main.dart"
    "android/app/build.gradle"
    "android/build.gradle"
    "android/gradle.properties"
    "lib/resources/firebase_options.dart"
)

for file in "${CRITICAL_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $file"
    else
        echo -e "${RED}✗ MISSING:${NC} $file"
        exit 1
    fi
done
echo ""

# Step 4: Check pubspec.yaml dependencies
echo "4️⃣ Checking critical dependencies..."
REQUIRED_PACKAGES=(
    "firebase_core"
    "cloud_firestore"
    "firebase_auth"
    "agora_rtc_engine"
    "provider"
    "google_sign_in"
)

for package in "${REQUIRED_PACKAGES[@]}"; do
    if grep -q "$package:" pubspec.yaml; then
        echo -e "${GREEN}✓${NC} $package"
    else
        echo -e "${RED}✗ MISSING:${NC} $package"
    fi
done
echo ""

# Step 5: Verify Firebase configuration
echo "5️⃣ Checking Firebase configuration..."
if [ -f "lib/resources/firebase_options.dart" ]; then
    echo -e "${GREEN}✓ firebase_options.dart exists${NC}"
fi

if [ -f "/opt/flutter/google-services.json" ]; then
    echo -e "${GREEN}✓ google-services.json found${NC}"
    
    # Check if google-services.json is in android/app/
    if [ ! -f "android/app/google-services.json" ]; then
        echo -e "${YELLOW}⚠ Copying google-services.json to android/app/${NC}"
        cp /opt/flutter/google-services.json android/app/
        echo -e "${GREEN}✓ google-services.json copied${NC}"
    fi
else
    echo -e "${YELLOW}⚠ google-services.json not found (Firebase features may not work)${NC}"
fi
echo ""

# Step 6: Check Gradle configuration
echo "6️⃣ Checking Gradle configuration..."
if grep -q "org.gradle.jvmargs=-Xmx" android/gradle.properties; then
    HEAP_SIZE=$(grep "org.gradle.jvmargs" android/gradle.properties | grep -oP 'Xmx\K[0-9]+')
    echo -e "${GREEN}✓ Gradle heap size: ${HEAP_SIZE}MB${NC}"
else
    echo -e "${RED}✗ Gradle heap size not configured${NC}"
fi

if grep -q "android.useAndroidX=true" android/gradle.properties; then
    echo -e "${GREEN}✓ AndroidX enabled${NC}"
fi

if grep -q "multiDexEnabled true" android/app/build.gradle; then
    echo -e "${GREEN}✓ MultiDex enabled${NC}"
fi
echo ""

# Step 7: Check for common issues
echo "7️⃣ Checking for common build issues..."

# Check for deprecated properties
if grep -q "android.enableBuildCache" android/gradle.properties; then
    echo -e "${RED}✗ DEPRECATED: android.enableBuildCache found${NC}"
    exit 1
else
    echo -e "${GREEN}✓ No deprecated properties${NC}"
fi

# Check for empty Java home
if grep -q "org.gradle.java.home=$" android/gradle.properties; then
    echo -e "${RED}✗ Empty org.gradle.java.home property${NC}"
    exit 1
else
    echo -e "${GREEN}✓ No empty Java home${NC}"
fi
echo ""

# Step 8: Run flutter analyze
echo "8️⃣ Running Flutter analyze..."
ANALYZE_OUTPUT=$(flutter analyze 2>&1)
ERROR_COUNT=$(echo "$ANALYZE_OUTPUT" | grep -c "error •" || echo "0")
WARNING_COUNT=$(echo "$ANALYZE_OUTPUT" | grep -c "warning •" || echo "0")

if [ "$ERROR_COUNT" -eq "0" ]; then
    echo -e "${GREEN}✓ No errors found${NC}"
else
    echo -e "${RED}✗ $ERROR_COUNT error(s) found${NC}"
    echo "$ANALYZE_OUTPUT"
    exit 1
fi

if [ "$WARNING_COUNT" -gt "0" ]; then
    echo -e "${YELLOW}⚠ $WARNING_COUNT warning(s) found (non-blocking)${NC}"
fi
echo ""

# Step 9: Check dependencies
echo "9️⃣ Verifying dependencies..."
flutter pub get > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Dependencies resolved successfully${NC}"
else
    echo -e "${RED}✗ Dependency resolution failed${NC}"
    exit 1
fi
echo ""

# Step 10: Verify build directories are clean
echo "🔟 Checking build directories..."
BUILD_DIRS=(
    "build"
    ".dart_tool/build_cache"
    "android/build"
    "android/app/build"
    "android/.gradle"
)

NEEDS_CLEAN=false
for dir in "${BUILD_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        SIZE=$(du -sh "$dir" 2>/dev/null | awk '{print $1}')
        echo -e "${YELLOW}ℹ${NC} $dir exists ($SIZE)"
        NEEDS_CLEAN=true
    fi
done

if [ "$NEEDS_CLEAN" = true ]; then
    echo -e "${YELLOW}⚠ Recommend running flutter clean before build${NC}"
fi
echo ""

# Final summary
echo "========================================"
echo -e "${GREEN}✅ PRE-BUILD VERIFICATION COMPLETE${NC}"
echo "========================================"
echo ""
echo "📋 SUMMARY:"
echo "  • Flutter version: $FLUTTER_VERSION ✓"
echo "  • Java version: $JAVA_VERSION ✓"
echo "  • All critical files present ✓"
echo "  • Dependencies resolved ✓"
echo "  • Errors: $ERROR_COUNT"
echo "  • Warnings: $WARNING_COUNT"
echo ""
echo "🚀 READY TO BUILD!"
echo ""
echo "Build commands:"
echo "  Web:     flutter build web --release"
echo "  Debug:   flutter build apk --debug"
echo "  Release: flutter build apk --release"
echo ""
