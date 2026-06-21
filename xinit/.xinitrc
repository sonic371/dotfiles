#!/bin/sh

# Ensure XDG_RUNTIME_DIR is set for systemctl --user
[ -z "$XDG_RUNTIME_DIR" ] && export XDG_RUNTIME_DIR="/run/user/$(id -u)"

# === CONFIGURATION ===
IDLE_TIMEOUT=2100      # 35 minutes
LOCK_TIMEOUT=600       # 10 minutes
UNCLUTTER_IDLE=3

# === HARDWARE & SYSTEM SETUP ===
# Input devices — configured via /etc/X11/xorg.conf.d/40-touchpad.conf
# setxkbmap -option altwin:swap_ralt_rwin 2>/dev/null

# Display setup
autorandr -c || echo "Warning: autorandr failed to apply display config" 2>/dev/null

# X resources
xrdb -merge ~/.Xresources 2>/dev/null

# Disable beep
xset -b

# Initialize state files
echo "off" > /tmp/redshift_state

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
