#!/bin/bash

# Install required packages
sudo pacman -Syu git firefox zoxide lxappearance feh kitty xorg-server xorg-xinit xorg-xrandr base-devel libx11 libxinerama libxft webkit2gtk --noconfirm

# Clone yay from AUR
cd ~
git clone https://aur.archlinux.org/yay-git.git
cd yay-git
makepkg -si --noconfirm
cd ~
sudo rm -r yay-git

# Install xcursor-breeze package with yay
yay -S --noconfirm xcursor-breeze

# Clone dwm, dmenu, and dotfiles repositories
git clone https://github.com/ProMaster-4/dwm
git clone https://git.suckless.org/dmenu
git clone https://github.com/ProMaster-4/dotfiles

# Copy dotfiles to home directory
cd dotfiles
cp -r . ~

# Clean up dotfiles directory
cd ~
rm -rf dotfiles

# Clean up dwm and dmenu directories
cd dwm
sudo make clean install
cd ~
cd dmenu
sudo make clean install
cd ~

sudo reboot
