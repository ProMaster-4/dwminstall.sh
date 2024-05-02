#!/bin/bash

# Check if yay is installed, if not, install it
if ! command -v yay &>/dev/null; then
    git clone https://aur.archlinux.org/yay-git.git ~/yay-git &&
    (cd ~/yay-git && makepkg -si --noconfirm) &&
    rm -rf ~/yay-git
fi

# Define resolutions
resolutions=("1280x720" "1920x1080" "2560x1440" "3840x2160")

# Prompt for resolution choice
echo "Choose your desired resolution:"
for ((i=0; i<${#resolutions[@]}; i++)); do
    echo "$(($i+1)). ${resolutions[$i]}"
done
read -p "Enter the corresponding number for your resolution: " resolution_choice
resolution="${resolutions[$(($resolution_choice-1))]:-"1920x1080"}"

# Prompt for refresh rate
read -p "Enter desired refresh rate (integer only): " refresh_rate
if ! [[ "$refresh_rate" =~ ^[0-9]+$ ]]; then
    echo "Error: Refresh rate must be an integer."
    exit 1
fi

# Check if packages are installed
packages=("git" "firefox" "noto-fonts-cjk" "noto-fonts-emoji" "discord_arch_electron" "zoxide" "picom" "starship" "lxappearance" "feh" "kitty" "xorg-server" "xorg-xinit" "xorg-xrandr" "base-devel" "libx11" "libxinerama" "libxft" "webkit2gtk" "xcursor-breeze")
missing_packages=()
for pkg in "${packages[@]}"; do
    if ! yay -Qq "$pkg" &>/dev/null; then
        missing_packages+=("$pkg")
    fi
done

# Install missing packages
if [[ ${#missing_packages[@]} -gt 0 ]]; then
    yay -Syu --noconfirm "${missing_packages[@]}"
fi

# Clone repositories
git clone https://github.com/ProMaster-4/dwm ~/dwm &&
git clone https://git.suckless.org/dmenu ~/dmenu &&
git clone https://github.com/ProMaster-4/dotfiles ~/dotfiles || exit 1

# Update refresh rate in dwm config.h
sed -i "s/static const unsigned int refresh_rate    = 60;/static const unsigned int refresh_rate    = $refresh_rate;/g" ~/dwm/config.h || exit 1

# Compile and install dwm and dmenu
for dir in ~/dwm ~/dmenu; do
    (cd "$dir" && sudo make clean install) || exit 1
done

# Copy dotfiles to home directory
cp -r ~/dotfiles/. ~ && sudo rm -r ~/.git || exit 1

# Modify .xinitrc to include resolution and refresh rate
xinitrc_path="$HOME/.xinitrc"
temp_file=$(mktemp)
echo "xrandr --auto --output $(xrandr | awk '/ connected/ {print $1}') --mode $resolution --rate $refresh_rate" > "$temp_file"
cat "$xinitrc_path" >> "$temp_file"
mv "$temp_file" "$xinitrc_path" || exit 1

# Prompt to reboot
read -p "Do you want to reboot now? (y/n): " reboot_choice
if [[ $reboot_choice == "y" || $reboot_choice == "Y" ]]; then
    sudo reboot
else
    echo "Please remember to reboot to apply changes."
fi
