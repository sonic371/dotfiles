#!/usr/bin/env sh
ffplay -video_size 640x480 -window_title "Webcam" -i /dev/video0 >/dev/null 2>&1 &
