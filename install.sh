#!/bin/bash
# First-time setup of a new Mac from this repo, following the steps in
# README.md. Every step checks what is already done, so it is safe to re-run.
#
#   ./install.sh           full setup
#   ./install.sh --check   report what is missing; changes nothing
#   ./install.sh --links   only (re)create the config symlinks
#
# Written for the bash 3.2 that ships with macOS.
#
# A literal ~ in messages and in the ssh config line is intentional:
# shellcheck disable=SC2088
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
BREW_PREFIX=/opt/homebrew

# Config symlinks, "repo path:link path" (link path relative to $HOME).
LINKS=(
  "zsh/.zshrc:.zshrc"
  "zsh/.zprofile:.zprofile"
  "starship/starship.toml:.config/starship.toml"
  "ghostty/config:.config/ghostty/config"
  "tmux/tmux.conf:.tmux.conf"
  "zed/settings.json:.config/zed/settings.json"
  "git/config:.config/git/config"
  "git/ignore:.config/git/ignore"
)
# Every script in bin/ goes into ~/.local/bin (on PATH, see zsh/.zprofile).
for script in "$REPO"/bin/*; do
  [[ -e $script ]] || continue  # bin/ is empty (no nullglob in bash 3.2)
  LINKS+=("bin/${script##*/}:.local/bin/${script##*/}")
done

# --- Output helpers -------------------------------------------------------
if [[ -t 1 ]]; then
  bold=$'\e[1m' green=$'\e[32m' yellow=$'\e[33m' red=$'\e[31m' reset=$'\e[0m'
else
  bold='' green='' yellow='' red='' reset=''
fi
step() { printf '\n%s==> %s%s\n' "$bold" "$1" "$reset"; }
ok()   { printf '  %s✓%s %s\n' "$green" "$reset" "$1"; }
warn() { printf '  %s!%s %s\n' "$yellow" "$reset" "$1"; PROBLEMS=$((PROBLEMS + 1)); }
note() { printf '  - %s\n' "$1"; }
die()  { printf '%s✗ %s%s\n' "$red" "$1" "$reset" >&2; exit 1; }
PROBLEMS=0

# Prompt on the terminal; returns 1 when there is none (e.g. piped input).
ask() {  # ask <prompt> <variable>
  { : < /dev/tty; } 2> /dev/null || return 1
  printf '  %s ' "$1" > /dev/tty
  IFS= read -r "$2" < /dev/tty
}
confirm() {  # confirm <question>  (default yes)
  local answer
  ask "$1 [Y/n]" answer || return 1
  [[ -z $answer || $answer == [Yy]* ]]
}

# --- Steps ------------------------------------------------------------------
preflight() {
  step "Preflight"
  [[ $(uname -s) == Darwin ]] || die "This script is for macOS."
  [[ $(uname -m) == arm64 ]] || die "This setup assumes Apple Silicon (Homebrew in $BREW_PREFIX)."
  if xcode-select -p > /dev/null 2>&1; then
    ok "Xcode Command Line Tools"
  elif [[ $MODE == check ]]; then
    warn "Xcode Command Line Tools missing (xcode-select --install)"
  else
    xcode-select --install || true
    die "Finish the Command Line Tools install in the dialog, then re-run ./install.sh."
  fi
}

homebrew() {
  step "Homebrew"
  if [[ ! -x $BREW_PREFIX/bin/brew ]]; then
    [[ $MODE == check ]] && { warn "Homebrew not installed"; return; }
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    [[ -x $BREW_PREFIX/bin/brew ]] || die "Homebrew install failed (see above); re-run ./install.sh."
  fi
  eval "$("$BREW_PREFIX/bin/brew" shellenv)"
  ok "Homebrew $(brew --version | awk '{print $2; exit}')"
}

brew_bundle() {
  step "Brewfile packages"
  command -v brew > /dev/null || return 0
  if brew bundle check --file="$REPO/Brewfile" > /dev/null 2>&1; then
    ok "Everything in the Brewfile is installed"
    return
  elif [[ $MODE == check ]]; then
    warn "Missing or outdated packages (brew bundle check --file=Brewfile --verbose)"
    return
  fi
  # Third-party tap formulae need explicit trust (see README step 4): every
  # tap-qualified `brew "user/tap/name"` line in the Brewfile.
  local formula tapped=()
  while IFS= read -r formula; do
    tapped+=("$formula")
  done < <(sed -n 's|^brew "\([^"/]*/[^"/]*/[^"/]*\)".*|\1|p' "$REPO/Brewfile")
  if (( ${#tapped[@]} )); then
    brew trust --formula "${tapped[@]}"
  fi
  brew bundle --file="$REPO/Brewfile" || warn "brew bundle reported errors (see above); re-run to retry"
}

zsh_completions() {
  step "zsh completion directories"
  command -v brew > /dev/null || return 0
  # zsh refuses to load completions from group-writable directories.
  local insecure
  # Same directories zsh/.zshrc and zsh/.zprofile add to fpath.
  insecure=$(zsh -c 'fpath=($HOMEBREW_PREFIX/share/zsh-completions(N) $HOME/.docker/completions(N)
    $HOMEBREW_PREFIX/share/zsh/site-functions(N) $fpath)
    autoload -Uz compaudit; compaudit 2>/dev/null' || true)
  if [[ -z $insecure ]]; then
    ok "No insecure directories"
  elif [[ $MODE == check ]]; then
    warn "Insecure completion directories: ${insecure//$'\n'/ }"
  else
    local dir
    while IFS= read -r dir; do
      if chmod go-w "$dir"; then
        ok "Removed group write access from ${dir/#$HOME/~}"
      else
        warn "Couldn't fix $dir (chmod go-w it by hand)"
      fi
    done <<< "$insecure"
  fi
}

git_identity() {
  step "git identity (~/.gitconfig, never committed)"
  local key value prompt
  for key in user.name user.email user.signingkey; do
    if git config --file "$HOME/.gitconfig" "$key" > /dev/null 2>&1; then
      ok "$key is set"
      continue
    fi
    if [[ $MODE == check ]]; then
      warn "$key missing from ~/.gitconfig"
      continue
    fi
    case $key in
      user.name) prompt="Your name for git commits:" ;;
      user.email) prompt="Your email for git commits:" ;;
      user.signingkey)
        echo "  Commits are signed with an SSH key in 1Password. Open 1Password, sign in,"
        echo "  turn on Settings > Developer > Use the SSH agent, then copy the key's public key."
        prompt="Paste the public key (ssh-ed25519 AAAA...), or Enter to skip:" ;;
    esac
    if ask "$prompt" value && [[ -n $value ]]; then
      git config --file "$HOME/.gitconfig" "$key" "$value"
      ok "$key saved"
    else
      warn "$key not set; commits fail until it is (git config --file ~/.gitconfig $key ...)"
    fi
  done
}

links() {
  step "Config symlinks"
  # git/config gets linked into ~/.config/git; ~/.gitconfig must exist so that
  # `git config --global` (and `gh auth login`) write there, not into the repo.
  if [[ ! -e $HOME/.gitconfig ]]; then
    if [[ $MODE == check ]]; then
      warn "~/.gitconfig missing, so \`git config --global\` would write into the repo"
    else
      touch "$HOME/.gitconfig"
    fi
  fi
  local entry rel src dest exists backup
  for entry in "${LINKS[@]}"; do
    rel=${entry#*:}
    src="$REPO/${entry%%:*}"
    dest="$HOME/$rel"
    if [[ -L $dest && $(readlink "$dest") == "$src" ]]; then
      ok "~/$rel"
      continue
    fi
    exists=; [[ -e $dest || -L $dest ]] && exists=1
    if [[ $MODE == check ]]; then
      if [[ -n $exists ]]; then
        warn "~/$rel exists but is not a link to the repo"
      else
        warn "~/$rel missing"
      fi
      continue
    fi
    mkdir -p "$(dirname "$dest")"
    if [[ -n $exists ]]; then
      backup="$dest.backup-$(date +%Y%m%d-%H%M%S)"
      mv "$dest" "$backup"
      echo "  Backed up the existing file to ${backup/#$HOME/~}"
    fi
    ln -s "$src" "$dest"
    ok "~/$rel -> ${src/#$HOME/~}"
  done
}

repo_hooks() {
  step "Secret scan before each commit to this repo"
  # .githooks/pre-commit runs gitleaks with the rules in .gitleaks.toml.
  if [[ $(git -C "$REPO" config --get core.hooksPath) == .githooks ]]; then
    ok "core.hooksPath is .githooks"
  elif [[ $MODE == check ]]; then
    warn "Pre-commit hook not enabled (git config core.hooksPath .githooks)"
  else
    git -C "$REPO" config core.hooksPath .githooks
    ok "Enabled the pre-commit hook (core.hooksPath = .githooks)"
  fi
}

ssh_agent() {
  step "ssh uses the 1Password agent"
  local config="$HOME/.ssh/config"
  local agent='~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock'
  # Match on the part after "Group Containers/" so a config that spells out
  # the home directory instead of ~ also counts.
  if grep -qsF "${agent#*Group Containers/}" "$config"; then
    ok "IdentityAgent set in ~/.ssh/config"
    return
  fi
  [[ $MODE == check ]] && { warn "~/.ssh/config has no 1Password IdentityAgent"; return; }
  mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
  printf '\nHost *\n  IdentityAgent "%s"\n' "$agent" >> "$config"
  chmod 600 "$config"
  ok "Added IdentityAgent to ~/.ssh/config"
}

toolchains() {
  step "Language toolchains"
  command -v brew > /dev/null || return 0
  # Same FNM_DIR as zsh/.zprofile, so fnm installs where the shell looks.
  export FNM_DIR="${FNM_DIR:-$HOME/.local/share/fnm}"
  local rustup="$BREW_PREFIX/opt/rustup/bin/rustup" toolchain
  if [[ -e $FNM_DIR/aliases/default ]]; then
    ok "Node: fnm default is set"
  elif [[ $MODE == check ]]; then
    warn "Node: no fnm default (fnm install --lts && fnm default lts-latest)"
  elif fnm install --lts && fnm default lts-latest; then
    ok "Node: installed the latest LTS as the fnm default"
  else
    warn "Node: fnm install failed (fnm install --lts && fnm default lts-latest)"
  fi
  if [[ ! -x $rustup ]]; then
    warn "Rust: rustup not installed (it's in the Brewfile)"
  elif toolchain=$("$rustup" default 2> /dev/null); then
    ok "Rust: ${toolchain%% *} is the default toolchain"
  elif [[ $MODE == check ]]; then
    warn "Rust: no default toolchain (rustup default stable)"
  elif "$rustup" default stable; then
    ok "Rust: stable is the default toolchain"
  else
    warn "Rust: couldn't set a default toolchain (rustup default stable)"
  fi
}

tmux_plugins() {
  step "tmux plugins"
  local tpm="$BREW_PREFIX/opt/tpm/share/tpm/bin/install_plugins"
  # Every `set -g @plugin 'owner/name'` in tmux.conf, installed as ~/.tmux/plugins/name.
  local plugin missing=
  while IFS= read -r plugin; do
    [[ -d $HOME/.tmux/plugins/${plugin##*/} ]] || missing+=" ${plugin##*/}"
  done < <(sed -n "s|^set -g @plugin '\([^']*\)'.*|\1|p" "$REPO/tmux/tmux.conf")
  if [[ -z $missing ]]; then
    ok "All plugins from tmux.conf installed"
  elif [[ $MODE == check ]]; then
    warn "tmux plugins missing:$missing (prefix + I in tmux)"
  elif [[ ! -x $tpm ]]; then
    warn "tpm not installed (it's in the Brewfile)"
  elif "$tpm" > /dev/null; then
    ok "Installed the plugins from tmux.conf"
  else
    warn "tpm failed to install the plugins (prefix + I in tmux)"
  fi
}

macos_defaults() {
  step "macOS settings"
  if [[ $MODE == check ]]; then
    ok "Skipped (not checkable; run ./macos/defaults.sh to apply)"
  elif confirm "Apply macOS settings from macos/defaults.sh? Dock and Finder restart."; then
    "$REPO/macos/defaults.sh"
  else
    echo "  Skipped. Run ./macos/defaults.sh later."
  fi
}

github() {
  step "GitHub (gh login and SSH keys)"
  command -v gh > /dev/null || { warn "gh not installed (it's in the Brewfile)"; return; }
  local scopes=admin:public_key,admin:ssh_signing_key
  if gh auth status > /dev/null 2>&1; then
    ok "gh is logged in"
  elif [[ $MODE == check ]]; then
    warn "gh is not logged in (gh auth login)"
    return
  else
    # Default gh scopes can't read or add SSH keys; ask for those up front.
    gh auth login --hostname github.com --git-protocol https --web --scopes "$scopes" ||
      { warn "gh login failed"; return; }
  fi

  # The signing key doubles as the SSH key for pushes; register it for both.
  local key
  key=$(git config --file "$HOME/.gitconfig" user.signingkey 2>/dev/null | awk '{print $1" "$2}') || true
  [[ -n $key ]] || { warn "No user.signingkey, so no key to add to GitHub"; return; }
  local pair endpoint type keys
  for pair in keys:authentication ssh_signing_keys:signing; do
    endpoint=${pair%%:*} type=${pair#*:}
    if ! keys=$(gh api --paginate "user/$endpoint" --jq '.[].key' 2> /dev/null); then
      if [[ $MODE == check ]]; then
        note "Can't check the $type key on GitHub: the gh token lacks the key scopes (./install.sh asks for them)"
        continue
      fi
      # Logged in earlier without the key scopes.
      if ! gh auth refresh --hostname github.com --scopes "$scopes" ||
        ! keys=$(gh api --paginate "user/$endpoint" --jq '.[].key'); then
        warn "Couldn't list the $type keys on GitHub"
        continue
      fi
    fi
    if awk -v k="$key" '$1" "$2 == k { found = 1 } END { exit !found }' <<< "$keys"; then
      ok "Key is on GitHub as the $type key"
    elif [[ $MODE == check ]]; then
      warn "Key not on GitHub as the $type key"
    elif printf '%s\n' "$key" |
      gh ssh-key add - --title "1Password ($(scutil --get ComputerName))" --type "$type"; then
      ok "Added the key to GitHub as the $type key"
    else
      warn "Couldn't add the key to GitHub as the $type key"
    fi
  done
}

# --- Main -------------------------------------------------------------------
MODE=install
case ${1:-} in
  "") ;;
  --check) MODE=check ;;
  --links) links; exit 0 ;;
  -h|--help) sed -n '2,8s/^# \{0,1\}//p' "$0"; exit 0 ;;
  *) die "Unknown option: $1 (see --help)" ;;
esac

preflight
homebrew
brew_bundle
zsh_completions
git_identity
links
repo_hooks
ssh_agent
toolchains
tmux_plugins
macos_defaults
github

if [[ $MODE == check ]]; then
  step "Result"
  if (( PROBLEMS )); then
    printf '  %d item(s) need attention; ./install.sh fixes most of them.\n' "$PROBLEMS"
    exit 1
  fi
  ok "Everything is set up"
  exit 0
fi

step "Done. A few things need a manual step:"
cat << 'EOF'
  - Open a new terminal (Ghostty) to load the new shell config.
  - Ghostty quick terminal (ctrl+`): allow Ghostty under System Settings >
    Privacy & Security > Accessibility.
  - Restart Zed so it installs its extensions.
  - Optional: brew services start postgresql@18 / redis.
  - Log out and back in for the remaining macOS settings to apply.
EOF
(( PROBLEMS == 0 )) || printf '\n  %s%d warning(s) above.%s Re-run ./install.sh after fixing them.\n' "$yellow" "$PROBLEMS" "$reset"
