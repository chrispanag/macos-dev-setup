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

# --- Window tiling --------------------------------------------------------
# No gaps between tiled windows
defaults write com.apple.WindowManager EnableTiledWindowMargins -bool false

# --- Activity Monitor -----------------------------------------------------
# Show all processes
defaults write com.apple.ActivityMonitor ShowCategory -int 100

# Apply
killall Dock Finder 2>/dev/null || true
echo "Done. Some settings (mouse speed, appearance) apply after logging out."
