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

setopt extended_history         # Save timestamps and duration
setopt hist_fcntl_lock          # Use system file locking to prevent corruption
setopt hist_ignore_all_dups     # Drop older duplicates of a command
setopt hist_reduce_blanks       # Remove superfluous blanks from commands

# Real-time history sync between terminals: share_history writes each command
# immediately and incrementally reads new entries from other shells.
setopt share_history

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
