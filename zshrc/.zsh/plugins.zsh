# ============================================================================
# STANDALONE ZSH PLUGINS
# ============================================================================
# Single responsibility: Load zsh plugins sourced directly from the repo
# (not through Oh My Zsh)

# Resolve plugins directory relative to the dotfiles repo layout.
# .zsh/plugins.zsh → look in the sibling plugins/ directory alongside .zshrc/
_PLUGINS_DIR="${${${(%):-%N}:h}:A:h}/plugins"

# fzf-tab — fzf for Tab completion. Must load after compinit and before
# autosuggestions/syntax-highlighting, which wrap widgets.
if [[ -d "$_PLUGINS_DIR/fzf-tab" ]]; then
  source "$_PLUGINS_DIR/fzf-tab/fzf-tab.plugin.zsh"
  zstyle ':fzf-tab:*' switch-group '<' '>'
  zstyle ':fzf-tab:complete:(cd|z|__zoxide_z):*' fzf-preview 'eza -1 --color=always $realpath'
  zstyle ':fzf-tab:complete:(nvim|v|bat|less|cat):*' fzf-preview \
    'bat --style=numbers --color=always $realpath 2>/dev/null || eza -1 --color=always $realpath'
fi

# zsh-autosuggestions — command suggestions based on history, falling back
# to completion when history has no match
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
if [[ -d "$_PLUGINS_DIR/zsh-autosuggestions" ]]; then
  source "$_PLUGINS_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# zsh-syntax-highlighting — must be sourced LAST (wraps zle widgets)
if [[ -d "$_PLUGINS_DIR/zsh-syntax-highlighting" ]]; then
  source "$_PLUGINS_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
