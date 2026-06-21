# ============================================================================
# VI MODE
# ============================================================================
# Single responsibility: Configure vi mode

set -o vi
bind -m vi-insert '"\C-l": clear-screen'
bind -m vi-command '"\C-l": clear-screen'

# Bash cursor shape changes are trickier than ZLE.
# Usually done via PS1 or custom bindings if the terminal supports it.
# For simplicity, we'll keep the vi mode.
# Cursor shape changes in Bash typically require specific prompt configurations.
