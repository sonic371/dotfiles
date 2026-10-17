# File listing aliases
if command -v eza >/dev/null; then
  alias ls='eza'
  alias lt='eza --all --long  --tree --level 3 --group-directories-first'
  alias lts='eza --all --long  --tree --level 3 --group-directories-first --total-size'
fi

# Dotfiles navigation
alias dot='cd ~/dotfiles'
alias dots='cd ~/dotfiles && git status'

# Neovim
alias v='nvim'
