#!/bin/sh
# Simple script to clone repositories - follows Unix philosophy (do one thing well)

set -e  # Exit on error

# Create base directory for source code
mkdir -p "$HOME/.local/src"

# Clone st-flexipatch
if [ ! -d "$HOME/.local/src/st-flexipatch" ]; then
    echo "Cloning st-flexipatch..."
    git clone https://github.com/sonic371/st-flexipatch.git "$HOME/.local/src/st-flexipatch"
else
    echo "st-flexipatch already exists, skipping..."
fi

# Clone dwm
if [ ! -d "$HOME/.local/src/dwm" ]; then
    echo "Cloning dwm..."
    git clone https://github.com/sonic371/dwm.git "$HOME/.local/src/dwm"
else
    echo "dwm already exists, skipping..."
fi

# Clone dwmblocks-async
if [ ! -d "$HOME/.local/src/dwmblocks-async" ]; then
    echo "Cloning dwmblocks-async..."
    git clone https://github.com/sonic371/dwmblocks-async.git "$HOME/.local/src/dwmblocks-async"
else
    echo "dwmblocks-async already exists, skipping..."
fi

# Clone dmenu
if [ ! -d "$HOME/.local/src/dmenu" ]; then
    echo "Cloning dmenu..."
    git clone https://github.com/sonic371/dmenu.git "$HOME/.local/src/dmenu"
else
    echo "dmenu already exists, skipping..."
fi

echo "All repositories cloned successfully!"
