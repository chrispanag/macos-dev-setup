# macos-setup

My macOS setup, so a new machine can be brought up quickly and reproducibly.

## Step-by-step install

### 1. Install the Xcode Command Line Tools

Needed for `git` and for compiling anything Homebrew can't install from a bottle.

```sh
xcode-select --install
```

### 2. Install Homebrew

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Then add Homebrew to your shell, as the installer tells you to (Apple Silicon path shown):

```sh
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

### 3. Clone this repository

```sh
mkdir -p ~/Developer
git clone https://github.com/chrispanag/macos-dev-setup.git ~/Developer/macos-setup
cd ~/Developer/macos-setup
```

### 4. Install packages from the Brewfile

Homebrew ignores formulae from third-party taps until they are trusted. Trust only the ones the Brewfile uses (the Brewfile adds the taps themselves):

```sh
brew trust --formula bufbuild/buf/buf golangci/tap/golangci-lint namespacelabs/namespace/nsc
```

Then install everything:

```sh
brew bundle --file=Brewfile
```

This installs the taps, CLI tools, fonts, and apps listed in [`Brewfile`](./Brewfile). To verify everything is in place afterwards:

```sh
brew bundle check --file=Brewfile --verbose
```

#### Post-install notes

- **postgresql@18 / redis**: Not started automatically. Run `brew services start postgresql@18` and `brew services start redis` if you want them running in the background.
- **Nerd Fonts**: `starship` icons need a Nerd Font in the terminal; the Ghostty config (step 6) already uses *JetBrainsMono Nerd Font*.

### 5. Set up zsh

The zsh config lives in [`zsh/`](./zsh). It uses plain zsh (no Oh My Zsh): plugins come from the Brewfile and the prompt is `starship`.

Homebrew's `share` directories are group-writable by default, which makes zsh refuse to load completions from them. Fix whatever zsh flags as insecure:

```sh
autoload -Uz compaudit && compaudit | xargs chmod go-w
```

Link the config files into your home directory (back up any existing ones first):

```sh
ln -sf ~/Developer/macos-setup/zsh/.zshrc ~/.zshrc
ln -sf ~/Developer/macos-setup/zsh/.zprofile ~/.zprofile
```

Anything machine-specific or secret (tokens, work-only settings) goes in `~/.zshrc.local`, which `.zshrc` sources if present. It is never committed.

Link the [Starship](https://starship.rs) prompt config. It's a two-line prompt in Catppuccin Mocha colors that shows the directory, git status, slow command durations and the current `AWS_PROFILE`, in red when it's a prod profile:

```sh
mkdir -p ~/.config
ln -sf ~/Developer/macos-setup/starship/starship.toml ~/.config/starship.toml
```

Finish setting up the language toolchains:

```sh
fnm install --lts && fnm default lts-latest
rustup default stable
```

Open a new terminal to pick everything up.

### 6. Set up Ghostty

[Ghostty](https://ghostty.org) is the terminal (installed by the Brewfile). Link its config:

```sh
mkdir -p ~/.config/ghostty
ln -sf ~/Developer/macos-setup/ghostty/config ~/.config/ghostty/config
```

It uses the *JetBrainsMono Nerd Font* from the Brewfile and the built-in *Catppuccin Mocha* theme. Reload with <kbd>Cmd</kbd>+<kbd>Shift</kbd>+<kbd>,</kbd>.

### 7. Apply macOS settings

[`macos/defaults.sh`](./macos/defaults.sh) sets Dock, Finder, mouse and other system preferences. It is safe to re-run:

```sh
./macos/defaults.sh
```

Dock and Finder restart immediately; log out and back in for the rest to take effect.

### 8. Set up tmux

Link the config, then start tmux and press <kbd>prefix</kbd> <kbd>I</kbd> (default prefix: <kbd>Ctrl</kbd>+<kbd>b</kbd>) to install the plugins with [tpm](https://github.com/tmux-plugins/tpm) (installed by the Brewfile):

```sh
ln -sf ~/Developer/macos-setup/tmux/tmux.conf ~/.tmux.conf
```

[tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect) and [tmux-continuum](https://github.com/tmux-plugins/tmux-continuum) save sessions every 15 minutes and restore them when tmux starts, e.g. after a reboot.

### 9. Set up Zed

Link the [Zed](https://zed.dev) settings, then restart Zed so it installs the extensions listed under `auto_install_extensions` (including the Catppuccin theme):

```sh
mkdir -p ~/.config/zed
ln -sf ~/Developer/macos-setup/zed/settings.json ~/.config/zed/settings.json
```

### 10. Set up git

The shared git settings ([`git/config`](./git/config): aliases, [delta](https://github.com/dandavison/delta) as the diff pager, SSH commit signing through 1Password, GitHub over SSH) and the global ignore file go in `~/.config/git`. Your identity goes in `~/.gitconfig`, which git reads afterwards and which stays out of the repo. Create it first, so that `git config --global` keeps writing there and not into the repo:

```sh
git config --file ~/.gitconfig user.name "Your Name"
git config --file ~/.gitconfig user.email "you@example.com"
# Public key of the SSH key in 1Password (Copy > Public Key), used to sign commits
git config --file ~/.gitconfig user.signingkey "ssh-ed25519 AAAA..."

mkdir -p ~/.config/git
ln -sf ~/Developer/macos-setup/git/config ~/.config/git/config
ln -sf ~/Developer/macos-setup/git/ignore ~/.config/git/ignore
```

In 1Password, turn on **Settings > Developer > Use the SSH agent**, otherwise signing fails. Then point `ssh` at the 1Password agent, otherwise every push to GitHub (rewritten to SSH by `git/config`, including in this repo, which was cloned over HTTPS) fails with `Permission denied (publickey)`. Add this to `~/.ssh/config`:

```
Host *
  IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
```

Fetches from `https://github.com` remotes stay on HTTPS and authenticate with the `gh` token, so private repos and Go modules keep working even when 1Password is locked. Log in once with `gh auth login`.

Finally, add the same public key to GitHub twice, once as an authentication key and once as a signing key (so commits show as *Verified*):

```sh
gh auth refresh -s admin:public_key,admin:ssh_signing_key
gh ssh-key add <(echo "ssh-ed25519 AAAA...") --title "1Password"
gh ssh-key add <(echo "ssh-ed25519 AAAA...") --title "1Password" --type signing
```

## Keeping the Brewfile up to date

After installing or removing something with Homebrew, update the `Brewfile` by hand (it is curated, so avoid overwriting it with `brew bundle dump`).

To find anything installed that isn't in the `Brewfile`:

```sh
brew bundle cleanup --file=Brewfile
```

This only lists the extras. Add `--force` to actually uninstall them. `--force` can also reset Homebrew's tap trust list, so re-run the `brew trust` command from step 4 afterwards.

## Contributing

This repository is public. Never commit secrets, tokens, credentials, hostnames, or other personal data.
