# ============================================================================
# ENVIRONMENT VARIABLES
# ============================================================================
# Single responsibility: Set global environment variables

# Editor and terminal
export EDITOR="/usr/bin/nvim"
export TERMINAL=st

# Application-specific paths
export _ZO_DATA_DIR="$HOME/.local/share/zoxide"
export PROTONPATH="/usr/share/steam/compatibilitytools.d/proton-ge-custom"

# Input method (fcitx5)
export GTK_IM_MODULE=fcitx5
export QT_IM_MODULE=fcitx5
export XMODIFIERS=@im=fcitx5

# PATH modifications
export PATH="$HOME/.local/bin:$PATH"

# System resource limits (process-specific, not environment)
ulimit -n 8192
