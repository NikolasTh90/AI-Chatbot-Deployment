#!/bin/bash

# Prerequisites Check Script
# Validates system requirements before running the setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[CHECK]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check functions
check_os() {
    log "Checking operating system..."
    
    if [[ ! -f /etc/os-release ]]; then
        error "Cannot determine OS version"
        return 1
    fi
    
    local os_info=$(cat /etc/os-release)
    
    if echo "$os_info" | grep -q "Ubuntu 24.04"; then
        success "Ubuntu 24.04 LTS detected"
        return 0
    elif echo "$os_info" | grep -q "Ubuntu"; then
        warning "Ubuntu detected, but not 24.04 LTS. Scripts may work but are not tested."
        return 0
    else
        error "This script is designed for Ubuntu 24.04 LTS"
        return 1
    fi
}

check_user() {
    log "Checking user privileges..."
    
    if [[ $EUID -eq 0 ]]; then
        error "Do not run this script as root. Use a regular user with sudo privileges."
        return 1
    fi
    
    if ! sudo -n true 2>/dev/null; then
        error "User does not have sudo privileges. Please ensure you can run sudo commands."
        return 1
    fi
    
    success "User has appropriate privileges"
    return 0
}

check_internet() {
    log "Checking internet connectivity..."
    
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        success "Internet connectivity verified"
        return 0
    elif ping -c 1 1.1.1.1 >/dev/null 2>&1; then
        success "Internet connectivity verified"
        return 0
    else
        error "No internet connectivity detected. This is required for downloads."
        return 1
    fi
}

check_disk_space() {
    log "Checking available disk space..."
    
    local available_gb=$(df / | awk 'NR==2 {print int($4/1024/1024)}')
    local required_gb=20
    
    if [[ $available_gb -ge $required_gb ]]; then
        success "Sufficient disk space available (${available_gb}GB free, ${required_gb}GB required)"
        return 0
    else
        error "Insufficient disk space. Available: ${available_gb}GB, Required: ${required_gb}GB"
        return 1
    fi
}

check_memory() {
    log "Checking system memory..."
    
    local memory_gb=$(free -g | awk '/^Mem:/ {print $2}')
    local required_gb=4
    
    if [[ $memory_gb -ge $required_gb ]]; then
        success "Sufficient memory available (${memory_gb}GB total, ${required_gb}GB minimum)"
        return 0
    else
        warning "Low memory detected. Available: ${memory_gb}GB, Recommended: ${required_gb}GB+"
        return 0
    fi
}

check_nvidia_gpu() {
    log "Checking for NVIDIA GPU..."
    
    if lspci | grep -i nvidia >/dev/null 2>&1; then
        local gpu_info=$(lspci | grep -i nvidia | head -1)
        success "NVIDIA GPU detected: $gpu_info"
        return 0
    else
        error "No NVIDIA GPU detected. This setup is specifically for NVIDIA GPU instances."
        return 1
    fi
}

check_existing_installations() {
    log "Checking for existing installations..."
    
    local warnings=0
    
    # Check for existing Docker
    if command -v docker >/dev/null 2>&1; then
        warning "Docker is already installed. Setup will check and preserve existing configuration."
        ((warnings++))
    fi
    
    # Check for existing NVIDIA drivers
    if command -v nvidia-smi >/dev/null 2>&1; then
        warning "NVIDIA drivers are already installed. Setup will verify and update if needed."
        ((warnings++))
    fi
    
    # Check for existing Portainer
    if sudo docker ps --format "table {{.Names}}" 2>/dev/null | grep -q "portainer"; then
        warning "Portainer appears to be running. Setup may conflict with existing installation."
        ((warnings++))
    fi
    
    if [[ $warnings -eq 0 ]]; then
        success "No conflicting installations detected"
    else
        log "$warnings existing installations detected. Review warnings above."
    fi
    
    return 0
}

check_aws_instance() {
    log "Checking AWS instance type..."
    
    # Check if running on AWS
    if curl -s --connect-timeout 2 http://169.254.169.254/latest/meta-data/instance-type 2>/dev/null; then
        local instance_type=$(curl -s --connect-timeout 2 http://169.254.169.254/latest/meta-data/instance-type 2>/dev/null)
        
        if [[ $instance_type =~ ^g[0-9] ]]; then
            success "Running on AWS GPU instance: $instance_type"
        else
            warning "Running on AWS, but not a GPU instance type: $instance_type"
        fi
    else
        log "Not running on AWS or metadata service unavailable"
    fi
    
    return 0
}

display_summary() {
    echo
    log "System Summary:"
    echo "=============="
    
    echo "OS: $(lsb_release -d | cut -f2 2>/dev/null || echo 'Unknown')"
    echo "Kernel: $(uname -r)"
    echo "Architecture: $(uname -m)"
    echo "CPU: $(nproc) cores"
    echo "Memory: $(free -h | awk '/^Mem:/ {print $2}')"
    echo "Disk Space: $(df -h / | awk 'NR==2 {print $4}') available"
    
    if lspci | grep -i nvidia >/dev/null 2>&1; then
        echo "GPU: $(lspci | grep -i nvidia | head -1 | cut -d':' -f3 | xargs)"
    fi
    
    local instance_type=$(curl -s --connect-timeout 2 http://169.254.169.254/latest/meta-data/instance-type 2>/dev/null || echo "Unknown")
    if [[ "$instance_type" != "Unknown" ]]; then
        echo "AWS Instance: $instance_type"
    fi
    
    echo
}

main() {
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                           Prerequisites Check                                ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    local failed=0
    
    # Run all checks
    check_os || ((failed++))
    check_user || ((failed++))
    check_internet || ((failed++))
    check_disk_space || ((failed++))
    check_memory || ((failed++))
    check_nvidia_gpu || ((failed++))
    check_existing_installations || ((failed++))
    check_aws_instance || ((failed++))
    
    display_summary
    
    # Final assessment
    if [[ $failed -eq 0 ]]; then
        success "All prerequisite checks passed! System is ready for setup."
        echo
        log "Next steps:"
        echo "1. Run: ./scripts/setup-datacenter.sh"
        echo "2. Reboot after setup completes"
        echo "3. Run: ./scripts/verify-setup.sh"
        echo
        return 0
    else
        error "Some prerequisite checks failed. Please address the issues above before proceeding."
        echo
        log "If you believe the errors can be safely ignored, you can still proceed with setup:"
        echo "./scripts/setup-datacenter.sh"
        echo
        return 1
    fi
}

# Run main function
main "$@"