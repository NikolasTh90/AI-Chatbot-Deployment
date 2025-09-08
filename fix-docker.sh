#!/bin/bash

# Docker Configuration Fix Script
# Fixes the RLIMIT issue by removing problematic ulimits from daemon.json

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

# Fix Docker daemon configuration
fix_docker_config() {
    local daemon_config="/etc/docker/daemon.json"
    
    log "Fixing Docker daemon configuration..."
    
    # Backup existing config
    if [[ -f "$daemon_config" ]]; then
        sudo cp "$daemon_config" "${daemon_config}.backup"
        log "Backed up existing configuration to ${daemon_config}.backup"
    fi
    
    # Create corrected daemon.json without problematic ulimits
    sudo tee "$daemon_config" > /dev/null << 'EOF'
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    },
    "storage-driver": "overlay2",
    "live-restore": true,
    "userland-proxy": false,
    "experimental": false,
    "metrics-addr": "127.0.0.1:9323"
}
EOF
    
    success "Docker daemon configuration fixed"
}

# Restart Docker service
restart_docker() {
    log "Restarting Docker service..."
    
    sudo systemctl stop docker
    sleep 2
    sudo systemctl start docker
    sleep 5
    
    if sudo systemctl is-active docker > /dev/null; then
        success "Docker service restarted successfully"
    else
        error "Failed to restart Docker service"
        return 1
    fi
}

# Test Docker functionality
test_docker() {
    log "Testing Docker functionality..."
    
    if sudo docker run --rm hello-world > /dev/null 2>&1; then
        success "Docker is working correctly!"
        return 0
    else
        error "Docker test still failing"
        log "Checking Docker service status..."
        sudo systemctl status docker --no-pager -l
        return 1
    fi
}

# Create proxy network
create_proxy_network() {
    log "Creating proxy network..."
    
    if ! sudo docker network ls | grep -q "proxy"; then
        sudo docker network create proxy
        success "Proxy network created"
    else
        success "Proxy network already exists"
    fi
}

# Main execution
main() {
    log "Starting Docker configuration fix..."
    
    # Fix configuration
    fix_docker_config
    
    # Restart Docker
    restart_docker
    
    # Test Docker
    test_docker
    
    # Create proxy network
    create_proxy_network
    
    success "Docker fix completed!"
    log "You can now run: sudo docker run --rm hello-world"
    log "Or continue with the setup: ./setup.sh"
}

# Run main function
main "$@"