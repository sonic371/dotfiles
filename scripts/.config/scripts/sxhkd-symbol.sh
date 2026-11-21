#!/bin/bash
# Look up the ticker in the clipboard in the terminal, Webull and TOS (super+r)

# Hotkey scripts have no terminal, so errors go to a notification
fail() {
    notify-send -u normal "Ticker lookup" "$1"
    echo "$1" >&2
    return 1
}

# Function to validate stock symbol
validate_symbol() {
    local symbol="$1"
    local shown="${symbol:0:30}"

    # Remove any whitespace
    symbol=$(echo "$symbol" | tr -d ' ')

    # Check if symbol is empty
    if [ -z "$symbol" ]; then
        fail "Clipboard is empty — copy a ticker first"
        return 1
    fi

    # Check if symbol contains only valid characters (letters, numbers, dots, hyphens)
    if ! [[ "$symbol" =~ ^[A-Za-z0-9.-]+$ ]]; then
        fail "Not a ticker: $shown"
        return 1
    fi

    # Check length (most symbols are 1-5 characters, some up to 10)
    if [ ${#symbol} -gt 10 ]; then
        fail "Too long for a ticker: $shown"
        return 1
    fi

    return 0
}

# Get clipboard content
SYMBOL=$(xclip -selection clipboard -o 2>/dev/null)

# Remove whitespace and convert to uppercase
SYMBOL=$(echo "$SYMBOL" | tr -d ' ' | tr '[:lower:]' '[:upper:]')

# Validate symbol (stop before touching any windows if it isn't a ticker)
validate_symbol "$SYMBOL" || exit 1


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

# Webull
sleep 0.5
xdotool mousemove 170 135
sleep 0.2
xdotool click 1
sleep 0.2
xdotool type "$SYMBOL"
sleep 1.5
xdotool key Return

# TOS
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

# Back to terminal
sleep 0.2
xdotool mousemove 1610 1080
