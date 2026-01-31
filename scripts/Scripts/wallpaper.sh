#!/bin/bash
while true; do
  # Using --randomize to select a random wallpaper
  # Using --recursive to search for images in subdirectories
  # Using --bg-fill to set the wallpaper
  feh --recursive --randomize --bg-fill ~/Pictures/wallpaper/
  # Change the sleep time to adjust the frequency of wallpaper changes
  sleep 60 # 10 minutes
done
