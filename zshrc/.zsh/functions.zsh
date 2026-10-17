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
    # Match all common video formats
    for file in *.(mp4|mkv|webm)(N); do
        comp "$file"
    done
}

# Export aur diffs
aurdiff() {
  local d=~/pkgbuild-diffs clone p
  mkdir -p "$d"
  rm -f "$d"/*.diff(N)                       # clear old diffs (N = safe when none exist)
  for p in $(paru -Qua | awk '{print $1}'); do
    clone=~/.cache/paru/clone/"$p"
    [ -d "$clone" ] || continue
    git -C "$clone" fetch -q 2>/dev/null     # pull fresh commits, don't touch working tree
    git -C "$clone" diff HEAD origin/master > "$d/$p.diff"   # incoming = new vs. currently-installed
  done
  ls -la "$d"
}
