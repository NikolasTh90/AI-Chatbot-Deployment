#!/bin/bash

# Portainer Setup Script
# Installs and configures Portainer for Docker container management
# Uses the docker-compose.yml file in the same directory

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

# Get script directory (where docker-compose.yml is located)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORTAINER_PORT="9000"
PORTAINER_AGENT_PORT="9001"

# Check if Docker is available
check_docker() {
    if ! command -v docker >/dev/null 2>&1; then
        error "Docker is not installed. Please run the Docker setup script first."
        exit 1
    fi
    
    if ! sudo docker info >/dev/null 2>&1; then
        error "Docker daemon is not running or accessible."
        exit 1
    fi
    
    success "Docker is available and running"
}

# Check if docker-compose.yml exists
check_compose_file() {
    if [[ ! -f "$SCRIPT_DIR/docker-compose.yml" ]]; then
        error "docker-compose.yml not found in $SCRIPT_DIR"
        exit 1
    fi
    
    success "Docker Compose file found"
}

# Check if Portainer is already running
portainer_running() {
    if sudo docker ps --format "table {{.Names}}" | grep -q "portainer"; then
        return 0
    else
        return 1
    fi
}

# Create Portainer data directory
create_portainer_directory() {
    log "Creating Portainer data directory..."
    
    mkdir -p "$SCRIPT_DIR/data"
    sudo chown -R 1000:1000 "$SCRIPT_DIR/data" 2>/dev/null || true
    
    success "Portainer directory created at $SCRIPT_DIR/data"
}

# Generate default admin password
generate_admin_password() {
    local password_file="$SCRIPT_DIR/portainer_password"
    
    if [[ ! -f "$password_file" ]]; then
        log "Generating default admin password..."
        
        # Generate a secure random password
        local password=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-16)
        
        # Hash the password using bcrypt (Portainer's preferred method)
        local hashed_password=$(sudo docker run --rm httpd:2.4-alpine htpasswd -nbB admin "$password" | cut -d ":" -f 2)
        
        echo "$hashed_password" > "$password_file"
        chmod 600 "$password_file"
        
        # Save the plain text password for the user
        echo "$password" > "$SCRIPT_DIR/admin_password.txt"
        chmod 600 "$SCRIPT_DIR/admin_password.txt"
        
        success "Default admin password generated"
        log "Admin username: admin"
        log "Admin password saved to: $SCRIPT_DIR/admin_password.txt"
    else
        success "Admin password file already exists"
    fi
}

# Create proxy network if it doesn't exist
create_proxy_network() {
    log "Checking for proxy network..."
    
    if ! docker network ls | grep -q "proxy"; then
        log "Creating proxy network..."
        docker network create proxy
        success "Proxy network created"
    else
        success "Proxy network already exists"
    fi
}

# Start Portainer
start_portainer() {
    if portainer_running; then
        success "Portainer is already running"
        return 0
    fi
    
    log "Starting Portainer..."
    
    # Change to script directory
    cd "$SCRIPT_DIR"
    
    # Start Portainer using Docker Compose
    if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
        docker compose up -d
    elif command -v docker-compose >/dev/null 2>&1; then
        docker-compose up -d
    else
        error "Neither docker compose nor docker-compose found"
        exit 1
    fi
    
    # Wait for Portainer to start
    log "Waiting for Portainer to start..."
    sleep 10
    
    # Check if Portainer is running
    if portainer_running; then
        success "Portainer started successfully"
    else
        error "Failed to start Portainer"
        return 1
    fi
}

# Configure firewall (if ufw is active)
configure_firewall() {
    if command -v ufw >/dev/null 2>&1 && sudo ufw status | grep -q "Status: active"; then
        log "Configuring firewall for Portainer..."
        
        sudo ufw allow "$PORTAINER_PORT"/tcp comment "Portainer Web UI"
        sudo ufw allow "$PORTAINER_AGENT_PORT"/tcp comment "Portainer Agent"
        
        success "Firewall configured for Portainer"
    else
        log "UFW firewall not active, skipping firewall configuration"
    fi
}

# Create management scripts
create_management_scripts() {
    log "Creating Portainer management scripts..."
    
    # Start script
    cat > "$SCRIPT_DIR/start.sh" << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    docker compose up -d
elif command -v docker-compose >/dev/null 2>&1; then
    docker-compose up -d
else
    echo "Neither docker compose nor docker-compose found"
    exit 1
fi
EOF
    
    # Stop script
    cat > "$SCRIPT_DIR/stop.sh" << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    docker compose down
elif command -v docker-compose >/dev/null 2>&1; then
    docker-compose down
else
    docker stop portainer 2>/dev/null || true
    docker rm portainer 2>/dev/null || true
fi
EOF
    
    # Restart script
    cat > "$SCRIPT_DIR/restart.sh" << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
./stop.sh
sleep 5
./start.sh
EOF
    
    # Logs script
    cat > "$SCRIPT_DIR/logs.sh" << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    docker compose logs -f
elif command -v docker-compose >/dev/null 2>&1; then
    docker-compose logs -f
else
    docker logs -f portainer 2>/dev/null || echo "Portainer container not found"
fi
EOF
    
    # Make scripts executable
    chmod +x "$SCRIPT_DIR"/{start,stop,restart,logs}.sh
    
    success "Management scripts created in $SCRIPT_DIR"
}

# Display connection information
display_connection_info() {
    local server_ip=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "YOUR_SERVER_IP")
    local local_ip=$(hostname -I | awk '{print $1}')
    
    success "Portainer setup completed!"
    echo
    log "Connection Information:"
    log "======================="
    log "Local URL:     http://localhost:${PORTAINER_PORT}"
    log "Local IP URL:  http://${local_ip}:${PORTAINER_PORT}"
    log "Public URL:    http://${server_ip}:${PORTAINER_PORT}"
    echo
    log "Default Credentials:"
    log "Username: admin"
    log "Password: $(cat $SCRIPT_DIR/admin_password.txt 2>/dev/null || echo 'See admin_password.txt')"
    echo
    log "Management Commands:"
    log "Start:   $SCRIPT_DIR/start.sh"
    log "Stop:    $SCRIPT_DIR/stop.sh"
    log "Restart: $SCRIPT_DIR/restart.sh"
    log "Logs:    $SCRIPT_DIR/logs.sh"
    echo
    log "Files Location: $SCRIPT_DIR"
    log "- docker-compose.yml (stack definition)"
    log "- admin_password.txt (plain text password)"
    log "- portainer_password (bcrypt hash)"
    log "- data/ (persistent data volume)"
    echo
    warning "SECURITY NOTE: Change the default password after first login!"
    warning "Consider setting up SSL/TLS for production use."
}

# Main function
main() {
    log "Setting up Portainer..."
    log "Working directory: $SCRIPT_DIR"
    
    # Pre-flight checks
    check_docker
    check_compose_file
    
    # Setup steps
    create_portainer_directory
    generate_admin_password
    create_proxy_network
    start_portainer
    configure_firewall
    create_management_scripts
    display_connection_info
    
    success "Portainer setup completed successfully!"
}

# Run main function
main "$@"