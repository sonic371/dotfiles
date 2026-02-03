#!/bin/bash

# --- Essential services ---
# Restart sxhkd to avoid multiple instances on reload
pkill -x sxhkd
sxhkd -c ~/.config/i3/sxhkd/sxhkdrc &

dex --autostart --environment i3 &
dunst &
picom &

# --- Display & Input ---
~/Scripts/wallpaper.sh &
~/Scripts/touchpad-setup.sh &
~/Scripts/xinput-wacom-pan.sh &

# --- System utilities ---
unclutter -idle 3 &
auto-cpufreq --daemon &

# --- Applications ---
fcitx5 -d &
mega-sync &

# --- Power management & Screen lock ---
# Disable beep
xset -b
# Set screen saver timeout
xset s 2100 2100
# Set DPMS energy saving
xset dpms 2100 2100 2100
# Lock screen on suspend
xss-lock --transfer-sleep-lock -- i3lock --nofork -c 000000 &
# Auto-suspend after a period of inactivity
xautolock -time 35 -locker 'systemctl suspend' -notify 30 -notifier 'notify-send "Suspending in 30 seconds"' &
