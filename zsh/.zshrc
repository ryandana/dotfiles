# Oh My Zsh configuration
export ZSH="$HOME/.oh-my-zsh"

# Use Starship instead of Oh My Zsh themes
ZSH_THEME=""

# Essential plugins
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    docker
    docker-compose
    archlinux
    you-should-use
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

# Scripts directory
export PATH="$HOME/Scripts:$PATH"

export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools
