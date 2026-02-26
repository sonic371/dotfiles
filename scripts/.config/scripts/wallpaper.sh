#!/usr/bin/env bash

# Try to find feh in common locations
if command -v feh >/dev/null 2>&1; then
    FEH_CMD="feh"
elif [ -f "/run/current-system/sw/bin/feh" ]; then
    FEH_CMD="/run/current-system/sw/bin/feh"
elif [ -f "/usr/bin/feh" ]; then
    FEH_CMD="/usr/bin/feh"
else
    echo "feh not found" >&2
    exit 1
fi

# Randomizing wallpapers
exec "$FEH_CMD" --recursive --randomize --bg-fill ~/Pictures/wallpaper/
