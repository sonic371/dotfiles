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
