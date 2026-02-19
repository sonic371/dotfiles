#!/bin/bash

# Exit on error
set -e

# Print commands as they're executed
set -x

echo "Starting system setup..."

# Update system first
run_sudo pacman -Syu --noconfirm

# Install core packages
run_sudo pacman -S --noconfirm fd ripgrep fzf zoxide eza git stow yazi zsh

# Install base development tools
run_sudo pacman -S --needed --noconfirm base-devel

# Install Xorg and related packages
run_sudo pacman -S --noconfirm xorg-xinit xorg-server libxinerama libxft imlib2

# Change default shell to zsh
echo "Changing default shell to zsh..."
chsh -s /usr/bin/zsh

# Clone and stow dotfiles
echo "Setting up dotfiles..."
if [ ! -d "$HOME/dotfiles" ]; then
    git clone https://github.com/sonic371/dotfiles.git $HOME/dotfiles
else
    echo "Dotfiles directory already exists, skipping clone..."
fi

# Run stow with --override flag to handle existing files
cd $HOME/dotfiles && stow --verbose --override=.* -t $HOME zshrc

# Clone additional repositories
echo "Cloning additional repositories..."
mkdir -p $HOME/.local/src

if [ ! -d "$HOME/.local/src/st-flexipatch" ]; then
    git clone https://github.com/bakkeby/st-flexipatch.git $HOME/.local/src/st-flexipatch
else
    echo "st-flexipatch directory already exists, skipping clone..."
fi

if [ ! -d "$HOME/.local/src/dwm" ]; then
    git clone https://github.com/sonic371/dwm $HOME/.local/src/dwm
else
    echo "dwm directory already exists, skipping clone..."
fi

# Install Oh My Zsh (only if not already installed)
echo "Installing Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo "Oh My Zsh already installed, skipping..."
fi

echo "Setup complete!"
echo "NOTE: You may need to log out and back in for shell changes to take effect."
