#!/usr/bin/env bash
# Set a random wallpaper from ~/Pictures/wallpaper (run by change-wallpaper.service)

command -v feh >/dev/null 2>&1 || { echo "feh not found" >&2; exit 1; }

exec feh --recursive --randomize --bg-fill ~/Pictures/wallpaper/
