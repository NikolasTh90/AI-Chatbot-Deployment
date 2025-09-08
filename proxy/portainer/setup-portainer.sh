#!/bin/bash

# Portainer Setup Script (Proxy Version)
# Sets up Portainer in the proxy network for NPM integration

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

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check Docker availability
check_docker() {
    if ! command -v docker >/dev/null 2>&1; then
        error "Docker is not installed"
        exit 1
    fi
    
    if ! docker info >/dev/null 2>&1; then
        error "Docker daemon is not running"
        exit 1
    fi
    
    success "Docker is available"
}

# Create proxy network
create_proxy_network() {
    log "Setting up proxy network..."
    
    if ! docker network ls | grep -q "proxy"; then
        docker network create proxy
        success "Proxy network created"
    else
        success "Proxy network already exists"
    fi
}

# Generate admin password
generate_admin_password() {
    local password_file="$SCRIPT_DIR/portainer_password"
    local admin_password_file="$SCRIPT_DIR/admin_password.txt"
    
    if [[ ! -f "$password_file" ]] || [[ ! -s "$password_file" ]]; then
        log "Generating admin password..."
        
        # Generate secure random password
        local password
        password=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-16)
        
        if [[ -z "$password" ]]; then
            error "Failed to generate random password"
            exit 1
        fi
        
        log "Generated password: $password"
        
        # Save plain text password first
        echo "$password" > "$admin_password_file"
        chmod 600 "$admin_password_file"
        log "Plain text password saved"
        
        # Try Portainer helper first
        log "Generating password hash..."
        if echo "$password" | docker run --rm -i portainer/helper-reset-password > "$password_file" 2>/dev/null; then
            if [[ -s "$password_file" ]]; then
                chmod 600 "$password_file"
                success "Password hash generated successfully"
            else
                log "Portainer helper produced empty file, using fallback..."
                # Fallback to htpasswd
                local hashed_password
                hashed_password=$(docker run --rm httpd:2.4-alpine htpasswd -nbB admin "$password" 2>/dev/null | cut -d ":" -f 2)
                
                if [[ -n "$hashed_password" ]]; then
                    echo "$hashed_password" > "$password_file"
                    chmod 600 "$password_file"
                    success "Password hash generated using htpasswd fallback"
                else
                    error "Failed to generate password hash"
                    exit 1
                fi
            fi
        else
            error "Failed to generate password hash"
            exit 1
        fi
        
        success "Admin password generated"
        log "Password: $password"
    else
        success "Admin password already exists"
        log "Existing password: $(cat "$admin_password_file" 2>/dev/null || echo 'Unable to read')"
    fi
}

# Create data directory
create_data_directory() {
    log "Creating data directory..."
    mkdir -p "$SCRIPT_DIR/data"
    success "Data directory created"
}

# Deploy Portainer
deploy_portainer() {
    log "Deploying Portainer..."
    
    cd "$SCRIPT_DIR"
    
    if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
        docker compose up -d
    elif command -v docker-compose >/dev/null 2>&1; then
        docker-compose up -d
    else
        error "Docker Compose not available"
        exit 1
    fi
    
    # Wait for startup
    sleep 5
    
    if docker ps | grep -q "portainer"; then
        success "Portainer deployed successfully"
    else
        error "Portainer deployment failed"
        exit 1
    fi
}

# Create management scripts
create_management_scripts() {
    log "Creating management scripts..."
    
    # Start script
    cat > "$SCRIPT_DIR/start.sh" << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    docker compose up -d
else
    docker-compose up -d
fi
EOF
    
    # Stop script
    cat > "$SCRIPT_DIR/stop.sh" << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    docker compose down
else
    docker-compose down
fi
EOF
    
    # Restart script
    cat > "$SCRIPT_DIR/restart.sh" << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
./stop.sh
sleep 3
./start.sh
EOF
    
    # Logs script
    cat > "$SCRIPT_DIR/logs.sh" << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    docker compose logs -f portainer
else
    docker-compose logs -f portainer
fi
EOF
    
    # Make executable
    chmod +x "$SCRIPT_DIR"/{start,stop,restart,logs}.sh
    
    success "Management scripts created"
}

# Display final information
display_info() {
    local server_ip
    server_ip=$(hostname -I | awk '{print $1}')
    
    success "Portainer proxy setup completed!"
    echo
    log "Access Information:"
    log "=================="
    log "URL: http://$server_ip:9000"
    log "Username: admin"
    log "Password: $(cat "$SCRIPT_DIR/admin_password.txt")"
    echo
    log "Next Steps:"
    log "1. Access Portainer web interface"
    log "2. Change default password"
    log "3. Deploy Nginx Proxy Manager stack"
    log "4. Configure NPM to proxy Portainer (optional)"
    echo
    log "Management Commands:"
    log "$SCRIPT_DIR/start.sh"
    log "$SCRIPT_DIR/stop.sh" 
    log "$SCRIPT_DIR/restart.sh"
    log "$SCRIPT_DIR/logs.sh"
    echo
}

# Main execution
main() {
    log "Setting up Portainer for proxy network..."
    
    check_docker
    create_proxy_network
    create_data_directory
    generate_admin_password
    deploy_portainer
    create_management_scripts
    display_info
    
    success "Setup complete!"
}

# Run main function
main "$@"