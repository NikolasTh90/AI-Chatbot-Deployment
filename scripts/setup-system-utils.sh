#!/bin/bash

# System Packages Setup Script  
# Installs essential system packages using nala package manager
# This script replaces the old setup-system-utils.sh with nala-based installation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if a package is installed
package_installed() {
    dpkg -l "$1" 2>/dev/null | grep -q '^ii'
}

# Install package if not already installed
install_if_missing() {
    local package=$1
    local command_name=${2:-$1}
    
    if command_exists "$command_name"; then
        success "$command_name is already installed"
        return 0
    fi
    
    if package_installed "$package"; then
        success "$package is already installed"
        return 0
    fi
    
    log "Installing $package..."
    sudo nala install -y "$package"
    success "$package installed successfully"
}

# Install Helix editor from GitHub releases
install_helix() {
    if command_exists "hx"; then
        success "Helix editor is already installed"
        return 0
    fi
    
    log "Installing Helix editor..."
    
    # Create temporary directory
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    # Get latest release info
    local latest_url=$(curl -s https://api.github.com/repos/helix-editor/helix/releases/latest | grep -o 'https://github.com/helix-editor/helix/releases/download/[^"]*linux.*\.tar\.xz')
    
    if [[ -z "$latest_url" ]]; then
        error "Could not find Helix download URL"
        return 1
    fi
    
    log "Downloading Helix from: $latest_url"
    wget -q "$latest_url" -O helix.tar.xz
    
    # Extract and install
    tar -xf helix.tar.xz
    local helix_dir=$(find . -name "helix-*" -type d | head -1)
    
    sudo cp "$helix_dir/hx" /usr/local/bin/
    sudo mkdir -p /usr/local/share/helix
    sudo cp -r "$helix_dir/runtime" /usr/local/share/helix/
    
    # Clean up
    cd - > /dev/null
    rm -rf "$temp_dir"
    
    success "Helix editor installed successfully"
}

# Install essential build tools and utilities
install_build_essentials() {
    log "Installing build essential tools..."
    
    local packages=(
        "build-essential"
        "software-properties-common"
        "apt-transport-https"
        "ca-certificates"
        "gnupg"
        "lsb-release"
        "curl"
        "wget"
        "unzip"
        "zip"
        "tree"
        "htop"
        "iotop"
        "iftop"
        "ncdu"
        "jq"
        "tmux"
        "screen"
        "rsync"
        "vim"
        "nano"
    )
    
    for package in "${packages[@]}"; do
        install_if_missing "$package"
    done
}

# Install development tools
install_dev_tools() {
    log "Installing development tools..."
    
    # Git
    install_if_missing "git" "git"
    
    # Python development tools
    install_if_missing "python3-pip" "pip3"
    install_if_missing "python3-venv" "python3"
    
    # Node.js (using NodeSource repository)
    if ! command_exists "node"; then
        log "Installing Node.js..."
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
        sudo nala install -y nodejs
        success "Node.js installed successfully"
    else
        success "Node.js is already installed"
    fi
}

# Configure Git (if not already configured)
configure_git() {
    if command_exists "git"; then
        if [[ -z $(git config --global user.name 2>/dev/null) ]] || [[ -z $(git config --global user.email 2>/dev/null) ]]; then
            warning "Git is not configured with user information."
            log "You can configure it later with:"
            log "git config --global user.name 'Your Name'"
            log "git config --global user.email 'your.email@example.com'"
        else
            success "Git is already configured"
        fi
    fi
}

# Install monitoring tools
install_monitoring_tools() {
    log "Installing monitoring tools..."
    
    local packages=(
        "nethogs"
        "nload"
        "dstat"
        "sysstat"
        "lsof"
        "strace"
        "tcpdump"
        "net-tools"
    )
    
    for package in "${packages[@]}"; do
        install_if_missing "$package"
    done
}

# Main function
main() {
    log "Setting up system utilities..."
    
    # Install essential packages
    install_build_essentials
    
    # Install development tools
    install_dev_tools
    
    # Install Helix editor
    install_helix
    
    # Install monitoring tools
    install_monitoring_tools
    
    # Configure Git
    configure_git
    
    success "System utilities setup completed!"
}

# Run main function
main "$@"