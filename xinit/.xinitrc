#!/bin/sh

# === CONFIGURATION ===
IDLE_TIMEOUT=2100      # 35 minutes
LOCK_TIMEOUT=600       # 10 minutes
UNCLUTTER_IDLE=3

# === HARDWARE & SYSTEM SETUP ===
# Input devices
# setxkbmap -option altwin:swap_ralt_rwin 2>/dev/null
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

# === POWER MANAGEMENT ===
# Screen saver and DPMS
xset s "$IDLE_TIMEOUT" "$IDLE_TIMEOUT"
xset dpms "$IDLE_TIMEOUT" "$IDLE_TIMEOUT" "$IDLE_TIMEOUT"
xset r rate 200 35

# === ENVIRONMENT VARIABLES ===
# Input method (fcitx5)
export GTK_IM_MODULE=fcitx5
export QT_IM_MODULE=fcitx5
export XMODIFIERS=@im=fcitx5

# === SYSTEMD USER SESSION SETUP ===
# Import environment variables into systemd user session
systemctl --user import-environment DISPLAY XAUTHORITY PATH GTK_IM_MODULE QT_IM_MODULE XMODIFIERS

# Setup cleanup trap to stop the graphical session on exit or termination
cleanup() {
    systemctl --user stop graphical-session.target
}
trap cleanup EXIT INT TERM HUP

# Clear any failed states from the previous session
systemctl --user reset-failed

# Start the systemd user graphical session target
systemctl --user start dwm-session.target

# === START WINDOW MANAGER ===
# Run dwm (without exec so we can clean up on exit)
dwm
