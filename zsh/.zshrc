# Interactive shell settings. Environment (PATH, EDITOR, ...) lives in .zprofile.

# Keep PATH and fpath free of duplicates.
typeset -U path fpath

# --- History ---------------------------------------------------------------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS
# Show `!!`-style expansions for editing instead of running them; save timestamps.
setopt HIST_VERIFY EXTENDED_HISTORY

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

# Ctrl+G: pick a project and switch to its tmux session (bin/tmux-project).
# Whatever was typed comes back at the next prompt; the leading space keeps the
# command out of history.
_tmux_project() { zle push-input; BUFFER=' tmux-project'; zle accept-line }
zle -N _tmux_project
bindkey '^G' _tmux_project

# --- Aliases ---------------------------------------------------------------
# Local IP of the interface with the default route (Wi-Fi, Ethernet, ...)
# (`function ip` rather than `ip()`: re-sourcing this file in a shell that still
# has the old `ip` alias would otherwise alias-expand it into a parse error.)
function ip { ipconfig getifaddr "$(route -n get default | awk '/interface:/ {print $2}')" }

# eza instead of ls
alias ls="eza --group-directories-first"
alias ll="eza -l --git --icons --group-directories-first"
alias la="eza -la --git --icons --group-directories-first"
alias lt="eza --tree --level=2 --icons --git-ignore"

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

# --- Node (fnm) -----------------------------------------------------------
# .zprofile puts fnm's default Node on PATH. fnm's own env (a per-shell
# multishell dir, so it can't be cached) loads on first use: a `fnm` call or
# a directory fnm reads a version from (same check as fnm's cd hook).
autoload -Uz add-zsh-hook
_fnm_init() {
  unfunction fnm _fnm_init
  add-zsh-hook -d chpwd _fnm_lazy_chpwd
  eval "$(command fnm env --use-on-cd --shell zsh)"
}
fnm() { _fnm_init && fnm "$@" }
_fnm_lazy_chpwd() {
  [[ -f .node-version || -f .nvmrc || -f package.json ]] || return 0
  _fnm_init && _fnm_autoload_hook
}
add-zsh-hook chpwd _fnm_lazy_chpwd
_fnm_lazy_chpwd  # the shell may start inside a project

# --- Machine-specific / secret settings (not in the repo) -------------------
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

# --- Plugins & prompt (keep last) -----------------------------------------
# fzf: Ctrl+R history, Ctrl+T files, Alt+C cd, `**<Tab>` completion.
# Sourced directly rather than `source <(fzf --zsh)` to avoid a fork.
# fd lists files instead of find: faster, and skips .gitignore'd paths.
export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:200 {}'"
export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git'
source "$HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh"
source "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh"
source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
# Source a tool's shell init from ~/.cache/zsh instead of running the tool on
# every shell start. One cache per installed version (the Cellar dir in the
# binary's resolved path), rebuilt when <dependency> is newer. Built in a temp
# file and renamed into place, so shells starting at once (e.g. tmux restoring
# panes) never source a half-written cache, and a failing tool doesn't leave a
# broken one behind.
_cached_init() {  # _cached_init <binary> <dependency or ""> <command...>
  local bin=$1 dep=$2; shift 2
  local cache=${XDG_CACHE_HOME:-$HOME/.cache}/zsh/${bin:t}-${${bin:A:h:h}:t}.zsh
  if [[ ! -s $cache || ( -n $dep && $dep -nt $cache ) ]]; then
    local tmp=$cache.$$ old
    mkdir -p ${cache:h}
    if "$@" >| $tmp && mv -f $tmp $cache; then
      old=( ${cache:h}/${bin:t}-*.zsh(N) )
      rm -f ${old:#$cache}
    else
      rm -f $tmp
    fi
  fi
  [[ -r $cache ]] && source $cache
}

# Starship's init with PROMPT2 baked in: the init would otherwise fork
# `starship prompt --continuation` on every shell.
_starship_init() {
  local bin=$HOMEBREW_PREFIX/bin/starship
  $bin init zsh | grep -v '^PROMPT2=' && (( ! pipestatus[1] )) &&
    print -r -- "PROMPT2=${(q)$(STARSHIP_SHELL=zsh $bin prompt --continuation)}"
}

# zoxide: `z <part of a path>` jumps to a frequently used directory, `zi` picks
# one with fzf. Plain `cd` is unchanged.
_cached_init $HOMEBREW_PREFIX/bin/zoxide "" $HOMEBREW_PREFIX/bin/zoxide init zsh
_cached_init $HOMEBREW_PREFIX/bin/starship ~/.config/starship.toml _starship_init
unfunction _cached_init _starship_init
