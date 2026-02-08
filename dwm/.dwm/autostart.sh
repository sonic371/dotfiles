#!/bin/bash

# --- Essential services ---

# Kill existing instances before starting to avoid duplicates
pkill dunst 2>/dev/null
pkill picom 2>/dev/null
pkill dwmblocks 2>/dev/null
pkill musicup 2>/dev/null

# Start services with delay to ensure proper initialization
dunst &
picom &
dwmblocks &
musicup &

# --- Display & Input ---
~/.config/scripts/wallpaper.sh
~/.config/scripts/touchpad-setup.sh
~/.config/scripts/xinput-wacom-pan.sh

# --- System utilities ---
pkill unclutter 2>/dev/null
unclutter -idle 3 &

# --- Applications ---
pkill fcitx5 2>/dev/null
fcitx5 -d

# Kill mega-sync if already running to avoid duplicates
pkill mega-sync 2>/dev/null
mega-sync

# --- Power management & Screen lock ---
# Disable xset
xset s off -dpms -b

# Kill existing xidlehook before starting new one
pkill xidlehook 2>/dev/null

# Auto-suspend after a period of inactivity
xidlehook \
  --not-when-audio \
  --timer 60 'xset dpms force off' '' \
  --timer 2070 'notify-send "Suspending in 30 seconds"' '' \
  --timer 2100 'i3lock --nofork -c 000000 & systemctl suspend' '' &
