#!/bin/bash
# Play random recent videos from a YouTube channel (~/.local/src/random-play-yt).
# Usage: random-play-yt.sh <channel-id>
#   penguinz0  UCq6VFHwMzcMXbuKyG7SQYIg
#   PewDiePie  UC-lHJZR3Gqxm24_Vd_AJ5Yw

[[ -n "${1:-}" ]] || { echo "Usage: $0 <channel-id>" >&2; exit 1; }

cd /home/wade/.local/src/random-play-yt || exit 1

exec uv run python random_play.py "$1" --playlist 50 --shuffle --after-date 20240101 --max-resolution 1080 --no-shorts --sleep 2100
