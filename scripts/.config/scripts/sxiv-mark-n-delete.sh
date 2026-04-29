#!/usr/bin/env sh
# Select images interactively, get their paths when done
sxiv -to . -r . | while read -r img; do
    echo "Deleted: $img"
    rm -- "$img"
    done
