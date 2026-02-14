#!/bin/sh
# Apply all .diff patches 
# Simple: patch < A.diff patch < B.diff patch < C.diff

for patch in *.diff; do
    [ -f "$patch" ] || continue
    echo "applying $patch"
    patch < "$patch"
done
