# ============================================================================
# CUSTOM SHELL FUNCTIONS
# ============================================================================

# Yazi file manager integration with directory changing
y() {
    local tmp
    tmp="$(mktemp -t "yazi-cwd.XXXXX")"
    yazi "$@" --cwd-file="$tmp"

    if [ -f "$tmp" ]; then
        local cwd
        cwd="$(cat "$tmp")"
        rm -f "$tmp"
        [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && cd "$cwd"
    fi
}

# Rebuild and install a source tree under ~/.local/src. git clean -fd deletes
# untracked files, so refuse to run anywhere else.
rebuild() {
    local top
    top="$(git rev-parse --show-toplevel 2>/dev/null)"
    if [[ "$top" != "$HOME/.local/src/"* || "$PWD" != "$top" || ! -f Makefile ]]; then
        echo "rebuild: run from the top of a ~/.local/src repo with a Makefile" >&2
        return 1
    fi
    git clean -fd && sudo make clean install
}

# ============================================================================
# RELOAD FUNCTION
# ============================================================================
reload() {
    source ~/.bashrc && echo "Bash configuration reloaded"
}

# ============================================================================
# FFMPEG EDITING 
# ============================================================================

# Quick preview function
prev() {
    ffmpeg -i "$1" "${@:2}" -f matroska - | ffplay -
}

# Quick encode function (using your last preview command)
enc() {
    ffmpeg -i "$1" -c:v libx264 -c:a aac "${@:2}"
}

# Video compression
comp() {
    if [ -z "$2" ]; then
        # No resolution provided - keep original
        ffmpeg -i "$1" -c:v libx264 -crf 32 -preset fast -c:a aac -b:a 96k "${1%.*}_compressed.mp4"
    else
        # Resolution provided - scale to it
        local resolution=$2
        ffmpeg -i "$1" -vf "scale=$resolution" -c:v libx264 -crf 32 -preset fast -c:a aac -b:a 96k "${1%.*}_${resolution/:/x}_compressed.mp4"
    fi
}

# Batch compress all mp4/mkv files in current directory
batchcomp() {
    # Enable extended globbing and nullglob for matching
    local old_extglob=$(shopt -p extglob)
    local old_nullglob=$(shopt -p nullglob)
    shopt -s extglob nullglob
    
    for file in *.@(mp4|mkv|webm); do
        comp "$file"
    done
    
    # Restore settings
    eval "$old_extglob"
    eval "$old_nullglob"
}
