#!/bin/sh
# ~/.xinitrc - Complete but minimal startup

# === KILL EXISTING INSTANCES ===
pkill dunst
pkill picom
pkill dwmblocks
pkill dwmblocks-musicup
pkill unclutter
pkill fcitx5
pkill mega-sync
pkill xidlehook
pkill sxhkd

# === ESSENTIAL SERVICES (sequential) ===
dunst &
picom &
sxhkd &
dwmblocks &
dwmblocks-musicup &

# === DISPLAY & INPUT (blocking) ===
~/.config/scripts/wallpaper.sh
~/.config/scripts/touchpad-setup.sh >/dev/null 2>&1

# === SYSTEM UTILITIES (background) ===
unclutter -idle 3 &

# === APPLICATIONS (background) ===
fcitx5 -d >/dev/null 2>&1 &
mega-sync >/dev/null 2>&1

# === POWER MANAGEMENT ===
# Disable screensaver and DPMS
xset s off -dpms -b

# Auto-suspend with xidlehook
xidlehook \
  --not-when-audio \
  --timer 60 'xset dpms force off' '' \
  --timer 2070 'notify-send "Suspending in 30 seconds"' '' \
  --timer 2100 'i3lock --nofork -c 000000 & systemctl suspend' '' \
  &

# === FINAL: START DWM ===
exec dwm
