# Portainer Setup

This directory contains a standalone Portainer deployment using Docker Compose.

## 📁 Structure

```
portainer/
├── docker-compose.yml      # Portainer service definition
├── setup-portainer.sh      # Setup script
├── README.md               # This file
├── data/                   # Portainer data (created on first run)
├── admin_password.txt      # Plain text admin password (created on setup)
├── portainer_password      # Hashed admin password (created on setup)
├── start.sh                # Start Portainer (created on setup)
├── stop.sh                 # Stop Portainer (created on setup)
├── restart.sh              # Restart Portainer (created on setup)
└── logs.sh                 # View Portainer logs (created on setup)
```

## 🚀 Quick Start

1. **Run the setup script:**
   ```bash
   ./setup-portainer.sh
   ```

2. **Access Portainer:**
   - Open http://YOUR_SERVER_IP:9000 in your browser
   - Username: `admin`
   - Password: Check `admin_password.txt`

## 🎛️ Management

Once setup is complete, you can use these commands:

```bash
# Start Portainer
./start.sh

# Stop Portainer
./stop.sh

# Restart Portainer
./restart.sh

# View logs
./logs.sh
```

## 📋 Docker Compose Commands

You can also use standard Docker Compose commands:

```bash
# Start in background
docker compose up -d

# Stop services
docker compose down

# View logs
docker compose logs -f

# Check status
docker compose ps
```

## 🔧 Configuration

### Ports
- **9000**: Portainer web interface
- **9001**: Portainer agent (if using agent setup)

### Volumes
- `./data:/data` - Persistent Portainer data
- `./portainer_password:/data/portainer_password:ro` - Admin password file
- `/var/run/docker.sock:/var/run/docker.sock:ro` - Docker socket access

### Environment Variables
- `PUID=1000` - User ID for file permissions
- `PGID=1000` - Group ID for file permissions

## 🔐 Security

### Default Password
The setup script generates a secure random password and saves it in both:
- `admin_password.txt` (plain text for reference)
- `portainer_password` (bcrypt hash for Portainer)

### Password Update
To change the admin password:

1. **Using Portainer UI:** Log in and go to Users → admin → Change password
2. **Using script:** Run the password update script from the main project:
   ```bash
   ../scripts/update-portainer-password.sh
   ```

## 🌐 Network Access

### Local Access
- http://localhost:9000
- http://YOUR_LOCAL_IP:9000

### Remote Access
- http://YOUR_PUBLIC_IP:9000

**Security Warning:** For production use, always:
- Change the default password
- Set up SSL/TLS (HTTPS)
- Configure firewall rules
- Use strong authentication

## 🔍 Troubleshooting

### Container Won't Start
```bash
# Check logs
./logs.sh

# Check Docker status
docker ps -a | grep portainer

# Restart Docker daemon
sudo systemctl restart docker
```

### Permission Issues
```bash
# Fix data directory permissions
sudo chown -R 1000:1000 ./data

# Check file permissions
ls -la admin_password.txt portainer_password
```

### Port Already in Use
```bash
# Check what's using port 9000
sudo netstat -tulpn | grep :9000

# Kill process or change port in docker-compose.yml
```

### Password File Not Found
```bash
# Regenerate password files
rm -f admin_password.txt portainer_password
./setup-portainer.sh
```

## 🔄 Updates

To update Portainer to the latest version:

```bash
# Stop current instance
./stop.sh

# Pull latest image
docker compose pull

# Start with new image
./start.sh
```

## 📝 Notes

- The Docker Compose file uses relative paths (`./data`, `./portainer_password`)
- All scripts are designed to work from the portainer directory
- The setup script is idempotent (safe to run multiple times)
- Data persists between container restarts in the `./data` directory