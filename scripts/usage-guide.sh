#!/bin/bash

# Usage Guide Script
# Displays helpful information about the setup scripts

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                     NVIDIA GPU Data Center Setup Scripts                     ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════════════════════╝${NC}"
echo

echo -e "${BLUE}🚀 QUICK START:${NC}"
echo -e "   ${GREEN}./scripts/setup-datacenter.sh${NC}    # Complete automated setup"
echo -e "   ${GREEN}sudo reboot${NC}                      # Reboot after setup"
echo -e "   ${GREEN}./scripts/verify-setup.sh${NC}       # Verify installation"
echo

echo -e "${BLUE}🛠️  INDIVIDUAL SCRIPTS:${NC}"
echo -e "   ${GREEN}./scripts/setup-system-utils.sh${NC}  # System tools, git, helix editor"
echo -e "   ${GREEN}./scripts/setup-nvidia.sh${NC}        # NVIDIA drivers, CUDA, container toolkit"
echo -e "   ${GREEN}./scripts/setup-docker.sh${NC}        # Docker Engine & Docker Compose"
echo -e "   ${GREEN}./scripts/setup-portainer.sh${NC}     # Portainer container management"
echo -e "   ${GREEN}./scripts/verify-setup.sh${NC}        # Verify all installations"
echo

echo -e "${BLUE}📊 POST-SETUP ACCESS:${NC}"
echo -e "   ${YELLOW}Portainer Web UI:${NC} http://$(hostname -I | awk '{print $1}'):9000"
echo -e "   ${YELLOW}Admin Password:${NC}   /opt/portainer/admin_password.txt"
echo

echo -e "${BLUE}🧪 TEST GPU WORKLOADS:${NC}"
echo -e "   ${GREEN}nvidia-smi${NC}                                    # Check GPU status"
echo -e "   ${GREEN}docker run --rm --gpus all nvidia/cuda:latest nvidia-smi${NC}   # Test Docker GPU"
echo

echo -e "${BLUE}🎛️  MANAGEMENT COMMANDS:${NC}"
echo -e "   ${GREEN}sudo /opt/portainer/start.sh${NC}      # Start Portainer"
echo -e "   ${GREEN}sudo /opt/portainer/stop.sh${NC}       # Stop Portainer"
echo -e "   ${GREEN}sudo /opt/portainer/restart.sh${NC}    # Restart Portainer"
echo -e "   ${GREEN}docker ps${NC}                         # List running containers"
echo

echo -e "${BLUE}⚠️  IMPORTANT NOTES:${NC}"
echo -e "   • Run as regular user with sudo privileges (${RED}NOT as root${NC})"
echo -e "   • Reboot required after NVIDIA driver installation"
echo -e "   • Change default Portainer password after first login"
echo -e "   • Check ${GREEN}./README.md${NC} for detailed documentation"
echo

echo -e "${BLUE}🔍 SYSTEM REQUIREMENTS:${NC}"
echo -e "   • Ubuntu 24.04 LTS"
echo -e "   • NVIDIA GPU (AWS G6 instance recommended)"
echo -e "   • Minimum 4GB RAM (8GB+ recommended)"
echo -e "   • Minimum 20GB free disk space"
echo -e "   • Internet connectivity"
echo

echo -e "${YELLOW}Ready to set up your GPU-enabled data center instance?${NC}"
echo -e "Run: ${GREEN}./scripts/setup-datacenter.sh${NC}"