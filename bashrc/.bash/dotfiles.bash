# ============================================================================
# DOTFILES MANAGEMENT FUNCTIONS
# ============================================================================
# Note: Simple navigation aliases are in ~/.bash/aliases.bash

_DOTS_DIR=~/dotfiles

# Packages that stow into ~. Packages containing etc/ (systemd-system, udev,
# xorg-conf) belong under / and are skipped.
_dots-pkgs() {
    local p
    for p in "$_DOTS_DIR"/*/; do
        p=${p%/}
        [[ -d $p/etc ]] || echo "${p##*/}"
    done
}

_dots-stow() {
    stow -d "$_DOTS_DIR" -t ~ "$@"
}

# --adopt rewrites repo files, so only allow it on a clean working tree
_dots-require-clean() {
    if [[ -n "$(git -C "$_DOTS_DIR" status --porcelain)" ]]; then
        echo "dotfiles has uncommitted changes; commit or stash first" >&2
        return 1
    fi
}

# Install all packages (aborts on conflicts; see dots-adopt / dots-force)
dots-install() {
    _dots-stow $(_dots-pkgs)
}

# Pull existing files from ~ into the repo, then review with git diff
dots-adopt() {
    local -a pkgs=("$@")
    (( ${#pkgs[@]} )) || pkgs=($(_dots-pkgs))
    _dots-require-clean || return
    _dots-stow --adopt "${pkgs[@]}" && git -C "$_DOTS_DIR" status --short
}

# Repo versions win: adopt conflicting files, then restore repo content
dots-force() {
    local -a pkgs=("$@")
    (( ${#pkgs[@]} )) || pkgs=($(_dots-pkgs))
    _dots-require-clean || return
    _dots-stow --adopt "${pkgs[@]}" && git -C "$_DOTS_DIR" checkout -- .
}

# Remove all packages
dots-remove() {
    _dots-stow -D $(_dots-pkgs)
}

# Restow (remove + install)
dots-restow() {
    _dots-stow -R $(_dots-pkgs)
}

# Update from git and redeploy
dots-update() {
    git -C "$_DOTS_DIR" pull && _dots-stow -R $(_dots-pkgs)
}

# List available packages
dots-list() {
    (
        cd ~/dotfiles
        echo "📦 Available packages:"
        for p in */; do
            [ -d "$p" ] && [ "$p" != ".git/" ] && echo "  • ${p%/}"
        done
    )
}

# Check status of packages
dots-check() {
    (
        cd ~/dotfiles
        echo "🔍 Checking symlinks..."
        for pkg in */; do
            if [ -d "$pkg" ] && [ "$pkg" != ".git/" ]; then
                echo -e "\n${pkg%/}:"
                find "$pkg" -type f | head -3 | while read f; do
                    target="$HOME/${f#$pkg/}"
                    if [ -L "$target" ]; then
                        echo "  ✅ ${f#$pkg/}"
                    else
                        echo "  📄 ${f#$pkg/} (regular file)"
                    fi
                done
            fi
        done
    )
}

# Install specific packages
dots-install-pkg() {
    (cd ~/dotfiles && stow -t ~ "$@")
    echo "✅ Installed packages: $@"
}

# Remove specific packages
dots-remove-pkg() {
    (cd ~/dotfiles && stow -D -t ~ "$@")
    echo "🗑️  Removed packages: $@"
}
