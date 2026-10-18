# Environment for login shells (every new terminal on macOS). Interactive-only
# settings live in .zshrc. Must be here rather than .zshenv: /etc/zprofile runs
# path_helper after .zshenv and would push system paths ahead of these.

eval "$(/opt/homebrew/bin/brew shellenv)"

export EDITOR=vim

# Node: fnm's `default` alias (lts-latest), switching on cd into a project
# with .nvmrc / .node-version.
eval "$(fnm env --use-on-cd --shell zsh)"

# pnpm global packages
export PNPM_HOME="$HOME/Library/pnpm"

typeset -U path
path=(
  $HOME/.local/bin
  $PNPM_HOME
  $HOME/go/bin
  $HOME/.cargo/bin
  $HOMEBREW_PREFIX/opt/rustup/bin
  $path
)

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :
