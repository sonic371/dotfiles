#!/bin/sh
# Example script for dmenu -persist
# This script allows you to launch multiple programs in the background
# while keeping the menu open.

# Path to your compiled dmenu
DMENU="./dmenu"

# Use dmenu_path to get the list of executables
# Pipe to dmenu with the -persist flag
# Read each line and execute it in the background
dmenu_path | $DMENU -persist "$@" | while read -r cmd; do
    # Only try to execute if the command is not empty
    if [ -n "$cmd" ]; then
        echo "Launching: $cmd"
        # The '&' here is key: it backgrounds the app so 
        # the loop can immediately read the next choice.
        $cmd &
    fi
done
