#!/bin/bash

# Get clipboard content
SYMBOL=$(xclip -selection clipboard -o)

# Switch client
sleep 0.5
xdotool key alt+1

# Terminal
sleep 0.5
xdotool mousemove 1610 1080
sleep 0.5
xdotool key s
sleep 0.5
xdotool type "$SYMBOL"
sleep 0.2
xdotool key enter

#Webull
sleep 0.5
# xdotool mousemove 965 50
xdotool mousemove 170 135
sleep 0.2
xdotool click 1
sleep 0.2
xdotool type "$SYMBOL"
sleep 1.5
xdotool key Return

#TOS
sleep 0.3
xdotool mousemove 1510 120
sleep 0.2
xdotool click 1
sleep 0.2
xdotool key ctrl+a
sleep 0.2
xdotool type "$SYMBOL"
sleep 1.0
xdotool key Return

#Back to terminal
sleep 0.2
xdotool mousemove 1610 1080
