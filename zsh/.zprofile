# Environment for login shells (every new terminal on macOS). Interactive-only
# settings live in .zshrc. Must be here rather than .zshenv: /etc/zprofile runs
# path_helper after .zshenv and would push system paths ahead of these.

# Homebrew (Apple Silicon): the output of `brew shellenv`, inlined to save
# forking brew (a bash script) on every login shell.
export HOMEBREW_PREFIX=/opt/homebrew
export HOMEBREW_CELLAR=$HOMEBREW_PREFIX/Cellar
export HOMEBREW_REPOSITORY=$HOMEBREW_PREFIX
[[ -n ${MANPATH-} ]] && export MANPATH=":${MANPATH#:}"  # keep man's default search path
export INFOPATH="$HOMEBREW_PREFIX/share/info:${INFOPATH:-}"
fpath[1,0]=$HOMEBREW_PREFIX/share/zsh/site-functions
export FPATH
export HOMEBREW_NO_ENV_HINTS=1  # hide "Adjust how often this is run with..." hints

export EDITOR=vim
# GUI editor for git commit, crontab -e, etc. EDITOR stays vim as the
# terminal-only fallback (e.g. over SSH).
export VISUAL="zed --wait"
export BAT_THEME="Catppuccin Mocha"  # matches the Ghostty theme

# Node: fnm's `default` alias (lts-latest). fnm's per-shell env, which
# switches versions on cd, loads lazily in .zshrc.
export FNM_DIR="$HOME/.local/share/fnm"

# pnpm global packages
export PNPM_HOME="$HOME/Library/pnpm"

typeset -U path
path=(
  $HOME/.local/bin
  $PNPM_HOME
  $HOME/go/bin
  $HOME/.cargo/bin
  $HOMEBREW_PREFIX/opt/rustup/bin
  $FNM_DIR/aliases/default/bin
  $HOMEBREW_PREFIX/bin
  $HOMEBREW_PREFIX/sbin
  $path
)

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :
