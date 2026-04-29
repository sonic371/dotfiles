#!/usr/bin/env sh

THRESHOLD=6
SPEED=0.03

eval "$(xdotool getmouselocation --shell)"
OLDY=$Y

while xdotool keydown XF86AudioPrev 2>/dev/null; do
    sleep "$SPEED"

    eval "$(xdotool getmouselocation --shell)"
    NEWY=$Y

    DIFF=$((NEWY - OLDY))

    if [ "$DIFF" -gt "$THRESHOLD" ]; then
        xdotool click 5
    elif [ "$DIFF" -lt "-$THRESHOLD" ]; then
        xdotool click 4
    fi

    OLDY=$NEWY
done
