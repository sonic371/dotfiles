# ============================================================================
# OH MY ZSH CONFIGURATION
# ============================================================================
# Single responsibility: Configure and load Oh My Zsh framework

export ZSH="$HOME/.oh-my-zsh"

# Theme configuration
ZSH_THEME="random"  # nice themes: af-magic, jonathan, rkj

# Plugin selection - each plugin has a specific purpose
plugins=(
  git                    # Git integration and aliases
  zsh-autosuggestions    # Command suggestions based on history
  zsh-syntax-highlighting # Syntax highlighting for commands
  colored-man-pages      # Colorized man pages
  command-not-found      # Suggest packages for missing commands
  extract                # Archive extraction utility
)

# Load Oh My Zsh
source "$ZSH/oh-my-zsh.sh"