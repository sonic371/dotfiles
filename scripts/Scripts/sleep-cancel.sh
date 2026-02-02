#!/bin/bash
# ~/.local/bin/cancel-with-pids.sh

# Find and kill all timer processes
for pid_file in /tmp/timer_pids.*; do
    if [ -f "$pid_file" ]; then
        while IFS=: read -r type pid; do
            kill "$pid" 2>/dev/null
        done < "$pid_file"
        rm "$pid_file"
    fi
done

# Also kill by pattern as backup
pkill -f "sleep.*[0-9]*[m]"

notify-send "⏹️ All Timers Cancelled" ""
