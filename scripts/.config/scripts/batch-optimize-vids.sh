#!/bin/sh

# Optimize videos for wallpaper - does one thing well
# Usage: ./optimize-videos.sh [suffix] [directory]

SUFFIX="${1:-_perf_8fps}"
DIR="${2:-$HOME/Videos/Hidamari}"
RES="1920:1200"
FPS="12"
CRF="30"

cd "$DIR" 2>/dev/null || { echo "Error: Cannot access $DIR"; exit 1; }

for f in *.mp4 *.webm; do
    [ -f "$f" ] || continue
    case "$f" in *"$SUFFIX"*) continue ;; esac
    
    out="${f%.*}${SUFFIX}.mp4"
    [ -f "$out" ] && continue
    
    echo "$f"
    ffmpeg -i "$f" \
        -vf "scale=$RES:force_original_aspect_ratio=decrease,pad=$RES:(ow-iw)/2:(oh-ih)/2,fps=$FPS" \
        -c:v libx264 -preset ultrafast -crf $CRF \
        -tune fastdecode -an -y "$out" 2>/dev/null &&
    echo "  -> $out"
done
