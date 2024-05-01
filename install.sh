#!/bin/bash

# Prompt for desired resolution
echo "Choose your desired resolution:"
echo "1. 720p (1280x720)"
echo "2. 1080p (1920x1080)"
echo "3. 1440p (2560x1440)"
echo "4. 2160p (3840x2160)"
read -p "Enter the corresponding number for your resolution: " resolution_choice

case $resolution_choice in
    1)
        resolution="1280x720"
        ;;
    2)
        resolution="1920x1080"
        ;;
    3)
        resolution="2560x1440"
        ;;
    4)
        resolution="3840x2160"
        ;;
    *)
        echo "Invalid choice. Defaulting to 1080p."
        resolution="1920x1080"
        ;;
esac

# Prompt for desired refresh rate
read -p "Enter desired refresh rate (integer only): " refresh_rate
if ! [[ "$refresh_rate" =~ ^[0-9]+$ ]]; then
    echo "Error: Refresh rate must be an integer."
    exit 1
fi

# List of required packages
packages=("git" "firefox" "zoxide" "picom" "starship" "lxappearance" "feh" "kitty" "xorg-server" "xorg-xinit" "xorg-xrandr" "base-devel" "libx11" "libxinerama" "libxft" "webkit2gtk")

# Install required packages if not already installed
for pkg in "${packages[@]}"; do
    if ! pacman -Qq "$pkg" &>/dev/null; then
        sudo pacman -Syu --noconfirm "$pkg"
    fi
done

# Clone yay from AUR
cd ~ || exit
git clone https://aur.archlinux.org/yay-git.git
cd yay-git || exit
makepkg -si --noconfirm
cd ~ || exit
sudo rm -r yay-git

# Install xcursor-breeze package with yay if not already installed
if ! yay -Qq xcursor-breeze &>/dev/null; then
    yay -S --noconfirm xcursor-breeze
fi

# Clone dwm, dmenu, and dotfiles repositories
git clone https://github.com/ProMaster-4/dwm
git clone https://git.suckless.org/dmenu
git clone https://github.com/ProMaster-4/dotfiles

# Replace refresh rate in dwm config.h
if grep -q "static const unsigned int refresh_rate    = 60;" ~/dwm/config.h; then
    sed -i "s/static const unsigned int refresh_rate    = 60;/static const unsigned int refresh_rate    = $refresh_rate;/g" ~/dwm/config.h
fi

# Compile and install dwm
cd ~/dwm || exit
sudo make clean install

# Compile and install dmenu
cd ~/dmenu || exit
sudo make clean install

# Copy dotfiles to home directory
cd ~/dotfiles || exit
cp -r . ~

# Modify .xinitrc to include resolution and refresh rate
xinitrc_path="$HOME/.xinitrc"
temp_file=$(mktemp)
echo "xrandr -s $resolution -r $refresh_rate" > "$temp_file"
cat "$xinitrc_path" >> "$temp_file"
mv "$temp_file" "$xinitrc_path"

# Clean up dotfiles directory
cd ~ || exit
rm -rf dotfiles

# Prompt to reboot
read -p "Do you want to reboot now? (y/n): " reboot_choice
if [[ $reboot_choice == "y" || $reboot_choice == "Y" ]]; then
    sudo reboot
else
    echo "Please remember to reboot to apply changes."
fi
