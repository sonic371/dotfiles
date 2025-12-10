#!/bin/bash

# Get current brightness percentage
get_brightness() {
    brightnessctl -d amdgpu_bl1 info | grep -oP '\(\K[0-9]+(?=%)' || echo "0"
}

# Handle click and scroll events
case $1 in
    "up")
        brightnessctl -d amdgpu_bl1 set +10%
        ;;
    "down")
        brightnessctl -d amdgpu_bl1 set 10%-
        ;;
    "click")
        # Toggle between 30% and 100% on click
        current=$(get_brightness)
        if [ "$current" -lt 50 ]; then
            brightnessctl -d amdgpu_bl1 set 100%
        else
            brightnessctl -d amdgpu_bl1 set 30%
        fi
        ;;
    *)
        # Display current brightness
        current=$(get_brightness)

        # Choose icon based on brightness level (Nerd Font icons)
        if [ "$current" -lt 20 ]; then
            icon="󰃞"
        elif [ "$current" -lt 40 ]; then
            icon="󰃟"
        elif [ "$current" -lt 60 ]; then
            icon="󰃝"
        elif [ "$current" -lt 80 ]; then
            icon="󰃠"
        else
            icon="󰃡"
        fi

        echo "$icon $current%"
        ;;
esac