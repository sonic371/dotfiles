#!/bin/sh

# Quick video stats checker
cd "$HOME/Videos/Hidamari" || exit

echo "=== Original vs Optimized Video Comparison ==="
echo ""

for optimized in *_optimized.mp4; do
    [ -f "$optimized" ] || continue
    
    # Get original filename (remove _optimized)
    original="${optimized%_optimized.mp4}.mp4"
    [ -f "$original" ] || original="${optimized%_optimized.mp4}.webm"
    [ -f "$original" ] || continue
    
    echo "File: $original"
    echo "----------------------------------------"
    
    # Original video stats
    echo "ORIGINAL:"
    ffprobe -v error \
        -show_entries stream=codec_name,width,height,r_frame_rate,bit_rate \
        -of default=noprint_wrappers=1:nokey=0 "$original" | \
        sed 's/^/  /'
    
    # Optimized video stats
    echo "OPTIMIZED:"
    ffprobe -v error \
        -show_entries stream=codec_name,width,height,r_frame_rate,bit_rate \
        -of default=noprint_wrappers=1:nokey=0 "$optimized" | \
        sed 's/^/  /'
    
    # File sizes
    orig_size=$(du -h "$original" | cut -f1)
    opt_size=$(du -h "$optimized" | cut -f1)
    echo "  Size: $orig_size -> $opt_size"
    
    echo ""
done
