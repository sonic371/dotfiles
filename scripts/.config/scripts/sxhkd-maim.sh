#!/bin/bash
output=~/Pictures/screenshots/$(date +%Y-%m-%d_%H-%M-%S).png
tempfile=$(mktemp --suffix=.png)

if maim -s "$tempfile"; then
    mv "$tempfile" "$output"
    cat "$output" | xclip -selection clipboard -t image/png
    notify-send "Screenshot saved" "$output"
else
    rm -f "$tempfile"
    echo "Screenshot cancelled" >&2
fi
