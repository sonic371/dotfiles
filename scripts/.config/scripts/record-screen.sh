#!/bin/bash
# record-screen.sh - Just record the screen with audio

SCREEN_SIZE="1920x1200"
SCREEN_FPS="30"
OUTPUT_DIR="$HOME/Videos"
SYSTEM_AUDIO="alsa_output.pci-0000_c3_00.6.HiFi__Speaker__sink.monitor"
MIC_SOURCE="alsa_input.pci-0000_c3_00.6.HiFi__Mic1__source"

mkdir -p "$OUTPUT_DIR"
OUTPUT_FILE="$OUTPUT_DIR/recording_$(date +%Y%m%d_%H%M%S).mp4"

exec ffmpeg -y \
    -f x11grab -video_size "$SCREEN_SIZE" -framerate "$SCREEN_FPS" -i :0.0 \
    -f pulse -i "$SYSTEM_AUDIO" \
    -f pulse -i "$MIC_SOURCE" \
    -filter_complex "[1:a][2:a]amix=inputs=2:duration=longest[aout]" \
    -map 0:v -map "[aout]" \
    -c:v libx264 -preset ultrafast -crf 23 \
    -c:a aac \
    "$OUTPUT_FILE"
