# =============================================================================
#  Homebrew Initialization
# =============================================================================
# Set up Homebrew PATHs based on architecture (Apple Silicon vs Intel)
if [[ -f "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -f "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# Path to your oh-my-zsh installation.
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
export ZSH="$HOME/.oh-my-zsh"

# =============================================================================
#  Theme Selection
# =============================================================================
# If Starship is installed, use it. Otherwise, fall back to RobbyRussell.
if command -v starship >/dev/null; then
    ZSH_THEME=""
else
    ZSH_THEME="robbyrussell"
fi

# Plugins to load
plugins=(
    git
    iterm2
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-completions
    fzf
    fzf-tab
    vi-mode
    extract     # Auto-extract archives
    copyfile    # Copies file content to clipboard
    copypath    # Copies file path to clipboard
)

source $ZSH/oh-my-zsh.sh

# iTerm2 Shell Integration
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# =============================================================================
#  User Configuration
# =============================================================================

export EDITOR='vim'

# macOS specific: Use Homebrew's gls if available for colors, otherwise standard ls
if command -v gls >/dev/null 2>&1; then
    alias ls='gls --color=auto'
    export LS_COLORS='di=1;34:ln=1;36:so=1;35:pi=1;33:ex=1;32:bd=1;34;46:cd=1;34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43'
else
    # BSD ls (macOS default)
    export CLICOLOR=1
    export LSCOLORS=Gxfxcxdxbxegedabagacad
    alias ls='ls -G'
fi

alias sl='ls'
alias ssh='ssh -A'
alias ll='ls -l'
alias la='ls -a'

# History settings
export HISTSIZE=50000
export SAVEHIST=10000
setopt HIST_IGNORE_DUPS
unsetopt SHARE_HISTORY # Prevents overlapping history between panes

# =============================================================================
#  Modern Unix Upgrades
# =============================================================================

# Starship Prompt Init
if command -v starship >/dev/null; then
    eval "$(starship init zsh)"
fi

# Zoxide (Smart Directory Jumper) - Replaces 'cd' with 'z'
if command -v zoxide >/dev/null; then
    eval "$(zoxide init zsh)"
    alias cd="z"
fi

# Eza (Modern ls)
if command -v eza >/dev/null; then
    # Function to handle muscle memory for ls -t (sort by time) -> eza --sort=modified
    _ls_eza_wrapper() {
        local -a args
        local arg
        local sort_time=false
        local sort_reverse=false

        for arg in "$@"; do
            # Only process short flags (start with - but not --)
            if [[ "$arg" == -* && "$arg" != --* ]]; then
                # Check for 't' (sort by time -> modified)
                if [[ "$arg" =~ "t" ]]; then
                    sort_time=true
                    arg="${arg//t/}"
                fi
                # Check for 'r' (reverse sort)
                if [[ "$arg" =~ "r" ]]; then
                    sort_reverse=true
                    arg="${arg//r/}"
                fi

                # If arg is now just '-', skip it (it was just -t or -r)
                [[ "$arg" == "-" ]] && continue
            fi
            args+=("$arg")
        done

        local -a cmd=(eza --icons --git)
        
        if $sort_time; then
             cmd+=(--sort=modified)
             # eza --sort=modified defaults to Oldest First.
             # ls -t defaults to Newest First.
             # So:
             # ls -t  (Newest First) -> Add -r to reverse eza's default.
             # ls -tr (Oldest First) -> Do NOT add -r (keep eza's default).
             if ! $sort_reverse; then
                 cmd+=(-r)
             fi
        elif $sort_reverse; then
             # Standard reverse sort (by name)
             cmd+=(-r)
        fi
        
        "${cmd[@]}" "${args[@]}"
    }
    alias ls='_ls_eza_wrapper'
    alias ll='eza -l --icons --git'
    alias la='eza -la --icons --git'
    alias lt='eza --tree --level=2 --icons'

    # Ensure tab completion works for the wrapper
    compdef _ls_eza_wrapper=eza
fi

# Bat (Modern cat)
if command -v bat >/dev/null; then
    alias cat='bat'
    export MANPAGER="sh -c 'col -bx | bat -l man -p'" # Use bat for man pages
fi

# Ripgrep (Modern grep)
if command -v rg >/dev/null; then
    unalias grep 2>/dev/null
    function grep {
        local legacy=0
        for arg in "$@"; do
            if [[ "$arg" == "--include"* || "$arg" == "--exclude"* || "$arg" == "-R" || "$arg" == "-r" ]]; then
                legacy=1; break
            fi
        done

        if [[ $legacy -eq 1 ]]; then
            echo -e "\033[0;33m[Modern Unix Tip] Legacy 'grep' flags detected.\033[0m"
            [[ "$*" == *"--include"* ]] && echo -e "  --include='*.py' -> -g '*.py'"
            [[ "$*" == *"--exclude"* ]] && echo -e "  --exclude='*.py' -> -g '!*.py'"
            [[ "$*" == *"-r"* || "$*" == *"-R"* ]] && echo -e "  -r/-R -> (recursive by default in rg)"
            echo -e "\033[0;32mFalling back to system 'grep'...\033[0m"
            command grep "$@"
        else
            rg "$@"
        fi
    }
fi

# Fd (Modern find)
if command -v fd >/dev/null; then
    unalias find 2>/dev/null
    function find {
        local legacy=0
        for arg in "$@"; do
            if [[ "$arg" == "-name" || "$arg" == "-iname" || "$arg" == "-exec" || "$arg" == "-type" || "$arg" == "-maxdepth" || "$arg" == "-mindepth" || "$arg" == "-o" || "$arg" == "-a" || "$arg" == "-print0" ]]; then
                legacy=1; break
            fi
        done

        if [[ $legacy -eq 1 ]]; then
            echo -e "\033[0;33m[Modern Unix Tip] Legacy 'find' flags detected.\033[0m"
            [[ "$*" == *"-name"* ]] && echo -e "  -name 'foo' -> 'foo' (or -g 'foo')"
            [[ "$*" == *"-iname"* ]] && echo -e "  -iname 'foo' -> -i 'foo'"
            [[ "$*" == *"-type"* ]] && echo -e "  -type f/d   -> -t f/d"
            [[ "$*" == *"-exec"* ]] && echo -e "  -exec ...   -> -x ..."
            echo -e "\033[0;32mFalling back to system 'find'...\033[0m"
            command find "$@"
        else
            fd "$@"
        fi
    }
fi

# =============================================================================
#  FZF & Interactive Tools
# =============================================================================

# Setup fzf
if [ -f ~/.fzf.zsh ]; then
    source ~/.fzf.zsh
elif [ -f /usr/local/opt/fzf/install ]; then
    # Fallback for Homebrew install location
    [ -f /usr/local/opt/fzf/shell/key-bindings.zsh ] && source /usr/local/opt/fzf/shell/key-bindings.zsh
    [ -f /usr/local/opt/fzf/shell/completion.zsh ] && source /usr/local/opt/fzf/shell/completion.zsh
fi

# FZF Configuration: Stop looking at gitignore
if command -v fd >/dev/null; then
    # --no-ignore: Show gitignored files
    # --hidden: Show hidden files
    # --follow: Follow symlinks
    # --exclude .git: But still don't show the .git directory itself
    export FZF_DEFAULT_COMMAND='fd --type f --no-ignore --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --no-ignore --hidden --follow --exclude .git'

    # Apply to fzf **<TAB> completion
    _fzf_compgen_path() {
        fd --hidden --follow --exclude ".git" --no-ignore . "$1"
    }
    _fzf_compgen_dir() {
        fd --type d --hidden --follow --exclude ".git" --no-ignore . "$1"
    }
fi

# FZF Tab styling
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':fzf-tab:*' switch-group ',' '.'

# Use eza for FZF previews if available
if command -v eza >/dev/null; then
    zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
elif command -v ls >/dev/null; then
    zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls -1 $realpath'
fi

# =============================================================================
#  Vi Mode Overrides
# =============================================================================
bindkey -v
export KEYTIMEOUT=1

# Use vim keys in tab complete menu:
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history

# Fix backspace in vi command mode
bindkey -M viins '^?' backward-delete-char
bindkey -M viins '^H' backward-delete-char

# Edit command in editor
autoload -z edit-command-line
zle -N edit-command-line
bindkey -M vicmd v edit-command-line

# =============================================================================
#  Local Overrides
# =============================================================================
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
# =============================================================================
#  Daily Tips
# =============================================================================
source $HOME/.zsh_tips.zsh
