#!/bin/bash

# Set your desired threshold (e.g., 15%)
threshold=20

# Get battery status and capacity
status=$(cat /sys/class/power_supply/BAT0/status)
capacity=$(cat /sys/class/power_supply/BAT0/capacity)

# Alternatively, using acpi:
# battery_info=$(acpi -b)
# status=$(echo "$battery_info" | awk '{print $3}' | tr -d ',')
# capacity=$(echo "$battery_info" | awk -F'[,:%]' '{print $3}')

if [ "$status" = "Discharging" ] && [ "$capacity" -le $threshold ]; then
    # Send urgent notification with Dunst
    notify-send -u critical "🔋 Battery Low!" "Battery is at ${capacity}%. Connect charger soon." -t 10000
fi
