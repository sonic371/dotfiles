#!/bin/bash
# record-screen.sh - Just record the screen without audio

SCREEN_SIZE="1920x1200"
SCREEN_FPS="60"
OUTPUT_DIR="$HOME/Videos"

mkdir -p "$OUTPUT_DIR"
OUTPUT_FILE="$OUTPUT_DIR/recording_$(date +%Y%m%d_%H%M%S).mp4"

exec ffmpeg -y \
    -f x11grab -video_size "$SCREEN_SIZE" -framerate "$SCREEN_FPS" -i :0.0 \
    -c:v libx264 -preset ultrafast -crf 23 \
    "$OUTPUT_FILE"
