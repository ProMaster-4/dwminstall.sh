#!/bin/bash

# Function to check and install yay
install_yay() {
    if ! command -v yay &>/dev/null; then
        git clone https://aur.archlinux.org/yay-git.git ~/yay-git &&
        (cd ~/yay-git && makepkg -si --noconfirm) &&
        rm -rf ~/yay-git ||
        { echo "Failed to install yay. Exiting."; exit 1; }
    fi
}

# Function to prompt for resolution choice
prompt_resolution_choice() {
    echo "Choose your desired resolution:"
    for ((i=0; i<${#resolutions[@]}; i++)); do
        echo "$(($i+1)). ${resolutions[$i]}"
    done
    read -p "Enter the corresponding number for your resolution: " resolution_choice
    resolution="${resolutions[$(($resolution_choice-1))]:-"1920x1080"}"
}

# Function to prompt for refresh rate
prompt_refresh_rate() {
    read -p "Enter desired refresh rate (integer only): " refresh_rate
    if ! [[ "$refresh_rate" =~ ^[0-9]+$ ]]; then
        echo "Error: Refresh rate must be an integer."
        exit 1
    fi
}

# Function to install missing packages
install_missing_packages() {
    local missing_packages=()
    for pkg in "${packages[@]}"; do
        yay -Qq "$pkg" &>/dev/null || missing_packages+=("$pkg")
    done

    [[ ${#missing_packages[@]} -gt 0 ]] && 
    yay -Syu --noconfirm "${missing_packages[@]}" ||
    { echo "Failed to install missing packages. Exiting."; exit 1; }
}

# Function to clone repositories
clone_repositories() {
    git clone https://github.com/ProMaster-4/dwm ~/dwm &&
    git clone https://git.suckless.org/dmenu ~/dmenu &&
    git clone https://github.com/ProMaster-4/dotfiles ~/dotfiles ||
    { echo "Failed to clone repositories. Exiting."; exit 1; }
}

# Function to update refresh rate in dwm config.h
update_refresh_rate() {
    sed -i "s/static const unsigned int refresh_rate    = 60;/static const unsigned int refresh_rate    = $refresh_rate;/g" ~/dwm/config.h ||
    { echo "Failed to update refresh rate in dwm config.h. Exiting."; exit 1; }
}

# Function to compile and install dwm and dmenu
compile_and_install() {
    for dir in ~/dwm ~/dmenu; do
        (cd "$dir" && sudo make clean install) ||
        { echo "Failed to compile and install $dir. Exiting."; exit 1; }
    done
}

# Function to modify .xinitrc to include resolution and refresh rate
modify_xinitrc() {
    xinitrc_path="$HOME/.xinitrc"
    temp_file=$(mktemp)
    echo "xrandr --auto --output $(xrandr | awk '/ connected/ {print $1}') --mode $resolution --rate $refresh_rate" > "$temp_file"
    cat "$xinitrc_path" >> "$temp_file"
    mv "$temp_file" "$xinitrc_path" ||
    { echo "Failed to modify .xinitrc. Exiting."; exit 1; }
}

# Function to prompt for reboot
prompt_reboot() {
    read -p "Do you want to reboot now? (y/n): " reboot_choice
    [[ $reboot_choice == "y" || $reboot_choice == "Y" ]] && sudo reboot
}

# Main script
install_yay || exit 1
resolutions=("1280x720" "1920x1080" "2560x1440" "3840x2160")
prompt_resolution_choice
prompt_refresh_rate || exit 1
packages=("git" "firefox" "noto-fonts-cjk" "noto-fonts-emoji" "discord_arch_electron" "zoxide" "picom" "starship" "lxappearance" "feh" "kitty" "xorg-server" "xorg-xinit" "xorg-xrandr" "base-devel" "libx11" "libxinerama" "libxft" "webkit2gtk" "xcursor-breeze")
install_missing_packages || exit 1
clone_repositories || exit 1
update_refresh_rate || exit 1
compile_and_install || exit 1
cp -r ~/dotfiles/. ~ && sudo rm -r ~/.git ||
{ echo "Failed to copy dotfiles. Exiting."; exit 1; }
modify_xinitrc || exit 1
prompt_reboot || exit 1
echo "Please remember to reboot to apply changes."
