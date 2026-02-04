#!/bin/bash

PIDFILE="/tmp/wallpaper.pid"

if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
  echo "wallpaper.sh is already running."
  exit
fi

echo $$ > "$PIDFILE"
trap 'rm -f "$PIDFILE"' EXIT

while true; do
  # Using --randomize to select a random wallpaper
  # Using --recursive to search for images in subdirectories
  # Using --bg-fill to set the wallpaper
  feh --recursive --randomize --bg-fill ~/Pictures/wallpaper/
  # Change the sleep time to adjust the frequency of wallpaper changes
  sleep 60 # 1 minutes
done
