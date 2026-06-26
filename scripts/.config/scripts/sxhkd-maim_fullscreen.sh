#!/bin/bash
output=~/Pictures/screenshots/$(date +%Y-%m-%d_%H-%M-%S).png

if maim "$output"; then
    cat "$output" | xclip -selection clipboard -t image/png
    notify-send "Screenshot saved" "$output"
else
    echo "Screenshot failed" >&2
    exit 1
fi
