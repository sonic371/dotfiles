#!/usr/bin/env sh

# Define source and destination directories
SOURCE_DIR="/home/wade/.config/i3/"
DEST_DIR="/home/wade/MEGASync/Obsidian/Linux/config/i3/"

# Function to display differences
show_diffs() {
    echo "=== DIFFERENCES FOUND ==="
    echo "Source: $SOURCE_DIR"
    echo "Destination: $DEST_DIR"
    echo "========================="
    echo ""
    
    # Check if diff command is available
    if ! command -v diff &> /dev/null; then
        echo "Error: 'diff' command not found. Please install diffutils."
        exit 1
    fi
    
    # Compare directories and show differences
    diff -rq --no-dereference "$SOURCE_DIR" "$DEST_DIR" || true
    
    echo ""
    echo "=== DETAILED FILE DIFFERENCES ==="
    
    # Show actual content differences for each file
    find "$SOURCE_DIR" -type f -name "*" | while read -r src_file; do
        # Get relative path
        rel_path="${src_file#$SOURCE_DIR}"
        dest_file="$DEST_DIR$rel_path"
        
        # Check if destination file exists
        if [[ -f "$dest_file" ]]; then
            # Compare files and show diff if they differ
            if ! cmp -s "$src_file" "$dest_file"; then
                echo "────────────────────────────────────"
                echo "Differences in: $rel_path"
                echo "────────────────────────────────────"
                diff --color=always -u "$dest_file" "$src_file" || true
                echo ""
            fi
        else
            echo "────────────────────────────────────"
            echo "NEW FILE: $rel_path (not in destination)"
            echo "────────────────────────────────────"
            echo ""
        fi
    done
}

# Function to perform sync
perform_sync() {
    echo "Starting sync..."
    rsync -av --progress "$SOURCE_DIR" "$DEST_DIR"
    echo ""
    echo "✅ Sync completed!"
}

# Main execution
echo "i3 Config Sync Tool"
echo "==================="

# First, check if there are any differences
if diff -rq --no-dereference "$SOURCE_DIR" "$DEST_DIR" >/dev/null 2>&1; then
    echo "✅ No differences found. Directories are already in sync."
    exit 0
fi

# Show differences
show_diffs

# Ask for confirmation
echo ""
echo "=== SYNC CONFIRMATION ==="
read -p "Do you want to proceed with synchronization? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    perform_sync
else
    echo "❌ Sync cancelled by user."
    exit 0
fi
