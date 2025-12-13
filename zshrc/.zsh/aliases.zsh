# File listing aliases
alias ls='eza'
alias la='eza -la'
alias lt='eza --all --long  --tree --level 3 --group-directories-first'

# Utilities aliases
alias grep='rg'
alias yz='yazi'

# Git Shortcuts
alias g='git'
alias gs='git status'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit -v'
alias gcm='git commit -m'
alias gca='git commit --amend'
alias gco='git checkout'
alias gb='git branch'
alias gd='git diff'
alias gds='git diff --staged'
alias gl='git log --oneline --graph -20'
alias gps='git push'
alias gpl='git pull'
alias gf='git fetch'
alias gr='git restore'
alias grs='git restore --staged'
alias gst='git stash'
alias gsp='git stash pop'

# Dotfiles specific
alias dot='cd ~/dotfiles'
alias dots='cd ~/dotfiles && git status'
