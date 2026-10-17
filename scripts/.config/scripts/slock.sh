#!/bin/bash

# Start slock in the background
slock &
SLOCK_PID=$!

# If xss-lock gave us a sleep lock FD, close it now to allow suspend
if [ -n "$XSS_SLEEP_LOCK_FD" ]; then
    eval "exec ${XSS_SLEEP_LOCK_FD}<&-"
fi

# Wait for slock to finish (i.e., for you to unlock)
wait $SLOCK_PID
