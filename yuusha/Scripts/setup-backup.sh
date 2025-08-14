#!/bin/bash

# Enhanced Minimal Arch Linux Developer Setup Script
# Post-minimal installation script for clean development environment
# Supports Intel Alder Lake with Iris Xe graphics
# Author: Optimized setup for minimal desktop experience with enhanced tooling

# Enhanced colors and styling
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Get script directory for .config folder detection
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Enhanced logging functions with better formatting
print_header() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE} $1${CYAN} ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

log() {
    echo -e "${GREEN}✓${NC} ${WHITE}[$(date +'%H:%M:%S')]${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠${NC} ${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} ${RED}[ERROR]${NC} $1"
    exit 1
}

info() {
    echo -e "${BLUE}ℹ${NC} ${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}🎉${NC} ${GREEN}$1${NC}"
}

# Prompt function for Y/n questions
prompt_yes_no() {
    local prompt="$1"
    local default="${2:-y}"
    local response
    
    if [ "$default" = "y" ]; then
        echo -e "${YELLOW}$prompt${NC} [${GREEN}Y${NC}/${RED}n${NC}]: "
    else
        echo -e "${YELLOW}$prompt${NC} [${RED}y${NC}/${GREEN}N${NC}]: "
    fi
    
    read -r response
    if [ -z "$response" ]; then
        response="$default"
    fi
    
    [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
}

# Function to copy .config folder if it exists
copy_config_folder() {
    local config_source="$SCRIPT_DIR/.config"
    
    if [ -d "$config_source" ]; then
        log "Found .config folder in script directory, copying to home..."
        
        # Create ~/.config if it doesn't exist
        mkdir -p ~/.config
        
        # Copy contents of .config folder, preserving existing files when prompted
        cp -ri "$config_source/"* ~/.config/ 2>/dev/null || {
            # If cp -ri fails, try with rsync for better handling
            if command -v rsync &> /dev/null; then
                rsync -av "$config_source/" ~/.config/
            else
                warning "Could not copy .config folder contents. Please copy manually if needed."
                return 1
            fi
        }
        
        success ".config folder copied to home directory"
        return 0
    else
        info "No .config folder found in script directory, skipping..."
        return 0
    fi
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   error "This script should not be run as root"
fi

# Check if sudo is available
if ! command -v sudo &> /dev/null; then
    error "sudo is required but not installed"
fi

# Welcome banner
clear
echo -e "${PURPLE}"
cat << "EOF"
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                                                                           ║
    ║    ╔═╗┬─┐┌─┐┬ ┬  ╦  ┬┌┐┌┬ ┬─┐ ┬  ╔═╗┌─┐┌┬┐┬ ┬┌─┐                        ║
    ║    ╠═╣├┬┘│  ├─┤  ║  ││││││ │┌┴┬┘  ╚═╗├┤  │ │ │├─┘                        ║
    ║    ╩ ╩┴└─└─┘┴ ┴  ╩═╝┴┘└┘└─┘┴ └─  ╚═╝└─┘ ┴ └─┘┴                          ║
    ║                                                                           ║
    ║                    Enhanced Developer Environment                         ║
    ║                                                                           ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

print_header "Starting Enhanced Arch Linux Developer Environment Setup"

# Request sudo password upfront and keep it alive
info "Requesting sudo privileges..."
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# ============================================================================
# CONFIG FOLDER DETECTION AND COPYING
# ============================================================================

print_header "CONFIG FOLDER SETUP"
copy_config_folder

# ============================================================================
# SCRIPTS INSTALLATION
# ============================================================================

print_header "SCRIPTS INSTALLATION"

log "Creating Scripts directory and installing yt-dlp.sh..."
mkdir -p ~/Scripts

# Create yt-dlp.sh script
cat > ~/Scripts/yt-dlp.sh << 'EOF'
#!/bin/bash

# === Downloader Script by yuusha ===

# Ask for URL
url=$(zenity --entry --title="Downloader" --text="Enter the video URL:" --width="600")
[ -z "$url" ] && exit 1

# Ask for type
choice=$(zenity --list --radiolist \
    --title="Download Type" \
    --text="Choose what to download:" \
    --column="Pick" --column="Type" \
    TRUE "Video (MP4 with AAC)" \
    FALSE "Audio (MP3)")

[ -z "$choice" ] && exit 1

# Setup format and output path
if [ "$choice" = "Video (MP4 with AAC)" ]; then
    outpath="$HOME/Videos/%(title).200s.%(ext)s"
    format="bv*[ext=mp4]+ba[acodec^=mp4a]/b[ext=mp4]/b"
    opts=(--merge-output-format mp4)
else
    outpath="$HOME/Music/%(title).200s.%(ext)s"
    format="bestaudio"
    opts=(--extract-audio --audio-format mp3)
fi

# Launch the download in background and show progress bar
(
    yt-dlp "$url" \
        -f "$format" \
        "${opts[@]}" \
        --embed-thumbnail \
        --embed-metadata \
        --add-metadata \
        --audio-quality 0 \
        --no-mtime \
        --newline \
        --progress-template "download:%(progress._percent_str)s" \
        -o "$outpath" 2>&1 |
    while read -r line; do
        if [[ "$line" =~ ([0-9]{1,3}\.[0-9])% ]]; then
            percent=${BASH_REMATCH[1]}
            echo "${percent%.*}"
        fi
    done
) |
zenity --progress \
    --title="Downloader" \
    --text="Downloading..." \
    --percentage=0 \
    --auto-close \
    --width=400 \
    --window-icon=info

# Completion notification
if [ $? -eq 0 ]; then
    notify-send "Downloader" "Download completed."
else
    notify-send "Downloader" "Download cancelled or failed."
fi
EOF

# Make the script executable
chmod +x ~/Scripts/yt-dlp.sh

success "yt-dlp.sh script installed and configured"

# ============================================================================
# SYSTEM UPDATE AND ESSENTIAL PACKAGES
# ============================================================================

print_header "SYSTEM UPDATE AND ESSENTIAL PACKAGES"

log "Updating system packages..."
sudo pacman -Syu --noconfirm

log "Installing essential base packages..."
sudo pacman -S --needed --noconfirm \
    base-devel \
    git \
    wget \
    curl \
    unzip \
    vim \
    nano \
    btop \
    tree \
    rsync \
    man-db \
    man-pages \
    bash-completion \
    net-tools \
    libxcrypt-compat \
    yt-dlp \
    zenity \
    cava \
    obs-studio \
    kitty \
    imagemagick

success "Essential packages installed successfully"

# Deteksi apakah menggunakan GNOME
if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then
  echo "🟢 Detected GNOME. Applying GNOME-specific workspace config..."

  for i in {1..9}; do
  # Remove Super + [1-9] default app shortcuts
    gsettings set org.gnome.shell.keybindings switch-to-application-$i "[]"
  
    # Super + [1-9] => switch workspace
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-$i "['<Super>$i']"

    # Super + Shift + [1-9] => move window
    gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-$i "['<Super><Shift>$i']"
  done

  echo "✅ GNOME-specific keybindings updated."
else
  echo "⚠️ Not GNOME. Skipping GNOME-specific config..."
fi


# ============================================================================
# OPTIONAL INTEL HARDWARE SUPPORT (Alder Lake + Iris Xe)
# ============================================================================

INSTALL_INTEL_HW=false
if prompt_yes_no "Install Intel hardware support (Alder Lake + Iris Xe graphics, microcode, power management)?"; then
    INSTALL_INTEL_HW=true
fi

if [ "$INSTALL_INTEL_HW" = true ]; then
    print_header "INTEL HARDWARE SUPPORT (ALDER LAKE + IRIS XE)"

    log "Installing Intel CPU and GPU support for Alder Lake..."

    # Intel microcode and graphics drivers (minimal set)
    sudo pacman -S --needed --noconfirm \
        intel-ucode \
        mesa \
        vulkan-intel \
        intel-media-driver \
        libva-intel-driver \
        libva-utils \
        intel-gpu-tools \
        intel-compute-runtime \
        vpl-gpu-rt

    # Power management
    log "Installing power management tools..."
    sudo pacman -S --needed --noconfirm power-profiles-daemon
    sudo systemctl enable power-profiles-daemon

    success "Intel hardware support configured"
fi

# ============================================================================
# NETWORK TOOLS
# ============================================================================

print_header "NETWORK CONFIGURATION"

log "Installing network tools..."
sudo pacman -S --needed --noconfirm \
    networkmanager \
    network-manager-applet \
    wireless_tools \
    wpa_supplicant

# Enable NetworkManager
sudo systemctl enable NetworkManager

success "Network tools configured"

# ============================================================================
# AUR HELPER INSTALLATION (PARU)
# ============================================================================

print_header "AUR HELPER INSTALLATION"

log "Installing Paru AUR helper..."
if ! command -v paru &> /dev/null; then
    cd /tmp
    git clone https://aur.archlinux.org/paru-bin.git
    cd paru-bin
    makepkg -si --noconfirm
    cd ~
    rm -rf /tmp/paru-bin
    success "Paru installed successfully"
else
    log "Paru already installed"
fi

# ============================================================================
# FLATPAK SUPPORT
# ============================================================================

print_header "FLATPAK SUPPORT"

log "Installing Flatpak support..."
sudo pacman -S --needed --noconfirm flatpak

# Add Flathub repository
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

success "Flatpak support configured"

# ============================================================================
# DEVELOPMENT TOOLS
# ============================================================================

print_header "DEVELOPMENT TOOLS"

# Visual Studio Code
log "Installing Visual Studio Code..."
paru -S --needed --noconfirm visual-studio-code-bin

# Google Chrome
log "Installing Google Chrome..."
paru -S --needed --noconfirm google-chrome

# Install dependencies for Python compilation
sudo pacman -S --needed --noconfirm \
    make \
    openssl \
    zlib \
    bzip2 \
    readline \
    sqlite \
    llvm \
    ncurses \
    xz \
    tk \
    libxml2 \
    libxslt \
    libffi

# Docker for Laravel Sail
log "Installing Docker..."
sudo pacman -S --needed --noconfirm \
    docker \
    docker-compose \
    docker-buildx

# Enable Docker service and add user to docker group
sudo systemctl enable docker
sudo usermod -aG docker $USER

success "Development tools installed successfully"

# ============================================================================
# NODE.JS INSTALLATION (OFFICIAL NVM)
# ============================================================================

print_header "NODE.JS INSTALLATION (OFFICIAL NVM)"

log "Installing NVM from official repository..."
if [ ! -d "$HOME/.nvm" ]; then
    # Get latest NVM version from GitHub
    NVM_VERSION=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh" | bash
    
    success "NVM installed successfully"
else
    log "NVM already installed"
fi

# Source NVM for current session
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Install Node.js LTS if NVM is available
if command -v nvm &> /dev/null; then
    log "Installing Node.js LTS..."
    nvm install --lts
    nvm use --lts
    nvm alias default lts/*
    success "Node.js LTS installed and set as default"
else
    warning "NVM not available in current session. Node.js will be available after shell restart."
fi

# ============================================================================
# PYTHON INSTALLATION (OFFICIAL PYENV)
# ============================================================================

print_header "PYTHON INSTALLATION (OFFICIAL PYENV)"

log "Installing Pyenv from official repository..."
if [ ! -d "$HOME/.pyenv" ]; then
    curl https://pyenv.run | bash
    success "Pyenv installed successfully"
else
    log "Pyenv already installed"
fi

success "Pyenv configured - will be available after shell restart"

# ============================================================================
# FONTS INSTALLATION
# ============================================================================

print_header "FONTS INSTALLATION"

log "Installing essential fonts..."
sudo pacman -S --needed --noconfirm \
    ttf-liberation \
    ttf-dejavu \
    noto-fonts \
    noto-fonts-cjk \
    noto-fonts-extra \
    noto-fonts-emoji \
    ttf-jetbrains-mono-nerd

# Microsoft fonts for better compatibility
log "Installing Microsoft fonts..."
paru -S --needed --noconfirm ttf-ms-fonts

# Install neofetch from AUR
log "Installing hyprland packages from AUR..."

paru -Rns --noconfirm dolphin wofi

paru -S --needed --noconfirm \
    # System info & tweaks
    neofetch nwg-look papirus-folders-catppuccin-git catppuccin-gtk-theme-mocha papirus-icon-theme otf-font-awesome \
    \
    # Hyprland utilities
    wlogout hypridle hyprpicker swww waybar rofi dunst brightnessctl wl-clipboard \
    \
    # File management
    thunar thunar-archive-plugin thunar-volman gvfs gvfs-afc xarchiver \
    \
    # Media
    mpd rmpc pavucontrol \
    \
    # Connectivity
    blueman \
    \
    # Apps
    discord

systemctl --user enable --now mpd
papirus-folder -c cat-mocha-lavender --theme Papirus-Dark

git clone -b main --depth=1 https://github.com/uiriansan/SilentSDDM && cd SilentSDDM && ./install.sh
cd ~

success "Package installation completed"

# ============================================================================
# SHELL SETUP (ZSH + OH-MY-ZSH + STARSHIP)
# ============================================================================

print_header "SHELL CONFIGURATION"

log "Installing Zsh and Starship..."
sudo pacman -S --needed --noconfirm zsh starship

# Install Oh-My-Zsh
log "Installing Oh-My-Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Install essential Zsh plugins
log "Installing essential Zsh plugins..."

# zsh-autosuggestions
if [ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
fi

# zsh-syntax-highlighting
if [ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
fi

# you-should-use
if [ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/you-should-use" ]; then
    git clone https://github.com/MichaelAquilina/zsh-you-should-use.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/you-should-use
fi

# Install additional shell tools
log "Installing additional shell tools..."
sudo pacman -S --needed --noconfirm bat exa

# Configure Starship with Catppuccin Powerline preset
log "Configuring Starship with Catppuccin Powerline preset..."
mkdir -p ~/.config
starship preset nerd-font-symbols -o ~/.config/starship.toml

# Create enhanced .zshrc
log "Configuring enhanced .zshrc..."
cat > ~/.zshrc << 'EOF'
# Oh My Zsh configuration
export ZSH="$HOME/.oh-my-zsh"

# Use Starship instead of Oh My Zsh themes
ZSH_THEME=""

# Essential plugins
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    nvm
    docker
    docker-compose
    archlinux
    you-should-use
    pyenv
    python
)

source $ZSH/oh-my-zsh.sh

# Initialize Starship
eval "$(starship init zsh)"

# Essential aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias cat='bat --style=plain'
alias ls='exa --icons'

# Pacman aliases
alias pacup='sudo pacman -Syu'                    # Update system
alias pacin='sudo pacman -S'                      # Install package
alias pacrem='sudo pacman -Rns'                   # Remove package with dependencies
alias pacsearch='pacman -Ss'                      # Search packages
alias pacinfo='pacman -Si'                        # Package info
alias paclist='pacman -Q'                         # List installed packages
alias pacorphan='sudo pacman -Rns $(pacman -Qtdq)' # Remove orphaned packages
alias pacclean='sudo pacman -Sc'                  # Clean package cache
alias pacupgrade='sudo pacman -Syu && paru -Sua'  # Full system upgrade (official + AUR)

# Laravel Sail alias
alias sail='[ -f sail ] && bash sail || bash vendor/bin/sail'

# Docker aliases
alias d='docker'
alias dc='docker-compose'
alias dps='docker ps'
alias di='docker images'

# NVM initialization
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Pyenv initialization (following official guide)
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# Scripts directory
export PATH="$HOME/Scripts:$PATH"
EOF

# Create .zprofile for environment variables (following official pyenv guide)
log "Creating .zprofile for environment setup..."
cat > ~/.zprofile << 'EOF'
# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Pyenv (following official installation guide)
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# Scripts directory
export PATH="$HOME/Scripts:$PATH"
EOF

# Also add to PATH in .zshrc and .zprofile for Scripts
log "Adding ~/Scripts to PATH..."

# Make sure Scripts PATH is in both files
if ! grep -q 'export PATH="$HOME/Scripts:$PATH"' ~/.zshrc; then
    echo 'export PATH="$HOME/Scripts:$PATH"' >> ~/.zshrc
fi

if ! grep -q 'export PATH="$HOME/Scripts:$PATH"' ~/.zprofile; then
    echo 'export PATH="$HOME/Scripts:$PATH"' >> ~/.zprofile
fi

# Change default shell to zsh
if [ "$SHELL" != "$(which zsh)" ]; then
    log "Changing default shell to zsh..."
    chsh -s $(which zsh)
fi

success "Shell configuration completed with Starship and Catppuccin Powerline preset"

# ============================================================================
# CLEANUP AND OPTIMIZATION
# ============================================================================

print_header "CLEANUP AND OPTIMIZATION"

log "Cleaning up system..."

# Remove orphaned packages (only if there are any)
orphans=$(pacman -Qtdq 2>/dev/null)
if [ -n "$orphans" ]; then
    sudo pacman -Rns $orphans --noconfirm
    log "Removed orphaned packages"
else
    log "No orphaned packages found"
fi

# Clear AUR cache
paru -Sc --noconfirm

# Update font cache
fc-cache -fv

success "System cleanup completed"

# ============================================================================
# COMPLETION MESSAGE
# ============================================================================

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

print_header "INSTALLATION SUMMARY"

echo ""
success "Enhanced Arch Linux Developer Environment Setup Complete!"
echo ""
echo -e "${CYAN}Installed Components:${NC}"
if [ "$INSTALL_INTEL_HW" = true ]; then
    echo -e "  ${GREEN}✓${NC} Intel Alder Lake CPU/GPU support with microcode"
    echo -e "  ${GREEN}✓${NC} Power management and hardware optimization"
fi
echo -e "  ${GREEN}✓${NC} Essential system tools (btop, neofetch, yt-dlp, cava, zenity, obs-studio, kitty, imagemagick)"
echo -e "  ${GREEN}✓${NC} Development tools:"
echo -e "    ${BLUE}•${NC} VS Code, Google Chrome"
echo -e "    ${BLUE}•${NC} Node.js LTS via official NVM"
echo -e "    ${BLUE}•${NC} Pyenv (official installation with proper .zprofile setup)"
echo -e "    ${BLUE}•${NC} Docker with official CE plugins"
echo -e "  ${GREEN}✓${NC} Enhanced shell environment:"
echo -e "    ${BLUE}•${NC} Zsh with Oh-My-Zsh"
echo -e "    ${BLUE}•${NC} Starship prompt with Catppuccin Powerline preset"
echo -e "    ${BLUE}•${NC} Essential plugins and aliases"
echo -e "    ${BLUE}•${NC} Proper .zprofile configuration following official guides"
echo -e "  ${GREEN}✓${NC} Custom scripts:"
echo -e "    ${BLUE}•${NC} yt-dlp.sh GUI downloader in ~/Scripts"
echo -e "  ${GREEN}✓${NC} Fonts: JetBrains Mono Nerd Font + system fonts"
echo -e "  ${GREEN}✓${NC} Flatpak support ready for additional applications"
if [ -d "$SCRIPT_DIR/.config" ]; then
    echo -e "  ${GREEN}✓${NC} Custom .config folder copied from script directory"
fi
echo -e "  ${GREEN}✓${NC} System optimized and cleaned"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo -e "  ${BLUE}1.${NC} Reboot your system: ${WHITE}sudo reboot${NC}"
echo -e "  ${BLUE}2.${NC} Your new shell (Zsh) will load with Starship + Catppuccin Powerline theme"
echo -e "  ${BLUE}3.${NC} Docker group membership will be active after reboot"
echo -e "  ${BLUE}4.${NC} Use ${WHITE}nvm list${NC} to see installed Node.js versions"
echo -e "  ${BLUE}5.${NC} Install Python: ${WHITE}pyenv install 3.12.7 && pyenv global 3.12.7${NC}"
echo -e "  ${BLUE}6.${NC} Try ${WHITE}cava${NC} for audio visualization"
echo -e "  ${BLUE}7.${NC} Use ${WHITE}yt-dlp.sh${NC} for GUI-based video/audio downloads"
echo -e "  ${BLUE}8.${NC} Use ${WHITE}kitty${NC} as your terminal emulator"
echo -e "  ${BLUE}9.${NC} Starship theme can be customized at ${WHITE}~/.config/starship.toml${NC}"
echo ""
if prompt_yes_no "Reboot now?"; then
    echo -e "${GREEN}✓${NC} Rebooting system..."
    sudo reboot
else
    echo -e "${BLUE}ℹ${NC} Reboot skipped. Please reboot manually when ready: ${WHITE}sudo reboot${NC}"
    echo -e "${YELLOW}Note:${NC} Docker group membership and shell changes require a reboot to take effect."
fi
