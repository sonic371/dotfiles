# ============================================================================
# ZSH SHELL OPTIONS
# ============================================================================
# Single responsibility: Configure zsh shell behavior and options

# ----------------------------------------------------------------------------
# HISTORY CONFIGURATION
# ----------------------------------------------------------------------------
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000

setopt append_history           # Append to history (don't overwrite)
setopt extended_history         # Save timestamps and duration
setopt hist_fcntl_lock          # Use system file locking to prevent corruption
setopt hist_ignore_dups         # Don't save duplicate commands
setopt hist_ignore_all_dups     # Don't show duplicate history entries
setopt hist_reduce_blanks       # Remove superfluous blanks from commands
setopt inc_append_history_time  # Write every command to HISTFILE immediately
setopt no_share_history         # Manual sharing below instead

# Reliable real-time history sync between terminals:
# inc_append_history_time writes each command on execution.
# fc -R at every prompt reads entries written by other shells.
_async_update_history() { fc -R 2>/dev/null || true; }
precmd_functions+=(_async_update_history)

# ----------------------------------------------------------------------------
# INTERACTIVE SHELL BEHAVIOR
# ----------------------------------------------------------------------------
setopt interactive_comments     # Allow comments in interactive shell
setopt no_beep                  # Don't beep on error
setopt extended_glob            # Enable globbing patterns like **/*.txt

# Note: auto_cd removed - use zoxide (zi) or fzf (Alt+C) for directory navigation
# setopt auto_cd                # Disabled: often confusing, use zoxide instead

# ----------------------------------------------------------------------------
# TAB COMPLETION
# ----------------------------------------------------------------------------
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
