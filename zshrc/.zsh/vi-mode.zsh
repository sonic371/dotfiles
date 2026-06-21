# ============================================================================
# VI MODE
# ============================================================================
# Single responsibility: Configure vi mode and cursor shape feedback

bindkey -v
bindkey -M vicmd 'U' redo
export KEYTIMEOUT=1

function zle-keymap-select {
    case $KEYMAP in
        vicmd) echo -ne '\e[1 q';;      # block cursor for normal mode
        viins|main) echo -ne '\e[5 q';; # beam cursor for insert mode
    esac
}
zle -N zle-keymap-select
echo -ne '\e[5 q'  # beam cursor on startup
