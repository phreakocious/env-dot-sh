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

# Plugins to load.
# Order matters: fzf-tab must come before anything that wraps ZLE widgets, and
# zsh-syntax-highlighting must be dead last or it misses later-defined widgets.
plugins=(
    git
    iterm2
    zsh-completions
    fzf-tab
    vi-mode
    extract     # Auto-extract archives
    copyfile    # Copies file content to clipboard
    copypath    # Copies file path to clipboard
    zsh-autosuggestions
    zsh-syntax-highlighting  # keep last
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
alias ll='ls -l'
alias la='ls -a'

# Agent forwarding is per-host, not global: anyone with root on a host you
# forward to can use your keys. Put `ForwardAgent yes` under the specific Host
# in ~/.ssh/config, or use ProxyJump/-J to reach boxes behind a bastion.

# History settings (override Oh My Zsh's lib/history.zsh, sourced above)
HISTSIZE=50000
SAVEHIST=50000          # OMZ defaults this to 10000 and silently drops the rest
setopt EXTENDED_HISTORY      # record timestamp and duration
setopt HIST_IGNORE_ALL_DUPS  # keep only the most recent copy of a command
setopt HIST_IGNORE_SPACE     # leading space keeps a command out of history
setopt HIST_REDUCE_BLANKS
unsetopt SHARE_HISTORY # Prevents overlapping history between panes

# =============================================================================
#  Modern Unix Upgrades
# =============================================================================

# Starship Prompt Init
if command -v starship >/dev/null; then
    eval "$(starship init zsh)"
fi

# Zoxide (Smart Directory Jumper) - takes over 'cd' itself.
# --cmd cd is the supported way to do this; `alias cd=z` misses plain `cd`
# navigations and never learns from them. Interactive picker is `cdi`.
if command -v zoxide >/dev/null; then
    eval "$(zoxide init zsh --cmd cd)"
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

# Ripgrep and fd deliberately keep their own names.
#
# We used to shadow `grep` and `find` with wrappers that sniffed for legacy
# flags and fell back to the real tool. They caught flag differences but could
# not catch the one that actually bites: regex dialect. `grep 'a\+b'` is BRE and
# means "one or more a"; `rg 'a\+b'` means a literal plus. Both compile, neither
# errors, and the results differ. Same class of trap in fd, where the pattern is
# a regex rather than a glob and hidden files are skipped by default.
#
# So: type `rg` and `fd` when you want them, and `grep`/`find` stay honest —
# which is also what you get on any server that doesn't have these installed.

# =============================================================================
#  FZF & Interactive Tools
# =============================================================================

# Setup fzf. Since fzf 0.48 the binary ships its own shell integration, which
# replaces ~/.fzf.zsh and the hardcoded Homebrew-prefix fallbacks.
if command -v fzf >/dev/null; then
    source <(fzf --zsh)
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

# Atuin (SQLite-backed shell history). Must init *after* fzf so it wins the
# Ctrl-R binding — fzf keeps everything else (Ctrl-T files, Alt-C dirs, **<TAB>).
# --disable-up-arrow leaves Up as plain "previous command", which is muscle
# memory worth keeping; Ctrl-R is where the searching happens.
# Sync is off unless you run `atuin register`; the db is local either way.
if command -v atuin >/dev/null; then
    eval "$(atuin init zsh --disable-up-arrow)"
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
[ -f "$HOME/.zsh_tips.zsh" ] && source "$HOME/.zsh_tips.zsh"
