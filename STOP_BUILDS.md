# 🛑 CÁCH TẮT BUILD ĐANG CHẠY

## 📋 **TRÊN LINUX/MACOS (Sandbox)**

### **1. Tắt Flutter Build:**
```bash
# Kill tất cả Flutter build processes
pkill -f "flutter build"

# Hoặc kill theo tên cụ thể
pkill -f "flutter"
```

### **2. Tắt Dart Compiler:**
```bash
# Kill dart2js compiler (web builds)
pkill -f "dart2js"

# Kill tất cả Dart processes
pkill -f "dart"
```

### **3. Tắt Web Server:**
```bash
# Kill Python HTTP server
lsof -ti:5060 | xargs -r kill -9

# Hoặc kill tất cả Python HTTP servers
pkill -f "python3 -m http.server"
```

### **4. Tắt TẤT CẢ (Nuclear Option):**
```bash
# Kill mọi thứ liên quan Flutter/Dart/Server
pkill -f "flutter" && pkill -f "dart" && lsof -ti:5060 | xargs -r kill -9
echo "✅ All processes killed"
```

### **5. Check còn process nào đang chạy:**
```bash
# Xem Flutter/Dart processes
ps aux | grep -E "(flutter|dart)" | grep -v grep

# Xem process dùng port 5060
lsof -i:5060

# Xem tất cả background jobs
jobs -l
```

---

## 🪟 **TRÊN WINDOWS**

### **1. Tắt Flutter Build trong Terminal:**

**Cách 1: Nhấn `Ctrl + C` trong terminal đang chạy build**

**Cách 2: Dùng Task Manager**
```
1. Nhấn Ctrl + Shift + Esc
2. Tìm process "flutter.bat" hoặc "dart.exe"
3. Click "End Task"
```

**Cách 3: Dùng Command Prompt/PowerShell**

#### **Command Prompt:**
```cmd
REM Kill Flutter processes
taskkill /F /IM flutter.bat
taskkill /F /IM dart.exe

REM Kill Gradle (Android build)
taskkill /F /IM java.exe

REM Kill tất cả
taskkill /F /IM flutter.bat & taskkill /F /IM dart.exe & taskkill /F /IM java.exe
```

#### **PowerShell:**
```powershell
# Kill Flutter build
Get-Process | Where-Object {$_.ProcessName -like "*flutter*"} | Stop-Process -Force

# Kill Dart compiler
Get-Process | Where-Object {$_.ProcessName -like "*dart*"} | Stop-Process -Force

# Kill Java (Gradle)
Get-Process | Where-Object {$_.ProcessName -eq "java"} | Stop-Process -Force

# Kill tất cả cùng lúc
Get-Process | Where-Object {$_.ProcessName -like "*flutter*" -or $_.ProcessName -like "*dart*" -or $_.ProcessName -eq "java"} | Stop-Process -Force
```

### **2. Tắt Gradle Build (Android):**

```cmd
REM Command Prompt
cd D:\test1\chat_app2\android
gradlew --stop

REM Hoặc kill Java processes
taskkill /F /IM java.exe
```

```powershell
# PowerShell
cd D:\test1\chat_app2\android
.\gradlew --stop

# Hoặc
Get-Process java | Stop-Process -Force
```

### **3. Tắt Flutter Dev Server:**

```cmd
REM Kill process trên port 5060
netstat -ano | findstr :5060
taskkill /PID <PID_NUMBER> /F
```

```powershell
# PowerShell
$port = 5060
Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue | ForEach-Object {
    Stop-Process -Id $_.OwningProcess -Force
}
```

---

## 🎯 **QUICK REFERENCE**

### **Linux/macOS:**
```bash
# Kill Flutter build
pkill -f "flutter build"

# Kill everything
pkill -f "flutter" && pkill -f "dart" && lsof -ti:5060 | xargs -r kill -9
```

### **Windows Command Prompt:**
```cmd
taskkill /F /IM flutter.bat & taskkill /F /IM dart.exe & taskkill /F /IM java.exe
```

### **Windows PowerShell:**
```powershell
Get-Process | Where-Object {$_.ProcessName -like "*flutter*" -or $_.ProcessName -like "*dart*"} | Stop-Process -Force
```

---

## 💡 **TIPS**

### **1. Graceful Shutdown (Khuyến nghị):**
- Nhấn `Ctrl + C` trong terminal đang build
- Chờ process tự dọn dẹp và thoát

### **2. Force Kill (Khi cần thiết):**
- Dùng khi `Ctrl + C` không work
- Có thể để lại file lock hoặc cache bẩn
- Nên chạy `flutter clean` sau khi force kill

### **3. Check Before Kill:**
```bash
# Linux/macOS
ps aux | grep flutter

# Windows
tasklist | findstr flutter
```

### **4. Clean After Force Kill:**
```bash
# Linux/macOS/Windows
cd /path/to/project
flutter clean
rm -rf build .dart_tool
```

---

## ⚠️ **WARNINGS**

### **❌ Không nên:**
- Kill process khi đang ở giữa Android build (có thể corrupt Gradle cache)
- Kill quá nhiều lần (gây issue với Flutter SDK)
- Kill Java process khi không chắc (có thể kill IDE hoặc app khác)

### **✅ Nên:**
- Thử `Ctrl + C` trước
- Chờ build complete nếu có thể
- Run `flutter clean` sau khi force kill
- Restart IDE sau khi kill nhiều processes

---

## 🔧 **TROUBLESHOOTING**

### **Issue: "Port already in use" sau khi kill**

**Linux/macOS:**
```bash
lsof -ti:5060 | xargs -r kill -9
sleep 2
# Try start server again
```

**Windows:**
```cmd
netstat -ano | findstr :5060
taskkill /PID <PID> /F
timeout /t 2
REM Try start server again
```

### **Issue: "Gradle daemon not stopped"**

```bash
# Linux/macOS
./gradlew --stop

# Windows
cd android
.\gradlew --stop
```

### **Issue: "Flutter build hung/frozen"**

```bash
# 1. Kill process
pkill -9 -f flutter  # Force kill

# 2. Clean everything
flutter clean
rm -rf build .dart_tool android/build android/.gradle

# 3. Restart
flutter pub get
```

---

## 📊 **PROCESS PRIORITY**

Kill theo thứ tự này để tránh issues:

1. **Flutter CLI** (`flutter build`, `flutter run`)
2. **Dart Compiler** (`dart2js`, `dart compile`)
3. **Gradle Daemon** (`./gradlew --stop`)
4. **Java Processes** (nếu cần)
5. **Web Server** (Python HTTP server)

---

## 🎉 **SUMMARY**

| Platform | Quick Kill Command |
|----------|-------------------|
| **Linux/macOS** | `pkill -f "flutter build"` |
| **Windows CMD** | `taskkill /F /IM flutter.bat` |
| **Windows PS** | `Get-Process flutter \| Stop-Process -Force` |
| **Graceful** | `Ctrl + C` in terminal |
| **Nuclear** | Kill all Flutter + Dart + Java |

**Sau khi kill, luôn chạy:** `flutter clean`
