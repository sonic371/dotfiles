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

# Reset to beam at each new prompt (otherwise stays block after a vicmd command)
function zle-line-init { echo -ne '\e[5 q' }
zle -N zle-line-init
echo -ne '\e[5 q'  # beam cursor on startup
