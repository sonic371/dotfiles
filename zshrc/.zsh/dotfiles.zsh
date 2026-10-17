# ============================================================================
# DOTFILES MANAGEMENT FUNCTIONS
# ============================================================================
# Note: Simple navigation aliases are in ~/.zsh/aliases.zsh

_DOTS_DIR=~/dotfiles

# Packages that stow into ~. Packages containing etc/ (systemd-system, udev,
# xorg-conf) belong under / and are skipped.
_dots-pkgs() {
    local p
    for p in $_DOTS_DIR/*(/N); do
        [[ -d $p/etc ]] || echo ${p:t}
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
    (( $#pkgs )) || pkgs=($(_dots-pkgs))
    _dots-require-clean || return
    _dots-stow --adopt "${pkgs[@]}" && git -C "$_DOTS_DIR" status --short
}

# Repo versions win: adopt conflicting files, then restore repo content
dots-force() {
    local -a pkgs=("$@")
    (( $#pkgs )) || pkgs=($(_dots-pkgs))
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
    echo "📦 Available packages:"
    _dots-pkgs | sed 's/^/  • /'
}

# Check that each package's files resolve into the repo. Stow folds whole
# directories into one symlink, so compare resolved paths, not -L.
dots-check() {
    local pkg f rel
    echo "🔍 Checking symlinks..."
    for pkg in $(_dots-pkgs); do
        echo "\n$pkg:"
        for f in $_DOTS_DIR/$pkg/**/*~*/(plugins/*|.stow-local-ignore)(.DN[1,3]); do
            rel=${f#$_DOTS_DIR/$pkg/}
            if [[ ${${:-$HOME/$rel}:A} == ${f:A} ]]; then
                echo "  ✅ $rel"
            else
                echo "  📄 $rel (not linked)"
            fi
        done
    done
}

# Install specific packages
dots-install-pkg() {
    _dots-stow "$@" && echo "✅ Installed packages: $*"
}

# Remove specific packages
dots-remove-pkg() {
    _dots-stow -D "$@" && echo "🗑️  Removed packages: $*"
}
