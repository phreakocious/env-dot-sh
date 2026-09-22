#!/bin/bash

# Usage: setup.sh [-n|--dry-run] [-y|--yes]
#
# Every action that touches your machine goes through run(), and the script makes
# two passes over the same function: the first with execution suppressed, which
# IS the plan, then the real one. The plan is therefore the literal commands, not
# a summary written beside them -- a summary is a second copy of the truth and
# reports the old actions the first time one of them moves.

OMZ_DIR="$HOME/.oh-my-zsh"
ZSH_CUSTOM="$OMZ_DIR/custom"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"  # absolute: symlinks below need it
REPO_DIR="$(dirname "$SCRIPT_DIR")"
STAMP="$(date +%s)"

PLAN_ONLY=0
ASSUME_YES=0
for arg in "$@"; do
    case "$arg" in
        -n|--dry-run) PLAN_ONLY=1 ;;
        -y|--yes)     ASSUME_YES=1 ;;
        -h|--help)    sed -n '3,10p' "$0"; exit 0 ;;
        *) echo "unknown option: $arg (try --help)" >&2; exit 2 ;;
    esac
done

DRY=1
run() {
    # %q, not %s: a plan line you cannot paste back is a plan line you cannot check.
    if [ "$DRY" = 1 ]; then printf '   '; printf ' %q' "$@"; printf '\n'; return 0; fi
    "$@"
}
note() { [ "$DRY" = 1 ] && printf '    %s\n' "$1"; return 0; }

# Symlink, don't copy: edits in the repo then take effect immediately, and
# re-running this script doesn't pile up backups of files it created itself.
link() {
    local src="$1" dst="$2"
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
        note "(already linked: $dst)"
        return
    fi
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        run mv "$dst" "$dst.backup.$STAMP"
    fi
    run ln -s "$src" "$dst"
}

# `git config --global` overwrites in place and keeps no record of what it
# replaced, so take the whole file aside first -- once per run, and only on a run
# that is actually going to write something. Keys already at the wanted value are
# left alone, which keeps the plan honest: it lists changes, not intentions.
GITCONFIG_SAVED=0
gitcfg() {
    local key="$1" val="$2"
    if [ "$(git config --global --get "$key" 2>/dev/null)" = "$val" ]; then
        note "(already set: $key)"
        return
    fi
    if [ "$GITCONFIG_SAVED" = 0 ] && [ -f "$HOME/.gitconfig" ]; then
        run cp "$HOME/.gitconfig" "$HOME/.gitconfig.backup.$STAMP"
        GITCONFIG_SAVED=1
    fi
    run git config --global "$key" "$val"
}

# The optional network installs are decided once, before either pass, so the
# plan shows what will actually happen rather than a branch it might not take.
decide() {
    WANT_BREW=no
    WANT_BUNDLE=no
    if command -v brew >/dev/null; then
        WANT_BUNDLE=ask
    else
        WANT_BREW=ask
    fi
    [ "$PLAN_ONLY" = 1 ] && return          # a dry run asks nothing
    if [ "$ASSUME_YES" = 1 ]; then
        [ "$WANT_BREW" = ask ]   && WANT_BREW=yes
        [ "$WANT_BUNDLE" = ask ] && WANT_BUNDLE=yes
        return
    fi
    if [ "$WANT_BREW" = ask ]; then
        read -p "Homebrew not found. Install it? [y/N] " -n 1 -r; echo
        [[ $REPLY =~ ^[Yy]$ ]] && WANT_BREW=yes || WANT_BREW=no
    fi
    if [ "$WANT_BUNDLE" = ask ]; then
        read -p "Install Modern Unix tools (starship, eza, zoxide, ...) via Brewfile? [y/N] " -n 1 -r; echo
        [[ $REPLY =~ ^[Yy]$ ]] && WANT_BUNDLE=yes || WANT_BUNDLE=no
    fi
}

actions() {
    echo "Homebrew:"
    case "$WANT_BREW" in
        ask) note "(will ask whether to install Homebrew)" ;;
        yes) run bash -c '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
             # Configure the current session so the Brewfile step below can run
             if [ "$DRY" = 0 ]; then
                 [ -f /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
                 [ -f /usr/local/bin/brew ]    && eval "$(/usr/local/bin/brew shellenv)"
             fi ;;
        *)   note "(present: $(command -v brew 2>/dev/null || echo 'absent, skipping'))" ;;
    esac
    case "$WANT_BUNDLE" in
        ask) note "(will ask whether to run brew bundle)" ;;
        yes) run brew bundle --file="$SCRIPT_DIR/Brewfile" ;;
    esac

    echo "Oh My Zsh:"
    if [ ! -d "$OMZ_DIR" ]; then
        run sh -c 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended'
    else
        note "(already installed: $OMZ_DIR)"
    fi

    echo "Plugins:"
    local p
    for p in \
        "zsh-autosuggestions https://github.com/zsh-users/zsh-autosuggestions" \
        "zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting.git" \
        "zsh-completions https://github.com/zsh-users/zsh-completions" \
        "fzf-tab https://github.com/Aloxaf/fzf-tab"
    do
        set -- $p
        if [ ! -d "$ZSH_CUSTOM/plugins/$1" ]; then
            run git clone "$2" "$ZSH_CUSTOM/plugins/$1"
        else
            note "(already present: $1)"
        fi
    done

    echo "Configuration:"
    link "$SCRIPT_DIR/.zshrc" "$HOME/.zshrc"
    link "$SCRIPT_DIR/tips.zsh" "$HOME/.zsh_tips.zsh"

    # git reads ~/.config/git/ignore on its own, so this needs no core.excludesFile
    # key — and setting none means we can't clobber one you already have.
    run mkdir -p "$HOME/.config/git"
    link "$REPO_DIR/git/ignore" "$HOME/.config/git/ignore"

    echo "Git configuration:"
    # delta does nothing until git is told to use it
    if command -v delta >/dev/null; then
        gitcfg core.pager delta
        gitcfg interactive.diffFilter "delta --color-only"
        gitcfg delta.navigate true
    else
        note "(delta not installed, skipping pager config)"
    fi
    # difftastic on demand as `git dft`. Left off core.pager on purpose: structural
    # diffs are the right tool some of the time, not all of it. delta keeps the job.
    if command -v difft >/dev/null; then
        gitcfg difftool.difftastic.cmd 'difft "$LOCAL" "$REMOTE"'
        gitcfg alias.dft 'difftool -t difftastic'
    else
        note "(difftastic not installed, skipping git dft)"
    fi

    echo "Shell history:"
    # One time only — re-importing would duplicate every entry, so key off
    # whether the db already exists.
    if command -v atuin >/dev/null && [ ! -f "$HOME/.local/share/atuin/history.db" ]; then
        run atuin import auto
    else
        note "(nothing to import)"
    fi

    echo "User binaries:"
    run mkdir -p "$HOME/bin" "$HOME/.local/bin"
    if [ -d "/Applications/Sublime Text.app" ]; then
        link "/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl" "$HOME/bin/subl"
    fi
    if [ -d "/Applications/Sublime Merge.app" ]; then
        link "/Applications/Sublime Merge.app/Contents/SharedSupport/bin/smerge" "$HOME/bin/smerge"
    fi
}

decide

echo
echo "Plan — what this will do to $HOME:"
DRY=1 actions
echo
echo "Anything replaced is moved aside as <file>.backup.$STAMP first."

if [ "$PLAN_ONLY" = 1 ]; then
    echo "Dry run; nothing was changed."
    exit 0
fi

if [ "$ASSUME_YES" != 1 ]; then
    read -p "Proceed? [y/N] " -n 1 -r; echo
    [[ $REPLY =~ ^[Yy]$ ]] || { echo "Aborted; nothing was changed."; exit 1; }
fi

echo
echo "Running:"
DRY=0 actions
echo
echo "Setup complete! Restart your terminal or run 'zsh' to see changes."
echo "To undo a replaced file:  mv <file>.backup.$STAMP <file>"
