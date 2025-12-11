# Environment Variables
export EDITOR="/usr/bin/micro"
export _ZO_DATA_DIR="$HOME/.local/share/zoxide"
export GTK_IM_MODULE=fcitx5
export QT_IM_MODULE=fcitx5
export XMODIFIERS=@im=fcitx5
export PROTONPATH="/usr/share/steam/compatibilitytools.d/proton-ge-custom"

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