#!/bin/bash

# ==============================================================================
#  ____  _______     _____  ____  ____  
# |  _ \| ____\ \   / / _ \|  _ \/ ___| 
# | | | |  _|  \ \ / / | | | |_) \___ \ 
# | |_| | |___  \ V /| |_| |  __/ ___) |
# |____/|_____|  \_/  \___/|_|   |____/ 
#
# DevOps Zsh Environment Setup Script
# Target: Ubuntu/Debian/Arch Linux/MacOS
# ==============================================================================

set -e  

# Colors for output
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}"
echo "  ____  _______     _____  ____  ____  "
echo " |  _ \| ____\ \   / / _ \|  _ \/ ___| "
echo " | | | |  _|  \ \ / / | | | |_) \___ \ "
echo " | |_| | |___  \ V /| |_| |  __/ ___) |"
echo " |____/|_____|  \_/  \___/|_|   |____/ "
echo -e "${NC}"

echo -e "${YELLOW}Starting DevOps Zsh Environment Setup...${NC}"

# ------------------------------------------------------------------------------
# Detect OS and distribution
# ------------------------------------------------------------------------------
detect_pkg_manager() {
    if command -v brew > /dev/null 2>&1; then 
        echo "brew"
    elif command -v apt-get > /dev/null 2>&1; then 
        echo "apt"
    elif command -v pacman > /dev/null 2>&1; then
        echo "pacman"
    elif command -v dnf > /dev/null 2>&1; then
        echo "dnf"
    elif command -v yum > /dev/null 2>&1; then 
        echo "yum"
    fi
}

PKG_MANAGER=$(detect_pkg_manager)
echo -e "${YELLOW}Detected Package Manager: $PKG_MANAGER${NC}"

# ------------------------------------------------------------------------------
# Install Zsh, Git, Curl, Awk if missing
# ------------------------------------------------------------------------------
install_packages() {
    case "$PKG_MANAGER" in
        apt)
            echo -e "${YELLOW}Using apt to install packages...${NC}"
            sudo apt update
            sudo apt install -y zsh git curl gawk
            ;;
        pacman)
            echo -e "${YELLOW}Using pacman to install packages...${NC}"
            sudo pacman -S --noconfirm zsh git curl gawk
            ;;
        brew)
            echo -e "${YELLOW}Using Homebrew to install packages...${NC}"
            brew install zsh git curl gawk
            ;;
        yum)
            echo -e "${YELLOW}Using yum to install packages...${NC}"
            sudo yum install -y zsh git curl gawk
            ;;
        dnf)
            echo -e "${YELLOW}Using dnf to install packages...${NC}"
            sudo dnf install -y zsh git curl gawk
            ;;
        *)
            echo -e "${RED}Unsupported OS. Please install zsh, git, curl, and awk manually.${NC}"
            exit 1
            ;;
    esac
}

# Check if required commands exist, install if missing
MISSING=()
for cmd in zsh git curl awk; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        MISSING+=("$cmd")
    fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
    echo -e "${YELLOW}Missing packages: ${MISSING[*]}. Installing...${NC}"
    install_packages
fi

# ------------------------------------------------------------------------------
# Install Oh My Zsh
# ------------------------------------------------------------------------------
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo -e "${YELLOW}Installing Oh My Zsh...${NC}"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# ------------------------------------------------------------------------------
# Clone required plugins and themes
# ------------------------------------------------------------------------------
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

echo -e "${YELLOW}Cloning plugins and themes...${NC}"

# Powerlevel10k Theme
if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
fi

# Zsh Autosuggestions
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

# Zsh Syntax Highlighting
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# ------------------------------------------------------------------------------
# Configure .zshrc
# ------------------------------------------------------------------------------
if [ -f "$HOME/.zshrc" ]; then
    echo -e "${YELLOW}Backing up existing .zshrc to .zshrc.bak${NC}"
    mv "$HOME/.zshrc" "$HOME/.zshrc.bak"
fi

# Logic to handle .zshrc setup
if [ -f ".zshrc" ]; then
    cp .zshrc "$HOME/.zshrc"
    echo -e "${GREEN}Copied local .zshrc configuration.${NC}"
else
    echo -e "${YELLOW}No local .zshrc found. Download remote repo...${NC}"
    if curl -fsSL "https://raw.githubusercontent.com/tree-1917/Snama/main/zshrc" -o "$HOME/.zshrc" ; then 
        echo "${GREEN}Remote .zshrc applied successfully.${NC}"        
    else 
        echo "${RED}Failed to download configuration from remote repo...${NC}"
        exit 1 
    fi
    echo -e "${GREEN}Default .zshrc created.${NC}"
fi

# ------------------------------------------------------------------------------
# Initialize snippets file
# ------------------------------------------------------------------------------
ZSH_SNIPPETS_FILE="$HOME/.zsh_snippets_history"
if [ -f ".zsh_snippets_history" ]; then
    cp .zsh_snippets_history "$ZSH_SNIPPETS_FILE"
    echo -e "${GREEN}Copied provided .zsh_snippets_history configuration.${NC}"
elif [ ! -f "$ZSH_SNIPPETS_FILE" ]; then
    echo -e "${YELLOW}No local .zsh_snippets_history found. Download remote repo...${NC}"
    if curl -fsSL "https://raw.githubusercontent.com/tree-1917/Snama/main/zsh_snippets_history" -o "$HOME/.zsh_snippets_history" ; then 
        echo "${GREEN}Remote .zsh_snippets_history updated current snippets.${NC}"        
    else 
        echo "${RED}Failed to download snippets from remote repo...${NC}"
        exit 1 
    fi
    echo -e "${YELLOW}Initialized empty snippets file at $ZSH_SNIPPETS_FILE${NC}"
fi

# ------------------------------------------------------------------------------
# Finalize
# ------------------------------------------------------------------------------
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${YELLOW}Please restart your terminal or run: exec zsh${NC}"
echo -e "${YELLOW}To configure your theme, run: p10k configure${NC}"
if [ "$SHELL" != "$(which zsh)" ]; then 
    echo -e "${YELLOW} Setting zsh as default shell... ${NC}"
    chsh -s "$(which zsh)"
    echo -e "${GREEN}Zsh is now default shell. Please log out and back in.${NC}"
fi
