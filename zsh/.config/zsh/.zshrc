# ===== Oh My Zsh Configuration =====
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

# ===== Environment Variables =====
export EDITOR="/usr/bin/micro"
export _ZO_DATA_DIR="$HOME/.local/share/zoxide"
export GTK_IM_MODULE=fcitx5
export QT_IM_MODULE=fcitx5
export XMODIFIERS=@im=fcitx5
export PROTONPATH="/usr/share/steam/compatibilitytools.d/proton-ge-custom"

# ===== fzf Integration =====
# Use system-provided fzf files if available
if [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]; then
  source /usr/share/doc/fzf/examples/key-bindings.zsh
fi

if [ -f /usr/share/doc/fzf/examples/completion.zsh ]; then
  source /usr/share/doc/fzf/examples/completion.zsh
fi

# fzf configuration with fd/fdfind
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

# ===== zoxide =====
eval "$(zoxide init zsh)"

# ===== Shell Options =====
setopt auto_cd           # Enable auto cd (type directory name to cd)
setopt share_history     # Share history between terminals
setopt hist_ignore_all_dups  # Don't show duplicate history entries

# ===== Aliases =====
# File listing
alias ls='eza'
alias ll='eza -alF'      # Use eza instead of ls for consistency
alias la='eza -A'
alias l='eza -CF'

# Utilities
alias grep='rg'
# Remove the 'find' alias since it conflicts with fd function
# alias find='fd'  # Commented out to avoid conflicts
alias yz='yazi'

# ===== Functions =====
# Yazi file manager integration with directory changing
y() {
    local tmp
    tmp="$(mktemp -t "yazi-cwd.XXXXX")"
    yazi "$@" --cwd-file="$tmp"
    
    if [ -f "$tmp" ]; then
        local cwd
        cwd="$(cat "$tmp")"
        rm -f "$tmp"
        [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && cd "$cwd"
    fi
}

# Micro editor shortcut
c() {
    if [ $# -eq 0 ]; then
        echo "Usage: c <file> (opens file in Micro)"
        return 1
    fi
    micro "$@"
}

# fd/fdfind wrapper - remove alias first if it exists
unalias fd 2>/dev/null

if command -v fdfind >/dev/null 2>&1; then
    fd() {
        command fdfind "$@"
    }
elif command -v fd >/dev/null 2>&1; then
    # fd command already exists, no need to redefine
    :
else
    echo "Warning: fd/fdfind not found. Using system find instead."
    fd() {
        find "$@"
    }
fi

bindkey '^I^I' autosuggest-accept  # Double-tap Tab to accept

ulimit -n 8192
