#!/bin/bash
# Toggle between the laptop-only and laptop-manga autorandr layouts (super+v)

CURRENT=$(autorandr --current)

if [ "$CURRENT" == "laptop-manga" ]; then
    autorandr -l laptop-only
else
    autorandr -l laptop-manga
fi
