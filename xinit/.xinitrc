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

# === ESSENTIAL SETUP (synchronous) ===
# Display setup
~/.config/scripts/wallpaper.sh || echo "Warning: wallpaper.sh failed"
~/.config/scripts/touchpad-setup.sh >/dev/null 2>&1 || echo "Warning: touchpad-setup.sh failed"
setxkbmap -option altwin:swap_ralt_rwin 2>/dev/null
xrdb -merge ~/.Xresources 2>/dev/null
autorandr -c 2>/dev/null

# === START SERVICES ===
# Status bar components
dwmblocks &
dwmblocks-musicup &

# Notification daemon
dunst &

# Compositor (start after display setup)
picom &

# Hotkey daemon
(setsid env PATH="$HOME/.local/bin:$PATH" sxhkd 2>/tmp/sxhkd.log) &

# System utilities
unclutter -idle "$UNCLUTTER_IDLE" &

# Applications
fcitx5 -d >/dev/null 2>&1 &
mega-sync >/dev/null 2>&1 &

# === POWER MANAGEMENT ===
xset -b                           # Disable beep
xset s "$IDLE_TIMEOUT" "$IDLE_TIMEOUT"     # Screensaver
xset dpms "$IDLE_TIMEOUT" "$IDLE_TIMEOUT" "$IDLE_TIMEOUT"  # DPMS

# Single xidlehook instance with chained actions
xidlehook \
    --not-when-audio \
    --timer "$IDLE_TIMEOUT" 'i3lock --nofork -c 000000' ''\
    --timer "$IDLE_TIMEOUT" 'systemctl suspend' ''\
    --timer 600 'xset dpms force off' ''\
    &

# === START WINDOW MANAGER ===
exec dwm
