#!/bin/sh
# ~/.xinitrc - Complete but minimal startup

# === KILL EXISTING INSTANCES ===
killall -q dunst picom dwmblocks dwmblocks-musicup unclutter fcitx5 mega-sync xidlehook sxhkd

# === ESSENTIAL SERVICES (sequential) ===
dunst &
picom &
(setsid env PATH="$HOME/.local/bin:$PATH" sxhkd 2>/tmp/sxhkd.log &) & disown
dwmblocks &
dwmblocks-musicup &

# === DISPLAY & INPUT (blocking) ===
~/.config/scripts/wallpaper.sh
~/.config/scripts/touchpad-setup.sh >/dev/null 2>&1
setxkbmap -option altwin:swap_ralt_rwin 2>/dev/null

# === SYSTEM UTILITIES (background) ===
unclutter -idle 3 &

# === APPLICATIONS (background) ===
fcitx5 -d >/dev/null 2>&1 &
mega-sync >/dev/null 2>&1

# === POWER MANAGEMENT ===
# Disable screensaver and DPMS
#xset s off
#xset -dpms
xset -b
xset s 2100 2100
xset dpms 2100 2100 2100

# Auto-suspend with xidlehook
xidlehook \
  --not-when-audio \
  --timer 2100 'i3lock --nofork -c 000000 & systemctl suspend' '' \
  &

xidlehook \
  --not-when-audio \
  --timer 600 'xset dpms force off' '' \
  &

#Load st color 
xrdb -merge ~/.Xresources
autorandr -c
# === FINAL: START DWM ===
exec dwm
