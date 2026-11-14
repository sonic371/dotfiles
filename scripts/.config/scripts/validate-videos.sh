#!/usr/bin/env bash
# Decode every video under the current folder and move it to
#   verified_videos/   decoded without errors
#   corrupted_videos/  ffmpeg reported an error
# The whole file is decoded (slow for long videos, but damage near the end is caught).
# Usage: validate-videos.sh [-n]   -n = dry run, only print the verdicts
# Name clashes in the target folder get _1, _2 … appended; files already sorted are left alone.
set -euo pipefail
DRY=0; [[ ${1:-} == -n ]] && DRY=1
export DRY
command -v ffmpeg >/dev/null || { echo "ffmpeg not installed: sudo pacman -S ffmpeg" >&2; exit 1; }

check() {
    local f=$1 dir name dest n=1
    if [[ -z $(ffmpeg -nostdin -v error -i "$f" -f null - 2>&1 | head -c 1) ]]; then
        dir=verified_videos
    else
        dir=corrupted_videos
    fi
    if (( DRY )); then echo "$dir: $f"; return; fi
    name=${f##*/}
    dest=$dir/$name
    # mv -n skips silently if a parallel job took the name first, so retry until the file has moved
    while [[ -e $f ]]; do
        [[ -e $dest ]] || mv -n -- "$f" "$dest"
        dest=$dir/${name%.*}_$n.${name##*.}; ((n++))
    done
    echo "$dir: $f"
}
export -f check

(( DRY )) || mkdir -p verified_videos corrupted_videos
# ffmpeg uses several cores per file, so run half as many jobs as cores
find . -type f \( -iname '*.mp4' -o -iname '*.mov' -o -iname '*.mkv' -o -iname '*.avi' \) \
    -not -path './verified_videos/*' -not -path './corrupted_videos/*' -print0 |
    xargs -0 -r -P "$(( ($(nproc) + 1) / 2 ))" -n 1 bash -c 'check "$1"' _

(( DRY )) && exit 0
echo
echo "verified:  $(find verified_videos -type f | wc -l)"
echo "corrupted: $(find corrupted_videos -type f | wc -l)"
