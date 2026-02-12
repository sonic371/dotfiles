# ============================================================================
# FZF INTEGRATION
# ============================================================================
if command -v fzf &>/dev/null; then
  export FZF_DEFAULT_COMMAND='fd --type f'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fd --type d'

  export FZF_DEFAULT_OPTS='
    --height=40%
    --layout=reverse
    --border
    --info=inline
    --preview="bat --style=numbers --color=always {} 2>/dev/null | head -200"
  '

  # Source fzf key bindings and completion if available
  [[ -f /usr/share/fzf/key-bindings.zsh ]] && source /usr/share/fzf/key-bindings.zsh
  [[ -f /usr/share/fzf/completion.zsh ]] && source /usr/share/fzf/completion.zsh
fi
