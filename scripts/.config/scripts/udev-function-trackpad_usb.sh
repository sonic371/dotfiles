#!/bin/bash
# /home/wade/dotfiles/scripts/.config/scripts/udev-function-trackpad.sh

export DISPLAY=:0
export XAUTHORITY="/home/wade/.Xauthority"

MOUSE_ID=$(xinput list | grep "HID 05ac:0265 Touchpad" | grep -o 'id=[0-9]*' | cut -d= -f2)
[ ! -z "$MOUSE_ID" ] && xinput set-prop $MOUSE_ID "libinput Tapping Enabled" 1
