#!/bin/bash

# Get battery info
BATTERY="/sys/class/power_supply/BAT0"
CAPACITY=$(cat "$BATTERY/capacity")
STATUS=$(cat "$BATTERY/status")

# Only proceed if discharging
if [ "$STATUS" != "Discharging" ]; then
    exit 0
fi

# Alert logic
if [ "$CAPACITY" -le 20 ] && [ "$CAPACITY" -gt 10 ]; then
    dunstify -u critical "Battery Low" "${CAPACITY}% remaining" -t 5000
elif [ "$CAPACITY" -le 10 ]; then
    # Send final warning and suspend
    dunstify -u critical "Battery Critical" "System will suspend in 10 seconds at ${CAPACITY}%" -t 10000
    sleep 10
    sudo systemctl suspend
fi
