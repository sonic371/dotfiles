# ============================================================================
# BASH SHELL OPTIONS
# ============================================================================
# Single responsibility: Configure bash shell behavior and options

# ----------------------------------------------------------------------------
# HISTORY CONFIGURATION
# ----------------------------------------------------------------------------
HISTFILE=~/.bash_history
HISTSIZE=10000
HISTFILESIZE=10000

# Bash history options
shopt -s histappend             # Append to history instead of overwriting
export HISTCONTROL=ignoredups:erasedups # Don't save duplicate commands
export HISTTIMEFORMAT="%F %T "  # Save timestamps

# ----------------------------------------------------------------------------
# INTERACTIVE SHELL BEHAVIOR
# ----------------------------------------------------------------------------
shopt -s checkwinsize           # Update window size after each command
shopt -s globstar               # Enable recursive globbing (**/*.txt)

# Don't beep on error
bind 'set bell-style none'

# ----------------------------------------------------------------------------
# TAB COMPLETION
# ----------------------------------------------------------------------------
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi
