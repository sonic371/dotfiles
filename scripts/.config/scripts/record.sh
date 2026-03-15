#!/bin/bash
# A simple script to record screen, webcam, and audio with ffmpeg on Arch Linux.
# Fixed version with proper webcam aspect ratio handling

# --- Configuration (Edit these to your liking) ---
SCREEN_SIZE="1920x1080"
SCREEN_FPS="30"
WEBCAM_DEVICE="/dev/video0"
WEBCAM_SIZE="640x360"  # Changed to match your webcam's native resolution
WEBCAM_FPS="30"        # Changed to match your webcam's native framerate
WEBCAM_POSITION="top-right"  # Options: top-right, top-left, bottom-right, bottom-left
WEBCAM_WIDTH=300       # Desired display width in pixels (height will be auto-calculated)
AUDIO_DEVICE="default" # ALSA device
OUTPUT_DIR="$HOME/Videos"
PRESET="ultrafast"     # ultrafast for speed, or try superfast, medium, etc.
VIDEO_CODEC="libx264"
AUDIO_CODEC="aac"
# --- End Configuration ---

# Check if ffmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
    echo "Error: ffmpeg is not installed. Please install it with: sudo pacman -S ffmpeg"
    exit 1
fi

# Check if the webcam device exists
if [ ! -e "$WEBCAM_DEVICE" ]; then
    echo "Warning: Webcam device $WEBCAM_DEVICE not found. Recording will continue without webcam."
    WEBCAM_INPUT=""
    FILTER_COMPLEX=""
else
    # First, probe the webcam to see what it actually gives us
    echo "Probing webcam capabilities..."
    WEBCAM_INFO=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height,r_frame_rate -of default=noprint_wrappers=1:nokey=1 "$WEBCAM_DEVICE" 2>/dev/null)
    
    if [ ! -z "$WEBCAM_INFO" ]; then
        # Parse the info
        WEBCAM_WIDTH_NATIVE=$(echo "$WEBCAM_INFO" | sed -n '1p')
        WEBCAM_HEIGHT_NATIVE=$(echo "$WEBCAM_INFO" | sed -n '2p')
        WEBCAM_FPS_NATIVE=$(echo "$WEBCAM_INFO" | sed -n '3p' | bc 2>/dev/null || echo "$WEBCAM_FPS")
        
        echo "Detected webcam native resolution: ${WEBCAM_WIDTH_NATIVE}x${WEBCAM_HEIGHT_NATIVE} @ ${WEBCAM_FPS_NATIVE}fps"
        
        # Use the detected values
        WEBCAM_SIZE="${WEBCAM_WIDTH_NATIVE}x${WEBCAM_HEIGHT_NATIVE}"
        WEBCAM_FPS="$WEBCAM_FPS_NATIVE"
    fi
    
    WEBCAM_INPUT="-f v4l2 -video_size $WEBCAM_SIZE -framerate $WEBCAM_FPS -i $WEBCAM_DEVICE"
    
    # Calculate target display size preserving aspect ratio
    # We'll scale to a fixed width and calculate height proportionally
    TARGET_WIDTH=$WEBCAM_WIDTH
    TARGET_HEIGHT=$(( ($WEBCAM_HEIGHT_NATIVE * TARGET_WIDTH) / $WEBCAM_WIDTH_NATIVE ))
    # Make height even (required for many codecs)
    TARGET_HEIGHT=$((TARGET_HEIGHT + (TARGET_HEIGHT % 2)))
    
    echo "Webcam will be displayed at ${TARGET_WIDTH}x${TARGET_HEIGHT}"
    
    # Calculate position based on WEBCAM_POSITION
    case $WEBCAM_POSITION in
        "top-left")
            POSITION="10:10"
            ;;
        "top-right")
            POSITION="main_w-overlay_w-10:10"
            ;;
        "bottom-left")
            POSITION="10:main_h-overlay_h-10"
            ;;
        "bottom-right")
            POSITION="main_w-overlay_w-10:main_h-overlay_h-10"
            ;;
        *)
            POSITION="main_w-overlay_w-10:10"  # Default to top-right
            ;;
    esac
    
    # Simple scaling that preserves aspect ratio without padding
    FILTER_COMPLEX="[1:v] scale=$TARGET_WIDTH:$TARGET_HEIGHT [webcam]; [0:v][webcam] overlay=$POSITION"
    
    # Alternative: If you want padding to exact dimensions instead:
    # FILTER_COMPLEX="[1:v] scale=$TARGET_WIDTH:$TARGET_HEIGHT:force_original_aspect_ratio=1,pad=$TARGET_WIDTH:$TARGET_HEIGHT:(ow-iw)/2:(oh-ih)/2 [webcam]; [0:v][webcam] overlay=$POSITION"
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Generate a filename with a timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_FILE="$OUTPUT_DIR/recording_$TIMESTAMP.mp4"

echo "Starting recording..."
echo "Output file: $OUTPUT_FILE"
echo "Webcam position: $WEBCAM_POSITION"
[ ! -z "$WEBCAM_INPUT" ] && echo "Webcam will be scaled while preserving aspect ratio"
echo "Press 'q' in the terminal to stop recording."

# Build the ffmpeg command
FFMPEG_CMD="ffmpeg -y \
    -f x11grab -video_size \"$SCREEN_SIZE\" -framerate \"$SCREEN_FPS\" -i :0.0"

if [ ! -z "$WEBCAM_INPUT" ]; then
    FFMPEG_CMD="$FFMPEG_CMD $WEBCAM_INPUT"
fi

FFMPEG_CMD="$FFMPEG_CMD -f alsa -i \"$AUDIO_DEVICE\""

if [ ! -z "$FILTER_COMPLEX" ]; then
    FFMPEG_CMD="$FFMPEG_CMD -filter_complex \"$FILTER_COMPLEX\""
fi

FFMPEG_CMD="$FFMPEG_CMD -c:v $VIDEO_CODEC -preset $PRESET -c:a $AUDIO_CODEC"

# Map streams appropriately
if [ ! -z "$WEBCAM_INPUT" ]; then
    FFMPEG_CMD="$FFMPEG_CMD -map 0:v -map 1:v -map 2:a"
else
    FFMPEG_CMD="$FFMPEG_CMD -map 0:v -map 1:a"
fi

FFMPEG_CMD="$FFMPEG_CMD \"$OUTPUT_FILE\""

# Execute the command
eval $FFMPEG_CMD

echo "Recording finished: $OUTPUT_FILE"
