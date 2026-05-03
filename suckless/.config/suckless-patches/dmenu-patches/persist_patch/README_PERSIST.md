# dmenu -persist patch

This patch adds a `-persist` flag to dmenu. When enabled, dmenu will not exit when an item is selected. Instead, it will print the selection to `stdout` and remain open for further selections.

It also supports **Dynamic Reloading**, allowing you to update the menu items in real-time while the menu is open.

## Usage

```bash
dmenu -persist
```

### Key Behaviors:
- **Enter / Mouse Click**: Prints the selected item and stays open.
- **Escape**: Exits dmenu normally.
- **Dynamic Updates**: dmenu will re-read `stdin` after every selection. Use the `\1` marker to signal the end of a menu update.

## Why use it?

The `-persist` flag is ideal for:
- **Control Panels**: Perform multiple actions (Volume Up, Mute, Next Track) without the menu closing.
- **Dynamic Menus**: Update the menu text (e.g., current song title or volume percentage) instantly after an action.
- **Multi-Launchers**: Launch several apps in a row from your PATH.

## Dynamic Updating Protocol

To update the menu without closing dmenu, the input script should follow this pattern:
1.  Print all menu items to `stdin`.
2.  Print a line containing only the `\1` character (Control-A) to signal the end of the menu.

### Example (Media Controller)

```bash
#!/bin/bash
mkfifo in out
dmenu -persist < in > out &

exec 3> in
# Send initial menu
echo -e "Play\nPause\nNext\n\1" >&3

while read -r sel < out; do
    # 1. Do something
    playerctl "$sel"
    # 2. Update the menu
    vol=$(amixer get Master | grep -o "[0-9]*%")
    echo -e "Play\nPause\nNext\nVol: $vol\n\1" >&3
done
```

## Technical Details

### Buffering & Flushing
When using `-persist`, dmenu explicitly flushes `stdout` after every selection. This ensures that piped commands (like `while read`) receive the input immediately.

### Flicker-Free Reloads
dmenu uses "double-buffering" for reloads. It reads the new menu items into memory before discarding the old ones. This ensures the menu never "blanks out" or flickers while your script is generating a new list.

### Selection & View Preservation
- **Index-Based**: dmenu remembers the index of your current selection. After a reload, it automatically highlights the same line, even if the text on that line has changed (e.g., volume percentage updates).
- **View Locking**: If you have scrolled to a specific page in a long list, dmenu will stay on that page after a reload.
- **Search Continuity**: Your current search/filter text is **not** cleared after a selection, allowing you to perform multiple actions within a filtered list without re-typing.

### UI Colors
The `SchemeOut` (selection marking) is disabled when `-persist` is active to keep the UI clean during long-running sessions.
