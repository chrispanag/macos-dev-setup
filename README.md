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

```sh
brew bundle --file=Brewfile
```

This installs the taps, CLI tools, fonts, and apps listed in [`Brewfile`](./Brewfile). To verify everything is in place afterwards:

```sh
brew bundle check --file=Brewfile --verbose
```

#### Post-install notes

- **postgresql@18 / redis**: Not started automatically. Run `brew services start postgresql@18` and `brew services start redis` if you want them running in the background.
- **Nerd Fonts**: Select a Nerd Font (e.g. *JetBrainsMono Nerd Font*) in your terminal so `starship` icons render.

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

Finish setting up the language toolchains:

```sh
fnm install --lts && fnm default lts-latest
rustup default stable
```

Open a new terminal to pick everything up.

## Keeping the Brewfile up to date

After installing or removing something with Homebrew, update the `Brewfile` by hand (it is curated, so avoid overwriting it with `brew bundle dump`).

To find anything installed that isn't in the `Brewfile`:

```sh
brew bundle cleanup --file=Brewfile
```

This only lists the extras. Add `--force` to actually uninstall them.

## Contributing

This repository is public. Never commit secrets, tokens, credentials, hostnames, or other personal data.
