#!/bin/bash

# ============================================
# MPV Media Controller with dmenu (DYNAMIC)
# Uses direct IPC socket to mpv
# ============================================

# ============================================
# CONFIGURATION SECTION
# ============================================

# Socket configuration
SOCKET="/tmp/mpv-socket"
SOCAT_CMD="socat"

# Music directory
MUSIC_DIR="/home/wade/Videos/Music"

# FIFO files for dmenu communication
FIFO_IN="/tmp/dmenu-media-in"
FIFO_OUT="/tmp/dmenu-media-out"

# Dmenu appearance
DMENU_OPTS=(
    -fn "Px437 DOS/V re. JPN30:size=18"
    -nb "#000000"
    -nf "#ffffff"
    -sb "#ffffff"
    -sf "#000000"
    -l 25
    -h 20
    -persist
)

NOTIFY_TIMEOUT=1500
MAX_TITLE_LENGTH=60

# ============================================
# FUNCTIONS
# ============================================

send_command() { echo "$1" | $SOCAT_CMD - "$SOCKET" 2>/dev/null; }
send_json_command() { echo "$1" | $SOCAT_CMD - "$SOCKET" 2>/dev/null; }

get_status() {
    response=$(send_json_command '{ "command": ["get_property", "pause"] }')
    [[ "$response" == *'"data":false'* ]] && echo "Playing" || echo "Paused"
}

get_song_title() {
    response=$(send_json_command '{ "command": ["get_property", "media-title"] }')
    title=$(echo "$response" | grep -o '"data":"[^"]*"' | cut -d'"' -f4)
    if [ -z "$title" ]; then
        response=$(send_json_command '{ "command": ["get_property", "filename"] }')
        title=$(echo "$response" | grep -o '"data":"[^"]*"' | cut -d'"' -f4 | sed 's/\.[^.]*$//')
    fi
    echo "$title"
}

get_volume() {
    response=$(send_json_command '{ "command": ["get_property", "volume"] }')
    volume=$(echo "$response" | grep -o '"data":[0-9]*' | cut -d':' -f2)
    echo "${volume:-0}"
}

is_mpv_running() { pgrep -x "mpv" > /dev/null; }

truncate_text() {
    local text="$1"
    local max_len="$2"
    ((${#text} > max_len)) && echo "${text:0:$((max_len-3))}..." || echo "$text"
}

show_menu() {
    if ! is_mpv_running; then
        echo "⚠️ MPV not running"
        echo "━━━━━━━━━━━━━━━━━━"
        echo "▶️ Start MPV"
        echo "🚪 Exit"
        return
    fi
    
    status=$(get_status)
    song=$(get_song_title)
    volume=$(get_volume)
    song=$(truncate_text "$song" "$MAX_TITLE_LENGTH")
    
    echo "🎵 $status: $song"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⏯️  Play/Pause"
    echo "⏭️  Next Track"
    echo "⏮️  Previous Track"
    echo "⏹️  Stop"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔊 Volume Up   +10%  (Current: ${volume}%)"
    echo "🔉 Volume Down -10%  (Current: ${volume}%)"
    echo "🔇 Mute/Unmute"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔄 Shuffle Toggle"
    echo "🔁 Loop Playlist"
    echo "🔂 Loop Single File"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⏩ Seek +30 seconds"
    echo "⏪ Seek -30 seconds"
    echo "⏫ Seek +5 minutes"
    echo "⏬ Seek -5 minutes"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 Current Track Info"
    echo "📊 Playlist Status"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🎯 Play Music Directory"
    echo "🔄 Restart MPV"
    echo "🚪 Exit"
}

execute_command() {
    case "$1" in
        "⏯️  Play/Pause") send_command "cycle pause" ;;
        "⏭️  Next Track") send_command "playlist-next" ;;
        "⏮️  Previous Track") send_command "playlist-prev" ;;
        "⏹️  Stop") send_command "stop" ;;
        "🔊 Volume Up"*) send_command "add volume 10" ;;
        "🔉 Volume Down"*) send_command "add volume -10" ;;
        "🔇 Mute/Unmute") send_command "cycle mute" ;;
        "🔄 Shuffle Toggle") send_command "cycle shuffle" ;;
        "🔁 Loop Playlist") send_command "set loop-playlist inf" ;;
        "🔂 Loop Single File") send_command "set loop-file inf" ;;
        "⏩ Seek +30 seconds") send_command "seek 30" ;;
        "⏪ Seek -30 seconds") send_command "seek -30" ;;
        "⏫ Seek +5 minutes") send_command "seek 300" ;;
        "⏬ Seek -5 minutes") send_command "seek -300" ;;
        "🎯 Play Music Directory") mpv --shuffle --loop-playlist=inf --no-video --input-ipc-server="$SOCKET" "$MUSIC_DIR" & ;;
        "🔄 Restart MPV"*) pkill mpv; sleep 0.5; mpv --shuffle --loop-playlist=inf --no-video --input-ipc-server="$SOCKET" "$MUSIC_DIR" & ;;
        "▶️ Start MPV") mpv --shuffle --loop-playlist=inf --no-video --input-ipc-server="$SOCKET" "$MUSIC_DIR" & ;;
        "🚪 Exit") exit 0 ;;
    esac
}

# ============================================
# MAIN LOOP
# ============================================

# Create FIFOs if they don't exist
[[ -p "$FIFO_IN" ]] || mkfifo "$FIFO_IN"
[[ -p "$FIFO_OUT" ]] || mkfifo "$FIFO_OUT"

# Start dmenu in the background
./dmenu "${DMENU_OPTS[@]}" < "$FIFO_IN" > "$FIFO_OUT" &
DMENU_PID=$!

# Cleanup on exit
trap "kill $DMENU_PID 2>/dev/null; rm -f $FIFO_IN $FIFO_OUT; exit" EXIT

# Open FIFO_IN for writing and keep it open
exec 3> "$FIFO_IN"

# 1. Send initial menu
show_menu >&3
printf "\1\n" >&3

# Controller Loop
while true; do
    # 2. Wait for user selection from dmenu
    if read -r selection < "$FIFO_OUT"; then
        # 3. Execute command
        execute_command "$selection"
        # 4. Small sleep to let MPV update its state
        sleep 0.1
        # 5. Send UPDATED menu to dmenu
        show_menu >&3
        printf "\1\n" >&3
    else
        # dmenu was closed (Escape)
        break
    fi
done
