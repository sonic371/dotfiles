#!/bin/bash

# Get the ID of the current workspace
CURRENT_WS=$(wmctrl -d | awk '/\*/ {print $1}')

# List windows on the current workspace OR sticky ones (-1)
WINDOWS=$(wmctrl -l | awk -v ws="$CURRENT_WS" '
    $2 == ws || $2 == -1 {
        title = "";
        for (i = 4; i <= NF; i++) title = title $i " ";
        print $1, title;
    }
')

# Exit if no windows found
[ -z "$WINDOWS" ] && exit 0

# Show windows via rofi
CHOSEN_WINDOW=$(printf "%s\n" "$WINDOWS" | rofi -dmenu -p "Switch to:" -i)

# Exit if cancelled
[ -z "$CHOSEN_WINDOW" ] && exit 0

# Extract Window ID and activate it
WIN_ID=$(awk '{print $1}' <<< "$CHOSEN_WINDOW")
wmctrl -i -a "$WIN_ID"
