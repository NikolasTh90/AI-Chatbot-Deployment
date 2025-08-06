#!/bin/bash

# Docker and Docker Compose Setup Script
# Installs Docker Engine and Docker Compose with NVIDIA GPU support

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

# Check if Docker is installed
docker_installed() {
    if command -v docker >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Check if Docker Compose is installed
docker_compose_installed() {
    if docker compose version >/dev/null 2>&1; then
        return 0
    elif command -v docker-compose >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Remove old Docker versions if they exist
remove_old_docker() {
    log "Checking for old Docker installations..."
    
    local old_packages=(
        "docker.io"
        "docker-doc"
        "docker-compose"
        "docker-compose-v2"
        "podman-docker"
        "containerd"
        "runc"
    )
    
    local to_remove=()
    for package in "${old_packages[@]}"; do
        if dpkg -l "$package" 2>/dev/null | grep -q '^ii'; then
            to_remove+=("$package")
        fi
    done
    
    if [[ ${#to_remove[@]} -gt 0 ]]; then
        warning "Found old Docker packages: ${to_remove[*]}"
        log "Removing old Docker packages..."
        sudo nala remove -y "${to_remove[@]}" || true
        success "Old Docker packages removed"
    else
        success "No old Docker packages found"
    fi
}

# Install Docker Engine
install_docker() {
    if docker_installed; then
        success "Docker is already installed"
        docker --version
        return 0
    fi
    
    log "Installing Docker Engine..."
    
    # Remove old versions
    remove_old_docker
    
    # Install prerequisites
    sudo nala update
    sudo nala install -y ca-certificates curl gnupg lsb-release
    
    # Add Docker's official GPG key
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    
    # Add Docker repository
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Update package index
    sudo nala update
    
    # Install Docker Engine, containerd, and Docker Compose
    sudo nala install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Start and enable Docker service
    sudo systemctl start docker
    sudo systemctl enable docker
    
    success "Docker Engine installed successfully"
    docker --version
}

# Add user to docker group
configure_docker_user() {
    local current_user=$(whoami)
    
    if groups "$current_user" | grep -q docker; then
        success "User $current_user is already in the docker group"
        return 0
    fi
    
    log "Adding user $current_user to docker group..."
    sudo usermod -aG docker "$current_user"
    
    success "User $current_user added to docker group"
    warning "Please log out and log back in (or run 'newgrp docker') for group changes to take effect"
}

# Configure Docker daemon for optimal performance
configure_docker_daemon() {
    local daemon_config="/etc/docker/daemon.json"
    
    log "Configuring Docker daemon..."
    
    # Create daemon.json if it doesn't exist
    if [[ ! -f "$daemon_config" ]]; then
        sudo mkdir -p /etc/docker
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
    "metrics-addr": "127.0.0.1:9323",
    "default-ulimits": {
        "nofile": {
            "hard": 64000,
            "soft": 64000
        }
    }
}
EOF
        success "Docker daemon configuration created"
    else
        success "Docker daemon configuration already exists"
    fi
}

# Configure NVIDIA runtime for Docker
configure_nvidia_runtime() {
    if ! command -v nvidia-container-runtime >/dev/null 2>&1; then
        warning "NVIDIA Container Toolkit not found. GPU support will be configured by the NVIDIA setup script."
        return 0
    fi
    
    log "Configuring NVIDIA runtime for Docker..."
    
    # Configure NVIDIA Container Runtime
    sudo nvidia-ctk runtime configure --runtime=docker
    
    # Test if nvidia runtime is configured
    if sudo docker info 2>/dev/null | grep -q nvidia; then
        success "NVIDIA runtime configured successfully"
    else
        warning "NVIDIA runtime configuration may need Docker restart"
    fi
}

# Install Docker Compose standalone (backup)
install_docker_compose_standalone() {
    if command -v docker-compose >/dev/null 2>&1; then
        success "Docker Compose standalone is already installed"
        return 0
    fi
    
    log "Installing Docker Compose standalone as backup..."
    
    # Get latest Docker Compose version
    local compose_version=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -o '"tag_name": "[^"]*' | cut -d'"' -f4)
    
    if [[ -z "$compose_version" ]]; then
        warning "Could not fetch latest Docker Compose version"
        return 1
    fi
    
    log "Installing Docker Compose $compose_version..."
    
    # Download and install
    sudo curl -L "https://github.com/docker/compose/releases/download/${compose_version}/docker-compose-$(uname -s)-$(uname -m)" \
        -o /usr/local/bin/docker-compose
    
    sudo chmod +x /usr/local/bin/docker-compose
    
    success "Docker Compose standalone installed"
    docker-compose --version
}

# Test Docker installation
test_docker() {
    log "Testing Docker installation..."
    
    # Test Docker engine
    if sudo docker run --rm hello-world > /dev/null 2>&1; then
        success "Docker engine is working correctly"
    else
        error "Docker engine test failed"
        return 1
    fi
    
    # Test Docker Compose plugin
    if docker compose version > /dev/null 2>&1; then
        success "Docker Compose plugin is working"
        docker compose version
    else
        warning "Docker Compose plugin not working, testing standalone version..."
        if command -v docker-compose >/dev/null 2>&1; then
            success "Docker Compose standalone is working"
            docker-compose --version
        else
            error "Neither Docker Compose plugin nor standalone version is working"
        fi
    fi
    
    # Test NVIDIA GPU support if available
    if command -v nvidia-container-runtime >/dev/null 2>&1; then
        log "Testing Docker NVIDIA GPU support..."
        if sudo docker run --rm --gpus all nvidia/cuda:12.2-base-ubuntu22.04 nvidia-smi > /dev/null 2>&1; then
            success "Docker NVIDIA GPU support is working"
        else
            warning "Docker NVIDIA GPU test failed"
        fi
    fi
}

# Clean up Docker system
cleanup_docker() {
    log "Cleaning up Docker system..."
    
    # Remove unused containers, networks, images
    sudo docker system prune -f > /dev/null 2>&1 || true
    
    success "Docker system cleaned up"
}

# Main function
main() {
    log "Setting up Docker and Docker Compose..."
    
    # Install Docker Engine
    install_docker
    
    # Configure Docker user
    configure_docker_user
    
    # Configure Docker daemon
    configure_docker_daemon
    
    # Configure NVIDIA runtime
    configure_nvidia_runtime
    
    # Install Docker Compose standalone as backup
    install_docker_compose_standalone
    
    # Restart Docker to apply all configurations
    log "Restarting Docker service..."
    sudo systemctl restart docker
    sleep 5  # Wait for Docker to fully restart
    
    # Test installation
    test_docker
    
    # Cleanup
    cleanup_docker
    
    success "Docker and Docker Compose setup completed!"
    log "Docker version: $(docker --version)"
    
    if docker compose version >/dev/null 2>&1; then
        log "Docker Compose plugin: $(docker compose version)"
    fi
    
    if command -v docker-compose >/dev/null 2>&1; then
        log "Docker Compose standalone: $(docker-compose --version)"
    fi
    
    warning "Please log out and log back in (or run 'newgrp docker') to use Docker without sudo"
}

# Run main function
main "$@"