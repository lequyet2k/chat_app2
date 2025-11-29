#!/bin/bash

# ===================================
# FORCE PULL - BỎ QUA THAY ĐỔI LOCAL
# ===================================
# Usage: ./force_pull.sh
# Warning: This will discard ALL local changes!

echo "🔄 Force pulling from GitHub..."
echo "⚠️  WARNING: This will discard ALL local changes!"
echo ""

# Show current status
echo "📊 Current status:"
git status --short

echo ""
read -p "Continue? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 Executing force pull..."
    echo ""
    
    # Fetch latest from remote
    echo "1/3 Fetching from origin..."
    git fetch origin
    
    # Reset to match remote exactly
    echo "2/3 Resetting to origin/main..."
    git reset --hard origin/main
    
    # Clean untracked files
    echo "3/3 Cleaning untracked files..."
    git clean -fd
    
    echo ""
    echo "✅ Force pull complete!"
    echo ""
    echo "📊 New status:"
    git status
    
    echo ""
    echo "📝 Latest commits:"
    git log --oneline -5
else
    echo "❌ Force pull cancelled"
    exit 1
fi
