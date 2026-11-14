#!/bin/sh
# Simple script to clone repositories - follows Unix philosophy (do one thing well)

set -e  # Exit on error

# Suckless tools (and dwmblocks-async) live together under ~/.local/src/suckless
SRC="$HOME/.local/src/suckless"
mkdir -p "$SRC"

# Clone st-flexipatch
if [ ! -d "$SRC/st-flexipatch" ]; then
    echo "Cloning st-flexipatch..."
    git clone https://github.com/sonic371/st-flexipatch.git "$SRC/st-flexipatch"
else
    echo "st-flexipatch already exists, skipping..."
fi

# Clone dwm
if [ ! -d "$SRC/dwm" ]; then
    echo "Cloning dwm..."
    git clone https://github.com/sonic371/dwm.git "$SRC/dwm"
else
    echo "dwm already exists, skipping..."
fi

# Clone dwmblocks-async
if [ ! -d "$SRC/dwmblocks-async" ]; then
    echo "Cloning dwmblocks-async..."
    git clone https://github.com/sonic371/dwmblocks-async.git "$SRC/dwmblocks-async"
else
    echo "dwmblocks-async already exists, skipping..."
fi

# Clone dmenu
if [ ! -d "$SRC/dmenu" ]; then
    echo "Cloning dmenu..."
    git clone https://github.com/sonic371/dmenu.git "$SRC/dmenu"
else
    echo "dmenu already exists, skipping..."
fi

echo "All repositories cloned successfully!"
