#!/bin/bash

# Function to validate stock symbol
validate_symbol() {
    local symbol="$1"
    
    # Remove any whitespace
    symbol=$(echo "$symbol" | tr -d ' ')
    
    # Check if symbol is empty
    if [ -z "$symbol" ]; then
        echo "Error: Empty symbol"
        return 1
    fi
    
    # Check if symbol contains only valid characters (letters, numbers, dots, hyphens)
    if ! [[ "$symbol" =~ ^[A-Za-z0-9.-]+$ ]]; then
        echo "Error: Invalid characters in symbol: $symbol"
        return 1
    fi
    
    # Check length (most symbols are 1-5 characters, some up to 10)
    if [ ${#symbol} -gt 10 ]; then
        echo "Error: Symbol too long: $symbol"
        return 1
    fi
    
    # Optional: Check against a list of common patterns
    # For US stocks: typically 1-5 uppercase letters
    # For crypto: often longer with special characters
    if [[ "$symbol" =~ ^[A-Z]+$ ]] && [ ${#symbol} -le 5 ]; then
        # Likely a valid US stock symbol
        return 0
    elif [[ "$symbol" =~ ^[A-Za-z0-9.-]+$ ]]; then
        # Allow other formats for crypto, ETFs, etc.
        return 0
    fi
    
    return 0
}

# Function to check if symbol exists in a local cache or API
check_symbol_existence() {
    local symbol="$1"
    
    # Option 1: Check with a free API (uncomment to use)
    # response=$(curl -s "https://query1.finance.yahoo.com/v8/finance/chart/$symbol" 2>/dev/null)
    # if echo "$response" | grep -q '"code":"Not Found"'; then
    #     return 1
    # fi
    
    # Option 2: Simple validation based on common patterns
    # Most valid US stock symbols are 1-5 uppercase letters
    if [[ "$symbol" =~ ^[A-Z]{1,5}$ ]]; then
        return 0
    # Crypto symbols often have a -USD or -USDT suffix
    elif [[ "$symbol" =~ ^[A-Z]{2,10}-(USD|USDT)$ ]]; then
        return 0
    # Some symbols have numbers or are longer (e.g., BRK.B)
    elif [[ "$symbol" =~ ^[A-Z0-9.]{1,10}$ ]]; then
        return 0
    else
        # If it doesn't match common patterns, warn but proceed
        echo "Warning: Symbol '$symbol' doesn't match common stock symbol patterns"
        return 0
    fi
}

# Get clipboard content
SYMBOL=$(xclip -selection clipboard -o)

# Remove whitespace and convert to uppercase
SYMBOL=$(echo "$SYMBOL" | tr -d ' ' | tr '[:lower:]' '[:upper:]')

# Validate symbol
if ! validate_symbol "$SYMBOL"; then
    echo "Invalid symbol: $SYMBOL"
    echo "Please copy a valid stock symbol and try again."
    exit 1
fi

# Optional: Check if symbol exists
if ! check_symbol_existence "$SYMBOL"; then
    echo "Warning: Symbol '$SYMBOL' may not exist on major exchanges"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Operation cancelled"
        exit 1
    fi
fi

echo "Validating symbol: $SYMBOL"
echo "Proceeding with script..."

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
