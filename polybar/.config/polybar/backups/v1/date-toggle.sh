#!/bin/bash

# State file to track display mode
STATE_FILE="/tmp/polybar-date-state"

# Default to time mode if state file doesn't exist
if [ ! -f "$STATE_FILE" ]; then
    echo "time" > "$STATE_FILE"
fi

# Read current state
STATE=$(cat "$STATE_FILE")

# Toggle state on click
if [ "$1" = "click" ]; then
    if [ "$STATE" = "time" ]; then
        echo "date" > "$STATE_FILE"
    else
        echo "time" > "$STATE_FILE"
    fi
    # Re-read state after toggle
    STATE=$(cat "$STATE_FILE")
fi

# Display based on state
case "$STATE" in
    "time")
        # Show time with seconds: Day HH:MM:SS
        date "+%a %H:%M:%S"
        ;;
    "date")
        # Show date only: YYYY-MM-DD
        date "+%Y-%m-%d"
        ;;
    *)
        # Fallback
        date "+%a %H:%M:%S"
        ;;
esac