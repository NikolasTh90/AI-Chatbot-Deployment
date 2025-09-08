#!/bin/bash

# Centralized Setup Control Script
# This script orchestrates the complete datacenter setup process

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_LOG="$SCRIPT_DIR/setup.log"
CREDENTIALS_FILE="$SCRIPT_DIR/portainer-credentials.txt"

# Default options
INSTALL_NVIDIA=false
FORCE_REBOOT=false
SKIP_CONFIRMATIONS=false

# Logging functions
log() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $message" | tee -a "$SETUP_LOG"
}

error() {
    local message="$1"
    echo -e "${RED}[ERROR]${NC} $message" >&2 | tee -a "$SETUP_LOG"
}

success() {
    local message="$1"
    echo -e "${GREEN}[SUCCESS]${NC} $message" | tee -a "$SETUP_LOG"
}

warning() {
    local message="$1"
    echo -e "${YELLOW}[WARNING]${NC} $message" | tee -a "$SETUP_LOG"
}

info() {
    local message="$1"
    echo -e "${CYAN}[INFO]${NC} $message" | tee -a "$SETUP_LOG"
}

# Helper functions
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root. Please run as a regular user with sudo privileges."
        exit 1
    fi
    
    # Check sudo access - first try non-interactive, then prompt if needed
    if ! sudo -n true 2>/dev/null; then
        log "This script requires sudo privileges. Checking sudo access..."
        if ! sudo -v; then
            error "Failed to obtain sudo privileges. Please ensure your user has sudo access."
            exit 1
        fi
    fi
    
    # Check OS
    if [[ ! -f /etc/os-release ]]; then
        error "Cannot determine OS version"
        exit 1
    fi
    
    local os_info=$(cat /etc/os-release)
    if ! echo "$os_info" | grep -q "Ubuntu"; then
        error "This script is designed for Ubuntu systems"
        exit 1
    fi
    
    # Check for NVIDIA GPU if nvidia option is selected
    if [[ "$INSTALL_NVIDIA" == "true" ]]; then
        if ! lspci | grep -i nvidia > /dev/null; then
            warning "NVIDIA GPU support requested but no NVIDIA GPU detected"
            read -p "Continue anyway? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
    fi
    
    success "Prerequisites check passed"
}

install_nala() {
    if command_exists "nala"; then
        success "Nala is already installed"
        return 0
    fi
    
    log "Installing nala package manager..."
    sudo apt update
    sudo apt install -y nala
    success "Nala installed successfully"
}

run_setup_step() {
    local step_name="$1"
    local script_path="$2"
    local optional="${3:-false}"
    
    if [[ ! -f "$script_path" ]]; then
        error "Setup script not found: $script_path"
        if [[ "$optional" == "false" ]]; then
            exit 1
        else
            warning "Skipping optional step: $step_name"
            return 0
        fi
    fi
    
    log "Running setup step: $step_name"
    
    # Make script executable
    chmod +x "$script_path"
    
    # Run the script
    if "$script_path"; then
        success "Completed: $step_name"
    else
        if [[ "$optional" == "true" ]]; then
            warning "Optional step failed: $step_name"
            return 0
        else
            error "Failed: $step_name"
            exit 1
        fi
    fi
}

check_reboot_required() {
    if [[ -f /var/run/reboot-required ]]; then
        return 0
    else
        return 1
    fi
}

prompt_reboot() {
    if check_reboot_required; then
        warning "System reboot is required for some changes to take effect"
        
        if [[ "$FORCE_REBOOT" == "true" ]]; then
            log "Auto-reboot enabled. Rebooting in 10 seconds..."
            sleep 10
            sudo reboot
        else
            read -p "Reboot now? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                log "Rebooting system..."
                sudo reboot
            else
                warning "Please reboot manually when convenient"
                log "After reboot, you can continue with: $0 --continue"
            fi
        fi
    fi
}

generate_credentials_summary() {
    log "Generating credentials summary..."
    
    local server_ip
    server_ip=$(hostname -I | awk '{print $1}')
    
    cat > "$CREDENTIALS_FILE" << EOF
==============================================
    DATACENTER SETUP COMPLETE
==============================================

Server IP: $server_ip

PORTAINER WEB UI
===============
URL: http://$server_ip:9000

FIRST-TIME SETUP:
1. Access the URL above in your browser
2. Create admin user on first visit (choose your own username/password)
3. No pre-configured credentials needed

NEXT STEPS
==========
1. Access Portainer web interface using the credentials above
2. Deploy Nginx Proxy Manager stack:
   - Go to Stacks → Add Stack
   - Name: nginx-proxy-manager
   - Upload docker-compose file: proxy/nginx-proxy-manager/docker-compose.yml

3. Deploy additional application stacks as needed:
   - AI Stack: stacks/ai/docker-compose.yml
   - Other stacks from the stacks/ directory

IMPORTANT NOTES
===============
- Change default passwords after first login
- Configure SSL/TLS certificates for production use
- Set up firewall rules as needed
- Regular backups recommended

Setup completed at: $(date)
Log file: $SETUP_LOG
EOF

    success "Credentials saved to: $CREDENTIALS_FILE"
}

display_final_summary() {
    echo
    echo -e "${BOLD}${GREEN}========================================${NC}"
    echo -e "${BOLD}${GREEN}    SETUP COMPLETED SUCCESSFULLY!${NC}"
    echo -e "${BOLD}${GREEN}========================================${NC}"
    echo
    
    cat "$CREDENTIALS_FILE"
    
    echo
    echo -e "${BOLD}${CYAN}Quick Commands:${NC}"
    echo -e "${YELLOW}View credentials:${NC} cat $CREDENTIALS_FILE"
    echo -e "${YELLOW}Check services:${NC} docker ps"
    echo -e "${YELLOW}View logs:${NC} tail -f $SETUP_LOG"
    echo
}

show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
  --nvidia              Install NVIDIA drivers, CUDA, and container toolkit
  --force-reboot        Automatically reboot without prompting when required
  --skip-confirmations  Skip interactive confirmations (use with caution)
  --continue            Continue setup after a reboot
  --help, -h            Show this help message

Examples:
  $0                    # Basic setup without NVIDIA support
  $0 --nvidia           # Setup with NVIDIA GPU support
  $0 --nvidia --force-reboot  # GPU setup with automatic reboot

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --nvidia)
            INSTALL_NVIDIA=true
            shift
            ;;
        --force-reboot)
            FORCE_REBOOT=true
            shift
            ;;
        --skip-confirmations)
            SKIP_CONFIRMATIONS=true
            shift
            ;;
        --continue)
            # This flag could be used for post-reboot continuation
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Main execution flow
main() {
    echo -e "${BOLD}${BLUE}================================================${NC}"
    echo -e "${BOLD}${BLUE}    DATACENTER SETUP CONTROL SCRIPT${NC}"
    echo -e "${BOLD}${BLUE}================================================${NC}"
    echo
    
    # Initialize log file
    echo "Setup started at $(date)" > "$SETUP_LOG"
    
    log "Starting datacenter setup process..."
    log "NVIDIA support: $INSTALL_NVIDIA"
    log "Force reboot: $FORCE_REBOOT"
    log "Skip confirmations: $SKIP_CONFIRMATIONS"
    
    # Step 1: Prerequisites
    check_prerequisites
    
    # Step 2: Install nala
    install_nala
    
    # Step 3: System utilities
    run_setup_step "System Utilities" "$SCRIPT_DIR/scripts/setup-system-packages.sh"
    
    # Step 4: NVIDIA (optional)
    if [[ "$INSTALL_NVIDIA" == "true" ]]; then
        run_setup_step "NVIDIA GPU Support" "$SCRIPT_DIR/scripts/setup-nvidia.sh"
    else
        info "Skipping NVIDIA setup (not requested)"
    fi
    
    # Step 5: Docker
    run_setup_step "Docker Platform" "$SCRIPT_DIR/scripts/setup-docker.sh" "true"
    
    # Step 6: Check for reboot requirement
    prompt_reboot
    
    # Step 7: Portainer
    run_setup_step "Portainer Container Management" "$SCRIPT_DIR/portainer/setup-portainer.sh"
    
    # Step 8: Generate credentials and summary
    generate_credentials_summary
    
    # Step 9: Final verification
    run_setup_step "Setup Verification" "$SCRIPT_DIR/scripts/verify-setup.sh" "true"
    
    # Step 10: Display final summary
    display_final_summary
    
    success "Datacenter setup completed successfully!"
}

# Execute main function
main "$@"