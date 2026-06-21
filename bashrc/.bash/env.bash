# ============================================================================
# ENVIRONMENT VARIABLES
# ============================================================================
# Single responsibility: Set global environment variables

# Editor and terminal
export EDITOR=nvim
export TERMINAL=st
export MANPAGER="bat -l man -p"

# Application-specific paths
export _ZO_DATA_DIR="$HOME/.local/share/zoxide"
export PROTONPATH="/usr/share/steam/compatibilitytools.d/proton-ge-custom"

# PATH modifications
export PATH="$HOME/.local/bin:$PATH"

# System resource limits (process-specific, not environment)
ulimit -n 8192

eval "$(starship init bash)"
