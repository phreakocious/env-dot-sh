# env.sh

Just one way to setup your macOS terminal environment.

## Features

- **Prompt:** [Starship](https://starship.rs/) for a fast, customizable, and cross-shell prompt.
- **Framework:** [Oh My Zsh](https://ohmyz.sh/) for plugin management and robust defaults.
- **Modern Unix Upgrades:**
    - `eza`: A modern replacement for `ls` (with icons and git integration).
    - `zoxide`: Takes over `cd` so it jumps by keyword and learns your habits (`cdi` to pick interactively).
    - `bat`: A `cat` clone with syntax highlighting and Git integration.
    - `ripgrep` (`rg`): An extremely fast alternative to `grep`.
    - `fd`: A simple, fast, and user-friendly alternative to `find`.
    - `fzf`: A general-purpose command-line fuzzy finder.
    - `tldr`: Simplified and community-driven man pages.
- **History:** [`atuin`](https://atuin.sh/) replaces `Ctrl-R` with a SQLite-backed search that records exit code, duration, and working directory. Press `Tab` inside it to scope results to the current directory. Local-only unless you run `atuin register`.
- **Git:**
    - `delta`: A syntax-highlighting pager, wired in as git's default.
    - `difftastic`: A structural diff that ignores pure reformatting, on demand via `git dft`.
    - `lazygit`: A TUI for staging hunks, rebasing, and cherry-picking.
    - `gh`: The GitHub CLI.
- **Inspecting the machine:** `dust` (`du`), `duf` (`df`), `btop` (`top`), `hyperfine` (benchmarking), `jq` (JSON).
- **Enhanced Completion:** `fzf-tab` replaces the default Zsh completion menu with an interactive fuzzy finder.
- **Productivity:**
    - `zsh-autosuggestions`: Fish-like fast autosuggestions.
    - `zsh-syntax-highlighting`: Fish-like syntax highlighting for the command line.
    - `vi-mode`: Robust Vi/Vim keybindings for the shell.
- **Daily Tips:** A custom "Tip of the Day" system to help you discover new CLI tools and shortcuts.

### What this deliberately doesn't do

**`grep` and `find` are left alone.** `rg` and `fd` are better, but they aren't drop-in replacements, and shadowing the originals hides that. The flag differences are easy to spot; the dialect differences aren't. `grep 'a\+b'` is a POSIX basic regex meaning "one or more `a`", while `rg 'a\+b'` matches a literal `+` — both compile, neither errors, and the results differ. `fd`'s pattern is a regex rather than a glob, and it skips hidden files by default. So type `rg` and `fd` when you want them. As a bonus, your habits keep working on a bare server.

`ls` is the exception: it's wrapped, because `eza` genuinely is close enough and `ls -ltr` is too deep in the fingers to give up.

## Installation

The setup is automated via a bootstrap script. It will handle Homebrew, Oh My Zsh, plugins, and configuration linking.

```bash
# Clone the repository
git clone https://github.com/your-username/env-dot-sh.git
cd env-dot-sh

# See exactly what it would do, and change nothing
./zsh/setup.sh --dry-run

# Run it (prints the same plan, then asks once before doing anything)
./zsh/setup.sh
```

The plan is not a description written beside the code — it is the same code path
with execution suppressed, so it cannot drift from what actually runs. Lines are
printed shell-quoted, so you can paste any one of them back to check it.

### What the script does:
1.  **Homebrew:** Installs Homebrew if missing and bundles all required tools via `zsh/Brewfile`.
2.  **Oh My Zsh:** Installs the framework and essential third-party plugins.
3.  **Config:** Backs up your existing `~/.zshrc`, then *symlinks* the repo copy — so edits here take effect immediately. Re-running is safe.
4.  **Git:** Links `git/ignore` to `~/.config/git/ignore` so Finder and editor droppings are ignored in *every* repo on the machine, and points `git` at `delta` for diffs. It copies `~/.gitconfig` aside before the first key it changes, and skips any key already at the wanted value — so a re-run on a configured machine writes nothing and leaves no backup.
5.  **Utilities:** Sets up `~/bin` and links common applications like Sublime Text (`subl`) and Sublime Merge (`smerge`) if found.

> **Set your terminal font to Hack Nerd Font afterwards.** The Brewfile installs it, but `eza --icons` and Starship's default prompt symbols render as tofu until your terminal profile actually selects it.

## Maintenance & Customization

### Adding New Tools
To keep the environment consistent, follow these steps when adding a new CLI tool:

1.  **`zsh/Brewfile`**: Add the package here to ensure it's tracked.
2.  **`zsh/.zshrc`**: Add aliases or initialization logic (e.g., `eval "$(tool init zsh)"`).
3.  **`zsh/tips.zsh`**: Add a new entry to the `tips` array so you (and others) learn how to use it!

### Local Overrides
If you have machine-specific configurations (like work email or private aliases), add them to `~/.zshrc.local`. This file is automatically sourced at the end of `.zshrc` and is ignored by git.

The one path you are likely to want there is your project tree, which defaults to `~/projects`:

```zsh
PROJECTS=/mnt/big-disk/code    # ~projects and $PROJECTS both follow this
```

## Daily Tips
Every time you open a new shell, a random tip is displayed from `zsh/tips.zsh`. This is a great way to build muscle memory for modern tools.

Example:
> `📂 **Eza:** Modern replacement for ls. Use -T for tree view.`

> `Try: lt (alias for eza --tree)`
