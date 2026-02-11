# ============================================================================
# ZOXIDE INTEGRATION
# ============================================================================
# Single responsibility: Configure and load zoxide (smart cd replacement)

# Initialize zoxide for zsh
eval "$(zoxide init zsh)"

# Note: Zoxide data directory is configured in ~/.zsh/env.zsh
# via export _ZO_DATA_DIR="$HOME/.local/share/zoxide"