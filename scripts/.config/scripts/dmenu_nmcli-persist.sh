#!/usr/bin/env bash

# ============================================
# Persistent Network Manager HUD
# ============================================

# CONFIGURATION
FIFO_IN="/tmp/dmenu-nmcli-in"
FIFO_OUT="/tmp/dmenu-nmcli-out"
MODE_FILE="/tmp/dmenu-nmcli-mode"

# DMENU OPTIONS
DMENU_OPTS=(
    -fn "Px437 DOS/V re. JPN30:size=24"
    -nb "#000000" -nf "#ffffff" 
    -sb "#ffffff" -sf "#000000"
    -l 15 -c -persist -i
    -p "[NET]"
)

# Initialize State
echo "MAIN" > "$MODE_FILE"

# Helper: Show notification
notify() {
    notify-send "Network HUD" "$1"
}

# Helper: Get active connection
get_active_connection() {
    nmcli -t -f NAME,TYPE,DEVICE connection show --active | head -n1 | cut -d: -f1
}

# Helper: Format WiFi list for dmenu
get_wifi_list() {
    local active=$(get_active_connection)
    nmcli -t -f SSID,SIGNAL,SECURITY,BARS device wifi list | \
        sort -t: -k2 -rn | \
        awk -v active="$active" -F: '{
            icon = ($1 == active ? "▶️" : "  ");
            printf "%s %-30s %s %s\n", icon, $1, $4, $3
        }'
}

show_menu() {
    local cur_mode=$(cat "$MODE_FILE")
    local active=$(get_active_connection)
    [[ -z "$active" ]] && active="Disconnected"

    # --------------------------------------------
    # SCANNING / WAITING STATES
    # --------------------------------------------
    if [[ "$cur_mode" == "SCANNING" ]]; then
        echo -e "📡 Scanning WiFi networks...\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n⌛ Please wait..."
        return
    fi

    if [[ "$cur_mode" == "CONNECTING" ]]; then
        echo -e "🔌 Connecting...\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n⌛ Please wait..."
        return
    fi

    # --------------------------------------------
    # WIFI LIST MODE
    # --------------------------------------------
    if [[ "$cur_mode" == "WIFI" ]]; then
        echo "📂 [Back to Main Menu]"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        get_wifi_list
        return
    fi

    # --------------------------------------------
    # SAVED CONNECTIONS MODE
    # --------------------------------------------
    if [[ "$cur_mode" == "SAVED" ]]; then
        echo "📂 [Back to Main Menu]"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        nmcli -t -f NAME,TYPE connection show | grep -v "^--" | cut -d: -f1 | sed 's/^/💾 /'
        return
    fi

    # --------------------------------------------
    # MAIN MENU MODE
    # --------------------------------------------
    echo "🌐 Active: $active"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "📡  Connect to WiFi\n🔒  Connect to Hidden SSID\n📶  Disconnect Current\n📋  Saved Connections\n🔧  Toggle WiFi\n🔌  Toggle Ethernet\n⚡  Enable All\n❌  Disable All\n🚪  Exit"
}

execute_command() {
    local sel="$1"
    local cur_mode=$(cat "$MODE_FILE")

    # Navigation
    if [[ "$sel" == "📂 "* ]]; then
        echo "MAIN" > "$MODE_FILE"
        return
    fi

    # Mode: WIFI SELECTION
    if [[ "$cur_mode" == "WIFI" ]]; then
        local ssid=$(echo "$sel" | sed 's/^[ ▶️]*//; s/  .*//; s/ *$//')
        [[ -z "$ssid" ]] && return
        
        echo "CONNECTING" > "$MODE_FILE"
        show_menu >&3; printf "\1\n" >&3

        if nmcli connection show "$ssid" &>/dev/null; then
            nmcli connection up "$ssid" >/dev/null 2>&1
        else
            # For new connections, we need a password.
            # Since persistent dmenu is open, we launch a one-shot popup for the password.
            local pass=$(echo "" | dmenu -P -p "Password for $ssid:" "${DMENU_OPTS[@]}")
            [[ -n "$pass" ]] && nmcli device wifi connect "$ssid" password "$pass" >/dev/null 2>&1
        fi
        echo "MAIN" > "$MODE_FILE"
        return
    fi

    # Mode: SAVED SELECTION
    if [[ "$cur_mode" == "SAVED" ]]; then
        local conn=$(echo "$sel" | sed 's/^💾 //')
        nmcli connection up "$conn" >/dev/null 2>&1
        echo "MAIN" > "$MODE_FILE"
        return
    fi

    # Mode: MAIN MENU ACTIONS
    case "$sel" in
        *"Connect to WiFi"*)
            echo "SCANNING" > "$MODE_FILE"
            show_menu >&3; printf "\1\n" >&3
            nmcli device wifi rescan
            echo "WIFI" > "$MODE_FILE"
            ;;
        *"Connect to Hidden SSID"*)
            local ssid=$(echo "" | dmenu -p "Enter SSID:" "${DMENU_OPTS[@]}")
            [[ -z "$ssid" ]] && return
            local pass=$(echo "" | dmenu -P -p "Enter Password:" "${DMENU_OPTS[@]}")
            nmcli device wifi connect "$ssid" password "$pass"
            ;;
        *"Disconnect Current"*)
            local active=$(get_active_connection)
            [[ -n "$active" ]] && nmcli connection down "$active"
            ;;
        *"Saved Connections"*)
            echo "SAVED" > "$MODE_FILE"
            ;;
        *"Toggle WiFi"*)
            local status=$(nmcli radio wifi)
            [[ "$status" == "enabled" ]] && nmcli radio wifi off || nmcli radio wifi on
            ;;
        *"Toggle Ethernet"*)
            local eth=$(nmcli -t -f DEVICE,TYPE device status | grep ":ethernet" | cut -d: -f1 | head -n1)
            if [[ -n "$eth" ]]; then
                local state=$(nmcli -t -f DEVICE,STATE device status | grep "^$eth:" | cut -d: -f2)
                [[ "$state" == "connected" ]] && nmcli device disconnect "$eth" || nmcli device connect "$eth"
            fi
            ;;
        *"Enable All"*)  nmcli networking on ;;
        *"Disable All"*) nmcli networking off ;;
        *"Exit"*) exit 0 ;;
    esac
}

# ============================================
# MAIN LOOP
# ============================================

# Cleanup and setup FIFOs
rm -f "$FIFO_IN" "$FIFO_OUT"
mkfifo "$FIFO_IN" "$FIFO_OUT"

# Start dmenu
dmenu "${DMENU_OPTS[@]}" < "$FIFO_IN" > "$FIFO_OUT" &
DMENU_PID=$!

# Permanent FDs
exec 3> "$FIFO_IN"
exec 4< "$FIFO_OUT"

# BACKGROUND TICKER (Refresh signal strengths)
(
  while true; do
    sleep 10
    mode=$(cat "$MODE_FILE")
    if [[ "$mode" == "WIFI" || "$mode" == "MAIN" ]]; then
        show_menu >&3
        printf "\1\n" >&3
    fi
  done
) &
TICKER_PID=$!

trap "kill $DMENU_PID $TICKER_PID 2>/dev/null; rm -f $FIFO_IN $FIFO_OUT $MODE_FILE; exit" EXIT

# Initial Display
show_menu >&3
printf "\1\n" >&3

# Interaction Loop
while read -r selection <&4; do
    execute_command "$selection"
    sleep 0.2
    show_menu >&3
    printf "\1\n" >&3
done
