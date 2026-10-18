# Interactive shell settings. Environment (PATH, EDITOR, ...) lives in .zprofile.

# Keep PATH and fpath free of duplicates.
typeset -U path fpath

# --- History ---------------------------------------------------------------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS

# --- Shell options ---------------------------------------------------------
setopt AUTO_CD INTERACTIVE_COMMENTS

# --- Completion ------------------------------------------------------------
fpath=(
  $HOMEBREW_PREFIX/share/zsh-completions(N)
  $HOME/.docker/completions(N)
  $fpath
)
# Full security check and dump rebuild at most once a day; otherwise reuse the
# cached dump (new completions show up after the daily rebuild or `rm ~/.zcompdump`).
autoload -Uz compinit
() {
  if (( $# )); then
    compinit && touch $1  # compinit only rewrites the dump if completions changed
  else
    compinit -C
  fi
} ${ZDOTDIR:-$HOME}/.zcompdump(N.mh+24)
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors ''

# Up/down arrows search history for what has been typed so far.
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search

# --- Aliases ---------------------------------------------------------------
alias ip="ipconfig getifaddr en0"

# Config shortcuts
alias zshconfig='$EDITOR ~/.zshrc'
alias zshsource="exec zsh"
alias sshhome="cd ~/.ssh"
alias sshconfig='$EDITOR ~/.ssh/config'
alias gitconfig='$EDITOR ~/.gitconfig'

# Git
alias gits="git status"
alias gitd="git diff"
alias gitl="git lg"
alias gita="git add ."

alias loc="npx sloc --format cli-table --format-option head --exclude 'build|\.svg$|\.xml$' ./"

# --- Machine-specific / secret settings (not in the repo) -------------------
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

# --- Plugins & prompt (keep last) -----------------------------------------
source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
eval "$(starship init zsh)"
