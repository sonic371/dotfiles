# dmenu -persist: Core Logic & Internals

The `-persist` feature transforms dmenu from a "one-shot" selection tool into a persistent, dynamic control interface. This document explains the internal mechanisms that make this possible.

## 1. The Persistent Event Loop
In standard dmenu, selecting an item triggers `cleanup()` and `exit(0)`. With `-persist` enabled:
- **Keyboard (`keypress`)**: The `XK_Return` case is modified to skip the exit branch.
- **Mouse (`buttonpress`)**: The left-click handler is modified to skip the exit branch.
- **Flushing**: After every selection, `fflush(stdout)` is called to ensure the selection is sent through the pipe immediately, allowing external scripts to react in real-time.

## 2. Dynamic Input Protocol (`readstdin`)
To allow the menu to update its text (e.g., current volume) without closing, `readstdin()` was refactored into a synchronized, double-buffered reloader.

### A. Double Buffering
To prevent the menu from "blanking" while new data is being read:
1.  New items are read into a temporary `struct item *new_items` list.
2.  The old `items` list is preserved until the read operation is complete.
3.  Only after the new list is successfully populated does dmenu free the old items and swap the pointers.

### B. The Sync Marker (`\1`)
Since `stdin` is a stream, dmenu needs to know when a "burst" of menu items is finished so it can redraw. 
- The script sends a line containing only the character `\1`.
- When `readstdin()` encounters this marker, it immediately breaks the read loop and displays the new items.

### C. FIFO Synchronization
When reading from a Named Pipe (FIFO), the reader hits `EOF` as soon as the writer closes the pipe. 
- `readstdin()` uses a `while(1)` loop with `clearerr(stdin)`.
- If it hits `EOF` but hasn't received any new items yet, it clears the error state and sleeps for 10ms before trying again.
- This allows dmenu to wait for the script to generate and send the next menu version.

## 3. State Preservation
To maintain a consistent UI across reloads, dmenu implements a **Hybrid Selection Strategy**:

1.  **Selection Text (`sel_text`)**: dmenu first attempts to find the exact text of the previously selected item. This is ideal for static lists like the Playlist Browser, ensuring you stay on the correct song even if its position changes.
2.  **Selection Index (`sel_index`)**: If the text match fails (common for dynamic lines like "Volume: 80%"), dmenu falls back to the **index** (line number). This is restricted to cases where the search box is empty to prevent jumping during filtered searches.
- **`lines_orig`**: dmenu normally shrinks the window if the number of input items is less than the `-l` flag. We store the original `-l` value in `lines_orig` so that subsequent reloads can restore the full window height even if the new menu is shorter.
- **View Locking**: During restoration, if the selected item is on a later page, dmenu automatically updates the `curr` (view) pointer to maintain the scroll position.
- **Search Query**: The `text` buffer (the search query) is **not** cleared after a selection. This allows users to keep their filter active while performing multiple actions.
- **Dynamic Resizing**: dmenu now recalculates its geometry and resizes the X window after every reload. This allows the menu to expand or shrink if the number of items changes.
- **Asynchronous Polling (`select`)**: When `-persist` is active, the `run()` loop uses `select()` to monitor both the X11 connection and `stdin`. This allows for background UI updates without user interaction.
- **Dual-Mode Event Loop**: To ensure 100% compatibility with standard dmenu scripts, the asynchronous `select()` loop is guarded. If `-persist` is NOT used, dmenu uses the original, standard `XNextEvent` loop, ensuring zero overhead and maximum stability for normal usage.
- **Atomic Reloading**: `readstdin()` implements an "Atomic Swap." It reads the entire new menu into a temporary list and only replaces the active menu once the `\1` marker is received. This prevents "menu blinking" or zero-height states during rapid updates.
- **Post-Reload Mouse Sync**: After `readstdin()` completes, dmenu calls `XQueryPointer` to fetch the current window-relative mouse position. It then immediately triggers a `motionevent()` to ensure the highlight is correctly positioned under the user's cursor.
- **Separator Logic**: Navigation and click handlers check for the `━` (UTF-8 box-drawing) prefix using `strncmp`. These items are skipped during keyboard navigation and ignored by mouse clicks.

- **Event-Driven Reloading**: To avoid busy-looping, `readstdin()` uses `select()` to wait for data on `stdin`. dmenu sleeps efficiently and wakes up the instant the script sends a new menu update, providing instantaneous UI response with zero CPU overhead.

## 4. Communication Flow
The recommended way to use this feature is via two FIFOs:

1.  **Script** writes the menu to `FIFO_IN`.
2.  **Script** writes `\1` to `FIFO_IN`.
3.  **dmenu** reads the menu, sees `\1`, and displays it.
4.  **User** makes a selection.
5.  **dmenu** writes the selection to `FIFO_OUT`.
6.  **Script** reads from `FIFO_OUT`, executes the command, and repeats from Step 1.

---

## Code Reference (`dmenu.c`)

```c
/* The heart of the event-driven dynamic reload */
while (1) {
    while ((len = getline(&line, &linesiz, stdin)) != -1) {
        if (line[0] == '\1' && line[1] == '\n') goto success;
        // ... (populate new_items) ...
    }
    if (feof(stdin) || !persist) break;
    clearerr(stdin);
    
    /* wait for more data from stdin using select() instead of busy-looping */
    fd_set fds;
    struct timeval tv = { .tv_sec = 0, .tv_usec = 50000 };
    FD_ZERO(&fds);
    FD_SET(STDIN_FILENO, &fds);
    select(STDIN_FILENO + 1, &fds, NULL, NULL, &tv);
}
```
