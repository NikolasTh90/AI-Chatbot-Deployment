#!/bin/bash

# Update Portainer Admin Password Script
# Safely updates the Portainer admin password

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[INFO]${NC} $1"
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

# Configuration
PORTAINER_DATA_DIR="/opt/portainer"
PASSWORD_FILE="${PORTAINER_DATA_DIR}/portainer_password"
PLAIN_PASSWORD_FILE="${PORTAINER_DATA_DIR}/admin_password.txt"

# Check if Portainer is installed
check_portainer() {
    if [[ ! -d "$PORTAINER_DATA_DIR" ]]; then
        error "Portainer installation not found at $PORTAINER_DATA_DIR"
        exit 1
    fi
    
    if ! sudo docker ps --format "table {{.Names}}" | grep -q "portainer"; then
        error "Portainer container is not running"
        exit 1
    fi
    
    success "Portainer installation found"
}

# Generate new password
generate_password() {
    local password_length=${1:-16}
    
    # Generate a secure random password
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-$password_length
}

# Hash password for Portainer
hash_password() {
    local password=$1
    
    # Use Portainer's preferred bcrypt hashing
    sudo docker run --rm httpd:2.4-alpine htpasswd -nbB admin "$password" | cut -d ":" -f 2
}

# Update password files
update_password_files() {
    local password=$1
    local hashed_password=$2
    
    log "Updating password files..."
    
    # Backup existing files
    if [[ -f "$PASSWORD_FILE" ]]; then
        sudo cp "$PASSWORD_FILE" "${PASSWORD_FILE}.backup.$(date +%Y%m%d-%H%M%S)"
    fi
    
    if [[ -f "$PLAIN_PASSWORD_FILE" ]]; then
        sudo cp "$PLAIN_PASSWORD_FILE" "${PLAIN_PASSWORD_FILE}.backup.$(date +%Y%m%d-%H%M%S)"
    fi
    
    # Write new password files
    echo "$hashed_password" | sudo tee "$PASSWORD_FILE" > /dev/null
    echo "$password" | sudo tee "$PLAIN_PASSWORD_FILE" > /dev/null
    
    # Set secure permissions
    sudo chmod 600 "$PASSWORD_FILE"
    sudo chmod 600 "$PLAIN_PASSWORD_FILE"
    
    success "Password files updated"
}

# Restart Portainer
restart_portainer() {
    log "Restarting Portainer to apply new password..."
    
    if [[ -f "${PORTAINER_DATA_DIR}/restart.sh" ]]; then
        sudo "${PORTAINER_DATA_DIR}/restart.sh"
    else
        # Fallback restart method
        sudo docker restart portainer
    fi
    
    # Wait for Portainer to start
    sleep 10
    
    if sudo docker ps --format "table {{.Names}}" | grep -q "portainer"; then
        success "Portainer restarted successfully"
    else
        error "Failed to restart Portainer"
        exit 1
    fi
}

# Interactive password setting
interactive_mode() {
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                      Portainer Password Update                               ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    log "Current admin password is stored in: $PLAIN_PASSWORD_FILE"
    
    echo
    echo "Password options:"
    echo "1. Generate a new random password (recommended)"
    echo "2. Set a custom password"
    echo "3. Exit without changes"
    echo
    
    read -p "Choose an option (1-3): " choice
    
    case $choice in
        1)
            log "Generating new random password..."
            local new_password=$(generate_password 16)
            ;;
        2)
            echo
            read -p "Enter new password: " -s new_password
            echo
            read -p "Confirm password: " -s confirm_password
            echo
            
            if [[ "$new_password" != "$confirm_password" ]]; then
                error "Passwords do not match"
                exit 1
            fi
            
            if [[ ${#new_password} -lt 8 ]]; then
                error "Password must be at least 8 characters long"
                exit 1
            fi
            ;;
        3)
            log "Exiting without changes"
            exit 0
            ;;
        *)
            error "Invalid option"
            exit 1
            ;;
    esac
    
    # Hash the password
    log "Hashing password..."
    local hashed_password=$(hash_password "$new_password")
    
    # Update password files
    update_password_files "$new_password" "$hashed_password"
    
    # Restart Portainer
    restart_portainer
    
    # Display new credentials
    echo
    success "Password updated successfully!"
    log "New admin credentials:"
    log "Username: admin"
    log "Password: $new_password"
    echo
    log "Password is also saved in: $PLAIN_PASSWORD_FILE"
    warning "Please log in to Portainer and change the password through the web interface as well"
}

# Command line mode
command_line_mode() {
    local password=$1
    
    if [[ -z "$password" ]]; then
        error "Password cannot be empty"
        exit 1
    fi
    
    if [[ ${#password} -lt 8 ]]; then
        error "Password must be at least 8 characters long"
        exit 1
    fi
    
    log "Updating password..."
    
    # Hash the password
    local hashed_password=$(hash_password "$password")
    
    # Update password files
    update_password_files "$password" "$hashed_password"
    
    # Restart Portainer
    restart_portainer
    
    success "Password updated successfully!"
    log "New admin password has been set"
}

# Show usage
show_usage() {
    echo "Usage: $0 [PASSWORD]"
    echo
    echo "Update the Portainer admin password"
    echo
    echo "Options:"
    echo "  PASSWORD    Set specific password (optional)"
    echo "  -h, --help  Show this help message"
    echo
    echo "Examples:"
    echo "  $0                    # Interactive mode - choose password option"
    echo "  $0 mypassword123      # Set specific password"
    echo
    echo "Notes:"
    echo "  - If no password is provided, interactive mode will start"
    echo "  - Passwords must be at least 8 characters long"
    echo "  - Portainer will be automatically restarted"
    echo "  - Old password files are backed up with timestamp"
}

# Main function
main() {
    # Check for help option
    if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
        show_usage
        exit 0
    fi
    
    # Check if Portainer is installed
    check_portainer
    
    # Check if password provided via command line
    if [[ -n "$1" ]]; then
        command_line_mode "$1"
    else
        interactive_mode
    fi
}

# Run main function
main "$@"