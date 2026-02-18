#!/bin/bash

# Exit on error
set -e

# Print commands as they're executed
set -x

echo "Starting system setup..."

# Update system first
sudo pacman -Syu --noconfirm

# Install core packages
sudo pacman -S --noconfirm fd ripgrep fzf zoxide eza git stow yazi zsh

# Install base development tools
sudo pacman -S --needed --noconfirm base-devel

# Install Xorg and related packages
sudo pacman -S --noconfirm xorg-xinit xorg-server libxinerama libxft imlib2

# Change default shell to zsh
echo "Changing default shell to zsh..."
chsh -s /usr/bin/zsh

# Install Oh My Zsh (non-interactively)
echo "Installing Oh My Zsh..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Clone and stow dotfiles
echo "Setting up dotfiles..."
git clone https://github.com/sonic371/dotfiles.git ~/dotfiles
cd ~/dotfiles && stow -t ~ zshrc

# Clone additional repositories
echo "Cloning additional repositories..."
git clone https://github.com/bakkeby/st-flexipatch.git ~/.local/src/st-flexipatch
git clone https://github.com/sonic371/dwm ~/.local/src/dwm
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting

echo "Setup complete!"
echo "NOTE: You may need to log out and back in for shell changes to take effect."
