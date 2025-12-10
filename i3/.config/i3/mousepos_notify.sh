#!/bin/bash

# get current mouse position
eval $(xdotool getmouselocation --shell)

# X and Y variables now contain the coordinates
# You can include SCREEN or WINDOW if you want

# send notification
notify-send "Mouse Position" "X=$X  Y=$Y"
