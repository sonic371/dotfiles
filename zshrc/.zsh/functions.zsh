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

# ============================================================================
# RELOAD FUNCTION
# ============================================================================
reload() {
    source ~/.zshrc && echo "ZSH configuration reloaded"
}

# ============================================================================
# FFMPEG EDITING 
# ============================================================================

# Quick preview function
prev() {
    ffmpeg -i "$1" ${@:2} -f matroska - | ffplay -
}

# Quick encode function (using your last preview command)
enc() {
    ffmpeg -i "$1" ${@:2} -c:v libx264 -c:a aac
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
    # Match all common video formats
    for file in *.(mp4|mkv|webm)(N); do
        comp "$file"
    done
}

