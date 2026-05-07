#!/bin/bash
# toggle-recording.sh - Single script with dunst notifications
# Usage: Bind to a single key in sxhkd for start/stop toggle

# Configuration
PID_FILE="/tmp/screen-recording.pid"
RECORDING_DIR="$HOME/Videos/recordings"
SCRIPT_NAME="screen-recording"

# Create recording directory if it doesn't exist
mkdir -p "$RECORDING_DIR"

# Dunst notification function
notify() {
    local message="$1"
    local urgency="${2:-normal}"
    local timeout="${3:-2000}"
    
    echo "$message"
    if command -v dunstify >/dev/null 2>&1; then
        dunstify -u "$urgency" -t "$timeout" -a "$SCRIPT_NAME" "🎥 Screen Recording" "$message"
    elif command -v notify-send >/dev/null 2>&1; then
        notify-send -u "$urgency" -t "$timeout" "🎥 Screen Recording" "$message"
    fi
}

# Check if recording is already running
is_recording() {
    [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null
}

# Cleanup function for the recording process
cleanup_recording() {
    echo ""
    notify "Processing recording..." "normal" 1000
    
    # Kill ffmpeg processes
    if [ -n "$SCREEN_PID" ]; then
        kill -SIGINT "$SCREEN_PID" 2>/dev/null
    fi
    if [ -n "$WEBCAM_PID" ]; then
        kill -SIGINT "$WEBCAM_PID" 2>/dev/null
    fi
    
    # Wait for processes to finish
    wait "$SCREEN_PID" 2>/dev/null
    wait "$WEBCAM_PID" 2>/dev/null
    
    # Combine the recordings
    if [ -f "$SCREEN_FILE" ] && [ -f "$WEBCAM_FILE" ]; then
        notify "Combining video tracks..." "normal" 1000
        ffmpeg -i "$SCREEN_FILE" -i "$WEBCAM_FILE" \
          -filter_complex "[1:v]scale=320:240[webcam];[0:v][webcam]overlay=15:H-h-30" \
          -c:v libx264 -crf 23 -c:a copy \
          "$COMBINED_FILE" -y 2>/dev/null
        
        if [ $? -eq 0 ]; then
            notify "✅ Recording saved: $(basename "$COMBINED_FILE")" "critical" 5000
            echo "Done! Combined file: $COMBINED_FILE"
            
            # Optional: Delete original files (uncomment to enable)
            # rm "$SCREEN_FILE" "$WEBCAM_FILE"
        else
            notify "❌ Failed to combine recordings!" "critical" 5000
        fi
    fi
    
    # Cleanup PID file
    rm -f "$PID_FILE"
    exit 0
}

# Start a new recording
start_recording() {
    cd "$RECORDING_DIR" || {
        notify "Failed to access recording directory!" "critical"
        exit 1
    }
    
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    SCREEN_FILE="screen_${TIMESTAMP}.mp4"
    WEBCAM_FILE="webcam_${TIMESTAMP}.mp4"
    COMBINED_FILE="combined_${TIMESTAMP}.mp4"
    
    export SCREEN_FILE WEBCAM_FILE COMBINED_FILE
    export SCREEN_PID WEBCAM_PID
    
    notify "🎬 Recording started" "normal" 2000
    notify "Screen + Webcam + Audio" "normal" 2000
    
    # Set up trap for cleanup
    trap cleanup_recording SIGINT SIGTERM
    
    # Record screen with audio
    ffmpeg -video_size 1920x1200 -framerate 30 \
      -f x11grab -i :0.0 \
      -f pulse -i alsa_output.pci-0000_c3_00.6.HiFi__Speaker__sink.monitor \
      -f pulse -i alsa_input.usb-YUKUI_YUKUI_D80_0000KT4c020000001-00.analog-stereo \
      -filter_complex "[1:a][2:a]amix=inputs=2:duration=longest[a]" \
      -map 0:v -map "[a]" \
      -c:v libx264 -preset veryfast -crf 23 \
      -c:a aac -b:a 128k \
      "$SCREEN_FILE" 2>/dev/null &
    
    SCREEN_PID=$!
    
    # Record webcam
    ffmpeg -f v4l2 -framerate 30 -video_size 640x480 -i /dev/video0 \
      -c:v libx264 -preset ultrafast -crf 23 \
      "$WEBCAM_FILE" 2>/dev/null &
    
    WEBCAM_PID=$!
    
    # Wait for processes
    wait $SCREEN_PID $WEBCAM_PID
}

# Stop recording and cleanup
stop_recording() {
    local pid
    pid=$(cat "$PID_FILE")
    
    notify "⏹️ Stopping recording..." "normal" 2000
    
    # Send SIGINT to the recording process
    kill -SIGINT "$pid" 2>/dev/null
    
    # Wait for cleanup to complete
    local count=0
    while kill -0 "$pid" 2>/dev/null && [ $count -lt 15 ]; do
        sleep 1
        ((count++))
    done
    
    # Force kill if needed
    if kill -0 "$pid" 2>/dev/null; then
        kill -9 "$pid" 2>/dev/null
    fi
    
    rm -f "$PID_FILE"
}

# Main toggle logic
if is_recording; then
    stop_recording
else
    # Start recording in background
    start_recording &
    echo "$!" > "$PID_FILE"
fi
