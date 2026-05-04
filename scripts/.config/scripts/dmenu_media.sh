#!/bin/bash

# ============================================
# MPV Media Controller (ELITE HUD VERSION)
# ============================================

# CONFIGURATION
SOCKET="/tmp/mpv-socket"
SOCAT_CMD="socat"
FIFO_IN="/tmp/dmenu-media-in"
FIFO_OUT="/tmp/dmenu-media-out"
MODE_FILE="/tmp/dmenu-media-mode"
MUSIC_DIR="/home/wade/Videos/Music"

# Startup command (Wallpaper mode)
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

# Helper: Send IPC command (Output captured)
ipc() { echo "$1" | $SOCAT_CMD - "$SOCKET" 2>/dev/null; }

# Helper: Send IPC command (Output silenced)
cmd() { ipc "$1" >/dev/null; }

# Helper: Fetch MPV property (Robust)
get_prop() { 
    ipc "{ \"command\": [\"get_property\", \"$1\"] }" | sed -E 's/.*"data":("([^"]*)"|([^,}]*)).*/\2\3/'
}

# Helper: Format seconds to MM:SS
fmt_time() {
    local sec=${1%.*}
    [[ -z "$sec" || "$sec" == "null" ]] && echo "00:00" && return
    printf "%02d:%02d" $((sec/60)) $((sec%60))
}

# Helper: Generate a progress bar [#######---]
draw_bar() {
    local val=${1%.*} # current value
    local max=${2%.*} # max value
    local width=$3    # character width
    [[ -z "$max" || "$max" == "null" || "$max" == "0" ]] && max=100
    (( val > max )) && val=$max
    (( val < 0 )) && val=0
    local filled=$(( val * width / max ))
    local bar=""
    for ((i=0; i<filled; i++)); do bar+="#"; done
    for ((i=filled; i<width; i++)); do bar+="-"; done
    echo "[$bar]"
}

show_menu() {
    # Heartbeat check
    if ! ipc '{ "command": ["get_property", "pause"] }' | grep -q "data"; then
        echo -e "⚠️ MPV Offline\n━━━━━━━━━━━━━━━━━━\n▶️ Start MPV\n🚪 Exit"
        return
    fi
    
    local playing_idx=$(get_prop "playlist-pos")
    local cur_mode=$(cat "$MODE_FILE")

    # --------------------------------------------
    # PLAYLIST BROWSER MODE
    # --------------------------------------------
    if [[ "$cur_mode" == "PLAYLIST" ]]; then
        echo "📂 [Back to Controls]"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        
        ipc '{ "command": ["get_property", "playlist"] }' | \
            grep -o '"filename":"[^"]*"' | cut -d'"' -f4 | \
            sed 's/.*\///; s/\.[^.]*$//' | \
            awk -v cur="$((playing_idx+1))" '{ printf "%s %02d: %s\n", (NR==cur ? "▶️" : "  "), NR, $0 }'
        return
    fi

    # --------------------------------------------
    # REMOTE CONTROL MODE (HUD)
    # --------------------------------------------
    local pause_state=$(get_prop "pause")
    local icon=$([[ "$pause_state" == "false" ]] && echo "󰝚" || echo "")
    local volume=$(get_prop "volume")
    local song=$(get_prop "media-title")
    [[ -z "$song" || "$song" == "null" ]] && song=$(get_prop "filename")
    local pos=$(get_prop "time-pos")
    local dur=$(get_prop "duration")
    
    # Clean up song title
    song=$(echo "$song" | sed 's/ #.*//; s/\.[^.]*$//')
    
    # Dynamic Volume Icon
    local vol_int=${volume%.*}
    local vol_icon=""
    if [[ $vol_int -eq 0 ]]; then vol_icon="󰝟"
    elif [[ $vol_int -lt 40 ]]; then vol_icon=""
    elif [[ $vol_int -lt 70 ]]; then vol_icon=""
    fi

    # Output Menu
    echo "$icon $song"
    echo "🕒 $(fmt_time $pos) $(draw_bar $pos $dur 15) $(fmt_time $dur)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "⏯️  Play/Pause\n⏭️  Next Track\n⏮️  Previous Track\n⏹️  Stop"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "$vol_icon $(draw_bar $vol_int 100 10) $vol_int%"
    echo -e "➕ Volume Up\n➖ Volume Down\n🔇 Mute/Unmute"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "⏩ Seek +30s\n⏪ Seek -30s\n⏫ Seek +5m\n⏬ Seek -5m"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "🔍 Browse Playlist\n🚪 Exit"
}

execute_command() {
    case "$1" in
        # Navigation
        "📂 "*) echo "CONTROLS" > "$MODE_FILE" ;;
        "🔍 "*) echo "PLAYLIST" > "$MODE_FILE" ;;
        
        # Seek Bar (Match by emoji, explicitly ignore)
        "🕒 "*) return ;;

        # Playlist Selection (Any line containing "digits:")
        *[0-9]*:*) 
            local idx=$(echo "$1" | grep -o "[0-9]*:" | head -n1 | tr -d ':')
            idx=$(( 10#$idx - 1 ))
            cmd "{ \"command\": [\"playlist-play-index\", $idx] }"
            echo "CONTROLS" > "$MODE_FILE" ;;

        # Title Info
        "󰝚 "*|" "*) 
            local full_title=$(get_prop 'media-title' | sed 's/ #.*//')
            local vol=$(get_prop 'volume')
            local info="Track: $full_title\nVol: ${vol%.*}%\nPlaylist: $(( $(get_prop 'playlist-pos') + 1 )) of $(get_prop 'playlist-count')"
            notify-send -t 2000 "MPV Media Center" "$info" ;;

        # Playback
        "⏯️  "*) cmd "cycle pause" ;;
        "⏭️  "*) cmd "playlist-next" ;;
        "⏮️  "*) cmd "playlist-prev" ;;
        "⏹️  "*) cmd "stop" ;;

        # Volume
        "➕ "*)  cmd "add volume 10" ;;
        "➖ "*)  cmd "add volume -10" ;;
        "🔇 "*)  cmd "cycle mute" ;;

        # Seeking
        "⏩ "*)  cmd "seek 30" ;;
        "⏪ "*)  cmd "seek -30" ;;
        "⏫ "*)  cmd "seek 300" ;;
        "⏬ "*)  cmd "seek -300" ;;

        # System
        "▶️ "*)
            eval "$MPV_CMD" &
            for i in {1..50}; do
                if ipc '{ "command": ["get_property", "pause"] }' | grep -q "data"; then break; fi
                sleep 0.1
            done
            ;;
        "🚪 "*) exit 0 ;;
    esac
}

# ============================================
# MAIN LOOP
# ============================================

# Create FIFOs if they don't exist
[[ -p "$FIFO_IN" ]] || mkfifo "$FIFO_IN"
[[ -p "$FIFO_OUT" ]] || mkfifo "$FIFO_OUT"

# Start dmenu in the background
dmenu "${DMENU_OPTS[@]}" < "$FIFO_IN" > "$FIFO_OUT" &
DMENU_PID=$!

# Open FIFOs and keep them open (Permanent Connection)
exec 3> "$FIFO_IN"
exec 4< "$FIFO_OUT"

# BACKGROUND TICKER (Inherits FD 3)
(
  while true; do
    sleep 1
    if [[ "$(cat "$MODE_FILE")" == "CONTROLS" ]]; then
        if ipc '{ "command": ["get_property", "pause"] }' | grep -q "data"; then
            show_menu >&3
            printf "\1\n" >&3
        fi
    fi
  done
) 2>/dev/null & # Silence background errors if dmenu closes
TICKER_PID=$!

# Cleanup on exit
trap "kill $DMENU_PID $TICKER_PID 2>/dev/null; rm -f $FIFO_IN $FIFO_OUT $MODE_FILE; exit" EXIT

# Initial menu
show_menu >&3
printf "\1\n" >&3

# Controller Loop (Uses permanent FD 4)
while read -r selection <&4; do
    execute_command "$selection"
    # Small sleep to let MPV process state
    sleep 0.1
    show_menu >&3
    printf "\1\n" >&3
done
