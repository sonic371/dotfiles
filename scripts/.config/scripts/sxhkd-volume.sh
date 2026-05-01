#!/bin/bash

SINK="@DEFAULT_SINK@"

case "$1" in
    up)
        pactl set-sink-volume "$SINK" +5% 2>/dev/null
        ;;
    down)
        pactl set-sink-volume "$SINK" -5% 2>/dev/null
        ;;
    mute)
        pactl set-sink-mute "$SINK" toggle 2>/dev/null
        ;;
    set)
        if [[ -n "$2" ]]; then
            pactl set-sink-volume "$SINK" "$2%" 2>/dev/null
        else
            echo "Usage: volume-control set <percentage>"
            exit 1
        fi
        ;;
    *)
        echo "Usage: volume-control {up|down|mute|set <percentage>}"
        exit 1
        ;;
esac

# Only proceed if command succeeded
if [[ $? -eq 0 ]]; then
    # Update dwmblocks
    kill -42 $(pidof dwmblocks) 2>/dev/null
    
    # Check if muted
    MUTED=$(pactl get-sink-mute "$SINK" | grep -oP '(?<=Mute: )\w+')
    
    if [[ "$MUTED" == "yes" ]]; then
        VOL="0%"
        dunstify -r 999 -u low -t 1000 -h int:value:0 \
            "Volume: Muted" -h string:hlcolor:#ffffff
    else
        VOL=$(pactl get-sink-volume "$SINK" | grep -oP '\d+%' | head -1)
        PERCENT=${VOL%\%}
        dunstify -r 999 -u low -t 1000 -h int:value:"$PERCENT" \
            "Volume: $VOL" -h string:hlcolor:#ffffff
    fi
fi
