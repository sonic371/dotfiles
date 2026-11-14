#!/usr/bin/env bash
# Sort the files in the current folder (not subfolders, not hidden files):
#   photos/       images with an EXIF capture date (camera/phone photos)
#   non_photos/   other images (screenshots, downloads, edits)
#   other_files/  everything else
# Usage: sort-photos.sh [-n]      -n = dry run, only print where each file would go
# Never overwrites: a name that already exists in the target folder is skipped and reported.
set -euo pipefail
DRY=0; [[ ${1:-} == -n ]] && DRY=1
export DRY

classify() {
    local f=$1 dest
    if [[ $(file -b --mime-type "$f") == image/* ]]; then
        if [[ -n $(identify -format '%[EXIF:DateTimeOriginal]' "${f}[0]" 2>/dev/null) ]]; then
            dest=photos
        else
            dest=non_photos
        fi
    else
        dest=other_files
    fi
    if [[ -e $dest/${f##*/} ]]; then
        echo "SKIP (already in $dest/): $f" >&2
    elif (( DRY )); then
        echo "$dest/ ← $f"
    else
        mv -n -- "$f" "$dest/" && echo "$dest/ ← $f"
    fi
}
export -f classify

(( DRY )) || mkdir -p photos non_photos other_files
find . -maxdepth 1 -type f ! -name '.*' -print0 |
    xargs -0 -r -P "$(nproc)" -n 1 bash -c 'classify "$1"' _

(( DRY )) && exit 0
echo
printf '%-12s %s\n' "photos:" "$(find photos -type f | wc -l)" \
    "non_photos:" "$(find non_photos -type f | wc -l)" \
    "other_files:" "$(find other_files -type f | wc -l)"
