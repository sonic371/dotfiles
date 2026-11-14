#!/usr/bin/env bash
# Delete empty folders under the current folder, including folders that only held empty folders.
# Usage: clean-empty-dirs.sh [-n]   -n = dry run (lists only folders that are empty right now)
set -euo pipefail
if [[ ${1:-} == -n ]]; then
    find . -mindepth 1 -type d -empty
else
    # -delete works depth-first, so a parent emptied by deleting its children goes too
    find . -mindepth 1 -type d -empty -print -delete | sed 's/^/removed: /'
fi
