#!/bin/bash

# List Scripts - Overview of all available scripts

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                        Available Setup Scripts                               ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════════════════════╝${NC}"
echo

echo -e "${BLUE}📋 MAIN SCRIPTS:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}setup-datacenter.sh${NC}        🚀 Main orchestrator script - runs all setup components"
echo -e "${GREEN}verify-setup.sh${NC}            ✅ Verify all installations and configurations"
echo -e "${GREEN}check-prerequisites.sh${NC}     🔍 Check system requirements before setup"
echo

echo -e "${BLUE}🛠️  COMPONENT SCRIPTS:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}setup-system-utils.sh${NC}      📦 System tools: git, helix, build tools, monitoring"
echo -e "${GREEN}setup-nvidia.sh${NC}            🎮 NVIDIA drivers, CUDA toolkit, container runtime"
echo -e "${GREEN}setup-docker.sh${NC}            🐳 Docker Engine, Docker Compose, GPU support"
echo -e "${GREEN}../portainer/setup-portainer.sh${NC} 🎛️  Portainer container management interface"
echo

echo -e "${BLUE}ℹ️  UTILITY SCRIPTS:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}usage-guide.sh${NC}             📖 Display usage guide and quick reference"
echo -e "${GREEN}update-portainer-password.sh${NC} 🔐 Update Portainer admin password"
echo -e "${GREEN}list-scripts.sh${NC}            📋 This script - list all available scripts"
echo

echo -e "${BLUE}📁 FILES STRUCTURE:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "."
echo "├── README.md                    # Comprehensive documentation"
echo "└── scripts/"
echo "    ├── check-prerequisites.sh  # System requirements check"
echo "    ├── setup-datacenter.sh     # Main setup orchestrator"
echo "    ├── setup-system-utils.sh   # System utilities installation"
echo "    ├── setup-nvidia.sh         # NVIDIA GPU configuration"
echo "    ├── setup-docker.sh         # Docker platform setup"
echo "    ├── setup-portainer.sh      # Legacy portainer script (use ../portainer/setup-portainer.sh)"
echo "├── portainer/"
echo "    ├── docker-compose.yml      # Portainer service definition"
echo "    ├── setup-portainer.sh      # Portainer deployment script"
echo "    └── README.md               # Portainer documentation"
echo "    ├── verify-setup.sh         # Installation verification"
echo "    ├── usage-guide.sh          # Usage instructions"
echo "    ├── update-portainer-password.sh # Portainer password management"
echo "    └── list-scripts.sh         # This listing"
echo

echo -e "${BLUE}🎯 RECOMMENDED WORKFLOW:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${YELLOW}1.${NC} ./scripts/check-prerequisites.sh    # Check system requirements"
echo -e "${YELLOW}2.${NC} ./scripts/setup-datacenter.sh       # Run complete setup"
echo -e "${YELLOW}3.${NC} sudo reboot                         # Reboot system"
echo -e "${YELLOW}4.${NC} ./scripts/verify-setup.sh           # Verify installation"
echo

echo -e "${BLUE}💡 QUICK TIPS:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "• All scripts are designed to be idempotent (safe to re-run)"
echo "• Scripts check for existing installations before proceeding"
echo "• Run as regular user with sudo privileges (NOT as root)"
echo "• Each script can be run individually if needed"
echo "• Check README.md for detailed documentation and troubleshooting"
echo

echo -e "${BLUE}📊 POST-SETUP ACCESS:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "• Portainer Web UI: http://$(hostname -I | awk '{print $1}'):9000"
echo "• Admin credentials: /opt/portainer/admin_password.txt"
echo "• Management scripts: /opt/portainer/{start,stop,restart}.sh"