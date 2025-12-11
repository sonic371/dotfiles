# Oh My Zsh Configuration
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="random"  # nice themes: af-magic, jonathan, rkj
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  colored-man-pages
  command-not-found
  extract
)
source "$ZSH/oh-my-zsh.sh"

# fzf Integration
# Use system-provided fzf files if available
if [ -f ~/.zsh/fzf/completion.zsh ]; then
  source ~/.zsh/fzf/completion.zsh
fi

if [ -f ~/.zsh/fzf/key-bindings.zsh ]; then
  source ~/.zsh/fzf/key-bindings.zsh
fi

# zoxide
eval "$(zoxide init zsh)"
