#!/bin/bash

# Get battery info from upower
get_battery_info() {
    upower -i /org/freedesktop/UPower/devices/battery_BAT0 2>/dev/null
}

# Format time from seconds to H:MM or HH:MM
format_time() {
    local total_seconds="$1"

    if [ -z "$total_seconds" ] || [ "$total_seconds" -eq 0 ]; then
        echo ""
        return
    fi

    local hours=$((total_seconds / 3600))
    local minutes=$(((total_seconds % 3600) / 60))

    # Format as H:MM or HH:MM (no leading zero for hours)
    printf "%d:%02d" $hours $minutes
}

# Get battery icon based on percentage
get_battery_icon() {
    local percentage="$1"
    local state="$2"

    # Charging animation icons
    if [ "$state" = "charging" ]; then
        if [ "$percentage" -lt 20 ]; then
            echo ""
        elif [ "$percentage" -lt 40 ]; then
            echo ""
        elif [ "$percentage" -lt 60 ]; then
            echo ""
        elif [ "$percentage" -lt 80 ]; then
            echo ""
        else
            echo ""
        fi
    # Discharging/static icons
    else
        if [ "$percentage" -lt 20 ]; then
            echo ""
        elif [ "$percentage" -lt 40 ]; then
            echo ""
        elif [ "$percentage" -lt 60 ]; then
            echo ""
        elif [ "$percentage" -lt 80 ]; then
            echo ""
        else
            echo ""
        fi
    fi
}

# Main script
battery_info=$(get_battery_info)

# Get percentage
percentage=$(echo "$battery_info" | grep "percentage:" | awk '{print $2}' | sed 's/%//')
percentage_num=$(echo "$percentage" | sed 's/%//')

# Get state (charging, discharging, etc.)
state=$(echo "$battery_info" | grep "state:" | awk '{print $2}')

# Get energy rate (power flow in watts)
energy_rate=$(echo "$battery_info" | grep "energy-rate:" | awk '{print $2}' | awk -F. '{print $1}')

# Get time to empty/full in seconds
if [ "$state" = "discharging" ]; then
    time_seconds=$(echo "$battery_info" | grep "time to empty:" | awk '{print $4}' | awk -F. '{print $1}')
elif [ "$state" = "charging" ]; then
    time_seconds=$(echo "$battery_info" | grep "time to full:" | awk '{print $4}' | awk -F. '{print $1}')
else
    time_seconds=""
fi

# Format time
formatted_time=$(format_time "$time_seconds")

# Get battery icon
icon=$(get_battery_icon "$percentage_num" "$state")

# Output based on state
if [ "$percentage_num" -eq 100 ]; then
    echo "$icon $percentage% (Full)"
elif [ -n "$formatted_time" ] && [ "$energy_rate" -ne 0 ]; then
    echo "$icon $percentage% ($formatted_time)"
elif [ "$energy_rate" -eq 0 ]; then
    echo "$icon $percentage% (Idle)"
else
    echo "$icon $percentage%"
fi