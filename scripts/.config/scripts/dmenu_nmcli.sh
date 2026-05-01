#!/usr/bin/env bash

# nmcli-dmenu - A dmenu interface for NetworkManager

# Configure dmenu appearance (array format handles spaces correctly)
DMENU_OPTS=(
    -fn "Px437 DOS/V re. JPN30:size=24"
    -nb "#000000"
    -nf "#ffffff"
    -sb "#ffffff"
    -sf "#000000"
    -l 10
    -i
)

# Helper function to run dmenu
dmenu_run() {
    dmenu "${DMENU_OPTS[@]}" "$@"
}

# Function to show notification
notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Network Manager" "$1"
    else
        echo "Notification: $1"
    fi
}

# Function to get active connection
get_active_connection() {
    nmcli -t -f NAME,TYPE,DEVICE connection show --active | head -n1 | cut -d: -f1
}

# Function to scan WiFi networks
scan_wifi() {
    echo "Scanning WiFi networks..." >&2
    nmcli device wifi rescan
    sleep 2
    nmcli -t -f SSID,SIGNAL,SECURITY device wifi list | \
        sort -t: -k2 -rn | \
        awk -F: '{printf "%-30s %3s%%   %s\n", $1, $2, $3}'
}

# Main menu options
main_menu() {
    echo -e "📡  Connect to WiFi\n🔒  Connect to Secure WiFi\n📶  Disconnect WiFi\n📋  Available Networks\n🔧  Toggle WiFi\n🔌  Toggle Ethernet\n📊  Connection Status\n⚡  Enable All\n❌  Disable All\n🚪  Exit"
}

# WiFi menu with signal strengths
wifi_menu() {
    networks=$(scan_wifi)
    if [ -z "$networks" ]; then
        notify "No WiFi networks found"
        exit 1
    fi
    
    selected=$(echo "$networks" | dmenu_run -p "Select WiFi Network:")
    [ -z "$selected" ] && exit 0
    
    # Extract SSID (handle spaces correctly)
    ssid=$(echo "$selected" | sed 's/  */ /g' | cut -d' ' -f1-6 | sed 's/ *$//')
    
    # Check if network is already connected
    if nmcli -t connection show --active | grep -q "^$ssid:"; then
        notify "Already connected to $ssid"
        exit 0
    fi
    
    # Check if connection exists but is disconnected
    if nmcli connection show "$ssid" &>/dev/null; then
        notify "Connecting to $ssid..."
        nmcli connection up "$ssid" && notify "Connected to $ssid"
    else
        # New connection - ask for password
        password=$(echo "" | dmenu_run -P -p "Password for $ssid:")
        [ -z "$password" ] && exit 0
        
        notify "Connecting to $ssid..."
        if nmcli device wifi connect "$ssid" password "$password"; then
            notify "Connected to $ssid"
        else
            notify "Failed to connect to $ssid"
        fi
    fi
}

# Secure WiFi menu (explicitly requiring password)
secure_wifi_menu() {
    ssid=$(echo "" | dmenu_run -p "Enter WiFi SSID:")
    [ -z "$ssid" ] && exit 0
    
    password=$(echo "" | dmenu_run -P -p "Password for $ssid:")
    [ -z "$password" ] && exit 0
    
    notify "Connecting to $ssid..."
    if nmcli device wifi connect "$ssid" password "$password"; then
        notify "Connected to $ssid"
    else
        notify "Failed to connect to $ssid"
    fi
}

# List and manage saved connections
saved_networks() {
    connections=$(nmcli -t -f NAME,TYPE connection show | grep -v "^--" | column -t -s:)
    selected=$(echo -e "$connections\nBack" | dmenu_run -p "Saved Connections:")
    
    case "$selected" in
        "Back"|"") exit 0 ;;
        *)
            action=$(echo -e "Connect\nDisconnect\nDelete\nBack" | dmenu_run -p "Action for $selected:")
            case "$action" in
                "Connect")
                    notify "Connecting to $selected..."
                    nmcli connection up "$selected" && notify "Connected to $selected"
                    ;;
                "Disconnect")
                    notify "Disconnecting $selected..."
                    nmcli connection down "$selected" && notify "Disconnected $selected"
                    ;;
                "Delete")
                    nmcli connection delete "$selected" && notify "Deleted $selected"
                    ;;
                *) exit 0 ;;
            esac
            ;;
    esac
}

# Toggle WiFi
toggle_wifi() {
    status=$(nmcli radio wifi)
    if [ "$status" = "enabled" ]; then
        nmcli radio wifi off
        notify "WiFi disabled"
    else
        nmcli radio wifi on
        notify "WiFi enabled"
        sleep 1
        wifi_menu
    fi
}

# Toggle Ethernet
toggle_ethernet() {
    # Get ethernet device
    eth_device=$(nmcli -t -f DEVICE,TYPE device status | grep ":ethernet" | cut -d: -f1 | head -n1)
    
    if [ -z "$eth_device" ]; then
        notify "No ethernet device found"
        exit 1
    fi
    
    status=$(nmcli -t -f DEVICE,STATE device status | grep "^$eth_device:" | cut -d: -f2)
    
    if [ "$status" = "connected" ]; then
        nmcli device disconnect "$eth_device"
        notify "Ethernet disconnected"
    else
        nmcli device connect "$eth_device"
        notify "Ethernet connected"
    fi
}

# Show connection status
connection_status() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Network Status" "$(nmcli device status)\n\nActive Connections:\n$(nmcli -t connection show --active)"
    else
        echo -e "Network Status:\n$(nmcli device status)\n\nActive Connections:\n$(nmcli -t connection show --active)"
        read -p "Press Enter to continue..." < /dev/tty
    fi
}

# Main loop
main() {
    while true; do
        action=$(main_menu | dmenu_run -p "Network:")
        
        case "$action" in
            *"Connect to WiFi"*) wifi_menu ;;
            *"Connect to Secure WiFi"*) secure_wifi_menu ;;
            *"Disconnect WiFi"*) 
                current=$(get_active_connection)
                if [ -n "$current" ]; then
                    nmcli connection down "$current" && notify "Disconnected from $current"
                else
                    notify "No active connection"
                fi
                ;;
            *"Available Networks"*) saved_networks ;;
            *"Toggle WiFi"*) toggle_wifi ;;
            *"Toggle Ethernet"*) toggle_ethernet ;;
            *"Connection Status"*) connection_status ;;
            *"Enable All"*)
                nmcli networking on
                notify "All networking enabled"
                ;;
            *"Disable All"*)
                nmcli networking off
                notify "All networking disabled"
                ;;
            *"Exit"*|"") exit 0 ;;
        esac
    done
}

# Check dependencies
for cmd in nmcli dmenu; do
    if ! command -v $cmd >/dev/null 2>&1; then
        echo "Error: $cmd is not installed"
        exit 1
    fi
done

# Run main function
main
