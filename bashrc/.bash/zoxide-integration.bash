# ============================================================================
# ZOXIDE INTEGRATION
# ============================================================================
# Single responsibility: Configure and load zoxide (smart cd replacement)

# Initialize zoxide for bash
eval "$(zoxide init bash)"

# Note: Zoxide data directory is configured in ~/.bash/env.bash
# via export _ZO_DATA_DIR="$HOME/.local/share/zoxide"
