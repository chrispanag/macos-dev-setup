#!/usr/bin/env bash
# macOS system settings. Only values that differ from (or pin) the macOS
# defaults live here. Safe to re-run; some changes need a logout to apply.
#
# Find a setting's key: `defaults read > before.txt`, change it in System
# Settings, `defaults read > after.txt`, then diff the two files.
set -euo pipefail

# --- Appearance -----------------------------------------------------------
# Switch between light and dark mode automatically
defaults write NSGlobalDomain AppleInterfaceStyleSwitchesAutomatically -bool true

# --- Keyboard -------------------------------------------------------------
# Fastest key repeat and shortest delay the System Settings sliders allow
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
# Holding a key repeats it instead of showing the accent picker
# (accents still work with Option combos, e.g. ⌥e then e)
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# --- Text substitutions (they break pasted code and commands) -------------
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# --- Mouse & trackpad -----------------------------------------------------
# Mouse tracking speed
defaults write NSGlobalDomain com.apple.mouse.scaling -float 2
# Don't swipe between pages with two fingers (no accidental "back")
defaults write NSGlobalDomain AppleEnableSwipeNavigateWithScrolls -bool false

# --- Dock -----------------------------------------------------------------
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock tilesize -int 54
# Hot corner, bottom right: Quick Note (14)
defaults write com.apple.dock wvous-br-corner -int 14
defaults write com.apple.dock wvous-br-modifier -int 0

# --- Finder ---------------------------------------------------------------
# New windows open in Recents
defaults write com.apple.finder NewWindowTarget -string "PfAF"
# Remove items from the Trash after 30 days
defaults write com.apple.finder FXRemoveOldTrashItems -bool true
# Always show file extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
# Path bar and status bar (item count, free space) at the bottom of windows
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
# Search the current folder by default, not the whole Mac
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
# Folders before files when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true
# No warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
# No .DS_Store files on network shares
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

# --- Screenshots ----------------------------------------------------------
# Save to ~/Pictures/Screenshots instead of the Desktop
mkdir -p "$HOME/Pictures/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Pictures/Screenshots"
# No drop shadow on window screenshots
defaults write com.apple.screencapture disable-shadow -bool true

# --- Window tiling --------------------------------------------------------
# No gaps between tiled windows
defaults write com.apple.WindowManager EnableTiledWindowMargins -bool false

# --- Activity Monitor -----------------------------------------------------
# Show all processes
defaults write com.apple.ActivityMonitor ShowCategory -int 100

# Apply
killall Dock Finder SystemUIServer 2>/dev/null || true
echo "Done. Some settings (key repeat, text substitutions, mouse speed, appearance) apply after logging out."
