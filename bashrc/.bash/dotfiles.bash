# ============================================================================
# DOTFILES MANAGEMENT FUNCTIONS
# ============================================================================
# Note: Simple navigation aliases are in ~/.bash/aliases.bash

# Install all packages with adoption (takes over existing files)
dots-install() {
    (cd ~/dotfiles && stow -t ~ --adopt */)
}

# Force installation (overrides all conflicts)
dots-force() {
    (cd ~/dotfiles && stow -t ~ --override=* */)
}

# Remove all packages
dots-remove() {
    (cd ~/dotfiles && stow -D -t ~ */)
}

# Restow (remove + install with adoption)
dots-restow() {
    (cd ~/dotfiles && stow -R -t ~ --adopt */)
}

# Update from git and redeploy
dots-update() {
    (cd ~/dotfiles && git pull && stow -R -t ~ --adopt */)
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

# Install specific packages with adoption
dots-install-pkg() {
    (cd ~/dotfiles && stow -t ~ --adopt "$@")
    echo "✅ Installed packages: $@"
}

# Remove specific packages
dots-remove-pkg() {
    (cd ~/dotfiles && stow -D -t ~ "$@")
    echo "🗑️  Removed packages: $@"
}
