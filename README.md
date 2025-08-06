# NVIDIA GPU Data Center Instance Setup

This collection of utility scripts sets up an Ubuntu 24.04 LTS AWS G6 instance for GPU workloads with Docker and Portainer management.

## 🚀 Quick Start

1. **Clone or download this repository to your server**
2. **Make scripts executable:**
   ```bash
   chmod +x scripts/*.sh
   ```
3. **Run the main setup script:**
   ```bash
   ./scripts/setup-datacenter.sh
   ```
4. **Reboot the system after setup completes**
5. **Verify installation:**
   ```bash
   ./scripts/verify-setup.sh
   ```

## 📋 What Gets Installed

### System Utilities
- **nala** - Modern APT package manager
- **git** - Version control system
- **Helix (hx)** - Modern text editor
- **Build tools** - gcc, make, cmake, etc.
- **Development tools** - Python3, Node.js, pip, npm
- **System monitoring** - htop, iotop, iftop, nethogs, etc.
- **Network tools** - curl, wget, netstat, etc.
- **Utilities** - jq, tree, tmux, screen, etc.

### NVIDIA GPU Support
- **NVIDIA Drivers** - Latest recommended drivers
- **CUDA Toolkit** - Full CUDA development environment
- **NVIDIA Container Toolkit** - Docker GPU support

### Container Platform
- **Docker Engine** - Latest stable version
- **Docker Compose** - Both plugin and standalone versions
- **Portainer** - Web-based Docker management interface

## 🛠️ Individual Scripts

You can run individual setup scripts if needed:

### 1. System Utilities Setup
```bash
./scripts/setup-system-utils.sh
```
Installs essential system tools, development environment, and utilities.

### 2. NVIDIA GPU Setup
```bash
./scripts/setup-nvidia.sh
```
Configures NVIDIA drivers, CUDA toolkit, and container runtime.

### 3. Docker Setup
```bash
./scripts/setup-docker.sh
```
Installs Docker Engine, Docker Compose, and configures GPU support.

### 4. Portainer Setup
```bash
./scripts/setup-portainer.sh
```
Deploys Portainer for web-based container management.

### 5. System Verification
```bash
./scripts/verify-setup.sh
```
Verifies all components are properly installed and configured.

## 🔧 Configuration Details

### NVIDIA Configuration
- Installs latest recommended NVIDIA drivers
- Sets up CUDA toolkit with PATH configuration
- Configures NVIDIA Container Toolkit for Docker
- Enables GPU passthrough to containers

### Docker Configuration
- Installs from official Docker repository
- Configures optimized daemon settings
- Sets up log rotation and storage optimization
- Adds user to docker group for non-root access
- Enables NVIDIA GPU support in containers

### Portainer Configuration
- **Port**: 9000 (web interface)
- **Data Directory**: `/opt/portainer`
- **Default User**: `admin`
- **Password**: Generated and saved to `/opt/portainer/admin_password.txt`
- **Auto-start**: Enabled via systemd service

## 📊 Service URLs

After successful setup:

- **Portainer Web UI**: `http://YOUR_SERVER_IP:9000`
- **Portainer Agent**: `http://YOUR_SERVER_IP:9001` (if enabled)

## 🔐 Security Notes

### Default Credentials
- **Portainer Username**: `admin`
- **Portainer Password**: Check `/opt/portainer/admin_password.txt`

### Important Security Steps
1. **Change default passwords** immediately after first login
2. **Configure firewall rules** for production use
3. **Set up SSL/TLS certificates** for HTTPS access
4. **Regularly update** all components

## 🎛️ Management Commands

### Portainer Management
```bash
# Start Portainer
sudo /opt/portainer/start.sh

# Stop Portainer
sudo /opt/portainer/stop.sh

# Restart Portainer
sudo /opt/portainer/restart.sh

# Update admin password
./scripts/update-portainer-password.sh

# View logs
sudo docker logs portainer
```

### Portainer Management
```bash
# Start Portainer
sudo /opt/portainer/start.sh

# Stop Portainer
sudo /opt/portainer/stop.sh

# Restart Portainer
sudo /opt/portainer/restart.sh

# Update admin password
./scripts/update-portainer-password.sh

# View logs
sudo docker logs portainer
```

### Docker Management
```bash
# Check Docker status
sudo systemctl status docker

# View running containers
docker ps

# Test GPU access
docker run --rm --gpus all nvidia/cuda:12.2-base-ubuntu22.04 nvidia-smi
```

### System Monitoring
```bash
# GPU status
nvidia-smi

# System resources
htop

# Network monitoring
iftop

# Docker system info
docker system df
```

## 🔍 Troubleshooting

### Common Issues

#### 1. NVIDIA Drivers Not Loading
```bash
# Check driver status
nvidia-smi

# If drivers aren't loaded, reboot the system
sudo reboot
```

#### 2. Docker Permission Denied
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Logout and login again, or run:
newgrp docker
```

#### 3. Portainer Not Accessible
```bash
# Check if container is running
docker ps | grep portainer

# Check logs
docker logs portainer

# Restart Portainer
sudo /opt/portainer/restart.sh
```

#### 4. GPU Not Available in Docker
```bash
# Test NVIDIA Container Toolkit
docker run --rm --gpus all nvidia/cuda:12.2-base-ubuntu22.04 nvidia-smi

# If fails, restart Docker
sudo systemctl restart docker
```

### Log Locations
- **Docker logs**: `journalctl -u docker.service`
- **Portainer logs**: `docker logs portainer`
- **System logs**: `/var/log/syslog`
- **Setup logs**: Check terminal output during installation

## 🧪 Testing GPU Workloads

### Test CUDA Container
```bash
docker run --rm --gpus all nvidia/cuda:12.2-devel-ubuntu22.04 nvcc --version
```

### Test PyTorch with GPU
```bash
docker run --rm --gpus all pytorch/pytorch:latest python -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}'); print(f'GPU count: {torch.cuda.device_count()}')"
```

### Test TensorFlow with GPU
```bash
docker run --rm --gpus all tensorflow/tensorflow:latest-gpu python -c "import tensorflow as tf; print('GPU devices:', tf.config.list_physical_devices('GPU'))"
```

## 📝 System Requirements

- **OS**: Ubuntu 24.04 LTS
- **Instance Type**: AWS G6 (or compatible NVIDIA GPU instance)
- **Memory**: Minimum 4GB RAM (8GB+ recommended)
- **Storage**: Minimum 20GB free space (50GB+ recommended)
- **Network**: Internet connectivity for downloads
- **Privileges**: sudo access required

## 🔄 Updates and Maintenance

### Regular Maintenance
```bash
# Update system packages
sudo nala update && sudo nala upgrade

# Update Docker images
docker images --format "table {{.Repository}}:{{.Tag}}" | grep -v REPOSITORY | xargs -I {} docker pull {}

# Clean up unused Docker resources
docker system prune -af

# Update Portainer
sudo /opt/portainer/stop.sh
docker pull portainer/portainer-ce:latest
sudo /opt/portainer/start.sh
```

### Backup Important Data
```bash
# Backup Portainer data
sudo tar -czf portainer-backup-$(date +%Y%m%d).tar.gz /opt/portainer

# Backup Docker volumes
docker run --rm -v /var/lib/docker/volumes:/backup-source:ro -v $(pwd):/backup busybox tar -czf /backup/docker-volumes-$(date +%Y%m%d).tar.gz /backup-source
```

## 🤝 Contributing

Feel free to submit issues, fork the repository, and create pull requests for any improvements.

## 📄 License

This project is open source and available under the MIT License.

## ⚡ Performance Tips

1. **GPU Memory**: Monitor GPU memory usage with `nvidia-smi`
2. **Docker Storage**: Use overlay2 storage driver (configured by default)
3. **Container Resources**: Set appropriate CPU and memory limits
4. **Network**: Use Docker networks for service communication
5. **Monitoring**: Set up monitoring with Portainer's built-in tools

---

**Note**: Always test in a development environment before deploying to production. Ensure you understand the security implications of running containers with GPU access.