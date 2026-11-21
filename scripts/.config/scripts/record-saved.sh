#!/bin/bash
# Run by gpu-screen-recorder (-sc) after it saves a file; `record` passes it by default.
# $1 = saved file path, $2 = type: regular, replay or screenshot

file="${1:-}"
type="${2:-regular}"
[[ -n "$file" ]] || exit 0

case "$type" in
    replay)     title="Replay saved" ;;
    screenshot) title="Screenshot saved" ;;
    *)          title="Recording saved" ;;
esac

size=$(du -h -- "$file" 2>/dev/null | cut -f1)
notify-send -a record -i video-x-generic "$title" "${file##*/}${size:+ ($size)}"$'\n'"${file%/*}"
