# env.sh

Just one way to setup your macOS terminal environment.

## Features

- **Prompt:** [Starship](https://starship.rs/) for a fast, customizable, and cross-shell prompt.
- **Framework:** [Oh My Zsh](https://ohmyz.sh/) for plugin management and robust defaults.
- **Modern Unix Upgrades:**
    - `eza`: A modern replacement for `ls` (with icons and git integration).
    - `zoxide`: A smarter `cd` command that learns your habits (`z`).
    - `bat`: A `cat` clone with syntax highlighting and Git integration.
    - `ripgrep` (`rg`): An extremely fast alternative to `grep`.
    - `fd`: A simple, fast, and user-friendly alternative to `find`.
    - `fzf`: A general-purpose command-line fuzzy finder.
    - `tldr`: Simplified and community-driven man pages.
    - `delta`: A syntax-highlighting pager for git, diff, and grep output.
- **Enhanced Completion:** `fzf-tab` replaces the default Zsh completion menu with an interactive fuzzy finder.
- **Productivity:**
    - `zsh-autosuggestions`: Fish-like fast autosuggestions.
    - `zsh-syntax-highlighting`: Fish-like syntax highlighting for the command line.
    - `vi-mode`: Robust Vi/Vim keybindings for the shell.
- **Daily Tips:** A custom "Tip of the Day" system to help you discover new CLI tools and shortcuts.

## Installation

The setup is automated via a bootstrap script. It will handle Homebrew, Oh My Zsh, plugins, and configuration linking.

```bash
# Clone the repository
git clone https://github.com/your-username/env-dot-sh.git
cd env-dot-sh

# Run the setup script
./zsh/setup.sh
```

### What the script does:
1.  **Homebrew:** Installs Homebrew if missing and bundles all required tools via `zsh/Brewfile`.
2.  **Oh My Zsh:** Installs the framework and essential third-party plugins.
3.  **Config:** Backs up your existing `~/.zshrc` and links the new configuration.
4.  **Utilities:** Sets up `~/bin` and links common applications like Sublime Text (`subl`) and Sublime Merge `smerge`) if found.

## Maintenance & Customization

### Adding New Tools
To keep the environment consistent, follow these steps when adding a new CLI tool:

1.  **`zsh/Brewfile`**: Add the package here to ensure it's tracked.
2.  **`zsh/.zshrc`**: Add aliases or initialization logic (e.g., `eval "$(tool init zsh)"`).
3.  **`zsh/tips.zsh`**: Add a new entry to the `tips` array so you (and others) learn how to use it!

### Local Overrides
If you have machine-specific configurations (like work email or private aliases), add them to `~/.zshrc.local`. This file is automatically sourced at the end of `.zshrc` and is ignored by git.

## Daily Tips
Every time you open a new shell, a random tip is displayed from `zsh/tips.zsh`. This is a great way to build muscle memory for modern tools.

Example:
> `📂 **Eza:** Modern replacement for ls. Use -T for tree view.`

> `Try: lt (alias for eza --tree)`
