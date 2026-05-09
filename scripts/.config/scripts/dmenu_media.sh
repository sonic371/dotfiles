#!/bin/bash

# ============================================
# MPV Media Controller (ELITE TICKER VERSION)
# ============================================

# CONFIGURATION
SOCKET="/tmp/mpv-socket"
SOCAT_CMD="socat"
FIFO_IN="/tmp/dmenu-nmcli-in" # Reusing FIFOs for consistency
FIFO_OUT="/tmp/dmenu-nmcli-out"
MODE_FILE="/tmp/dmenu-media-mode"
TICKER_FILE="/tmp/dmenu-media-ticker"
LAST_SONG_FILE="/tmp/dmenu-media-last"
MUSIC_DIR="/home/wade/Videos/Music"

# Startup command
MPV_CMD="xwinwrap -ni -nf -b -un -s -fs -ovr -d -- mpv -wid WID --input-ipc-server=$SOCKET --fs=yes --shuffle --loop-playlist=inf --osd-bar=no $MUSIC_DIR"

# DMENU OPTIONS
DMENU_OPTS=(
    -fn "Px437 DOS/V re. JPN30:size=18"
    -nb "#000000" -nf "#ffffff" 
    -sb "#ffffff" -sf "#000000"
    -l 20 -h 25 -c -persist -i -F
)

# Initialize State
echo "CONTROLS" > "$MODE_FILE"
echo 0 > "$TICKER_FILE"

# Helper: Send IPC command
ipc() { echo "$1" | $SOCAT_CMD - "$SOCKET" 2>/dev/null; }
cmd() { ipc "$1" >/dev/null; }

# Helper: Fetch MPV property
get_prop() { 
    ipc "{ \"command\": [\"get_property\", \"$1\"] }" | sed -E 's/.*"data":("([^"]*)"|([^,}]*)).*/\2\3/'
}

# Helper: Format seconds to MM:SS
fmt_time() {
    local sec=${1%.*}
    [[ -z "$sec" || "$sec" == "null" ]] && echo "00:00" && return
    printf "%02d:%02d" $((sec/60)) $((sec%60))
}

# Helper: Generate a progress bar
draw_bar() {
    local val=${1%.*}; local max=${2%.*}; local width=$3
    [[ -z "$max" || "$max" == "null" || "$max" == "0" ]] && max=100
    (( val > max )) && val=$max; (( val < 0 )) && val=0
    local filled=$(( val * width / max )); local bar=""
    for ((i=0; i<filled; i++)); do bar+="#"; done
    for ((i=filled; i<width; i++)); do bar+="-"; done
    echo "[$bar]"
}

# Helper: News Ticker Logic
get_scrolled_title() {
    local raw_title="$1"
    local max=40
    
    # 1. Clean the title
    local song=$(echo "$raw_title" | sed 's/ #.*//; s/\.[^.]*$//')
    local len=${#song}
    
    # 2. Reset ticker if song changed
    local last_song=$(cat "$LAST_SONG_FILE" 2>/dev/null)
    if [[ "$song" != "$last_song" ]]; then
        echo 0 > "$TICKER_FILE"
        echo "$song" > "$LAST_SONG_FILE"
    fi
    
    # 3. If short enough, just return it
    if (( len <= max )); then
        echo "$song"
        return
    fi
    
    # 4. Scroll logic
    local offset=$(cat "$TICKER_FILE" 2>/dev/null || echo 0)
    local padded="$song   "
    local plen=${#padded}
    
    local res="${padded:$offset:$max}"
    if (( ${#res} < max )); then
        res="${res}${padded:0:$((max - ${#res}))}"
    fi
    echo "$res"
}

show_menu() {
    if ! ipc '{ "command": ["get_property", "pause"] }' | grep -q "data"; then
        echo -e "⚠️ MPV Offline\n━━━━━━━━━━━━━━━━━━\n▶️ Start MPV\n🚪 Exit"
        return
    fi
    
    local cur_mode=$(cat "$MODE_FILE")
    local playing_idx=$(get_prop "playlist-pos")

    if [[ "$cur_mode" == "PLAYLIST" ]]; then
        echo "📂 [Back to Controls]"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        ipc '{ "command": ["get_property", "playlist"] }' | \
            grep -o '"filename":"[^"]*"' | cut -d'"' -f4 | \
            sed 's/.*\///; s/\.[^.]*$//' | \
            awk -v cur="$((playing_idx+1))" '{ printf "%s %02d: %s\n", (NR==cur ? "▶️" : "  "), NR, $0 }'
        return
    fi

    # REMOTE CONTROL MODE
    local pause_state=$(get_prop "pause")
    local icon=$([[ "$pause_state" == "false" ]] && echo "󰝚" || echo "")
    local title=$(get_prop "media-title")
    [[ -z "$title" || "$title" == "null" ]] && title=$(get_prop "filename")
    
    local scrolled=$(get_scrolled_title "$title")
    local vol=$(get_prop "volume")
    local pos=$(get_prop "time-pos")
    local dur=$(get_prop "duration")
    
    local vol_int=${vol%.*}
    local vol_icon=""
    [[ $vol_int -eq 0 ]] && vol_icon="󰝟" || [[ $vol_int -lt 40 ]] && vol_icon="" || [[ $vol_int -lt 70 ]] && vol_icon=""

    echo "$icon $scrolled"
    echo "🕒 $(fmt_time $pos) $(draw_bar $pos $dur 15) $(fmt_time $dur)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "⏯️  Play/Pause\n⏭️  Next Track\n⏮️  Previous Track\n⏹️  Stop"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "$vol_icon $(draw_bar $vol_int 100 10) $vol_int%"
    echo -e "➕ Volume Up\n➖ Volume Down\nMute/Unmute"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "⏩ Seek +30s\n⏪ Seek -30s\n⏫ Seek +5m\n⏬ Seek -5m"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "🔍 Browse Playlist\n🚪 Exit"
}

execute_command() {
    case "$1" in
        "📂 "*) echo "CONTROLS" > "$MODE_FILE" ;;
        "🔍 "*) echo "PLAYLIST" > "$MODE_FILE" ;;
        "🕒 "*) return ;;
        *[0-9]*:*) 
            local idx=$(echo "$1" | grep -o "[0-9]*:" | head -n1 | tr -d ':')
            cmd "{ \"command\": [\"playlist-play-index\", $((10#$idx - 1))] }"
            echo "CONTROLS" > "$MODE_FILE" ;;
        "󰝚 "*|" "*) 
            notify-send -t 2000 "MPV" "Track: $(get_prop 'media-title' | sed 's/ #.*//')\nVol: $(get_prop 'volume')%" ;;
        "⏯️  "*) cmd "cycle pause" ;;
        "⏭️  "*) cmd "playlist-next" ;;
        "⏮️  "*) cmd "playlist-prev" ;;
        "⏹️  "*) cmd "stop" ;;
        "➕ "*)  cmd "add volume 10" ;;
        "➖ "*)  cmd "add volume -10" ;;
        "Mute"*) cmd "cycle mute" ;;
        "⏩ "*)  cmd "seek 30" ;;
        "⏪ "*)  cmd "seek -30" ;;
        "⏫ "*)  cmd "seek 300" ;;
        "⏬ "*)  cmd "seek -300" ;;
        "▶️ "*)   eval "$MPV_CMD" & 
                  for i in {1..50}; do ipc '{ "command": ["get_property", "pause"] }' | grep -q "data" && break; sleep 0.1; done ;;
        "🚪 "*) exit 0 ;;
    esac
}

# SETUP
[[ -p "$FIFO_IN" ]] || mkfifo "$FIFO_IN"
[[ -p "$FIFO_OUT" ]] || mkfifo "$FIFO_OUT"
dmenu "${DMENU_OPTS[@]}" < "$FIFO_IN" > "$FIFO_OUT" &
DMENU_PID=$!
exec 3> "$FIFO_IN"
exec 4< "$FIFO_OUT"

# BACKGROUND TICKER (0.3s refresh for ticker animation)
(
  while true; do
    sleep 0.3
    if [[ "$(cat "$MODE_FILE")" == "CONTROLS" ]]; then
        if ipc '{ "command": ["get_property", "pause"] }' | grep -q "data"; then
            # Increment ticker offset
            offset=$(cat "$TICKER_FILE" 2>/dev/null || echo 0)
            song=$(cat "$LAST_SONG_FILE" 2>/dev/null)
            # Use song length + 3 spaces for modulo
            [[ -n "$song" ]] && echo $(( (offset + 1) % (${#song} + 3) )) > "$TICKER_FILE"
            
            show_menu >&3
            printf "\1\n" >&3
        fi
    fi
  done
) 2>/dev/null &
TICKER_PID=$!

trap "kill $DMENU_PID $TICKER_PID 2>/dev/null; rm -f $FIFO_IN $FIFO_OUT $MODE_FILE $TICKER_FILE $LAST_SONG_FILE; exit" EXIT

# Initial
show_menu >&3; printf "\1\n" >&3

while read -r selection <&4; do
    execute_command "$selection"
    sleep 0.1
    show_menu >&3; printf "\1\n" >&3
done
