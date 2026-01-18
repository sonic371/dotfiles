# Volume PipeWire

This module displays the current volume level and mute status for the default PipeWire sink.

## Features:
-   **Display:** Shows an icon (high, medium, low, or muted) and the volume percentage.
-   **Scroll Up/Down:** Adjusts the volume by a configurable delta (default 5%).
-   **Left Click:** Cycles through available audio output sinks.
-   **Middle Click:** Toggles mute/unmute for the default sink.
-   **Right Click:** Cycles through available audio output sinks in reverse.

## Configuration (in your i3blocks config):
```ini
[volume-pipewire]
interval=5
signal=1
AUDIO_DELTA=5
```
-   `interval`: How often the block updates (in seconds).
-   `signal`: Optional. If you have keyboard shortcuts or other events that signal i3blocks, this block will update.
-   `AUDIO_DELTA`: The percentage to increase or decrease the volume when scrolling.

## Dependencies:
-   `pactl` (from `pipewire-pulse` or `pulseaudio-utils`)
-   Nerd Fonts for icons

## Usage:
-   Scroll up/down on the module to change the volume.
-   Left-click to cycle to the next output device.
-   Middle-click to toggle mute.
-   Right-click to cycle to the previous output device.