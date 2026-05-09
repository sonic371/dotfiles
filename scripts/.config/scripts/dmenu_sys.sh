#!/bin/bash

# ============================================
# Persistent System Dashboard (FIXED & FAST)
# ============================================

# CONFIGURATION
FIFO_IN="/tmp/dmenu-sys-in"
FIFO_OUT="/tmp/dmenu-sys-out"
CACHE_FILE="/tmp/dmenu-sys-cache"
INTERFACE="wlp1s0" 
BAT_PATH="/sys/class/power_supply/BAT0"
TEMP_PATH="/sys/class/thermal/thermal_zone0/temp"
BL_PATH=$(find /sys/class/backlight -maxdepth 1 -mindepth 1 | head -n1)

# DMENU OPTIONS
DMENU_OPTS=(
    -fn "Px437 DOS/V re. JPN30:size=18"
    -nb "#000000" -nf "#ffffff" 
    -sb "#ffffff" -sf "#000000"
    -l 18 -c -persist -i -F
)

# Initialize Cache (Format: CPU_PERC|BW_STRING)
echo "0%|↓0B ↑0B" > "$CACHE_FILE"

# Helper: Progress Bar
draw_bar() {
    local val=$1; local max=$2; local width=$3
    [[ -z "$max" || "$max" == "0" ]] && max=100
    (( val > max )) && val=$max; (( val < 0 )) && val=0
    local filled=$(( val * width / max ))
    local bar=""
    for ((i=0; i<filled; i++)); do bar+="#"; done
    for ((i=filled; i<width; i++)); do bar+="-"; done
    echo "[$bar]"
}

# Helper: Fast Bytes
fmt_bytes() {
    local b=$1
    if (( b < 1024 )); then echo "${b}B"
    elif (( b < 1048576 )); then echo "$((b/1024))K"
    else echo "$((b/1048576))M"
    fi
}

render_ui() {
    # 1. Read Cached dynamic stats
    local cache=$(cat "$CACHE_FILE")
    local cpu_perc="${cache%|*}"
    local bw_stats="${cache#*|}"

    # 2. Memory
    local mem_perc=$(awk '/MemTotal/ {t=$2} /MemAvailable/ {a=$2} END {printf "%d%%", 100*(t-a)/t}' /proc/meminfo)

    # 3. Temp & Battery
    local temp=$(( $(< "$TEMP_PATH") / 1000 ))
    local bat_cap=$(< "$BAT_PATH/capacity")
    local bat_stat=$(< "$BAT_PATH/status")
    local bat_icon="🔋"
    [[ "$bat_stat" == "Charging" ]] && bat_icon="󱐋"
    [[ $bat_cap -lt 20 ]] && bat_icon="🪫"

    # 4. Storage
    local storage_perc=$(df -l / | awk 'NR==2 {print $5}')

    # 5. Volume
    local vol_raw=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\d+(?=%)' | head -1)
    local vol_mute=$(pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}')
    local vol_icon="🔊"
    [[ "$vol_mute" == "yes" ]] && vol_icon="🔇"

    # 6. Brightness
    local b_max=$(< "$BL_PATH/max_brightness")
    local b_cur=$(< "$BL_PATH/brightness")
    local bright_raw=$(( 100 * b_cur / b_max ))
    local b_icons=("󰃞" "󰃟" "󰃝" "󰃠")
    local b_idx=$((bright_raw / 25))
    (( b_idx > 3 )) && b_idx=3
    local bright_icon="${b_icons[b_idx]}"

    # 7. Bluetooth
    local bt_info="󰂲 Off"
    if bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
        local device=$(bluetoothctl info 2>/dev/null | awk -F': ' '/Name:/ {print $2}')
        if [[ -n "$device" ]]; then
            [[ ${#device} -gt 20 ]] && device="${device:0:17}..."
            bt_info="󰂯 $device"
        else
            bt_info="󰂯 Powered"
        fi
    fi

    # --------------------------------------------
    # OUTPUT MENU
    # --------------------------------------------
    echo "󰻠 $cpu_perc | 🌡️ $temp°C | 󰍛 $mem_perc | $bat_icon $bat_cap% | 💾 $storage_perc"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    # Combined Date and Time Line moved to the TOP
    echo "📅 $(date '+%A, %B %d %Y') | 󰥔 $(date '+%H:%M:%S')"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "$vol_icon $(draw_bar $vol_raw 100 15) $vol_raw%"
    echo "➕ Volume Up"
    echo "➖ Volume Down"
    echo "🔇 Mute Toggle"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "$bright_icon $(draw_bar $bright_raw 100 15) $bright_raw%"
    echo "☀️ Brightness Up"
    echo "🌙 Brightness Down"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📡 Bandwidth: $bw_stats"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "󰂯 Bluetooth: $bt_info"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🚪 Exit Dashboard"
}

execute_command() {
    case "$1" in
        "➕ "*) pactl set-sink-volume @DEFAULT_SINK@ +5% ;;
        "➖ "*) pactl set-sink-volume @DEFAULT_SINK@ -5% ;;
        "🔇 "*) pactl set-sink-mute @DEFAULT_SINK@ toggle ;;
        "☀️ "*) brightnessctl s +10% >/dev/null ;;
        "🌙 "*) brightnessctl s 10%- >/dev/null ;;
        "󰂯 "*) st -n "bluetui" -e bluetui &>/dev/null & ;;
        "📅 "*) st -e calcurse &>/dev/null & ;;
        "🚪 "*) exit 0 ;;
    esac
}

run_ticker() {
    while true; do
        read -r _ u n s i iw ir si st _ < /proc/stat
        local cpu_work=$((u+n+s+iw+ir+si+st))
        local cpu_total=$((cpu_work+i))
        local rx1=$(< /sys/class/net/$INTERFACE/statistics/rx_bytes)
        local tx1=$(< /sys/class/net/$INTERFACE/statistics/tx_bytes)

        sleep 1

        read -r _ u2 n2 s2 i2 iw2 ir2 si2 st2 _ < /proc/stat
        local cpu_work2=$((u2+n2+s2+iw2+ir2+si2+st2))
        local cpu_total2=$((cpu_work2+i2))
        local rx2=$(< /sys/class/net/$INTERFACE/statistics/rx_bytes)
        local tx2=$(< /sys/class/net/$INTERFACE/statistics/tx_bytes)

        local work_diff=$((cpu_work2 - cpu_work))
        local total_diff=$((cpu_total2 - cpu_total))
        local cpu_p="0"
        (( total_diff > 0 )) && cpu_p=$((100 * work_diff / total_diff))
        local rx_spd=$(fmt_bytes $((rx2 - rx1)))
        local tx_spd=$(fmt_bytes $((tx2 - tx1)))

        echo "${cpu_p}%|↓$rx_spd ↑$tx_spd" > "$CACHE_FILE"
        render_ui >&3
        printf "\1\n" >&3
    done
}

# SETUP
rm -f "$FIFO_IN" "$FIFO_OUT"
mkfifo "$FIFO_IN" "$FIFO_OUT"
dmenu "${DMENU_OPTS[@]}" < "$FIFO_IN" > "$FIFO_OUT" &
DMENU_PID=$!
exec 3> "$FIFO_IN"
exec 4< "$FIFO_OUT"

run_ticker 2>/dev/null &
TICKER_PID=$!

trap "kill $DMENU_PID $TICKER_PID 2>/dev/null; rm -f $FIFO_IN $FIFO_OUT $CACHE_FILE; exit" EXIT

# Initial
render_ui >&3
printf "\1\n" >&3

while read -r selection <&4; do
    execute_command "$selection"
    render_ui >&3
    printf "\1\n" >&3
done
