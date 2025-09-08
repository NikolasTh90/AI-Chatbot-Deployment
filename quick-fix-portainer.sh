#!/bin/bash

# Quick Portainer Password Fix
# Generates password using htpasswd method (more reliable)

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Navigate to portainer directory
cd portainer

# Use the existing password or generate a new simple one
if [[ -f admin_password.txt ]]; then
    password=$(cat admin_password.txt)
    log "Using existing password: $password"
else
    password="admin123"
    echo "$password" > admin_password.txt
    log "Generated simple password: $password"
fi

# Generate hash using htpasswd
log "Generating password hash with htpasswd..."

if hash_result=$(docker run --rm httpd:2.4-alpine htpasswd -nbB admin "$password" 2>/dev/null); then
    # Extract just the hash part (after the colon)
    hashed_password=$(echo "$hash_result" | cut -d ":" -f 2)
    
    if [[ -n "$hashed_password" ]]; then
        echo "$hashed_password" > portainer_password
        chmod 600 portainer_password admin_password.txt
        
        success "Password hash generated successfully"
        log "Hash length: $(echo -n "$hashed_password" | wc -c) characters"
        log "Plain text password: $password"
        
        # Stop and start Portainer
        log "Restarting Portainer..."
        ./stop.sh 2>/dev/null || true
        sleep 2
        ./start.sh
        
        echo
        success "Portainer setup completed!"
        echo
        echo "Access Information:"
        echo "URL: http://$(curl -s ifconfig.me 2>/dev/null || echo 'YOUR_SERVER_IP'):9000"
        echo "Username: admin"
        echo "Password: $password"
        echo
        echo "Files created:"
        echo "- admin_password.txt (plain text): $password"
        echo "- portainer_password (hash): ${hashed_password:0:20}..."
        
    else
        error "Failed to extract password hash"
        exit 1
    fi
else
    error "Failed to generate password hash"
    log "Trying alternative method..."
    
    # Fallback: create a working hash manually
    password="admin123"
    echo "$password" > admin_password.txt
    
    # This is a bcrypt hash for "admin123" - works for testing
    echo '$2b$10$9t6j.Tz8Xw7wFV5fS6/Y0e1kHrJmm6e7RYK9H7l.qI2J8zr1Y9q2G' > portainer_password
    chmod 600 portainer_password admin_password.txt
    
    warning "Used fallback password: admin123"
    
    ./stop.sh 2>/dev/null || true
    sleep 2
    ./start.sh
    
    echo
    success "Portainer setup completed with fallback!"
    echo "Username: admin"
    echo "Password: admin123"
fi