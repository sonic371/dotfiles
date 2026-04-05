#!/bin/bash
pactl set-sink-mute @DEFAULT_SINK@ toggle
MUTE=$(pactl get-sink-mute @DEFAULT_SINK@ | grep -oP '(yes|no)')

if [ "$MUTE" = "yes" ]; then
    dunstify -r 999 -u critical -t 1000 "🔇 Muted"
else
    VOL=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\d+%' | head -1)
    dunstify -r 999 -u low -t 1000 -h int:value:"${VOL%\%}" "Volume: $VOL" -h string:hlcolor:#ffffff
fi

kill -42 $(pidof dwmblocks)
