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
To maintain a consistent UI across reloads:
- **`lines_orig`**: dmenu normally shrinks the window if the number of input items is less than the `-l` flag. We store the original `-l` value in `lines_orig` so that subsequent reloads can restore the full window height even if the new menu is shorter.
- **`sel_index`**: Since dynamic menus (like volume) change their text, dmenu tracks the **index** (line number) of the selection. It calculates the index immediately before a reload and restores it by iterating through the new `matches` list.
- **View Locking**: During the `sel_index` restoration, if the index exceeds the current page height, dmenu automatically updates the `curr` (view) pointer. This ensures that if you are on page 3, you stay on page 3.
- **Search Query**: The `text` buffer (the search query) is **not** cleared after a selection. This allows users to keep their filter active while performing multiple actions.

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
/* The heart of the dynamic reload */
while (1) {
    while ((len = getline(&line, &linesiz, stdin)) != -1) {
        if (line[0] == '\1' && line[1] == '\n') goto success;
        // ... (populate new_items) ...
    }
    // If pipe is closed (feof), don't hang, just display current.
    if (i > 0 || !persist || feof(stdin)) break;
    clearerr(stdin); 
    usleep(10000);   
}
```
