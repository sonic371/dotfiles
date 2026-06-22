# ============================================================================
# STANDALONE ZSH PLUGINS
# ============================================================================
# Single responsibility: Load zsh plugins sourced directly from the repo
# (not through Oh My Zsh)

# Resolve plugins directory relative to the dotfiles repo layout.
# .zsh/plugins.zsh → look in the sibling plugins/ directory alongside .zshrc/
_PLUGINS_DIR="${${${(%):-%N}:h}:A:h}/plugins"

# zsh-autosuggestions — command suggestions based on history
if [[ -d "$_PLUGINS_DIR/zsh-autosuggestions" ]]; then
  source "$_PLUGINS_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# zsh-syntax-highlighting — must be sourced LAST (wraps zle widgets)
if [[ -d "$_PLUGINS_DIR/zsh-syntax-highlighting" ]]; then
  source "$_PLUGINS_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
