#!/bin/bash
# Locker for xss-lock --transfer-sleep-lock. slock must not inherit the
# sleep-lock FD, or suspend stalls until logind's InhibitDelayMaxSec.

if [ -n "$XSS_SLEEP_LOCK_FD" ] && [ -e "/dev/fd/$XSS_SLEEP_LOCK_FD" ]; then
    slock {XSS_SLEEP_LOCK_FD}<&- &
    SLOCK_PID=$!

    # slock has no "locked" signal; give it time to grab the screen, then
    # release the last copy of the FD so suspend can proceed
    sleep 0.5
    exec {XSS_SLEEP_LOCK_FD}<&-

    wait "$SLOCK_PID"
else
    exec slock
fi
