#!/bin/zsh

# Array of tips about the installed modern tools
tips=(
    "🚀 \033[1;32mZoxide (z):\033[0m Jump to frequently visited directories.\n   Try: \033[1;34mz env\033[0m (matches 'env-dot-sh')"
    
    "🚀 \033[1;32mZoxide (z):\033[0m Go back to the previous directory interactively.\n   Try: \033[1;34mzi\033[0m"

    "📂 \033[1;32mEza (ls):\033[0m List files with a tree view.\n   Try: \033[1;34mlt\033[0m (aliased to 'eza --tree --level=2')"
    
    "📂 \033[1;32mEza (ls):\033[0m List files with Git status.\n   Try: \033[1;34mll\033[0m (aliased to 'eza -l --git')"

    "⌨️  \033[1;32mMuscle Memory:\033[0m Any \033[1;34mls -t\033[0m command now works with Eza!\n   We automatically translate '-t' to '--sort=modified'."

    "🦇 \033[1;32mBat (cat):\033[0m View file with syntax highlighting.\n   Try: \033[1;34mcat file.json\033[0m (aliased to 'bat')"
    
    "🦇 \033[1;32mBat (cat):\033[0m Use it as a man-page reader.\n   Try: \033[1;34mman git\033[0m (auto-configured)"

    "🔍 \033[1;32mFZF (Ctrl-R):\033[0m Fuzzy search your command history.\n   Try: Press \033[1;34mCtrl-R\033[0m and type part of a command."

    "🔍 \033[1;32mFZF (Ctrl-T):\033[0m Fuzzy find files and paste their path.\n   Try: Press \033[1;34mCtrl-T\033[0m while typing a command."

    "🔍 \033[1;32mFZF Tab:\033[0m Preview directories during tab completion.\n   Try: Type \033[1;34mcd <Tab>\033[0m to see previews."

    "⚡ \033[1;32mRipgrep (rg):\033[0m Blazing fast code search.\n   Try: \033[1;34mrg 'function_name'\033[0m (replaces grep)"

    "⚡ \033[1;32mFd:\033[0m Faster, friendlier 'find'.\n   Try: \033[1;34mfd pattern\033[0m (replaces find)"

    "📦 \033[1;32mExtract:\033[0m Universal archive extractor.\n   Try: \033[1;34mextract archive.tar.gz\033[0m (works for zip, 7z, rar...)"

    "📋 \033[1;32mCopyfile:\033[0m Copy file contents to system clipboard.\n   Try: \033[1;34mcopyfile id_rsa.pub\033[0m"

    "📝 \033[1;32mVi Mode:\033[0m Quick edit current command in Vim.\n   Try: Press \033[1;34mv\033[0m in Normal mode (Esc first)."
)

# Seed random number generator
RANDOM=$$$(date +%s)

# Pick a random tip
# We use simple array indexing. Zsh arrays are 1-based.
index=$(( RANDOM % ${#tips[@]} + 1 ))
echo -e "\n💡 \033[1;33mTip of the Session:\033[0m ${tips[$index]}\n"
