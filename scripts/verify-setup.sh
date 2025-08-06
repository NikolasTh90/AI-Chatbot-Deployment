#!/bin/bash

# System Verification Script
# Verifies that all components are properly installed and configured

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

check_mark() {
    echo -e "${GREEN}✓${NC}"
}

cross_mark() {
    echo -e "${RED}✗${NC}"
}

# Verification functions
verify_system_utils() {
    log "Verifying system utilities..."
    
    local tools=(
        "git:git"
        "hx:Helix editor"
        "curl:cURL"
        "wget:wget"
        "htop:htop"
        "jq:jq"
        "tree:tree"
        "tmux:tmux"
        "python3:Python3"
        "pip3:Python3 pip"
        "node:Node.js"
        "npm:npm"
    )
    
    local failed=0
    
    for tool_info in "${tools[@]}"; do
        local cmd="${tool_info%%:*}"
        local name="${tool_info##*:}"
        
        printf "  %-20s: " "$name"
        if command -v "$cmd" >/dev/null 2>&1; then
            check_mark
        else
            cross_mark
            ((failed++))
        fi
    done
    
    if [[ $failed -eq 0 ]]; then
        success "All system utilities are installed"
    else
        warning "$failed system utilities are missing"
    fi
    
    return $failed
}

verify_nvidia() {
    log "Verifying NVIDIA GPU support..."
    
    local failed=0
    
    # Check for NVIDIA GPU
    printf "  %-20s: " "NVIDIA GPU"
    if lspci | grep -i nvidia >/dev/null 2>&1; then
        check_mark
        echo "    $(lspci | grep -i nvidia | head -1)"
    else
        cross_mark
        ((failed++))
    fi
    
    # Check NVIDIA drivers
    printf "  %-20s: " "NVIDIA Drivers"
    if command -v nvidia-smi >/dev/null 2>&1; then
        check_mark
        local driver_version=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader,nounits | head -1)
        echo "    Driver version: $driver_version"
    else
        cross_mark
        ((failed++))
    fi
    
    # Check CUDA
    printf "  %-20s: " "CUDA Toolkit"
    if command -v nvcc >/dev/null 2>&1; then
        check_mark
        local cuda_version=$(nvcc --version | grep "release" | awk '{print $6}' | cut -d',' -f1)
        echo "    CUDA version: $cuda_version"
    else
        cross_mark
        ((failed++))
    fi
    
    # Check NVIDIA Container Toolkit
    printf "  %-20s: " "Container Toolkit"
    if command -v nvidia-container-runtime >/dev/null 2>&1; then
        check_mark
    else
        cross_mark
        ((failed++))
    fi
    
    if [[ $failed -eq 0 ]]; then
        success "NVIDIA GPU support is fully configured"
    else
        warning "$failed NVIDIA components are missing or not working"
    fi
    
    return $failed
}

verify_docker() {
    log "Verifying Docker installation..."
    
    local failed=0
    
    # Check Docker Engine
    printf "  %-20s: " "Docker Engine"
    if command -v docker >/dev/null 2>&1; then
        check_mark
        local docker_version=$(docker --version | awk '{print $3}' | sed 's/,//')
        echo "    Version: $docker_version"
    else
        cross_mark
        ((failed++))
    fi
    
    # Check Docker daemon
    printf "  %-20s: " "Docker Daemon"
    if sudo docker info >/dev/null 2>&1; then
        check_mark
    else
        cross_mark
        ((failed++))
    fi
    
    # Check Docker Compose plugin
    printf "  %-20s: " "Docker Compose"
    if docker compose version >/dev/null 2>&1; then
        check_mark
        local compose_version=$(docker compose version | awk '{print $4}' | head -1)
        echo "    Plugin version: $compose_version"
    elif command -v docker-compose >/dev/null 2>&1; then
        check_mark
        local compose_version=$(docker-compose --version | awk '{print $4}' | sed 's/,//')
        echo "    Standalone version: $compose_version"
    else
        cross_mark
        ((failed++))
    fi
    
    # Check Docker user permissions
    printf "  %-20s: " "Docker User Access"
    if groups "$(whoami)" | grep -q docker; then
        check_mark
        echo "    User $(whoami) is in docker group"
    else
        cross_mark
        echo "    User $(whoami) is NOT in docker group"
        ((failed++))
    fi
    
    # Test Docker functionality
    printf "  %-20s: " "Docker Test"
    if sudo docker run --rm hello-world >/dev/null 2>&1; then
        check_mark
    else
        cross_mark
        ((failed++))
    fi
    
    # Test Docker GPU support
    if command -v nvidia-container-runtime >/dev/null 2>&1; then
        printf "  %-20s: " "Docker GPU Support"
        if sudo docker run --rm --gpus all nvidia/cuda:12.2-base-ubuntu22.04 nvidia-smi >/dev/null 2>&1; then
            check_mark
        else
            cross_mark
            ((failed++))
        fi
    fi
    
    if [[ $failed -eq 0 ]]; then
        success "Docker is fully configured and working"
    else
        warning "$failed Docker components are missing or not working"
    fi
    
    return $failed
}

verify_portainer() {
    log "Verifying Portainer installation..."
    
    local failed=0
    
    # Check if Portainer container is running
    printf "  %-20s: " "Portainer Container"
    if sudo docker ps --format "table {{.Names}}" | grep -q "portainer"; then
        check_mark
        local portainer_status=$(sudo docker ps --filter "name=portainer" --format "{{.Status}}" | head -1)
        echo "    Status: $portainer_status"
    else
        cross_mark
        ((failed++))
    fi
    
    # Check Portainer web interface
    printf "  %-20s: " "Web Interface"
    local portainer_port="9000"
    if curl -s "http://localhost:$portainer_port" >/dev/null 2>&1; then
        check_mark
        echo "    Accessible on port $portainer_port"
    else
        cross_mark
        ((failed++))
    fi
    
    # Check Portainer files
    printf "  %-20s: " "Configuration Files"
    if [[ -f "/opt/portainer/docker-compose.yml" ]]; then
        check_mark
    else
        cross_mark
        ((failed++))
    fi
    
    # Check admin password file
    printf "  %-20s: " "Admin Password"
    if [[ -f "/opt/portainer/admin_password.txt" ]]; then
        check_mark
    else
        cross_mark
        ((failed++))
    fi
    
    if [[ $failed -eq 0 ]]; then
        success "Portainer is fully configured and running"
    else
        warning "$failed Portainer components are missing or not working"
    fi
    
    return $failed
}

# System information display
display_system_info() {
    log "System Information:"
    log "=================="
    
    echo "OS: $(lsb_release -d | cut -f2)"
    echo "Kernel: $(uname -r)"
    echo "Architecture: $(uname -m)"
    echo "CPU: $(lscpu | grep "Model name" | cut -d':' -f2 | xargs)"
    echo "Memory: $(free -h | awk '/^Mem:/ {print $2}')"
    echo "Disk: $(df -h / | awk 'NR==2 {print $2 " (" $5 " used)"}')"
    
    # NVIDIA GPU info
    if command -v nvidia-smi >/dev/null 2>&1; then
        echo "GPU: $(nvidia-smi --query-gpu=name --format=csv,noheader,nounits | head -1)"
        echo "GPU Driver: $(nvidia-smi --query-gpu=driver_version --format=csv,noheader,nounits | head -1)"
        echo "GPU Memory: $(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | head -1) MiB"
    fi
    
    echo
}

# Network information
display_network_info() {
    log "Network Information:"
    log "==================="
    
    local local_ip=$(hostname -I | awk '{print $1}')
    local public_ip=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "Unable to determine")
    
    echo "Local IP: $local_ip"
    echo "Public IP: $public_ip"
    echo
    
    if sudo docker ps --filter "name=portainer" >/dev/null 2>&1; then
        log "Service URLs:"
        echo "Portainer: http://$local_ip:9000"
        if [[ "$public_ip" != "Unable to determine" ]]; then
            echo "Portainer (Public): http://$public_ip:9000"
        fi
    fi
    
    echo
}

# Performance check
check_performance() {
    log "Performance Check:"
    log "=================="
    
    # CPU performance
    echo "CPU Load: $(uptime | awk -F'load average:' '{print $2}')"
    
    # Memory usage
    echo "Memory Usage: $(free | awk '/^Mem:/ {printf "%.1f%%", $3/$2 * 100.0}')"
    
    # Disk usage
    echo "Disk Usage: $(df / | awk 'NR==2 {print $5}')"
    
    # Docker performance
    if command -v docker >/dev/null 2>&1; then
        echo "Docker Containers: $(sudo docker ps -q | wc -l) running"
        echo "Docker Images: $(sudo docker images -q | wc -l) total"
    fi
    
    echo
}

# Main verification function
main() {
    log "Starting system verification..."
    echo
    
    # Display system information
    display_system_info
    
    # Run verifications
    local total_failed=0
    
    verify_system_utils
    ((total_failed += $?))
    echo
    
    verify_nvidia
    ((total_failed += $?))
    echo
    
    verify_docker
    ((total_failed += $?))
    echo
    
    verify_portainer
    ((total_failed += $?))
    echo
    
    # Display network information
    display_network_info
    
    # Display performance information
    check_performance
    
    # Final summary
    if [[ $total_failed -eq 0 ]]; then
        success "All components verified successfully! ✓"
        log "Your data center instance is ready for GPU workloads with Portainer management."
    else
        warning "Some components failed verification ($total_failed issues found)"
        log "Please review the failed checks above and re-run the appropriate setup scripts."
        return 1
    fi
    
    # Recommendations
    log "Recommendations:"
    log "==============="
    log "1. Change Portainer admin password after first login"
    log "2. Consider setting up SSL/TLS certificates for production use"
    log "3. Configure backup solutions for important data"
    log "4. Monitor system resources regularly"
    log "5. Keep all components updated regularly"
}

# Run main function
main "$@"