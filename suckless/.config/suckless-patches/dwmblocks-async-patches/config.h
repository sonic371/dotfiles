#ifndef CONFIG_H
#define CONFIG_H

// String used to delimit block outputs in the status.
#define DELIMITER "  "

// Maximum number of Unicode characters that a block can output.
#define MAX_BLOCK_OUTPUT_LENGTH 45

// Control whether blocks are clickable.
#define CLICKABLE_BLOCKS 1

// Control whether a leading delimiter should be prepended to the status.
#define LEADING_DELIMITER 0

// Control whether a trailing delimiter should be appended to the status.
#define TRAILING_DELIMITER 0

// Define blocks for the status feed as X(icon, cmd, interval, signal).
#define BLOCKS(X)             \
    X("", "dwmblocks-music-status", 0, 2)   \
    X("", "dwmblocks-wireless", 60, 7)   \
    X("", "dwmblocks-bluetooth", 0, 3)   \
    X("", "dwmblocks-mic-toggle", 0, 6)     \
    X(" ", "info-memory", 3, 4) \
    X(" ", "info-cpu", 5, 5) \
    X("", "dwmblocks-brightness-control", 0, 1)  \
    X("", "dwmblocks-volume-control", 0, 8)  \
    X("", "info-battery", 60, 9) \
    X("", "dwmblocks-date", 1, 10)

#endif  // CONFIG_H
