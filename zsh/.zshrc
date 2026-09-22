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

# Claude Code replays a snapshot of this shell for its Bash tool, where output
# is parsed by a model rather than read by a person.
#
# Measured 2026-09-21 in that shell, against a 140-entry directory:
#     ls "$D" | wc -l        -> 140   correct, WITH a path argument
#     cd "$D" && ls | wc -l  ->   0   bare ls, the form you actually write
#     /bin/ls -1 | wc -l     -> 140   so the cwd was right either way
# It fails only for bare `ls` and works in the form you'd use to double-check,
# which is how it got believed. Does NOT reproduce under plain `zsh -c 'source
# .zshrc'` -- something about the snapshot replay, not this file.
#
# zoxide's `cd` resolves by frecency, so a scripted `cd build` can land
# somewhere else entirely. Ergonomics are for the human; keep them interactive.
#
# VERIFIED 2026-09-21 from a later session's Bash tool: CLAUDECODE=1 IS set in
# the snapshot shell, so this guard is live there. Same 140-entry control:
#     cd "$D" && ls | wc -l  -> 140   (was 0)
# Re-aliasing ls to eza in that same shell put it straight back to 0, so the
# check can report the failure, not only the pass. Re-check with:  alias ls
if [[ -o interactive && -z $CLAUDECODE ]]; then
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
fi  # interactive-only ergonomics

# No `else` branch here, deliberately -- an `unset` in one would be inert.
# Claude Code's Bash tool is `zsh -c 'source <snapshot> && eval <cmd>'`, and the
# snapshot (~/.claude/shell-snapshots/) is a dump of FUNCTIONS and ALIASES only:
# measured 2026-09-21, 233 alias lines, 13600 lines of functions, and exactly one
# export -- PATH. Everything else in the environment is inherited from the shell
# that launched `claude`, which ran the block above with CLAUDECODE unset.
#
# So this file can WITHHOLD an alias from a tool shell (verified: the snapshot
# contains no _ls_eza_wrapper) but cannot REMOVE an inherited export: the unset
# runs in the capture shell, leaves no trace in a state dump, and the variable
# arrives again from the process env. MANPAGER is still bat's there for that
# reason. The one lever that DOES work is ~/.zshenv, which `zsh -c` reads on every
# command, before the snapshot is sourced. Measured 2026-09-21 with a throwaway
# ~/.zshenv holding `ZSHENV_PROBE=ran` and `unset MANPAGER`: both directions took
# effect in the very next tool command -- the set proves the file was read, the
# unset is the claim -- and with NO new session, since nothing there is captured.
# Not worth a new dotfile for one cosmetic variable, but that is where to put it
# if an inherited export ever does matter; setup.sh would need to link it too.
#
# Corollary for anything added above: an export inside the guard reaches a tool
# shell anyway. Guard on the value, not on the block, if that ever matters.

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
# tips.zsh ends in a bare `echo -e`, so sourcing it writes to stdout. In a shell
# whose output a model parses, that prepends a random line to a command's result.
[[ -o interactive && -z $CLAUDECODE ]] && [ -f "$HOME/.zsh_tips.zsh" ] && source "$HOME/.zsh_tips.zsh"

# =============================================================================
#  Project Tree
# =============================================================================
# Where your code lives. Defaults to ~/projects; set PROJECTS in ~/.zshrc.local
# (sourced above, so it wins) if yours is elsewhere -- an external volume, say.
#
# Both forms on purpose. `~projects` is a zsh named directory and is nicer to
# type, but `hash -d` is shell-local state that does not reach a non-interactive
# shell: measured 2026-09-21, `echo ~projects` in Claude Code's Bash tool is
# "no such user or named directory". An export is inherited by every child
# process, so $PROJECTS is the form that works in a script or a tool shell.
: ${PROJECTS:=$HOME/projects}
export PROJECTS
hash -d projects=$PROJECTS
