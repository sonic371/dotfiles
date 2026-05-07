#!/bin/sh
# ~/.config/i3/sleep.sh - Timer with smart volume fade

set -eu  # Exit on error and undefined variables

# ============================================
# Configuration
# ============================================

DURATION_MINUTES=1
TARGET_PERCENT=20  # Target volume as % of original

# Directory for runtime files
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}/i3-sleep-timer"

# ============================================
# Helper Functions
# ============================================

setup_runtime_dir() {
    mkdir -p "$RUNTIME_DIR"
}

get_volume() {
    pactl get-sink-volume @DEFAULT_SINK@ | grep -o '[0-9]*%' | head -1 | tr -d '%'
}

cleanup_timer_files() {
    parent_pid="$1"
    rm -f "${RUNTIME_DIR}/timer_pids.${parent_pid}" \
          "${RUNTIME_DIR}/volume_state.${parent_pid}" \
          "${RUNTIME_DIR}/timer_cancel.${parent_pid}" \
          "${RUNTIME_DIR}/timer_done.${parent_pid}"
}

restore_volume() {
    state_file="$1"
    if [ -f "$state_file" ]; then
        volume=$(grep "^VOLUME:" "$state_file" | cut -d: -f2)
        if [ -n "$volume" ]; then
            pactl set-sink-volume "@DEFAULT_SINK@" "${volume}%"
            return 0
        fi
    fi
    return 1
}

cancel_timers() {
    pid_file="$1"
    
    if [ ! -f "$pid_file" ]; then
        notify-send "ℹ️ No Timers" "No active timers found"
        return 1
    fi
    
    # Extract parent PID from filename
    parent_pid=$(basename "$pid_file" | sed 's/timer_pids\.//')
    
    # Set cancel flag
    cancel_file="${RUNTIME_DIR}/timer_cancel.${parent_pid}"
    touch "$cancel_file"
    
    # Kill all timers
    killed=0
    while IFS=: read -r type pid; do
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null && killed=$((killed + 1))
        fi
    done < "$pid_file"
    
    # Restore volume
    state_file="${RUNTIME_DIR}/volume_state.${parent_pid}"
    restore_volume "$state_file"
    
    # Cleanup
    cleanup_timer_files "$parent_pid"
    rm -f "${RUNTIME_DIR}/last_timer_pids"
    
    notify_send_with_fallback "⏹️ Timers Cancelled" "Stopped $killed timer(s)\nVolume restored"
    return 0
}

notify_send_with_fallback() {
    title="$1"
    message="$2"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "$title" "$message"
    else
        echo "$title: $message"
    fi
}

# ============================================
# Timer Functions
# ============================================

start_audio_pause_timer() {
    duration="$1"
    done_file="$2"
    
    sleep "${duration}m"
    if command -v playerctl >/dev/null 2>&1; then
        playerctl pause 2>/dev/null
    fi
    touch "$done_file"
}

start_volume_fade_timer() {
    duration="$1"
    target_percent="$2"
    start_vol="$3"
    cancel_file="$4"
    done_file="$5"
    state_file="$6"
    
    # Calculate target volume (minimum 1%)
    target_vol=$((start_vol * target_percent / 100))
    [ "$target_vol" -lt 1 ] && target_vol=1
    
    # Don't fade if target is higher or equal
    [ "$start_vol" -le "$target_vol" ] && exit 0
    
    # Calculate fade steps
    steps=$((start_vol - target_vol))
    sleep_time=$((duration * 60 / steps))
    [ "$sleep_time" -lt 1 ] && sleep_time=1
    
    # Perform fade
    current="$start_vol"
    while [ "$current" -gt "$target_vol" ]; do
        [ -f "$cancel_file" ] && exit 0
        pactl set-sink-volume "@DEFAULT_SINK@" -1%
        current=$((current - 1))
        sleep "$sleep_time"
    done
    
    # Wait for audio to be paused before restoring volume
    timeout=60  # Maximum wait time in seconds
    waited=0
    while [ ! -f "$done_file" ] && [ ! -f "$cancel_file" ] && [ "$waited" -lt "$timeout" ]; do
        sleep 0.5
        waited=$((waited + 1))
    done
    
    # Restore original volume (only if not cancelled)
    if [ ! -f "$cancel_file" ] && [ -f "$state_file" ]; then
        restore_volume "$state_file"
    fi
    
    # Cleanup
    rm -f "$done_file" "$state_file" "$cancel_file"
}

# ============================================
# Main
# ============================================

setup_runtime_dir

case "${1:-start}" in
    cancel)
        # Find the PID file
        if [ -f "${RUNTIME_DIR}/last_timer_pids" ]; then
            pid_file=$(cat "${RUNTIME_DIR}/last_timer_pids")
        else
            # Find most recent timer_pids file
            pid_file=$(find "$RUNTIME_DIR" -maxdepth 1 -name "timer_pids.*" -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)
        fi
        
        if [ -z "$pid_file" ] || [ ! -f "$pid_file" ]; then
            notify_send_with_fallback "ℹ️ No Timers" "No active timers found"
            exit 0
        fi
        
        cancel_timers "$pid_file"
        exit 0
        ;;
    start|"")
        # Continue with start
        ;;
    *)
        echo "Usage: $0 [start|cancel]"
        echo "  start  - Start timers (default)"
        echo "  cancel - Cancel running timers and restore volume"
        exit 1
        ;;
esac

# Check if another instance is already running
last_timer_file="${RUNTIME_DIR}/last_timer_pids"
if [ -f "$last_timer_file" ]; then
    existing_pid_file=$(cat "$last_timer_file" 2>/dev/null)
    if [ -n "$existing_pid_file" ] && [ -f "$existing_pid_file" ]; then
        notify_send_with_fallback "⚠️ Timer Running" "Another timer is already active\nUse 'cancel' first or wait"
        exit 1
    fi
fi

# Start timers
parent_pid=$$
pid_file="${RUNTIME_DIR}/timer_pids.${parent_pid}"
state_file="${RUNTIME_DIR}/volume_state.${parent_pid}"
cancel_file="${RUNTIME_DIR}/timer_cancel.${parent_pid}"
timer_done_file="${RUNTIME_DIR}/timer_done.${parent_pid}"

# Save current volume
current_volume=$(get_volume)
if [ -z "$current_volume" ]; then
    notify_send_with_fallback "❌ Error" "Failed to get current volume"
    exit 1
fi
echo "VOLUME:$current_volume" > "$state_file"

# Send initial notification
notify_send_with_fallback "⏰ Timers Started" "Audio Pause: ${DURATION_MINUTES}m | Volume Fade: ${DURATION_MINUTES}m"

# Start audio pause timer
start_audio_pause_timer "$DURATION_MINUTES" "$timer_done_file" &
echo "AUDIO:$!" > "$pid_file"

# Start volume fade timer
start_volume_fade_timer "$DURATION_MINUTES" "$TARGET_PERCENT" "$current_volume" \
    "$cancel_file" "$timer_done_file" "$state_file" &
echo "VOLUME:$!" >> "$pid_file"

# Calculate target volume for notification
target_vol=$((current_volume * TARGET_PERCENT / 100))
[ "$target_vol" -lt 1 ] && target_vol=1
notify_send_with_fallback "✅ Timers Running" "Volume: ${current_volume}% → ${target_vol}% (${TARGET_PERCENT}% of original)\nPauses audio after ${DURATION_MINUTES}m"

# Save PID file location for cancel command
echo "$pid_file" > "$last_timer_file"
