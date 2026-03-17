#!/bin/bash
echo "=== AUDIO SOURCES (Microphones) ==="
pactl list sources short | grep -v ".monitor" | while read line; do
    name=$(echo "$line" | awk '{print $2}')
    desc=$(pactl list sources | grep -A1 "Name: $name" | grep "Description:" | cut -d: -f2-)
    echo "$line |$desc"
done

echo -e "\n=== AUDIO MONITORS (System Audio) ==="
pactl list sources short | grep ".monitor" | while read line; do
    name=$(echo "$line" | awk '{print $2}')
    desc=$(pactl list sources | grep -A1 "Name: $name" | grep "Description:" | cut -d: -f2-)
    echo "$line |$desc"
done

echo -e "\n=== VIDEO DEVICES ==="
for dev in /dev/video*; do
    if [ -e "$dev" ]; then
        info=$(v4l2-ctl --info -d "$dev" 2>/dev/null | grep "Card type" | cut -d: -f2-)
        echo "$dev -$info"
    fi
done
