# CLAUDE.md

Backup of a personal macOS (Apple Silicon) development setup, published as a **public** repository: https://github.com/chrispanag/macos-dev-setup

## Rules

- **No sensitive data, ever.** No secrets, tokens, credentials, hostnames, IPs, employer-specific details, usernames, or absolute paths containing the home directory (use `$HOME` / `~`). Before every commit, scan the staged diff for these. Secrets and machine-specific settings belong in `~/.zshrc.local`, which is gitignored and never committed.
- **Don't touch the live system without asking.** The repo is the source of truth, but changing files in `~` (dotfiles, symlinks), installing/uninstalling packages, or running `brew bundle` needs the user's go-ahead.
- **Keep the README in sync.** Every new tool or config file gets a step in the step-by-step install guide in `README.md`, in the order it must run on a fresh Mac.
- Use American English in docs and commit messages.

## Layout

- `Brewfile` – curated by hand, grouped by category with comments. Never regenerate it with `brew bundle dump`. Verify with `brew bundle check --file=Brewfile --verbose`.
- `zsh/.zprofile` – environment for login shells: `brew shellenv`, `EDITOR`, PATH entries, `fnm env`. Not `.zshenv`, because macOS `path_helper` in `/etc/zprofile` would reorder PATH.
- `zsh/.zshrc` – interactive-only settings: history, options, completion, keybindings, aliases, plugins, and `starship init` (last). Plain zsh, no Oh My Zsh; plugins come from Homebrew.
- `ghostty/config` – Ghostty terminal config. Only non-default settings.
- `zed/settings.json` – Zed editor settings (JSONC). Extensions go in `auto_install_extensions` so a fresh machine gets them.
- `tmux/tmux.conf` – tmux config; plugins via tpm from Homebrew (resurrect + continuum).
- `macos/defaults.sh` – macOS system settings via `defaults write`. Only values that differ from the macOS defaults; idempotent.
- Config files are symlinked into `~` (see README steps 5 and 6), so editing the repo changes the live setup.

## Conventions

- Node is managed by `fnm` (default = `lts-latest`), not nvm.
- Shell startup time matters (currently ~60ms without plugins). Avoid adding subprocesses (`$(...)`, `eval`) to startup; prefer zsh builtins and glob qualifiers, and guard optional paths with `(N)`.
- Test shell config changes without touching `~`: copy `zsh/` into a scratch dir and run
  `env -i HOME=$HOME TERM=xterm USER=$USER ZDOTDIR=<scratch> zsh -il -c '<check>'`.
  Check syntax with `zsh -n`.
