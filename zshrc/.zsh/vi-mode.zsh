# ============================================================================
# VI MODE
# ============================================================================
# Single responsibility: Configure vi mode and cursor shape feedback

bindkey -v
bindkey -M vicmd 'U' redo

# Let backspace/^W delete past the point where insert mode was entered
bindkey -M viins '^?' backward-delete-char
bindkey -M viins '^H' backward-delete-char
bindkey -M viins '^W' backward-kill-word

# Ctrl+Right/Left move by word; forward-word also accepts one word of an
# autosuggestion (zsh-autosuggestions treats it as a partial-accept widget)
bindkey -M viins '^[[1;5C' forward-word
bindkey -M viins '^[[1;5D' backward-word
bindkey -M vicmd '^[[1;5C' forward-word
bindkey -M vicmd '^[[1;5D' backward-word

# Ctrl+E accepts the whole autosuggestion (end-of-line is an accept widget)
bindkey -M viins '^E' end-of-line

# Up/Down (and k/j) search history for lines starting with what's typed
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
for key in '^[[A' '^[OA'; do bindkey -M viins "$key" up-line-or-beginning-search; done
for key in '^[[B' '^[OB'; do bindkey -M viins "$key" down-line-or-beginning-search; done
bindkey -M vicmd 'k' up-line-or-beginning-search
bindkey -M vicmd 'j' down-line-or-beginning-search

# v in normal mode opens the command line in $EDITOR (replaces visual-mode;
# V still selects the whole line)
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd 'v' edit-command-line

# Text objects for quotes and brackets: ci", da(, yi' ...
autoload -Uz select-bracketed select-quoted
zle -N select-quoted
zle -N select-bracketed
for km in viopp visual; do
    for c in {a,i}${(s..)^:-\'\"\`\|,./:;=+@}; do bindkey -M $km $c select-quoted; done
    for c in {a,i}${(s..)^:-'()[]{}<>bB'}; do bindkey -M $km $c select-bracketed; done
done
unset key km c
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
