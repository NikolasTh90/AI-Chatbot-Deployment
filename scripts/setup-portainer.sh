#!/bin/bash

# Portainer Setup Script
# Installs and configures Portainer for Docker container management

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

# Configuration
PORTAINER_VERSION="latest"
PORTAINER_PORT="9000"
PORTAINER_AGENT_PORT="9001"
PORTAINER_DATA_DIR="/opt/portainer"
COMPOSE_FILE="/opt/portainer/docker-compose.yml"

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
    
    sudo mkdir -p "$PORTAINER_DATA_DIR"
    sudo chown -R 1000:1000 "$PORTAINER_DATA_DIR" 2>/dev/null || true
    
    success "Portainer directory created at $PORTAINER_DATA_DIR"
}

# Create Docker Compose file for Portainer
create_compose_file() {
    log "Creating Docker Compose configuration..."
    
    sudo tee "$COMPOSE_FILE" > /dev/null << EOF
version: '3.8'

services:
  portainer:
    image: portainer/portainer-ce:${PORTAINER_VERSION}
    container_name: portainer
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - portainer_data:/data
    ports:
      - "${PORTAINER_PORT}:9000"
    environment:
      - PUID=1000
      - PGID=1000
    command: >
      --admin-password-file /tmp/portainer_password
      --bind :9000
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:9000/"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

volumes:
  portainer_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ${PORTAINER_DATA_DIR}/data

networks:
  default:
    name: portainer_network
    driver: bridge
EOF
    
    success "Docker Compose file created"
}

# Create Portainer agent compose file (optional)
create_agent_compose_file() {
    local agent_compose_file="${PORTAINER_DATA_DIR}/docker-compose-agent.yml"
    
    log "Creating Portainer Agent compose file..."
    
    sudo tee "$agent_compose_file" > /dev/null << EOF
version: '3.8'

services:
  portainer_agent:
    image: portainer/agent:${PORTAINER_VERSION}
    container_name: portainer_agent
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /var/lib/docker/volumes:/var/lib/docker/volumes
    ports:
      - "${PORTAINER_AGENT_PORT}:9001"
    environment:
      - AGENT_CLUSTER_ADDR=tasks.portainer_agent
    networks:
      - portainer_agent_network

networks:
  portainer_agent_network:
    driver: overlay
    attachable: true
EOF
    
    success "Portainer Agent compose file created"
    log "Agent compose file location: $agent_compose_file"
}

# Generate default admin password
generate_admin_password() {
    local password_file="${PORTAINER_DATA_DIR}/portainer_password"
    
    if [[ ! -f "$password_file" ]]; then
        log "Generating default admin password..."
        
        # Generate a secure random password
        local password=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-16)
        
        # Hash the password using bcrypt (Portainer's preferred method)
        local hashed_password=$(sudo docker run --rm httpd:2.4-alpine htpasswd -nbB admin "$password" | cut -d ":" -f 2)
        
        echo "$hashed_password" | sudo tee "$password_file" > /dev/null
        sudo chmod 600 "$password_file"
        
        # Save the plain text password for the user
        echo "$password" | sudo tee "${PORTAINER_DATA_DIR}/admin_password.txt" > /dev/null
        sudo chmod 600 "${PORTAINER_DATA_DIR}/admin_password.txt"
        
        success "Default admin password generated"
        log "Admin username: admin"
        log "Admin password saved to: ${PORTAINER_DATA_DIR}/admin_password.txt"
    else
        success "Admin password file already exists"
    fi
}

# Start Portainer
start_portainer() {
    if portainer_running; then
        success "Portainer is already running"
        return 0
    fi
    
    log "Starting Portainer..."
    
    # Create data volume directory
    sudo mkdir -p "${PORTAINER_DATA_DIR}/data"
    
    # Copy password file to container accessible location
    sudo cp "${PORTAINER_DATA_DIR}/portainer_password" "${PORTAINER_DATA_DIR}/data/"
    
    # Start Portainer using Docker Compose
    cd "$PORTAINER_DATA_DIR"
    
    if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
        sudo docker compose up -d
    elif command -v docker-compose >/dev/null 2>&1; then
        sudo docker-compose up -d
    else
        # Fallback to direct docker run
        log "Using direct Docker run as fallback..."
        sudo docker run -d \
            --name portainer \
            --restart unless-stopped \
            -p "${PORTAINER_PORT}:9000" \
            -v /etc/localtime:/etc/localtime:ro \
            -v /var/run/docker.sock:/var/run/docker.sock:ro \
            -v "${PORTAINER_DATA_DIR}/data:/data" \
            portainer/portainer-ce:${PORTAINER_VERSION} \
            --admin-password-file /data/portainer_password
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

# Create systemd service for auto-start (optional)
create_systemd_service() {
    local service_file="/etc/systemd/system/portainer.service"
    
    log "Creating systemd service for Portainer..."
    
    sudo tee "$service_file" > /dev/null << EOF
[Unit]
Description=Portainer Docker Management
Requires=docker.service
After=docker.service
StartLimitIntervalSec=0

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=${PORTAINER_DATA_DIR}
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
TimeoutStartSec=0
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
    
    sudo systemctl daemon-reload
    sudo systemctl enable portainer.service
    
    success "Systemd service created and enabled"
}

# Create management scripts
create_management_scripts() {
    log "Creating Portainer management scripts..."
    
    # Start script
    sudo tee "${PORTAINER_DATA_DIR}/start.sh" > /dev/null << 'EOF'
#!/bin/bash
cd /opt/portainer
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
    sudo tee "${PORTAINER_DATA_DIR}/stop.sh" > /dev/null << 'EOF'
#!/bin/bash
cd /opt/portainer
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
    sudo tee "${PORTAINER_DATA_DIR}/restart.sh" > /dev/null << 'EOF'
#!/bin/bash
cd /opt/portainer
./stop.sh
sleep 5
./start.sh
EOF
    
    # Make scripts executable
    sudo chmod +x "${PORTAINER_DATA_DIR}"/*.sh
    
    success "Management scripts created in $PORTAINER_DATA_DIR"
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
    log "Password: $(sudo cat ${PORTAINER_DATA_DIR}/admin_password.txt 2>/dev/null || echo 'See /opt/portainer/admin_password.txt')"
    echo
    log "Management Commands:"
    log "Start:   sudo ${PORTAINER_DATA_DIR}/start.sh"
    log "Stop:    sudo ${PORTAINER_DATA_DIR}/stop.sh"
    log "Restart: sudo ${PORTAINER_DATA_DIR}/restart.sh"
    echo
    warning "SECURITY NOTE: Change the default password after first login!"
    warning "Consider setting up SSL/TLS for production use."
}

# Main function
main() {
    log "Setting up Portainer..."
    
    # Pre-flight checks
    check_docker
    
    # Create directories
    create_portainer_directory
    
    # Generate admin password
    generate_admin_password
    
    # Create configuration files
    create_compose_file
    create_agent_compose_file
    
    # Start Portainer
    start_portainer
    
    # Configure firewall
    configure_firewall
    
    # Create systemd service
    create_systemd_service
    
    # Create management scripts
    create_management_scripts
    
    # Display connection information
    display_connection_info
    
    success "Portainer setup completed successfully!"
}

# Run main function
main "$@"