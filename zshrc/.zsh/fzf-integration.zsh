# ============================================================================
# FZF INTEGRATION
# ============================================================================
# Single responsibility: Configure and load fzf (fuzzy finder) integration

# Detect fd/fdfind for fzf commands
if command -v fdfind >/dev/null 2>&1; then
    FD_CMD="fdfind"
elif command -v fd >/dev/null 2>&1; then
    FD_CMD="fd"
else
    FD_CMD="find"
fi

export FZF_DEFAULT_COMMAND="$FD_CMD --type f --hidden --follow --exclude .git --strip-cwd-prefix"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="$FD_CMD --type d --hidden --follow --exclude .git --strip-cwd-prefix"

# Use system-provided fzf files if available
if [ -f ~/.zsh/fzf/completion.zsh ]; then
  source ~/.zsh/fzf/completion.zsh
fi

if [ -f ~/.zsh/fzf/key-bindings.zsh ]; then
  source ~/.zsh/fzf/key-bindings.zsh
fi