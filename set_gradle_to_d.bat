@echo off
echo ========================================
echo   SET GRADLE BUILD TO D: DRIVE
echo ========================================
echo.

REM Set Gradle User Home to D:
setx GRADLE_USER_HOME "D:\gradle_cache"

REM Create gradle.properties for this project
echo Creating android\gradle.properties...
(
echo # Gradle properties
echo org.gradle.jvmargs=-Xmx4096m -XX:MaxMetaspaceSize=1024m -XX:+HeapDumpOnOutOfMemoryError -Dfile.encoding=UTF-8
echo org.gradle.parallel=true
echo org.gradle.caching=true
echo org.gradle.daemon=true
echo.
echo # Android properties
echo android.useAndroidX=true
echo android.enableJetifier=false
echo.
echo # Build directory on D: drive
echo buildDir=D:/build_cache/%cd:~0,2%
echo.
echo # Kotlin properties
echo kotlin.code.style=official
echo.
echo # Performance optimization
echo android.enableR8.fullMode=false
echo android.enableBuildCache=true
) > android\gradle.properties

echo.
echo ✅ Gradle configured to use D: drive!
echo.
echo IMPORTANT: 
echo 1. Close and reopen your terminal
echo 2. Close and reopen Android Studio/VSCode
echo 3. Run: flutter clean
echo 4. Run: flutter pub get
echo.
pause
