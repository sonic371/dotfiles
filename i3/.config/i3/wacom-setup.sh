#!/bin/bash
        
    # Set pen button 2 to pan function
    xsetwacom --set "Wacom Intuos BT S Pen stylus" Button 2 "pan"
    
    # Set pad button 1 to workspace switching (Ctrl+Alt+Down)
    #  xsetwacom --set "Wacom Intuos BT S Pad pad" Button 1 "key +ctrl +alt +Down"
    
    # Set pan scroll threshold for smoother panning
    xsetwacom --set "Wacom Intuos BT S Pen stylus" "PanScrollThreshold" 200
    
    # Fix hover behavior - reduce cursor proximity for better control
    # xsetwacom --set "Wacom Intuos BT S Pen stylus" ProximityThreshold 1
    
    # Adjust suppress setting for better hover responsiveness
    # xsetwacom --set "Wacom Intuos BT S Pen stylus" Suppress 4
    
    # Improve hover tracking responsiveness
    #xsetwacom --set "Wacom Intuos BT S Pen stylus" RawSample 2
    
    # Optional: Set pressure curve (uncomment and modify if needed)
    # xsetwacom --set "Wacom Intuos BT S Pen stylus" PressureCurve "0 0 100 100"

    xinput set-prop "TPPS/2 Synaptics TrackPoint" "libinput Button Scrolling Button" 2
