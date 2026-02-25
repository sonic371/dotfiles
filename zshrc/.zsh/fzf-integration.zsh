# ============================================================================
# FZF INTEGRATION
# ============================================================================
if command -v fzf &>/dev/null; then

  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fd --type d --hidden --follow'

  # Global fzf options (UI only, no preview here)
  export FZF_DEFAULT_OPTS='
    --height=40%
    --layout=reverse
    --border
    --info=inline
  '

  # Preview when selecting files (CTRL-T)
  export FZF_CTRL_T_OPTS='
    --preview="bat --style=numbers --color=always {} 2>/dev/null | head -200"
    --bind "ctrl-/:toggle-preview"
  '

  # Preview when selecting directories (ALT-C)
  export FZF_ALT_C_OPTS='
    --preview="tree -C {} | head -200"
  '

  # Source fzf key bindings and fuzzy completion if available
  eval "$(fzf --zsh)"

fi

