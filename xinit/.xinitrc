#!/bin/sh
# ~/.xinitrc - Complete but minimal startup

# === KILL EXISTING INSTANCES ===
pkill dunst 2>/dev/null
pkill picom 2>/dev/null
pkill dwmblocks 2>/dev/null
pkill dwmblocks-musicup 2>/dev/null
pkill unclutter 2>/dev/null
pkill fcitx5 2>/dev/null
pkill mega-sync 2>/dev/null
pkill xidlehook 2>/dev/null

# === ESSENTIAL SERVICES (sequential) ===
dunst &
sleep 0.3
picom &
dwmblocks &
dwmblocks-musicup &

# === DISPLAY & INPUT (blocking) ===
~/.config/scripts/wallpaper.sh
~/.config/scripts/touchpad-setup.sh
~/.config/scripts/xinput-wacom-pan.sh

# === SYSTEM UTILITIES (background) ===
unclutter -idle 3 &

# === APPLICATIONS (background) ===
fcitx5 -d &
mega-sync &

# === POWER MANAGEMENT ===
# Disable screensaver and DPMS
xset s off -dpms -b

# Auto-suspend with xidlehook
xidlehook \
  --not-when-audio \
  --timer 60 'xset dpms force off' '' \
  --timer 2070 'notify-send "Suspending in 30 seconds"' '' \
  --timer 2100 'i3lock --nofork -c 000000 && systemctl suspend' '' &

# === FINAL: START DWM ===
exec dwm
