#!/bin/bash

    # Set pen button 2 to pan function
    xsetwacom --set "Wacom Intuos BT S Pen stylus" Button 2 "button +2"

    xinput set-prop "TPPS/2 Synaptics TrackPoint" "libinput Button Scrolling Button" 0
