#!/bin/bash

# Get WiFi status and information
get_wifi_status() {
    # Check if WiFi is connected
    if nmcli -t -f DEVICE,STATE dev status | grep -q "wlp1s0:connected"; then
        echo "connected"
    else
        echo "disconnected"
    fi
}

# Get connected SSID
get_wifi_ssid() {
    nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2 | head -1
}

# Get signal strength
get_wifi_signal() {
    nmcli -t -f active,signal dev wifi | grep '^yes' | cut -d: -f2 | head -1
}

# Get IP address
get_wifi_ip() {
    ip -4 addr show wlp1s0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1
}

# Handle click event
case $1 in
    "click")
        # Open nmtui in a new terminal with specific window size
        kitty -o initial_window_width=90c -o initial_window_height=40c nmtui &
        ;;
    *)
        # Display WiFi status
        status=$(get_wifi_status)

        if [ "$status" = "connected" ]; then
            ssid=$(get_wifi_ssid)
            signal=$(get_wifi_signal)
            ip=$(get_wifi_ip)

            if [ -n "$ssid" ]; then
                # Truncate SSID if too long
                if [ ${#ssid} -gt 15 ]; then
                    ssid="${ssid:0:12}..."
                fi

                # Show SSID and signal strength
                if [ -n "$signal" ]; then
                    echo " $ssid ($signal%)"
                else
                    echo " $ssid"
                fi
            else
                # Fallback: just show WiFi icon
                echo ""
            fi
        else
            # WiFi disconnected
            echo "󰤮"
        fi
        ;;
esac