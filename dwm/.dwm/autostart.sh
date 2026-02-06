#!/bin/bash

# --- Essential services ---
# Restart sxhkd to avoid multiple instances on reload
# pkill -x sxhkd
# sxhkd -c ~/.config/i3/sxhkd/sxhkdrc &

dunst &
picom &

# --- Display & Input ---
~/.config/scripts/wallpaper.sh
~/.config/scripts/touchpad-setup.sh
~/.config/scripts/xinput-wacom-pan.sh

# --- System utilities ---
unclutter -idle 3 &

# --- Applications ---
fcitx5 -d
mega-sync

# --- Power management & Screen lock ---
# Disable xset
xset s off -dpms -b

# Auto-suspend after a period of inactivity
xidlehook \
  --not-when-audio \
  --timer 60 'xset dpms force off' '' \
  --timer 2070 'notify-send "Suspending in 30 seconds"' '' \
  --timer 2100 'i3lock --nofork -c 000000 & systemctl suspend' ''
