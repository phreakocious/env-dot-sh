#!/bin/bash

# Define directories
OMZ_DIR="$HOME/.oh-my-zsh"
ZSH_CUSTOM="$OMZ_DIR/custom"
SCRIPT_DIR="$(dirname "$0")"

echo "Setting up modern Zsh environment for macOS..."

# 0. Install Homebrew & Packages (Optional)
if ! command -v brew >/dev/null; then
    echo "Homebrew not found."
    read -p "Do you want to install Homebrew? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Attempt to configure shell environment for the current session
        if [ -f "/opt/homebrew/bin/brew" ]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [ -f "/usr/local/bin/brew" ]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    fi
fi

if command -v brew >/dev/null; then
    echo "Homebrew detected."
    read -p "Do you want to install Modern Unix tools (starship, eza, zoxide, etc.) via Brewfile? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Installing packages from Brewfile..."
        brew bundle --file="$SCRIPT_DIR/Brewfile"
    fi
else
    echo "Homebrew not found or installation skipped. Skipping package installation."
fi

# 1. Install Oh-My-Zsh (unattended)
if [ ! -d "$OMZ_DIR" ]; then
  echo "Installing Oh-My-Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  echo "Oh-My-Zsh already installed."
fi

# 2. Install Plugins
echo "Installing plugins..."

# zsh-autosuggestions
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

# zsh-syntax-highlighting
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# fzf-tab (replaces default tab completion with fzf)
if [ ! -d "$ZSH_CUSTOM/plugins/fzf-tab" ]; then
  git clone https://github.com/Aloxaf/fzf-tab "$ZSH_CUSTOM/plugins/fzf-tab"
fi

# 3. Link .zshrc
echo "Backing up existing .zshrc and linking new one..."
[ -f "$HOME/.zshrc" ] && mv "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%s)"
cp "$SCRIPT_DIR/.zshrc" "$HOME/.zshrc"

# 4. Install Tips
echo "Installing tips..."
cp "$SCRIPT_DIR/tips.zsh" "$HOME/.zsh_tips.zsh"

# 5. Setup User Binaries
echo "Setting up user binaries..."
mkdir -p "$HOME/bin"

# Link Sublime Text
if [ -d "/Applications/Sublime Text.app" ]; then
    ln -sf "/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl" "$HOME/bin/subl"
    echo "Linked subl to ~/bin/subl"
fi

# Link Sublime Merge
if [ -d "/Applications/Sublime Merge.app" ]; then
    ln -sf "/Applications/Sublime Merge.app/Contents/SharedSupport/bin/smerge" "$HOME/bin/smerge"
    echo "Linked smerge to ~/bin/smerge"
fi

echo "Setup complete! Restart your terminal or run 'zsh' to see changes."