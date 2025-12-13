#!/usr/bin/env zsh
# Main ZSH configuration file
# Sources all modular configuration files from ~/.zsh/

# ============================================================================
# SOURCE MODULAR CONFIGURATION FILES
# ============================================================================
# Source files if they exist
[[ -f ~/.zsh/env.zsh ]] && source ~/.zsh/env.zsh
[[ -f ~/.zsh/plugins.zsh ]] && source ~/.zsh/plugins.zsh
[[ -f ~/.zsh/aliases.zsh ]] && source ~/.zsh/aliases.zsh
[[ -f ~/.zsh/functions.zsh ]] && source ~/.zsh/functions.zsh
[[ -f ~/.zsh/options.zsh ]] && source ~/.zsh/options.zsh

# ============================================================================
# SHELL OPTIONS
# ============================================================================
# Note: Most shell options are configured in ~/.zsh/options.zsh
# Keep only essential options that must be set early here
setopt auto_cd  # Enable auto cd (type directory name to cd)

# ============================================================================
# KEY BINDINGS
# ============================================================================
bindkey '^I^I' autosuggest-accept  # Double-tap Tab to accept autosuggestion

# ============================================================================
# SYSTEM SETTINGS
# ============================================================================
ulimit -n 8192  # Increase file descriptor limit

# ============================================================================
# SSH AGENT SETUP
# ============================================================================
if command -v keychain >/dev/null 2>&1; then
    # Tell keychain which keys to manage
    keychain --quiet ~/.ssh/id_ed25519

    # Source keychain environment variables
    # Keychain writes these into ~/.keychain/$HOST-sh
    if [ -f "$HOME/.keychain/$HOST-sh" ]; then
        source "$HOME/.keychain/$HOST-sh"
    fi
fi

# ============================================================================
# RELOAD FUNCTION
# ============================================================================
reload() {
    source ~/.zshrc && echo "ZSH configuration reloaded"
}

# ============================================================================
# DOTFILES MANAGEMENT FUNCTIONS
# ============================================================================
# Note: Simple navigation aliases are in ~/.zsh/aliases.zsh

# Install all packages with adoption (takes over existing files)
dots-install() {
    cd ~/dotfiles && stow -t ~ --adopt */
}

# Force installation (overrides all conflicts)
dots-force() {
    cd ~/dotfiles && stow -t ~ --override=* */
}

# Remove all packages
dots-remove() {
    cd ~/dotfiles && stow -D -t ~ */
}

# Restow (remove + install with adoption)
dots-restow() {
    cd ~/dotfiles && stow -R -t ~ --adopt */
}

# Update from git and redeploy
dots-update() {
    cd ~/dotfiles && git pull && stow -R -t ~ --adopt */
}

# List available packages
dots-list() {
    cd ~/dotfiles
    echo "📦 Available packages:"
    for p in */; do
        [ -d "$p" ] && [ "$p" != ".git/" ] && echo "  • ${p%/}"
    done
}

# Check status of packages
dots-check() {
    cd ~/dotfiles
    echo "🔍 Checking symlinks..."
    for pkg in */; do
        if [ -d "$pkg" ] && [ "$pkg" != ".git/" ]; then
            echo "\n${pkg%/}:"
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
}

# Install specific packages with adoption
dots-install-pkg() {
    cd ~/dotfiles
    stow -t ~ --adopt "$@"
    echo "✅ Installed packages: $@"
}

# Remove specific packages
dots-remove-pkg() {
    cd ~/dotfiles
    stow -D -t ~ "$@"
    echo "🗑️  Removed packages: $@"
}
