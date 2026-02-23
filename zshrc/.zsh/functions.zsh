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

# Micro editor shortcut
c() {
    if [ $# -eq 0 ]; then
        echo "Usage: c <file> (opens file in Micro)"
        return 1
    fi
    micro "$@"
}

# ============================================================================
# RELOAD FUNCTION
# ============================================================================
reload() {
    source ~/.zshrc && echo "ZSH configuration reloaded"
}

# ============================================================================
# VIM MODE 
# ============================================================================

# vi mode with cursor shape changes 
bindkey -v
bindkey -M vicmd 'U' redo
export KEYTIMEOUT=1

function zle-keymap-select {
    case $KEYMAP in
        vicmd) echo -ne '\e[1 q';;      # block cursor for normal mode
        viins|main) echo -ne '\e[5 q';; # beam cursor for insert mode
    esac
}
zle -N zle-keymap-select
echo -ne '\e[5 q'  # beam cursor on startup

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
