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

# Start ssh-agent if not already running
if ! pgrep -u "$USER" ssh-agent > /dev/null; then
    eval "$(ssh-agent -s)" > /dev/null
fi

# ===== Reload function =====
reload() {
    source ~/.zshrc && echo "ZSH config reloaded"
}