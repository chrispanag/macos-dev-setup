# Guide

How to use what this setup adds. [README.md](./README.md) covers installing it.

In the tables, <kbd>prefix</kbd> is tmux's prefix, <kbd>Ctrl</kbd>+<kbd>B</kbd>: press it, let go, then press the next key.

## Projects and tmux sessions

Every project gets its own tmux session, which keeps running when you close Ghostty.

| Keys | What it does |
|---|---|
| New Ghostty tab, window or split | Opens the project picker. <kbd>Esc</kbd> gives a plain shell |
| <kbd>Ctrl</kbd>+<kbd>G</kbd> at a zsh prompt | Opens the project picker |
| <kbd>prefix</kbd> <kbd>j</kbd> | Opens the project picker in a popup (works even while Claude Code or vim has focus) |

The picker lists the directories you use most (from zoxide), then every git repo in `~/Developer`. Type a few letters and press <kbd>Enter</kbd>:

- If the project has no session yet, one is created in the project folder.
- If it has one, you switch to it, with its windows and running programs as you left them.
- If it's already open in another Ghostty tab, this tab gets `<project>-2`: the same windows, but each tab can show a different one. Closing a tab removes its extra session; the windows stay.

## tmux

| Keys | What it does |
|---|---|
| <kbd>prefix</kbd> <kbd>c</kbd> | New window (a tab inside the session), in the current folder |
| <kbd>prefix</kbd> <kbd>1</kbd>…<kbd>9</kbd> | Go to window 1–9 |
| <kbd>prefix</kbd> <kbd>,</kbd> | Rename the current window |
| <kbd>prefix</kbd> <kbd>\|</kbd> / <kbd>prefix</kbd> <kbd>-</kbd> | Split left/right / top/bottom, in the current folder |
| <kbd>prefix</kbd> <kbd>z</kbd> | Zoom the current pane to full size and back |
| <kbd>prefix</kbd> arrow keys | Move between panes (or click with the mouse) |
| <kbd>prefix</kbd> <kbd>x</kbd> | Close the current pane |
| <kbd>prefix</kbd> <kbd>s</kbd> | Tree of all sessions and windows, with previews |
| <kbd>prefix</kbd> <kbd>d</kbd> | Detach: leave everything running and go back to the plain shell |
| <kbd>prefix</kbd> <kbd>[</kbd> | Scroll and search the history (<kbd>/</kbd> to search, <kbd>q</kbd> to quit) |
| <kbd>prefix</kbd> <kbd>r</kbd> | Reload `~/.tmux.conf` |
| <kbd>prefix</kbd> <kbd>?</kbd> | List every key binding |

The mouse works: click a pane to focus it, drag a border to resize, scroll for history. Hold <kbd>Option</kbd> while dragging to select text with Ghostty instead of tmux.

**Status bar**

- Left: the session (project) name. It turns red while tmux waits for the key after <kbd>prefix</kbd>.
- Middle: the windows. The current one is highlighted, `+` means a pane is zoomed, and a yellow 🔔 means something rang the bell, for example Claude Code waiting for input. Visiting the window clears it.
- Right: other sessions with a 🔔 window, then the time.

**Ghostty tab titles** follow the active pane: `project · title` when a program sets a title (Claude Code shows its thread name), otherwise just the project.

**After a reboot**, tmux brings back every session, window, split, folder and the text that was on screen. It saves every 15 minutes (<kbd>prefix</kbd> <kbd>Ctrl</kbd>+<kbd>S</kbd> saves now, <kbd>prefix</kbd> <kbd>Ctrl</kbd>+<kbd>R</kbd> restores). Running programs don't come back: restart servers, and use `claude --continue` to resume a Claude Code conversation.

**Avoid** running `tmux` inside tmux; use the picker or <kbd>prefix</kbd> <kbd>s</kbd> to move between sessions. `exit` in the last pane ends the session; <kbd>prefix</kbd> <kbd>d</kbd> keeps it.

## Shell

| Keys / command | What it does |
|---|---|
| `z <part of a path>` | Jump to a directory you've visited (`z mono`, `z setup zsh`); `z -` goes back |
| `zi <part>` | Same, but pick from a list |
| <kbd>Ctrl</kbd>+<kbd>R</kbd> | Search shell history with fzf |
| <kbd>Ctrl</kbd>+<kbd>T</kbd> | Insert a file path (with preview) |
| <kbd>Option</kbd>+<kbd>C</kbd> | `cd` into a subdirectory |
| `**`<kbd>Tab</kbd> | Fuzzy completion, e.g. `vim **`<kbd>Tab</kbd> |
| <kbd>↑</kbd> / <kbd>↓</kbd> | Search history for lines starting with what you've typed |
| `!!`, `!$` | Expand into the command line first, so you can check them before <kbd>Enter</kbd> |
| A leading space | Keeps that command out of history |
| A directory name alone | `cd`s into it |

Aliases:

| Alias | Runs |
|---|---|
| `ls`, `ll`, `la`, `lt` | eza: plain, long with git status, including hidden files, tree |
| `gits`, `gitd`, `gitl`, `gita` | `git status`, `git diff`, `git lg`, `git add .` |
| `ip` | Local IP address of the active network connection |
| `zshsource` | Reload the shell (`exec zsh`) |
| `zshconfig`, `sshconfig`, `gitconfig` | Open `~/.zshrc`, `~/.ssh/config`, `~/.gitconfig` (identity only; shared git settings are in `git/config`) |
| `loc` | Count lines of code in the current folder |

Other tools on the PATH: `rg` (fast grep), `fd` (fast find), `bat` (cat with highlighting), `dust` (disk usage), `btop` (system monitor), `tldr <command>` (short examples), `jq`.

## Prompt

```
macos-setup  main [!?]  dev  took 3s
❯
```

From left to right: the folder (trimmed to the repo), the git branch and status, the `AWS_PROFILE` (bold red when it contains `prod`), and how long the last command took if over 2 seconds. The `❯` turns red after a failed command.

## Git

| Command | What it does |
|---|---|
| `git lg` | Compact, colored commit graph |
| `git diff`, `git show`, `git log -p` | Side-by-side diffs with line numbers (delta). <kbd>n</kbd> / <kbd>N</kbd> jump between files |
| `git -c delta.side-by-side=false diff` | Single-column diff, for narrow panes |
| `git push` on a new branch | Sets the upstream automatically, no `-u` needed |

- Commits are signed with the SSH key in 1Password; approve with Touch ID when asked.
- Pushes to GitHub go over SSH, and fetches over HTTPS with the `gh` login, so fetching works even when 1Password is locked.
- Merge conflicts also show the common ancestor (`zdiff3`), between `|||||||` and `=======`.
- `.DS_Store` and Claude Code's `settings.local.json` are ignored in every repo.

## Ghostty

| Keys | What it does |
|---|---|
| <kbd>Ctrl</kbd>+<kbd>\`</kbd> | Quick terminal that drops down from the top, from any app. Needs Ghostty in System Settings > Privacy & Security > Accessibility |
| <kbd>Cmd</kbd>+<kbd>T</kbd> / <kbd>Cmd</kbd>+<kbd>N</kbd> | New tab / window (each opens the project picker) |
| <kbd>Cmd</kbd>+<kbd>Shift</kbd>+<kbd>←</kbd> / <kbd>→</kbd> | Previous / next tab |
| <kbd>Cmd</kbd>+<kbd>1</kbd>…<kbd>8</kbd> / <kbd>Cmd</kbd>+<kbd>9</kbd> | Go to tab 1–8 / the last tab |
| <kbd>Cmd</kbd>+<kbd>D</kbd> / <kbd>Cmd</kbd>+<kbd>Shift</kbd>+<kbd>D</kbd> | Split right / down (Ghostty splits; inside tmux, prefer tmux's) |
| <kbd>Cmd</kbd>+<kbd>Shift</kbd>+<kbd>Enter</kbd> / <kbd>Cmd</kbd>+<kbd>Shift</kbd>+<kbd>E</kbd> | Zoom a split / make splits equal |
| <kbd>Cmd</kbd>+<kbd>Shift</kbd>+<kbd>,</kbd> | Reload the config |

The left <kbd>Option</kbd> key works as Alt (word jumps in the shell); the right one still types special characters.

## Claude Code

- Use <kbd>Shift</kbd>+<kbd>Enter</kbd> for a newline in the prompt. It works inside tmux too.
- With `"preferredNotifChannel": "terminal_bell"` in `~/.claude/settings.json`, a Claude that's waiting for you shows as a yellow 🔔 in tmux's status bar, in whichever project it's in.

## macOS

- **Hot corner:** bottom right opens a Quick Note.
- **Screenshots** go to `~/Pictures/Screenshots`; window screenshots (<kbd>Cmd</kbd>+<kbd>Shift</kbd>+<kbd>4</kbd>, then <kbd>Space</kbd>) have no shadow.
- **Keyboard:** fast key repeat. Holding a key repeats it instead of showing accents; type accents with <kbd>Option</kbd> combinations (<kbd>Option</kbd>+<kbd>E</kbd>, then <kbd>E</kbd> gives é).
- **Text fields:** no smart quotes, smart dashes, autocorrect or double-space period.
- **Finder:** shows all file extensions and the path and status bars, searches the current folder, and sorts folders first.

## Maintaining this repo

| Command | What it does |
|---|---|
| `./install.sh --check` | Report what's missing or out of date; changes nothing |
| `./install.sh --links` | Recreate the config symlinks |
| `./install.sh` | Run the full setup again (skips whatever is done) |
| `./macos/defaults.sh` | Reapply the macOS settings |
| `brew bundle cleanup --file=Brewfile` | List installed packages that aren't in the Brewfile |

Every commit is scanned by gitleaks for secrets, email addresses and home-directory paths. If it blocks something by mistake, adjust `.gitleaks.toml` rather than skipping the check.
