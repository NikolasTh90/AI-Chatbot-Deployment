#!/bin/bash

# System Packages Setup Script
# Installs essential system packages using nala package manager

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

# Ensure nala is installed and up to date
ensure_nala() {
    if ! command_exists "nala"; then
        log "Installing nala package manager..."
        sudo apt update
        sudo apt install -y nala
        success "Nala installed successfully"
    else
        success "Nala is already available"
    fi
    
    log "Updating package lists with nala..."
    sudo nala update
}

# Install essential system packages
install_system_essentials() {
    log "Installing essential system packages..."
    
    local packages=(
        # Build tools
        "build-essential"
        "software-properties-common"
        "apt-transport-https"
        "ca-certificates"
        "gnupg"
        "lsb-release"
        
        # Basic utilities
        "curl"
        "wget"
        "unzip"
        "zip"
        "tar"
        "gzip"
        "tree"
        "jq"
        "rsync"
        
        # Text editors
        "vim"
        "nano"
        
        # Terminal multiplexers
        "tmux"
        "screen"
        
        # System monitoring
        "htop"
        "iotop"
        "iftop"
        "ncdu"
        "nethogs"
        "nload"
        "dstat"
        "sysstat"
        "lsof"
        "strace"
        
        # Network tools
        "tcpdump"
        "net-tools"
        "netstat"
        
        # Development tools
        "git"
        "make"
        "cmake"
        
        # Python development
        "python3"
        "python3-pip"
        "python3-venv"
        "python3-dev"
    )
    
    log "Installing ${#packages[@]} essential packages..."
    sudo nala install -y "${packages[@]}"
    success "Essential packages installed successfully"
}

# Install Node.js using NodeSource repository
install_nodejs() {
    if command_exists "node"; then
        success "Node.js is already installed ($(node --version))"
        return 0
    fi
    
    log "Installing Node.js LTS..."
    
    # Add NodeSource repository
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    
    # Install Node.js
    sudo nala install -y nodejs
    
    success "Node.js installed successfully ($(node --version))"
}

# Install Helix editor from GitHub releases
install_helix() {
    if command_exists "hx"; then
        success "Helix editor is already installed ($(hx --version | head -1))"
        return 0
    fi
    
    log "Installing Helix editor..."
    
    # Create temporary directory
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    # Get latest release info
    local latest_url
    latest_url=$(curl -s https://api.github.com/repos/helix-editor/helix/releases/latest | \
        grep -o 'https://github.com/helix-editor/helix/releases/download/[^"]*helix-[^"]*-x86_64-linux.tar.xz' | \
        head -1)
    
    if [[ -z "$latest_url" ]]; then
        error "Could not find Helix download URL for x86_64 Linux"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    log "Downloading Helix from: $latest_url"
    wget -q "$latest_url" -O helix.tar.xz
    
    # Extract and install
    tar -xf helix.tar.xz
    local helix_dir
    helix_dir=$(find . -name "helix-*" -type d | head -1)
    
    if [[ -z "$helix_dir" ]]; then
        error "Could not find extracted Helix directory"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Install binaries and runtime
    sudo cp "$helix_dir/hx" /usr/local/bin/
    sudo mkdir -p /usr/local/share/helix
    sudo cp -r "$helix_dir/runtime" /usr/local/share/helix/
    
    # Make executable
    sudo chmod +x /usr/local/bin/hx
    
    # Clean up
    cd - > /dev/null
    rm -rf "$temp_dir"
    
    success "Helix editor installed successfully"
}

# Configure Git if not already configured
configure_git() {
    if ! command_exists "git"; then
        warning "Git is not installed"
        return 1
    fi
    
    local git_user_name
    local git_user_email
    
    git_user_name=$(git config --global user.name 2>/dev/null || echo "")
    git_user_email=$(git config --global user.email 2>/dev/null || echo "")
    
    if [[ -z "$git_user_name" ]] || [[ -z "$git_user_email" ]]; then
        warning "Git is not configured with user information."
        log "You can configure it later with:"
        log "  git config --global user.name 'Your Name'"
        log "  git config --global user.email 'your.email@example.com'"
    else
        success "Git is configured for user: $git_user_name ($git_user_email)"
    fi
}

# Clean up package cache
cleanup_packages() {
    log "Cleaning up package cache..."
    sudo nala clean
    sudo nala autoremove -y
    success "Package cleanup completed"
}

# Display installed versions
show_installed_versions() {
    log "Installed package versions:"
    
    # System info
    echo "OS: $(lsb_release -d | cut -f2)"
    echo "Kernel: $(uname -r)"
    
    # Core tools
    command_exists "git" && echo "Git: $(git --version | cut -d' ' -f3)"
    command_exists "python3" && echo "Python: $(python3 --version | cut -d' ' -f2)"
    command_exists "node" && echo "Node.js: $(node --version)"
    command_exists "npm" && echo "npm: $(npm --version)"
    command_exists "hx" && echo "Helix: $(hx --version | head -1 | cut -d' ' -f2)"
    command_exists "docker" && echo "Docker: $(docker --version | cut -d' ' -f3 | tr -d ',')"
    command_exists "nala" && echo "Nala: $(nala --version | head -1 | cut -d' ' -f2)"
}

# Main function
main() {
    log "Starting system packages installation..."
    
    # Ensure nala is available and updated
    ensure_nala
    
    # Install essential system packages
    install_system_essentials
    
    # Install Node.js
    install_nodejs
    
    # Install Helix editor
    install_helix
    
    # Configure Git
    configure_git
    
    # Clean up
    cleanup_packages
    
    # Show installed versions
    show_installed_versions
    
    success "System packages installation completed!"
    
    log "Next steps:"
    log "1. Install NVIDIA drivers if needed: ./scripts/setup-nvidia.sh"
    log "2. Install Docker: ./scripts/setup-docker.sh"
    log "3. Set up Portainer: ./portainer/setup-portainer.sh"
}

# Run main function
main "$@"