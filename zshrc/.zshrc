#!/usr/bin/env zsh
# Main ZSH configuration file
# Sources all modular configuration files from ~/.zsh/

# ===== Source modular configuration files =====
# Source files if they exist
[[ -f ~/.zsh/env.zsh ]] && source ~/.zsh/env.zsh
[[ -f ~/.zsh/plugins.zsh ]] && source ~/.zsh/plugins.zsh
[[ -f ~/.zsh/aliases.zsh ]] && source ~/.zsh/aliases.zsh
[[ -f ~/.zsh/functions.zsh ]] && source ~/.zsh/functions.zsh
[[ -f ~/.zsh/options.zsh ]] && source ~/.zsh/options.zsh

# ===== Shell Options =====
setopt auto_cd           # Enable auto cd (type directory name to cd)
setopt share_history     # Share history between terminals
setopt hist_ignore_all_dups  # Don't show duplicate history entries

# ===== Key bindings =====
bindkey '^I^I' autosuggest-accept  # Double-tap Tab to accept

# ===== System settings =====
ulimit -n 8192

# Start agent if not running AND add your key
if ! pgrep -u "$USER" ssh-agent > /dev/null; then
    # Start SSH agent
    eval "$(ssh-agent -s)" > /dev/null
    
    # Add your SSH key (will prompt for passphrase)
    ssh-add ~/.ssh/id_ed25519 2>/dev/null
elif [ -z "$SSH_AUTH_SOCK" ]; then
    # Agent is running but shell doesn't know about it
    # Reconnect to existing agent
    export SSH_AUTH_SOCK="$(find /tmp -type s -name 'agent.*' 2>/dev/null | head -1)"
    
    # Now add your key
    ssh-add ~/.ssh/id_ed25519 2>/dev/null
fi

# ===== Reload function =====
reload() {
    source ~/.zshrc && echo "ZSH config reloaded"
}

# ============================================
# DOTFILES MANAGEMENT ALIASES (WITH --adopt)
# ============================================

# Navigation
alias dots='cd ~/dotfiles'

# Installation with adoption (TAKES OVER existing files)
alias dots-install='cd ~/dotfiles && stow -t ~ --adopt */'
alias dots-adopt='dots-install'  # Alternative name

# Force installation (even more aggressive)
alias dots-force='cd ~/dotfiles && stow -t ~ --override=* */'

# Removal
alias dots-remove='cd ~/dotfiles && stow -D -t ~ */'
alias dots-unstow='dots-remove'  # Alternative name

# Restow (remove + install with adoption)
alias dots-restow='cd ~/dotfiles && stow -R -t ~ --adopt */'

# Update from git and redeploy
alias dots-update='cd ~/dotfiles && git pull && stow -R -t ~ --adopt */'

# List available packages
alias dots-list='cd ~/dotfiles && echo "📦 Available packages:" && for p in */; do [ -d "$p" ] && [ "$p" != ".git/" ] && echo "  • ${p%/}"; done'

# Check status of packages
alias dots-check='cd ~/dotfiles && echo "🔍 Checking symlinks..." && for pkg in */; do if [ -d "$pkg" ] && [ "$pkg" != ".git/" ]; then echo "\n${pkg%/}:"; find "$pkg" -type f | head -3 | while read f; do target="$HOME/${f#$pkg/}"; if [ -L "$target" ]; then echo "  ✅ ${f#$pkg/}"; else echo "  📄 ${f#$pkg/} (regular file)"; fi; done; fi; done'

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
