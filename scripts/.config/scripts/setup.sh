#!/usr/bin/env bash
# Bootstrap a fresh Arch install from the dotfiles repo.
# Safe to re-run: every step skips work that is already done.

set -euo pipefail

DOTS="$HOME/dotfiles"
REPO="https://github.com/sonic371/dotfiles.git"

echo "==> System update and bootstrap packages"
sudo pacman -Syu --noconfirm
sudo pacman -S --needed --noconfirm base-devel git git-lfs stow zsh

echo "==> Dotfiles"
git lfs install
if [ ! -d "$DOTS" ]; then
    git clone --recurse-submodules "$REPO" "$DOTS"
else
    echo "$DOTS exists, skipping clone"
    git -C "$DOTS" submodule update --init --recursive
fi
git -C "$DOTS" lfs pull

echo "==> Packages from .pkglist"
# Install what the official repos provide; AUR packages are listed for paru.
pkglist="$DOTS/.pkglist/pkglist.txt"
mapfile -t repo_pkgs < <(comm -12 <(sort -u "$pkglist") <(pacman -Slq | sort -u))
mapfile -t aur_pkgs < <(comm -23 <(sort -u "$pkglist") <(pacman -Slq | sort -u))
sudo pacman -S --needed --noconfirm "${repo_pkgs[@]}"
if [ "${#aur_pkgs[@]}" -gt 0 ]; then
    echo "Not in official repos (install with paru -S --needed): ${aur_pkgs[*]}"
fi

echo "==> Stow home packages"
# Packages containing etc/ belong under / and are handled below
home_pkgs=()
for p in "$DOTS"/*/; do
    p=${p%/}
    [ -d "$p/etc" ] || home_pkgs+=("${p##*/}")
done
# Move aside the skeleton .bashrc a new account gets, or stow aborts
if [ -f "$HOME/.bashrc" ] && [ ! -L "$HOME/.bashrc" ]; then
    mv "$HOME/.bashrc" "$HOME/.bashrc.orig"
fi
stow -d "$DOTS" -t "$HOME" "${home_pkgs[@]}"

echo "==> System packages"
# Copied rather than symlinked so they don't depend on /home being mounted
sudo cp -r --no-preserve=ownership "$DOTS/xorg-conf/etc/." /etc/
sudo cp -r --no-preserve=ownership "$DOTS/systemd-system/etc/." /etc/
sudo systemctl daemon-reload
sudo systemctl enable autocpufreq.service disable-mic-led.service

echo "==> User services"
# *.wants/ links are gitignored, so enable units explicitly
systemctl --user daemon-reload
# dunst and the portal ship without [Install], so attach them directly
systemctl --user add-wants graphical-session.target \
    dunst.service xdg-desktop-portal-gtk.service
systemctl --user enable \
    change-wallpaper.service dwmblocks.service dwmblocks-musicup.service \
    fcitx5.service mega-sync.service picom.service sxhkd.service \
    unclutter.service xidlehook.service xss-lock.service \
    battery-alert.timer change-wallpaper.timer

echo "==> Source trees in ~/.local/src"
mkdir -p "$HOME/.local/src"
clone() {
    [ -d "$HOME/.local/src/$1" ] && { echo "$1 exists, skipping"; return; }
    git clone "$2" "$HOME/.local/src/$1"
}
clone st-flexipatch https://github.com/bakkeby/st-flexipatch.git
clone dwm https://github.com/sonic371/dwm

echo "==> Login shell"
[ "$(getent passwd "$USER" | cut -d: -f7)" = /usr/bin/zsh ] || chsh -s /usr/bin/zsh

echo "Setup complete. Log out and back in, then build dwm/st with: rebuild"
