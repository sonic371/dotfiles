# Shell Options Configuration
# Add custom shell options here to keep .zshrc clean

# History settings
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

# Append to history file instead of overwriting
setopt append_history

# Save each command's beginning timestamp and duration
setopt extended_history

# Don't save duplicate commands
setopt hist_ignore_dups
setopt hist_ignore_all_dups  # Don't show duplicate history entries

# Remove superfluous blanks from commands
setopt hist_reduce_blanks

# Share history between terminals
setopt share_history

# Allow comments in interactive shell
setopt interactive_comments

# Don't beep on error
setopt no_beep

# Enable auto cd (type directory name to cd)
setopt auto_cd

# Enable globbing patterns like **/*.txt
setopt extended_glob

# Better tab completion
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select