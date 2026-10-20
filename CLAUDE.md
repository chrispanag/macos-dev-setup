# CLAUDE.md

Backup of a personal macOS (Apple Silicon) development setup, published as a **public** repository: https://github.com/chrispanag/macos-dev-setup

## Rules

- **No sensitive data, ever.** No secrets, tokens, credentials, hostnames, IPs, employer-specific details, usernames, or absolute paths containing the home directory (use `$HOME` / `~`). Before every commit, scan the staged diff for these. The gitleaks pre-commit hook (`.githooks/`, rules in `.gitleaks.toml`) catches tokens, keys, emails and home paths automatically, but not hostnames or employer details. Never bypass it with `--no-verify`. Secrets and machine-specific settings belong in `~/.zshrc.local`, which is gitignored and never committed.
- **Don't touch the live system without asking.** The repo is the source of truth, but changing files in `~` (dotfiles, symlinks), installing/uninstalling packages, or running `brew bundle` needs the user's go-ahead.
- **Keep the README and `install.sh` in sync.** Every new tool or config file gets a step in the step-by-step install guide in `README.md`, in the order it must run on a fresh Mac, and the matching change in `install.sh`.
- Use American English in docs and commit messages.

## Layout

- `Brewfile` – curated by hand, grouped by category with comments. Never regenerate it with `brew bundle dump`. Verify with `brew bundle check --file=Brewfile --verbose`.
- `zsh/.zprofile` – environment for login shells: Homebrew env (`brew shellenv` output, inlined), `EDITOR`/`VISUAL`, PATH entries including fnm's default Node. Not `.zshenv`, because macOS `path_helper` in `/etc/zprofile` would reorder PATH.
- `zsh/.zshrc` – interactive-only settings: history, options, completion, keybindings, aliases, lazy `fnm env` (loads on first `fnm` call or a cd into a Node project), plugins, and the cached `zoxide init` and `starship init` (last; `_cached_init`, cache in `~/.cache/zsh`). Plain zsh, no Oh My Zsh; plugins come from Homebrew.
- `ghostty/config` – Ghostty terminal config. Only non-default settings.
- `zed/settings.json` – Zed editor settings (JSONC). Extensions go in `auto_install_extensions` so a fresh machine gets them.
- `tmux/tmux.conf` – tmux config; plugins via tpm from Homebrew (resurrect + continuum).
- `bin/` – personal scripts, symlinked into `~/.local/bin` (on PATH). `tmux-project` is the project/session switcher bound to Ctrl+G (zsh) and prefix + j (tmux), and run by new Ghostty shells (`TMUX_PROJECT_AUTOSTART` from ghostty/config).
- `macos/defaults.sh` – macOS system settings via `defaults write`. Only values that differ from the macOS defaults; idempotent.
- `git/config`, `git/ignore` – shared git settings and global gitignore, symlinked into `~/.config/git`. Identity (`user.*`) and machine-specific settings stay in `~/.gitconfig`, which is never committed.
- `install.sh` – first-time setup following the README steps; idempotent, bash 3.2 compatible (macOS `/bin/bash`), `--check` changes nothing, `--links` only links. A new config file goes in its `LINKS` list, and a new setup step gets a function there. Check with `shellcheck install.sh`.
- Config files are symlinked into `~` (see the README steps), so editing the repo changes the live setup.

## Conventions

- Node is managed by `fnm` (default = `lts-latest`), not nvm.
- Shell startup time matters (currently ~35-40ms). Avoid adding subprocesses (`$(...)`, `eval`) to startup; prefer zsh builtins and glob qualifiers, and guard optional paths with `(N)`.
- Test shell config changes without touching `~`: copy `zsh/` into a scratch dir and run
  `env -i HOME=$HOME TERM=xterm USER=$USER ZDOTDIR=<scratch> zsh -il -c '<check>'`.
  Check syntax with `zsh -n`.
