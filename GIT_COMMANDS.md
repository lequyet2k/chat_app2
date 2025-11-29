# 🔄 Git Commands Reference - Flutter Chat App

## ⚡ Quick Commands

### Force Pull (Bỏ qua thay đổi local)

```bash
# Option 1: One-liner (Fastest)
git fetch origin && git reset --hard origin/main && git clean -fd

# Option 2: Use script (Interactive)
./force_pull.sh

# Option 3: Step by step
git fetch origin
git reset --hard origin/main
git clean -fd
```

---

## 📋 Common Git Operations

### Pull với Stash (Giữ thay đổi local)
```bash
git stash
git pull origin main
git stash pop
```

### Check Status
```bash
git status
git status --short
```

### View Commits
```bash
git log --oneline -10
git log --all --decorate --oneline --graph -10
```

### Sync với Remote
```bash
# Check difference
git fetch origin
git log HEAD..origin/main --oneline

# Pull latest
git pull origin main
```

---

## 🔧 Advanced Operations

### Create Backup Branch
```bash
git branch backup-$(date +%Y%m%d-%H%M%S)
```

### Discard Changes to Specific File
```bash
git checkout -- <file_path>
```

### Undo Last Commit (Keep changes)
```bash
git reset --soft HEAD~1
```

### Undo Last Commit (Discard changes)
```bash
git reset --hard HEAD~1
```

### View Stash
```bash
git stash list
git stash show -p stash@{0}
```

### Apply Stash
```bash
git stash apply
git stash pop
```

### Delete Stash
```bash
git stash drop
git stash clear  # Delete all stash entries
```

---

## 🚨 Emergency Commands

### Reset to Remote (Nuclear option)
```bash
git fetch origin
git reset --hard origin/main
git clean -fdx  # Remove ALL untracked files including ignored ones
```

### Abort Merge
```bash
git merge --abort
```

### Abort Rebase
```bash
git rebase --abort
```

### Restore Deleted Branch
```bash
git reflog
git checkout -b <branch_name> <commit_hash>
```

---

## 📊 Repository Info

### Check Remote
```bash
git remote -v
```

### View Contributors
```bash
git shortlog -sn
```

### View File History
```bash
git log --follow -- <file_path>
```

### View Changes in Commit
```bash
git show <commit_hash>
git show <commit_hash> --stat
```

---

## 🎯 Flutter-Specific Commands

### Clean Flutter Build
```bash
flutter clean
rm -rf .dart_tool/build_cache
flutter pub get
```

### Full Reset + Rebuild
```bash
git fetch origin && git reset --hard origin/main && git clean -fd
flutter clean
flutter pub get
flutter build web --release
```

### Check Flutter Status
```bash
flutter doctor -v
flutter --version
```

---

## 📝 Notes

- **git reset --hard**: XÓA VĨNH VIỄN thay đổi local
- **git clean -fd**: Xóa untracked files và directories
- **git clean -fdx**: Xóa untracked files including ignored files
- Always backup important changes before force operations
- Use `git stash` when you want to keep changes temporarily

---

## 🔗 Repository

**GitHub**: https://github.com/lequyet2k/chat_app2

**Current Branch**: main

**Latest Commit**: 4df5f8a - Add Biometric Authentication - Security Feature
