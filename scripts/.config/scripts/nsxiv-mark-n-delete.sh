#!/usr/bin/env bash
# Browse the images in the current folder (recursively) with nsxiv, mark the ones
# to delete (m), quit (q), then confirm before anything is removed.
set -euo pipefail

mapfile -t marked < <(nsxiv -to -r .)
(( ${#marked[@]} )) || { echo "Nothing marked."; exit 0; }

printf '  %s\n' "${marked[@]}"
read -rp "Delete these ${#marked[@]} file(s)? [y/N] " ans
[[ $ans == [yY] ]] || { echo "Kept everything."; exit 0; }

for img in "${marked[@]}"; do
    rm -- "$img" && echo "Deleted: $img"
done
