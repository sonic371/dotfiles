#!/bin/bash
# ~/.local/bin/rotate-toggle.sh

CURRENT=$(autorandr --current)

if [ "$CURRENT" == "laptop-manga" ]; then
    autorandr -l laptop-only
else
    autorandr -l laptop-manga
fi
