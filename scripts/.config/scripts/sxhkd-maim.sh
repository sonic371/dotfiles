#!/bin/bash
# Screenshot to ~/Pictures/screenshots and the clipboard.
#   sxhkd-maim.sh          select an area (Esc cancels, nothing is saved)
#   sxhkd-maim.sh --full   whole screen

output=~/Pictures/screenshots/$(date +%Y-%m-%d_%H-%M-%S).png
tempfile=$(mktemp --suffix=.png)

case "$1" in
    --full) mode=() ;;
    "")     mode=(-s) ;;
    *)      echo "Usage: sxhkd-maim.sh [--full]" >&2; rm -f "$tempfile"; exit 1 ;;
esac

if maim "${mode[@]}" "$tempfile"; then
    mv "$tempfile" "$output"
    xclip -selection clipboard -t image/png < "$output"
    notify-send "Screenshot saved" "$output"
else
    rm -f "$tempfile"
    echo "Screenshot cancelled or failed" >&2
    exit 1
fi
