#!/bin/bash

# Check Bluetooth status
get_bluetooth_status() {
    # Check if Bluetooth controller is powered on
    if bluetoothctl show | grep -q "Powered: yes"; then
        echo "on"
    else
        echo "off"
    fi
}

# Get connected device name (if any)
get_connected_device() {
    # Get the first connected device
    device=$(bluetoothctl devices Connected | head -1 | awk '{$1=""; $2=""; print $0}' | sed 's/^[ \t]*//')
    if [ -n "$device" ]; then
        echo "$device"
    else
        echo ""
    fi
}

# Handle click event
case $1 in
    "click")
        # Open bluetuith in a new terminal with specific window size
        kitty -o initial_window_width=80c -o initial_window_height=24c bluetuith &
        ;;
    *)
        # Display Bluetooth status
        status=$(get_bluetooth_status)

        if [ "$status" = "on" ]; then
            device=$(get_connected_device)
            if [ -n "$device" ]; then
                # Truncate device name if too long
                if [ ${#device} -gt 15 ]; then
                    device="${device:0:12}..."
                fi
                echo "󰂯 $device"
            else
                echo "󰂯"
            fi
        else
            echo "󰂲"
        fi
        ;;
esac