#!/bin/bash

# Data Center Instance Setup Script
# For Ubuntu 24.04 LTS AWS G6 instances with NVIDIA GPU support
# Author: AI Assistant
# Version: 1.0

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
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

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root. Please run as a regular user with sudo privileges."
        exit 1
    fi
}

# Check if user has sudo privileges
check_sudo() {
    if ! sudo -n true 2>/dev/null; then
        error "This script requires sudo privileges. Please ensure your user can run sudo commands."
        exit 1
    fi
}

# Check if we're on Ubuntu 24.04
check_ubuntu_version() {
    if ! grep -q "Ubuntu 24.04" /etc/os-release; then
        warning "This script is designed for Ubuntu 24.04 LTS. Proceeding anyway, but some steps may fail."
    fi
}

# Update system packages
update_system() {
    log "Updating system packages..."
    sudo nala update || {
        warning "nala not found, installing nala first..."
        sudo apt update
        sudo apt install -y nala
        sudo nala update
    }
    sudo nala upgrade -y
    success "System packages updated"
}

main() {
    log "Starting Data Center Instance Setup..."
    log "Target: Ubuntu 24.04 LTS AWS G6 Instance with NVIDIA GPU"
    
    # Pre-flight checks
    check_root
    check_sudo
    check_ubuntu_version
    
    # Update system first
    update_system
    
    # Get script directory
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Run setup scripts in order
    log "Running system utilities setup..."
    bash "$SCRIPT_DIR/setup-system-utils.sh"
    
    log "Running NVIDIA GPU setup..."
    bash "$SCRIPT_DIR/setup-nvidia.sh"
    
    log "Running Docker setup..."
    bash "$SCRIPT_DIR/setup-docker.sh"
    
    log "Running Portainer setup..."
    # Get the project root directory (parent of scripts)
    PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
    bash "$PROJECT_ROOT/portainer/setup-portainer.sh"
    
    # Final system check
    log "Running post-installation verification..."
    bash "$SCRIPT_DIR/verify-setup.sh"
    
    success "Data center instance setup completed successfully!"
    log "Please reboot the system to ensure all changes take effect:"
    log "sudo reboot"
}

# Run main function
main "$@"