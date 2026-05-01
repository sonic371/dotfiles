#!/bin/bash

# Get current brightness values
BRIGHT=$(brightnessctl g)
MAX=$(brightnessctl m)
PERCENT=$((BRIGHT * 100 / MAX))

case "$1" in
    up)
        brightnessctl s +10% >/dev/null
        ;;
    down)
        brightnessctl s 10%- >/dev/null
        ;;
    set)
        if [[ -n "$2" ]]; then
            brightnessctl s "$2%" >/dev/null
        else
            echo "Usage: brightness-control set <percentage>"
            exit 1
        fi
        ;;
    *)
        echo "Usage: brightness-control {up|down|set <percentage>}"
        exit 1
        ;;
esac

# Only proceed if brightness actually changed
if [[ $? -eq 0 ]]; then
    # Get new brightness values
    BRIGHT=$(brightnessctl g)
    MAX=$(brightnessctl m)
    PERCENT=$((BRIGHT * 100 / MAX))
    
    # Update dwmblocks
    kill -35 $(pidof dwmblocks) 2>/dev/null
    
    # Send notification
    dunstify -r 998 -u low -t 1000 -h int:value:"$PERCENT" \
        "Brightness: ${PERCENT}%" -h string:hlcolor:#ffffff
fi
