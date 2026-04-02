#!/usr/bin/env sh
# ffplay -video_size 640x480 -window_title "Webcam" -i /dev/video0 >/dev/null 2>&1 &
mpv --no-osc --osd-level=0 --no-border --geometry=640x480 --title="Webcam" --x11-name=Webcam av://v4l2:/dev/video0 >/dev/null 2>&1 &
