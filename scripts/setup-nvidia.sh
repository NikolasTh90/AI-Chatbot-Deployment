#!/bin/bash

# NVIDIA GPU Setup Script
# Sets up NVIDIA drivers, CUDA, and container toolkit for Ubuntu 24.04

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

# Check if NVIDIA GPU is present
check_nvidia_gpu() {
    if ! lspci | grep -i nvidia > /dev/null; then
        error "No NVIDIA GPU detected. This script is for NVIDIA GPU-enabled instances."
        exit 1
    fi
    
    local gpu_info=$(lspci | grep -i nvidia)
    log "Detected NVIDIA GPU(s):"
    echo "$gpu_info"
}

# Check if NVIDIA drivers are already installed
nvidia_drivers_installed() {
    if command -v nvidia-smi >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Install NVIDIA drivers
install_nvidia_drivers() {
    if nvidia_drivers_installed; then
        success "NVIDIA drivers are already installed"
        nvidia-smi
        return 0
    fi
    
    log "Installing NVIDIA drivers..."
    
    # Add NVIDIA PPA
    sudo nala install -y software-properties-common
    sudo add-apt-repository -y ppa:graphics-drivers/ppa
    sudo nala update
    
    # Install recommended NVIDIA driver
    local recommended_driver=$(ubuntu-drivers devices | grep nvidia | grep recommended | awk '{print $3}')
    
    if [[ -n "$recommended_driver" ]]; then
        log "Installing recommended driver: $recommended_driver"
        sudo nala install -y "$recommended_driver"
    else
        log "Installing generic NVIDIA driver..."
        sudo ubuntu-drivers autoinstall
    fi
    
    success "NVIDIA drivers installed"
    log "Note: A reboot may be required for drivers to load properly"
}

# Check if CUDA is installed
cuda_installed() {
    if command -v nvcc >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Install CUDA toolkit
install_cuda() {
    if cuda_installed; then
        success "CUDA is already installed"
        nvcc --version
        return 0
    fi
    
    log "Installing CUDA toolkit..."
    
    # Download and install CUDA keyring
    local cuda_keyring_url="https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb"
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    wget -q "$cuda_keyring_url"
    sudo dpkg -i cuda-keyring_*.deb
    
    # Update and install CUDA
    sudo nala update
    sudo nala install -y cuda-toolkit
    
    # Add CUDA to PATH
    if ! grep -q "/usr/local/cuda/bin" ~/.bashrc; then
        echo 'export PATH=/usr/local/cuda/bin:$PATH' >> ~/.bashrc
        echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
    fi
    
    # Clean up
    cd - > /dev/null
    rm -rf "$temp_dir"
    
    success "CUDA toolkit installed"
    log "Please run 'source ~/.bashrc' or start a new shell session to update PATH"
}

# Check if NVIDIA Container Toolkit is installed
nvidia_container_toolkit_installed() {
    if command -v nvidia-container-runtime >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Install NVIDIA Container Toolkit
install_nvidia_container_toolkit() {
    if nvidia_container_toolkit_installed; then
        success "NVIDIA Container Toolkit is already installed"
        return 0
    fi
    
    log "Installing NVIDIA Container Toolkit..."
    
    # Add NVIDIA Container Toolkit repository
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
    
    sudo nala update
    sudo nala install -y nvidia-container-toolkit
    
    success "NVIDIA Container Toolkit installed"
}

# Configure Docker for NVIDIA GPU support
configure_docker_nvidia() {
    if ! command -v docker >/dev/null 2>&1; then
        warning "Docker is not installed yet. NVIDIA Docker configuration will be handled by the Docker setup script."
        return 0
    fi
    
    log "Configuring Docker for NVIDIA GPU support..."
    
    # Configure NVIDIA Container Runtime
    sudo nvidia-ctk runtime configure --runtime=docker
    
    # Restart Docker daemon
    sudo systemctl restart docker
    
    success "Docker configured for NVIDIA GPU support"
}

# Test NVIDIA setup
test_nvidia_setup() {
    log "Testing NVIDIA setup..."
    
    # Test NVIDIA drivers
    if nvidia_drivers_installed; then
        log "Testing nvidia-smi..."
        nvidia-smi
    else
        warning "NVIDIA drivers not accessible. A reboot may be required."
    fi
    
    # Test CUDA (if available in current session)
    if command -v nvcc >/dev/null 2>&1; then
        log "Testing CUDA..."
        nvcc --version
    else
        warning "CUDA not in current PATH. Run 'source ~/.bashrc' to update PATH."
    fi
    
    # Test Docker GPU support (if Docker is available)
    if command -v docker >/dev/null 2>&1 && nvidia_container_toolkit_installed; then
        log "Testing Docker GPU support..."
        if sudo docker run --rm --gpus all nvidia/cuda:12.2-base-ubuntu22.04 nvidia-smi 2>/dev/null; then
            success "Docker GPU support is working"
        else
            warning "Docker GPU test failed. This might work after Docker is properly installed and configured."
        fi
    fi
}

# Main function
main() {
    log "Setting up NVIDIA GPU support..."
    
    # Check for NVIDIA GPU
    check_nvidia_gpu
    
    # Install NVIDIA drivers
    install_nvidia_drivers
    
    # Install CUDA toolkit
    install_cuda
    
    # Install NVIDIA Container Toolkit
    install_nvidia_container_toolkit
    
    # Configure Docker if it exists
    configure_docker_nvidia
    
    # Test setup
    test_nvidia_setup
    
    success "NVIDIA GPU setup completed!"
    log "Note: If this is a fresh driver installation, please reboot the system:"
    log "sudo reboot"
}

# Run main function
main "$@"