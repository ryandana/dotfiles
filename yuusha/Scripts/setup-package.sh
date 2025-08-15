#!/bin/bash

# Simplified Modular Arch Linux Developer Setup Script
# Post-minimal installation script for clean development environment
# Author: Optimized setup with modular installation options

# ============================================================================
# CONFIGURATION AND GLOBAL VARIABLES
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUPS_DIR="$SCRIPT_DIR/backups"
AUR_HELPER=""  # Will be set after AUR helper installation

# Enhanced colors and styling
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Enhanced logging functions with better formatting
print_header() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    printf "${CYAN}║${WHITE}%-78s${CYAN}║${NC}\n" " $1"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

log() {
    echo -e "${GREEN}✓${NC} ${WHITE}[$(date +'%H:%M:%S')]${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠ ${NC} ${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} ${RED}[ERROR]${NC} $1"
}

info() {
    echo -e "${BLUE}ℹ${NC} ${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}🎉${NC} ${GREEN}$1${NC}"
}

# Enhanced prompt function for Y/n questions
prompt_yes_no() {
    local prompt="$1"
    local default="${2:-y}"
    local response
    
    while true; do
        if [ "$default" = "y" ]; then
            echo -ne "${YELLOW}$prompt${NC} [${GREEN}Y${NC}/${RED}n${NC}]: "
        else
            echo -ne "${YELLOW}$prompt${NC} [${RED}y${NC}/${GREEN}N${NC}]: "
        fi
        
        read -r response
        
        # Use default if empty
        if [ -z "$response" ]; then
            response="$default"
        fi
        
        # Validate response
        case "$response" in
            [yY]|[yY][eE][sS])
                return 0
                ;;
            [nN]|[nN][oO])
                return 1
                ;;
            *)
                echo -e "${RED}Please answer y or n${NC}"
                continue
                ;;
        esac
    done
}

# Function to handle sudo with retry logic
ensure_sudo() {
    local max_attempts=3
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if sudo -v 2>/dev/null; then
            # Keep sudo alive in background
            while true; do 
                sudo -n true
                sleep 60
                kill -0 "$$" || exit
            done 2>/dev/null &
            return 0
        else
            if [ $attempt -lt $max_attempts ]; then
                echo -e "${RED}Incorrect password. Attempt $attempt/$max_attempts${NC}"
                echo -e "${YELLOW}Please try again...${NC}"
                ((attempt++))
            else
                error "Failed to obtain sudo privileges after $max_attempts attempts"
                exit 1
            fi
        fi
    done
}

# Function removed - no longer copying backup folders

# ============================================================================
# INSTALLATION MODULES
# ============================================================================

# Module 1: System Update and Essential Packages
install_system_essentials() {
    print_header "SYSTEM UPDATE AND ESSENTIAL PACKAGES"
    
    log "Updating system packages..."
    if ! sudo pacman -Syu --noconfirm; then
        error "Failed to update system packages"
        return 1
    fi

    log "Installing essential base packages..."
    local essential_packages=(
        base-devel git wget curl unzip vim nano
        btop tree rsync man-db man-pages bash-completion
        net-tools libxcrypt-compat
    )
    
    if ! sudo pacman -S --needed --noconfirm "${essential_packages[@]}"; then
        error "Failed to install essential packages"
        return 1
    fi

    success "Essential packages installed successfully"
    return 0
}

# Module 2: Intel Hardware Support
install_intel_hardware() {
    print_header "INTEL HARDWARE SUPPORT (ALDER LAKE + IRIS XE)"

    log "Installing Intel CPU and GPU support for Alder Lake..."
    local intel_packages=(
        intel-ucode mesa vulkan-intel intel-media-driver
        libva-intel-driver libva-utils intel-gpu-tools
        intel-compute-runtime vpl-gpu-rt
    )
    
    if ! sudo pacman -S --needed --noconfirm "${intel_packages[@]}"; then
        error "Failed to install Intel hardware packages"
        return 1
    fi

    log "Installing power management tools..."
    if ! sudo pacman -S --needed --noconfirm power-profiles-daemon; then
        error "Failed to install power management"
        return 1
    fi
    
    sudo systemctl enable power-profiles-daemon

    success "Intel hardware support configured"
    return 0
}

# Module 3: Network Configuration
install_network_tools() {
    print_header "NETWORK CONFIGURATION"

    log "Installing network tools..."
    local network_packages=(
        networkmanager network-manager-applet
        wireless_tools wpa_supplicant
    )
    
    if ! sudo pacman -S --needed --noconfirm "${network_packages[@]}"; then
        error "Failed to install network packages"
        return 1
    fi

    # Enable NetworkManager and disable wait-online service
    sudo systemctl enable NetworkManager
    sudo systemctl disable NetworkManager-wait-online.service

    success "Network tools configured"
    return 0
}

# Function to choose AUR helper
choose_aur_helper() {
    echo ""
    echo -e "${CYAN}Available AUR Helpers:${NC}"
    echo -e "  ${BLUE}1.${NC} paru (build from source)"
    echo -e "  ${BLUE}2.${NC} paru-bin (pre-compiled binary)"
    echo -e "  ${BLUE}3.${NC} yay (build from source)"
    echo -e "  ${BLUE}4.${NC} yay-bin (pre-compiled binary)"
    echo ""
    
    while true; do
        echo -ne "${YELLOW}Choose AUR helper [1-4]:${NC} "
        read -r choice
        
        case "$choice" in
            1)
                echo "paru"
                return 0
                ;;
            2)
                echo "paru-bin"
                return 0
                ;;
            3)
                echo "yay"
                return 0
                ;;
            4)
                echo "yay-bin"
                return 0
                ;;
            *)
                echo -e "${RED}Please choose 1, 2, 3, or 4${NC}"
                continue
                ;;
        esac
    done
}

# Module 4: AUR Helper Installation
install_aur_helper() {
    print_header "AUR HELPER INSTALLATION"

    # Check if any AUR helper is already installed
    if command -v paru &> /dev/null; then
        log "Paru already installed, skipping..."
        AUR_HELPER="paru"
        return 0
    elif command -v yay &> /dev/null; then
        log "Yay already installed, skipping..."
        AUR_HELPER="yay"
        return 0
    fi

    # Let user choose AUR helper
    local aur_helper
    aur_helper=$(choose_aur_helper)
    
    log "Installing $aur_helper AUR helper..."
    local temp_dir="/tmp/${aur_helper}-build-$$"
    local repo_url
    
    # Set repository URL based on choice
    case "$aur_helper" in
        "paru")
            repo_url="https://aur.archlinux.org/paru.git"
            ;;
        "paru-bin")
            repo_url="https://aur.archlinux.org/paru-bin.git"
            ;;
        "yay")
            repo_url="https://aur.archlinux.org/yay.git"
            ;;
        "yay-bin")
            repo_url="https://aur.archlinux.org/yay-bin.git"
            ;;
    esac
    
    if ! git clone "$repo_url" "$temp_dir"; then
        error "Failed to clone $aur_helper repository"
        return 1
    fi
    
    cd "$temp_dir" || return 1
    
    if ! makepkg -si --noconfirm; then
        error "Failed to build and install $aur_helper"
        cd ~ && rm -rf "$temp_dir"
        return 1
    fi
    
    cd ~ && rm -rf "$temp_dir"
    success "$aur_helper installed successfully"
    
    # Set global variable for AUR helper command
    if command -v paru &> /dev/null; then
        AUR_HELPER="paru"
    elif command -v yay &> /dev/null; then
        AUR_HELPER="yay"
    else
        error "AUR helper installation failed"
        return 1
    fi
    
    return 0
}

# Module 5: Flatpak Support
install_flatpak() {
    print_header "FLATPAK SUPPORT"

    log "Installing Flatpak support..."
    if ! sudo pacman -S --needed --noconfirm flatpak; then
        error "Failed to install Flatpak"
        return 1
    fi

    # Add Flathub repository
    if ! flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo; then
        warning "Failed to add Flathub repository"
    fi

    success "Flatpak support configured"
    return 0
}

# Module 6: Development Tools
install_development_tools() {
    print_header "DEVELOPMENT TOOLS"

    # Check if AUR helper is available
    if [ -z "$AUR_HELPER" ]; then
        if command -v paru &> /dev/null; then
            AUR_HELPER="paru"
        elif command -v yay &> /dev/null; then
            AUR_HELPER="yay"
        else
            error "No AUR helper found. Please install AUR helper first."
            return 1
        fi
    fi

    # Install development dependencies first
    log "Installing development dependencies..."
    local dev_deps=(
        make openssl zlib bzip2 readline sqlite llvm
        ncurses xz tk libxml2 libxslt libffi
    )
    
    if ! sudo pacman -S --needed --noconfirm "${dev_deps[@]}"; then
        error "Failed to install development dependencies"
        return 1
    fi

    # Visual Studio Code
    log "Installing Visual Studio Code..."
    if ! $AUR_HELPER -S --needed --noconfirm visual-studio-code-bin; then
        warning "Failed to install VS Code"
    fi

    # Google Chrome
    log "Installing Google Chrome..."
    if ! $AUR_HELPER -S --needed --noconfirm google-chrome; then
        warning "Failed to install Google Chrome"
    fi

    # Docker
    log "Installing Docker..."
    local docker_packages=(docker docker-compose docker-buildx)
    
    if ! sudo pacman -S --needed --noconfirm "${docker_packages[@]}"; then
        error "Failed to install Docker"
        return 1
    fi

    # Enable Docker and add user to group
    sudo systemctl enable docker
    sudo usermod -aG docker "$USER"

    success "Development tools installed successfully"
    return 0
}

# Module 7: Node.js (NVM)
install_nodejs() {
    print_header "NODE.JS INSTALLATION (OFFICIAL NVM)"

    if [ -d "$HOME/.nvm" ]; then
        log "NVM already installed, skipping..."
        return 0
    fi

    log "Installing NVM from official repository..."
    local nvm_version
    nvm_version=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
    
    if [ -z "$nvm_version" ]; then
        error "Failed to get NVM version"
        return 1
    fi
    
    if ! curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/$nvm_version/install.sh" | bash; then
        error "Failed to install NVM"
        return 1
    fi

    success "NVM installed successfully"
    return 0
}

# Module 8: Python (Pyenv)
install_python() {
    print_header "PYTHON INSTALLATION (OFFICIAL PYENV)"

    if [ -d "$HOME/.pyenv" ]; then
        log "Pyenv already installed, skipping..."
        return 0
    fi

    log "Installing Pyenv from official repository..."
    if ! curl -s https://pyenv.run | bash; then
        error "Failed to install Pyenv"
        return 1
    fi

    success "Pyenv installed successfully"
    return 0
}

# Module 9: Media and Utility Tools
install_media_tools() {
    print_header "MEDIA AND UTILITY TOOLS"

    log "Installing media and utility tools..."
    local media_packages=(
        yt-dlp zenity cava obs-studio kitty imagemagick kdenlive blender
    )
    
    if ! sudo pacman -S --needed --noconfirm "${media_packages[@]}"; then
        error "Failed to install media tools"
        return 1
    fi

    success "Media and utility tools installed"
    return 0
}

# Module 10: Hyprland and Desktop Environment
install_hyprland() {
    print_header "HYPRLAND AND DESKTOP ENVIRONMENT"

    # Check if AUR helper is available
    if [ -z "$AUR_HELPER" ]; then
        if command -v paru &> /dev/null; then
            AUR_HELPER="paru"
        elif command -v yay &> /dev/null; then
            AUR_HELPER="yay"
        else
            error "No AUR helper found. Please install AUR helper first."
            return 1
        fi
    fi

    # Remove conflicting packages first
    log "Removing conflicting packages..."
    $AUR_HELPER -Rns --noconfirm wofi htop 2>/dev/null || true

    # Install Qt and KDE packages first (system packages)
    log "Installing Qt and KDE packages..."
    local qt_kde_packages=(
        qt5-wayland qt6-wayland qt5ct kvantum qt6ct-kde
        kdeconnect sshfs
    )
    
    if ! $AUR_HELPER -S --needed --noconfirm "${qt_kde_packages[@]}"; then
        warning "Some Qt/KDE packages failed to install"
    fi

    log "Installing Hyprland packages from AUR..."
    local hyprland_packages=(
        # System info & tweaks
        neofetch nwg-look papirus-folders-catppuccin-git 
        catppuccin-gtk-theme-mocha papirus-icon-theme otf-font-awesome
        # Hyprland utilities
        wlogout hypridle hyprpicker swww waybar rofi dunst 
        brightnessctl wl-clipboard rofi-emoji wtype neovim fd fzf grim slurp mpv loupe nautilus file-roller
        # Media
        mpd rmpc pavucontrol
        # Connectivity
        blueman
        # Apps
        discord
    )

    # Create standard directories
    mkdir -p ~/Desktop ~/Downloads ~/Documents ~/Pictures ~/Videos ~/Templates
    
    if ! $AUR_HELPER -S --needed --noconfirm "${hyprland_packages[@]}"; then
        warning "Some Hyprland packages failed to install"
    fi

    # Enable and configure services
    systemctl --user enable --now mpd 2>/dev/null || true
    papirus-folder -c cat-mocha-lavender --theme Papirus-Dark 2>/dev/null || true

    # Configure GNOME keybindings if running GNOME
    if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then
        log "Detected GNOME, applying workspace keybindings..."
        for i in {1..9}; do
            gsettings set org.gnome.shell.keybindings switch-to-application-$i "[]" 2>/dev/null || true
            gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-$i "['<Super>$i']" 2>/dev/null || true
            gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-$i "['<Super><Shift>$i']" 2>/dev/null || true
        done
        success "GNOME keybindings configured"
    fi

    success "Hyprland environment installed"
    return 0
}

# Module 11: Fonts
install_fonts() {
    print_header "FONTS INSTALLATION"

    # Check if AUR helper is available
    if [ -z "$AUR_HELPER" ]; then
        if command -v paru &> /dev/null; then
            AUR_HELPER="paru"
        elif command -v yay &> /dev/null; then
            AUR_HELPER="yay"
        else
            warning "No AUR helper found. Skipping AUR font packages."
        fi
    fi

    log "Installing essential fonts..."
    local font_packages=(
        ttf-liberation ttf-dejavu noto-fonts noto-fonts-cjk
        noto-fonts-extra noto-fonts-emoji ttf-jetbrains-mono-nerd
    )
    
    if ! sudo pacman -S --needed --noconfirm "${font_packages[@]}"; then
        error "Failed to install system fonts"
        return 1
    fi

    # Microsoft fonts (only if AUR helper is available)
    if [ -n "$AUR_HELPER" ]; then
        log "Installing Microsoft fonts..."
        if ! $AUR_HELPER -S --needed --noconfirm ttf-ms-fonts; then
            warning "Failed to install Microsoft fonts"
        fi
    else
        warning "Skipping Microsoft fonts (no AUR helper available)"
    fi

    # Update font cache
    fc-cache -fv

    success "Fonts installed successfully"
    return 0
}

# Module 12: Shell Configuration (Simplified)
install_shell() {
    print_header "SHELL CONFIGURATION (ZSH + OH-MY-ZSH + STARSHIP)"

    log "Installing Zsh and Starship..."
    if ! sudo pacman -S --needed --noconfirm zsh starship bat exa; then
        error "Failed to install shell packages"
        return 1
    fi

    # Install Oh-My-Zsh without configuration
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        log "Installing Oh-My-Zsh..."
        if ! sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; then
            error "Failed to install Oh-My-Zsh"
            return 1
        fi
    fi

    # Install only git plugin (keep it minimal)
    log "Git plugin is included by default in Oh-My-Zsh"

    # Change default shell to zsh
    if [ "$SHELL" != "$(which zsh)" ]; then
        log "Changing default shell to zsh..."
        chsh -s $(which zsh)
    fi

    success "Shell packages installed (no custom configuration applied)"
    return 0
}

# Module 13: Custom Scripts
install_scripts() {
    print_header "CUSTOM SCRIPTS INSTALLATION"

    log "Creating Scripts directory..."
    mkdir -p ~/Scripts

    log "Installing yt-dlp.sh script..."
    cat > ~/Scripts/yt-dlp.sh << 'EOF'
#!/bin/bash
# === Downloader Script by yuusha ===

url=$(zenity --entry --title="Downloader" --text="Enter the video URL:" --width="600")
[ -z "$url" ] && exit 1

choice=$(zenity --list --radiolist \
    --title="Download Type" \
    --text="Choose what to download:" \
    --column="Pick" --column="Type" \
    TRUE "Video (MP4 with AAC)" \
    FALSE "Audio (MP3)")
[ -z "$choice" ] && exit 1

if [ "$choice" = "Video (MP4 with AAC)" ]; then
    outpath="$HOME/Videos/%(title).200s.%(ext)s"
    format="bv*[ext=mp4]+ba[acodec^=mp4a]/b[ext=mp4]/b"
    opts=(--merge-output-format mp4)
else
    outpath="$HOME/Music/%(title).200s.%(ext)s"
    format="bestaudio"
    opts=(--extract-audio --audio-format mp3)
fi

(
    yt-dlp "$url" -f "$format" "${opts[@]}" --embed-thumbnail --embed-metadata \
        --add-metadata --audio-quality 0 --no-mtime --newline \
        --progress-template "download:%(progress._percent_str)s" -o "$outpath" 2>&1 |
    while read -r line; do
        if [[ "$line" =~ ([0-9]{1,3}\.[0-9])% ]]; then
            percent=${BASH_REMATCH[1]}
            echo "${percent%.*}"
        fi
    done
) | zenity --progress --title="Downloader" --text="Downloading..." \
    --percentage=0 --auto-close --width=400 --window-icon=info

if [ $? -eq 0 ]; then
    notify-send "Downloader" "Download completed."
else
    notify-send "Downloader" "Download cancelled or failed."
fi
EOF

    chmod +x ~/Scripts/yt-dlp.sh
    success "Custom scripts installed"
    return 0
}

# ============================================================================
# MAIN INSTALLATION FLOW
# ============================================================================

# Welcome banner
show_welcome() {
    clear
    echo -e "${PURPLE}"
    cat << "EOF"
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                                                                           ║
    ║    ╔══╗┬─┬┌─┬ ┬  ╦  ┬┌┌┬ ┬─┐ ┬  ╔══╗┌──┌┬─┬ ┬┌──                        ║
    ║    ╠══╣├┬┘│  ├─┤  ║  ││││ │ │┌─┴┬┘  ╚══╗├┤  │ │ │├──                        ║
    ║    ╩ ╩┴└─└─┘┴ ┴  ╩══┴┘└┘└─┘┴ └─  ╚══┘└─┘ ┴ └─┘┴                          ║
    ║                                                                           ║
    ║                    Simplified Modular Setup                               ║
    ║                                                                           ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Pre-installation checks
pre_install_checks() {
    print_header "PRE-INSTALLATION CHECKS"

    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root"
        exit 1
    fi

    # Check if sudo is available
    if ! command -v sudo &> /dev/null; then
        error "sudo is required but not installed"
        exit 1
    fi

    log "All pre-installation checks passed"
}

# System cleanup
cleanup_system() {
    print_header "CLEANUP AND OPTIMIZATION"

    log "Cleaning up system..."

    # Remove orphaned packages
    local orphans
    orphans=$(pacman -Qtdq 2>/dev/null) || true
    if [ -n "$orphans" ]; then
        sudo pacman -Rns $orphans --noconfirm
        log "Removed orphaned packages"
    else
        log "No orphaned packages found"
    fi

    # Clear package caches
    if command -v paru &> /dev/null; then
        paru -Sc --noconfirm 2>/dev/null || true
    elif command -v yay &> /dev/null; then
        yay -Sc --noconfirm 2>/dev/null || true
    fi
    sudo pacman -Sc --noconfirm

    success "System cleanup completed"
}

# Main installation function
main() {
    show_welcome
    pre_install_checks
    
    print_header "Starting Simplified Arch Linux Developer Environment Setup"
    
    info "Requesting sudo privileges..."
    ensure_sudo
    
    # File restoration - removed backup copying functionality
    print_header "FILE RESTORATION"
    info "Backup restoration functionality has been removed from this script"
    
    # Installation modules with Y/n prompts
    declare -A modules=(
        ["System Essentials"]="install_system_essentials"
        ["Intel Hardware Support"]="install_intel_hardware"
        ["Network Tools"]="install_network_tools"
        ["AUR Helper (Paru)"]="install_aur_helper"
        ["Flatpak Support"]="install_flatpak"
        ["Development Tools"]="install_development_tools"
        ["Node.js (NVM)"]="install_nodejs"
        ["Python (Pyenv)"]="install_python"
        ["Media & Utility Tools"]="install_media_tools"
        ["Hyprland Desktop"]="install_hyprland"
        ["Fonts"]="install_fonts"
        ["Shell (Zsh + Starship)"]="install_shell"
        ["Custom Scripts"]="install_scripts"
    )
    
    # Install modules based on user choice
    for module_name in "System Essentials" "Intel Hardware Support" "Network Tools" \
                      "AUR Helper (Paru)" "Flatpak Support" "Development Tools" \
                      "Node.js (NVM)" "Python (Pyenv)" "Media & Utility Tools" \
                      "Hyprland Desktop" "Fonts" "Shell (Zsh + Starship)" \
                      "Custom Scripts"; do
        
        if prompt_yes_no "Install $module_name?"; then
            local function_name="${modules[$module_name]}"
            if ! $function_name; then
                error "Failed to install $module_name"
                if ! prompt_yes_no "Continue with remaining installations?"; then
                    exit 1
                fi
            fi
        else
            info "Skipping $module_name"
        fi
        echo ""
    done
    
    # Final cleanup
    if prompt_yes_no "Run system cleanup and optimization?"; then
        cleanup_system
    fi
    
    # Show completion message
    show_completion
}

# Completion message
show_completion() {
    clear
    echo -e "${PURPLE}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║  ██████╗ ██████╗ ███╗   ███╗██████╗ ██╗     ███████╗████████╗███████╗       ║
║ ██╔════╝██╔═══██╗████╗ ████║██╔══██╗██║     ██╔════╝╚══██╔══╝██╔════╝       ║
║ ██║     ██║   ██║██╔████╔██║██████╔╝██║     █████╗     ██║   █████╗         ║
║ ██║     ██║   ██║██║╚██╔╝██║██╔═══╝ ██║     ██╔══╝     ██║   ██╔══╝         ║
║ ╚██████╗╚██████╔╝██║ ╚═╝ ██║██║     ███████╗███████╗   ██║   ███████╗       ║
║  ╚═════╝ ╚═════╝ ╚═╝     ╚═╝╚═╝     ╚══════╝╚══════╝   ╚═╝   ╚══════╝       ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"

    success "Simplified Arch Linux Developer Environment Setup Complete!"
    echo ""
    echo -e "${CYAN}Installation Summary:${NC}"
    echo -e "  ${GREEN}✓${NC} Modular installation with user choice for each component"
    echo -e "  ${GREEN}✓${NC} NetworkManager-wait-online.service disabled for faster boot"
    echo -e "  ${GREEN}✓${NC} Simplified shell installation (no custom configuration)"
    echo -e "  ${GREEN}✓${NC} Qt/KDE packages for better Wayland support"
    echo -e "  ${GREEN}✓${NC} Dolphin file manager with Ark archive support"
    echo -e "  ${GREEN}✓${NC} Clean, organized installation process"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo -e "  ${BLUE}1.${NC} Reboot your system: ${WHITE}sudo reboot${NC}"
    echo -e "  ${BLUE}2.${NC} Configure your shell manually if desired"
    echo -e "  ${BLUE}3.${NC} Docker group membership will be active after reboot"
    echo -e "  ${BLUE}4.${NC} Use ${WHITE}nvm list${NC} to see installed Node.js versions"
    echo -e "  ${BLUE}5.${NC} Install Python: ${WHITE}pyenv install 3.12.7 && pyenv global 3.12.7${NC}"
    echo -e "  ${BLUE}6.${NC} Custom scripts are available in ${WHITE}~/Scripts${NC}"
    echo -e "  ${BLUE}7.${NC} Configure Starship theme manually if desired"
    echo ""
    
    if prompt_yes_no "Reboot now to complete the setup?"; then
        echo -e "${GREEN}✓${NC} Rebooting system..."
        sudo reboot
    else
        echo -e "${BLUE}ℹ${NC} Reboot manually when ready: ${WHITE}sudo reboot${NC}"
        echo -e "${YELLOW}Note:${NC} Some changes require a reboot to take effect."
    fi
}

# ============================================================================
# SCRIPT EXECUTION
# ============================================================================

# Trap to handle script interruption
trap 'echo -e "\n${RED}Script interrupted by user${NC}"; exit 130' INT

# Run main function
main "$@"