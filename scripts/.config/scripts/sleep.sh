#!/bin/bash
# ~/.config/i3/sleep.sh

PID_FILE="/tmp/timer_pids.$$"

# Send initial notification
notify-send "⏰ Timers Started" "Screen: 1m | Chrome: 45m | Volume Fade: 45m\nPID file: $PID_FILE"

# Screen timer with PID tracking
(sleep 1m && xset dpms force off) &
SCREEN_PID=$!
echo "SCREEN:$SCREEN_PID" > "$PID_FILE"

# Chrome timer with PID tracking
(sleep 45m && pkill chrome) &
CHROME_PID=$!
echo "CHROME:$CHROME_PID" >> "$PID_FILE"

# Volume fade-out timer (45 minutes)
(
    FADE_TIME_SECONDS=2700 # 45 minutes
    NUM_VOLUME_STEPS=100 # From 100% to 0% by 1% each step
    SLEEP_PER_STEP=$((FADE_TIME_SECONDS / NUM_VOLUME_STEPS)) # 27 seconds

    # Loop 100 times, decreasing volume by 1% each time
    for i in $(seq 1 $NUM_VOLUME_STEPS); do
        pactl set-sink-volume @DEFAULT_SINK@ -1%
        sleep "$SLEEP_PER_STEP"
    done
    # Mute at the end to be sure
    pactl set-sink-mute @DEFAULT_SINK@ 1
) &
VOLUME_PID=$!
echo "VOLUME:$VOLUME_PID" >> "$PID_FILE"

# Send confirmation with PIDs
notify-send "✅ Timers Running" "PIDs: Screen=$SCREEN_PID, Chrome=$CHROME_PID, Volume=$VOLUME_PID"
