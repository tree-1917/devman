#!/bin/bash

# ==============================================================================
#  ____  _______     _____  ____  ____  
# |  _ \| ____\ \   / / _ \|  _ \/ ___| 
# | | | |  _|  \ \ / / | | | |_) \___ \ 
# | |_| | |___  \ V /| |_| |  __/ ___) |
# |____/|_____|  \_/  \___/|_|   |____/ 
#
# DevOps Zsh Environment Setup Script
# Target: Ubuntu/Debian/Arch Linux/macOS
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REMOTE_BASE_URL="https://raw.githubusercontent.com/tree-1917/Snama/main"

# Colors for output
readonly YELLOW='\033[1;33m'
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# ------------------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------------------
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# ------------------------------------------------------------------------------
# Banner
# ------------------------------------------------------------------------------
echo -e "${GREEN}"
echo "  ____  _______     _____  ____  ____  "
echo " |  _ \| ____\ \   / / _ \|  _ \/ ___| "
echo " | | | |  _|  \ \ / / | | | |_) \___ \ "
echo " | |_| | |___  \ V /| |_| |  __/ ___) |"
echo " |____/|_____|  \_/  \___/|_|   |____/ "
echo -e "${NC}"
log_info "Starting DevOps Zsh Environment Setup..."

# ------------------------------------------------------------------------------
# Detect OS and distribution
# ------------------------------------------------------------------------------
detect_pkg_manager() {
    # Prefer native package managers over Homebrew on Linux
    if [[ "$OSTYPE" == "darwin"* ]] && command_exists brew; then
        echo "brew"
    elif command_exists apt-get; then 
        echo "apt"
    elif command_exists pacman; then
        echo "pacman"
    elif command_exists dnf; then
        echo "dnf"
    elif command_exists yum; then 
        echo "yum"
    else
        echo "unknown"
    fi
}

PKG_MANAGER=$(detect_pkg_manager)
log_info "Detected Package Manager: $PKG_MANAGER"

# ------------------------------------------------------------------------------
# Install Zsh, Git, Curl, Awk if missing
# ------------------------------------------------------------------------------
install_packages() {
    case "$PKG_MANAGER" in
        apt)
            log_info "Using apt to install packages..."
            sudo apt-get update
            sudo apt-get install -y zsh git curl gawk
            ;;
        pacman)
            log_info "Using pacman to install packages..."
            sudo pacman -S --noconfirm zsh git curl gawk
            ;;
        brew)
            log_info "Using Homebrew to install packages..."
            brew install zsh git curl gawk
            ;;
        yum)
            log_info "Using yum to install packages..."
            sudo yum install -y zsh git curl gawk
            ;;
        dnf)
            log_info "Using dnf to install packages..."
            sudo dnf install -y zsh git curl gawk
            ;;
        *)
            log_error "Unsupported OS. Please install zsh, git, curl, and gawk manually."
            exit 1
            ;;
    esac
}

# Check if required commands exist, install if missing
MISSING=()
for cmd in zsh git curl awk; do
    if ! command_exists "$cmd"; then
        MISSING+=("$cmd")
    fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
    log_warn "Missing packages: ${MISSING[*]}. Installing..."
    install_packages
fi

# Verify installations succeeded
for cmd in zsh git curl awk; do
    if ! command_exists "$cmd"; then
        log_error "Failed to install $cmd. Please install it manually."
        exit 1
    fi
done

# ------------------------------------------------------------------------------
# Install Oh My Zsh
# ------------------------------------------------------------------------------
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    log_info "Installing Oh My Zsh..."
    RUNZSH=no CHSH=no sh -c \
        "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
        "" --unattended
    log_success "Oh My Zsh installed."
else
    log_info "Oh My Zsh already installed. Skipping..."
fi

# ------------------------------------------------------------------------------
# Clone required plugins and themes
# ------------------------------------------------------------------------------
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

clone_repo() {
    local repo_url="$1"
    local dest_dir="$2"
    local name="$3"

    if [ -d "$dest_dir" ]; then
        log_info "$name already exists. Pulling latest changes..."
        if git -C "$dest_dir" pull --ff-only 2>/dev/null; then
            log_success "$name updated."
        else
            log_warn "$name pull failed (possibly local changes). Skipping update."
        fi
    else
        log_info "Cloning $name..."
        if git clone --depth=1 "$repo_url" "$dest_dir"; then
            log_success "$name installed."
        else
            log_error "Failed to clone $name."
            exit 1
        fi
    fi
}

log_info "Setting up plugins and themes..."

clone_repo \
    "https://github.com/romkatv/powerlevel10k.git" \
    "$ZSH_CUSTOM/themes/powerlevel10k" \
    "Powerlevel10k Theme"

clone_repo \
    "https://github.com/zsh-users/zsh-autosuggestions" \
    "$ZSH_CUSTOM/plugins/zsh-autosuggestions" \
    "Zsh Autosuggestions"

clone_repo \
    "https://github.com/zsh-users/zsh-syntax-highlighting.git" \
    "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" \
    "Zsh Syntax Highlighting"

# ------------------------------------------------------------------------------
# Configure .zshrc
# ------------------------------------------------------------------------------
setup_zshrc() {
    local local_zshrc="$SCRIPT_DIR/.zshrc"
    local remote_zshrc_url="$REMOTE_BASE_URL/zshrc"
    local target="$HOME/.zshrc"

    # Backup existing .zshrc if present
    if [ -f "$target" ]; then
        local backup="$target.bak.$(date +%Y%m%d%H%M%S)"
        log_warn "Backing up existing .zshrc to $backup"
        cp "$target" "$backup"
    fi

    if [ -f "$local_zshrc" ]; then
        cp "$local_zshrc" "$target"
        log_success "Copied local .zshrc configuration."
    else
        log_warn "No local .zshrc found in $SCRIPT_DIR. Downloading from remote..."
        if curl -fsSL "$remote_zshrc_url" -o "$target"; then
            log_success "Remote .zshrc applied successfully."
        else
            log_error "Failed to download configuration from remote repo."
            exit 1
        fi
    fi
}

setup_zshrc

# ------------------------------------------------------------------------------
# Initialize snippets file
# ------------------------------------------------------------------------------
setup_snippets() {
    local local_snippets="$SCRIPT_DIR/.zsh_snippets_history"
    local remote_snippets_url="$REMOTE_BASE_URL/zsh_snippets_history"
    local target="$HOME/.zsh_snippets_history"

    if [ -f "$local_snippets" ]; then
        cp "$local_snippets" "$target"
        log_success "Copied provided .zsh_snippets_history configuration."
    elif [ -f "$target" ]; then
        log_info "Existing .zsh_snippets_history found. Keeping it."
    else
        log_warn "No local .zsh_snippets_history found. Downloading from remote..."
        if curl -fsSL "$remote_snippets_url" -o "$target"; then
            log_success "Remote .zsh_snippets_history downloaded successfully."
        else
            log_error "Failed to download snippets from remote repo."
            exit 1
        fi
    fi
}

setup_snippets

# ------------------------------------------------------------------------------
# Set Zsh as default shell (safely)
# ------------------------------------------------------------------------------
set_default_shell() {
    local zsh_path
    zsh_path=$(command -v zsh)

    if [ "$SHELL" = "$zsh_path" ]; then
        log_success "Zsh is already the default shell."
        return 0
    fi

    # Ensure zsh is in /etc/shells (required by chsh on many systems)
    if ! grep -qx "$zsh_path" /etc/shells 2>/dev/null; then
        log_warn "$zsh_path not found in /etc/shells. Attempting to add it..."
        if command_exists sudo; then
            echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
        else
            log_warn "Cannot add zsh to /etc/shells without sudo. You may need to run: sudo sh -c 'echo $zsh_path >> /etc/shells'"
        fi
    fi

    log_info "Setting zsh as default shell..."
    if chsh -s "$zsh_path" 2>/dev/null; then
        log_success "Zsh is now the default shell."
        log_warn "Please log out and back in for the change to take effect."
    else
        log_warn "Could not change default shell automatically (may require password)."
        log_info "Please run manually: chsh -s $zsh_path"
    fi
}

set_default_shell

# ------------------------------------------------------------------------------
# Finalize
# ------------------------------------------------------------------------------
echo ""
log_success "Setup Complete!"
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Restart your terminal or run: ${GREEN}exec zsh${NC}"
echo "  2. To configure your theme, run: ${GREEN}p10k configure${NC}"
echo ""
