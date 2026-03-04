#!/bin/bash
# /home/wade/dotfiles/scripts/.config/scripts/udev-function-trackpad.sh

export DISPLAY=:0
export XAUTHORITY="/home/wade/.Xauthority"

MOUSE_ID=$(xinput list | grep "HUKE T3 Pro Mouse" | grep -o 'id=[0-9]*' | cut -d= -f2)
[ ! -z "$MOUSE_ID" ] && xinput set-prop $MOUSE_ID "libinput Natural Scrolling Enabled" 1
