#!/bin/bash
pactl set-source-mute @DEFAULT_SOURCE@ toggle
MUTE=$(pactl get-source-mute @DEFAULT_SOURCE@ | grep -oP '(yes|no)')

if [ "$MUTE" = "yes" ]; then
    dunstify -r 997 -u low -t 1000 "Mic: Muted"
else
    dunstify -r 997 -u low -t 1000 "Mic: Unmuted"
fi

kill -40 $(pidof dwmblocks) 2>/dev/null
