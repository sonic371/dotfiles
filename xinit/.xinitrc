#!/bin/sh

# === CONFIGURATION ===
IDLE_TIMEOUT=2100      # 35 minutes
LOCK_TIMEOUT=600       # 10 minutes
UNCLUTTER_IDLE=3

# === KILL EXISTING INSTANCES ===
echo "Cleaning up existing processes..."
for p in dunst picom dwmblocks dwmblocks-musicup unclutter fcitx5 mega-sync xidlehook sxhkd; do
    killall -q "$p" 2>/dev/null
done

# === HARDWARE & SYSTEM SETUP ===
# Input devices
setxkbmap -option altwin:swap_ralt_rwin 2>/dev/null
~/.config/scripts/touchpad-setup.sh >/dev/null 2>&1 || echo "Warning: touchpad-setup.sh failed"

# Display setup (critical for everything visual)
autorandr -c 2>/dev/null
~/.config/scripts/wallpaper.sh || echo "Warning: wallpaper.sh failed"

# X resources
xrdb -merge ~/.Xresources 2>/dev/null

# Disable beep
xset -b

# Initialize state files
echo "off" > /tmp/i3blocks_redshift_state

# === START DAEMONS & SERVICES ===
# Notification daemon (needed early for other services)
dunst &

# Compositor (needed for transparency, etc.)
picom &

# Hotkey daemon
(setsid env PATH="$HOME/.local/bin:$PATH" sxhkd 2>/tmp/sxhkd.log) &

# Input method framework
fcitx5 -d >/dev/null 2>&1 &

# === START UTILITIES ===
# Status bars
dwmblocks &
dwmblocks-musicup &

# Auto-idle cursor hider
unclutter -idle "$UNCLUTTER_IDLE" &

# Cloud sync
mega-sync >/dev/null 2>&1 &

# === POWER MANAGEMENT ===
# Screen saver and DPMS
xset s "$IDLE_TIMEOUT" "$IDLE_TIMEOUT"
xset dpms "$IDLE_TIMEOUT" "$IDLE_TIMEOUT" "$IDLE_TIMEOUT"

# Idle manager with chained actions
xidlehook \
    --not-when-audio \
    --timer "$IDLE_TIMEOUT" 'i3lock --nofork -c 000000' '' \
    --timer "$IDLE_TIMEOUT" 'systemctl suspend' '' \
    --timer 600 'xset dpms force off' '' \
    &

# === START WINDOW MANAGER ===
exec dwm
