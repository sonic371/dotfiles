#!/usr/bin/env sh

# Check for proper number of arguments
if [ $# -ne 2 ]; then
    echo "Usage: $0 SOURCE_DIR DEST_DIR"
    echo "Example: $0 /home/wade/.config/i3/ /home/wade/MEGASync/Obsidian/Linux/config/i3/"
    exit 1
fi

SOURCE_DIR="$1"
DEST_DIR="$2"

# Function to display differences with less and color
show_diffs() {
    echo "=== DIFFERENCES FOUND ==="
    echo "Source: $SOURCE_DIR"
    echo "Destination: $DEST_DIR"
    echo "========================="
    echo ""
    
    # Check if diff command is available
    if ! command -v diff > /dev/null 2>&1; then
        echo "Error: 'diff' command not found. Please install diffutils."
        exit 1
    fi
    
    # Check if less is available
    if ! command -v less > /dev/null 2>&1; then
        echo "Warning: 'less' command not found. Falling back to normal diff output."
        USE_LESS=0
    else
        USE_LESS=1
    fi
    
    # Create a temporary file to hold all diff output
    TEMP_DIFF_FILE=$(mktemp)
    
    # Compare directories and show summary
    echo "Directory comparison summary:" >> "$TEMP_DIFF_FILE"
    echo "==============================" >> "$TEMP_DIFF_FILE"
    diff -rq --no-dereference "$SOURCE_DIR" "$DEST_DIR" >> "$TEMP_DIFF_FILE" 2>/dev/null || true
    echo "" >> "$TEMP_DIFF_FILE"
    
    # Show actual content differences for each file
    find "$SOURCE_DIR" -type f -name "*" | sort | while read -r src_file; do
        # Get relative path
        rel_path="${src_file#$SOURCE_DIR}"
        dest_file="$DEST_DIR$rel_path"
        
        # Check if destination file exists
        if [ -f "$dest_file" ]; then
            # Compare files and show diff if they differ
            if ! cmp -s "$src_file" "$dest_file"; then
                echo "────────────────────────────────────" >> "$TEMP_DIFF_FILE"
                echo "File: $rel_path" >> "$TEMP_DIFF_FILE"
                echo "────────────────────────────────────" >> "$TEMP_DIFF_FILE"
                echo "" >> "$TEMP_DIFF_FILE"
                # Use diff with color
                diff -u --color=always "$dest_file" "$src_file" >> "$TEMP_DIFF_FILE" 2>/dev/null || true
                echo "" >> "$TEMP_DIFF_FILE"
                echo "" >> "$TEMP_DIFF_FILE"
            fi
        else
            echo "────────────────────────────────────" >> "$TEMP_DIFF_FILE"
            echo "NEW FILE: $rel_path (not in destination)" >> "$TEMP_DIFF_FILE"
            echo "────────────────────────────────────" >> "$TEMP_DIFF_FILE"
            echo "" >> "$TEMP_DIFF_FILE"
            # Show the new file content
            echo "Content of new file:" >> "$TEMP_DIFF_FILE"
            echo "--------------------" >> "$TEMP_DIFF_FILE"
            cat "$src_file" >> "$TEMP_DIFF_FILE" 2>/dev/null || true
            echo "" >> "$TEMP_DIFF_FILE"
            echo "" >> "$TEMP_DIFF_FILE"
        fi
    done
    
    # Also check for files that exist in destination but not in source
    find "$DEST_DIR" -type f -name "*" | sort | while read -r dest_file; do
        # Get relative path
        rel_path="${dest_file#$DEST_DIR}"
        src_file="$SOURCE_DIR$rel_path"
        
        # Check if source file doesn't exist (extra file in destination)
        if [ ! -f "$src_file" ]; then
            echo "────────────────────────────────────" >> "$TEMP_DIFF_FILE"
            echo "EXTRA FILE: $rel_path (exists in destination but not in source)" >> "$TEMP_DIFF_FILE"
            echo "────────────────────────────────────" >> "$TEMP_DIFF_FILE"
            echo "This file will be DELETED during sync (if using --delete)" >> "$TEMP_DIFF_FILE"
            echo "" >> "$TEMP_DIFF_FILE"
        fi
    done
    
    # Display the diff using less with color support
    if [ $USE_LESS -eq 1 ]; then
        # Use less with color preservation and quit on EOF
        less -R --quit-if-one-screen --no-init "$TEMP_DIFF_FILE"
    else
        cat "$TEMP_DIFF_FILE"
    fi
    
    # Clean up temp file
    rm -f "$TEMP_DIFF_FILE"
}

# Function to perform sync
perform_sync() {
    echo ""
    echo "Starting sync..."
    echo "========================="
    
    # Use rsync with --delete to make DEST_DIR exactly match SOURCE_DIR
    # -a: archive mode (preserves permissions, timestamps, etc.)
    # -v: verbose
    # --delete: delete files in destination that aren't in source
    # --progress: show progress
    # --itemize-changes: show what's being changed
    rsync -av --delete --progress --itemize-changes "$SOURCE_DIR" "$DEST_DIR"
    
    echo ""
    echo "========================="
    echo "✅ Sync completed! Destination now exactly matches source."
}

# Validate source directory
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Source directory does not exist: $SOURCE_DIR"
    exit 1
fi

# Ensure destination directory exists
if [ ! -d "$DEST_DIR" ]; then
    echo "Warning: Destination directory does not exist. Creating it..."
    mkdir -p "$DEST_DIR" || {
        echo "Error: Failed to create destination directory: $DEST_DIR"
        exit 1
    }
fi

# Main execution
echo "Directory Sync Tool"
echo "==================="
echo "Source: $SOURCE_DIR"
echo "Destination: $DEST_DIR"
echo ""

# First, check if there are any differences
if diff -rq --no-dereference "$SOURCE_DIR" "$DEST_DIR" > /dev/null 2>&1; then
    echo "✅ No differences found. Directories are already in sync."
    exit 0
fi

# Show differences with less and color
show_diffs

# Ask for confirmation
echo ""
echo "=== SYNC CONFIRMATION ==="
printf "Do you want to proceed with synchronization? (y/N): "
read -r REPLY
echo ""

if echo "$REPLY" | grep -iq "^y"; then
    perform_sync
else
    echo "❌ Sync cancelled by user."
    exit 0
fi
