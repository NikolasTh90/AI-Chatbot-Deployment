# Nginx Proxy Manager

This directory contains the standalone Nginx Proxy Manager deployment.

## 📋 Overview

Nginx Proxy Manager provides a web interface for managing Nginx proxy configurations, SSL certificates, and routing traffic to your containerized services.

## 🚀 Quick Start

### Prerequisites

1. **Docker and Docker Compose installed**
2. **Proxy network created** (should be done automatically by setup scripts)

### Deploy Nginx Proxy Manager

1. **Create the proxy network** (if not exists):
   ```bash
   docker network create proxy
   ```

2. **Deploy using Docker Compose**:
   ```bash
   docker compose up -d
   ```

3. **Access the web interface**:
   - URL: http://YOUR_SERVER_IP:81
   - Default credentials:
     - Username: `admin@example.com`
     - Password: `changeme`

4. **Change default credentials immediately after first login**

## 📁 Structure

```
proxy/nginx-proxy-manager/
├── docker-compose.yml          # NPM service definition
├── README.md                   # This file
├── data/                       # NPM configuration data (created on first run)
└── letsencrypt/               # SSL certificates storage
```

## 🔧 Configuration

### Ports
- **80**: HTTP traffic (redirected to HTTPS)
- **81**: NPM web interface
- **443**: HTTPS traffic

### Volumes
- `./data:/data` - Persistent NPM configuration and database
- `./letsencrypt:/etc/letsencrypt` - SSL certificates storage

### Networks
- **proxy**: External network for connecting to other services

## 🌐 Managing Services

### Adding a New Service

1. **Access NPM web interface** (http://YOUR_SERVER_IP:81)
2. **Go to "Hosts" → "Proxy Hosts"**
3. **Click "Add Proxy Host"**
4. **Configure the proxy**:
   - **Domain Names**: your.domain.com
   - **Scheme**: http
   - **Forward Hostname/IP**: container_name (e.g., `open-webui`)
   - **Forward Port**: service port (e.g., `8080`)

### SSL Certificates

NPM can automatically obtain and manage Let's Encrypt SSL certificates:

1. **Edit a proxy host**
2. **Go to "SSL" tab**
3. **Select "Request a new SSL Certificate"**
4. **Enable "Force SSL" and "HTTP/2 Support"**
5. **Save**

## 🔍 Common Service Configurations

### Portainer
- **Forward Hostname**: `portainer`
- **Forward Port**: `9000`
- **Domain**: portainer.yourdomain.com

### Open WebUI (AI Stack)
- **Forward Hostname**: `open-webui`
- **Forward Port**: `8080`
- **Domain**: ai.yourdomain.com

### Any Docker Service
- **Forward Hostname**: `container_name`
- **Forward Port**: `service_port`
- **Domain**: service.yourdomain.com

## 🎛️ Management Commands

### Start NPM
```bash
docker compose up -d
```

### Stop NPM
```bash
docker compose down
```

### Restart NPM
```bash
docker compose restart
```

### View Logs
```bash
docker compose logs -f nginx-proxy-manager
```

### Update NPM
```bash
docker compose pull
docker compose up -d
```

## 🔐 Security Best Practices

1. **Change default credentials** immediately
2. **Use strong passwords**
3. **Enable 2FA if available**
4. **Regular updates**
5. **Monitor access logs**
6. **Use SSL certificates** for all public-facing services
7. **Configure fail2ban** for additional protection

## 🌍 DNS Configuration

For domain-based routing, configure your DNS:

1. **Point your domain to your server's public IP**
2. **Create A records** for subdomains:
   ```
   A  @              YOUR_SERVER_IP
   A  www            YOUR_SERVER_IP
   A  portainer      YOUR_SERVER_IP
   A  ai             YOUR_SERVER_IP
   A  *              YOUR_SERVER_IP  (wildcard)
   ```

## 🔧 Troubleshooting

### NPM Won't Start
```bash
# Check if ports are in use
sudo netstat -tulpn | grep -E ':80|:81|:443'

# Check Docker logs
docker compose logs nginx-proxy-manager

# Check proxy network
docker network ls | grep proxy
```

### Can't Access Services
```bash
# Verify containers are in proxy network
docker network inspect proxy

# Check service connectivity
docker exec nginx-proxy-manager ping container_name
```

### SSL Certificate Issues
```bash
# Check certificate status in NPM web interface
# Verify domain DNS resolution
dig your.domain.com

# Check Let's Encrypt rate limits
# Wait 1 hour between certificate attempts
```

### Service Not Accessible via Proxy
1. **Verify service is running**: `docker ps`
2. **Check proxy host configuration** in NPM
3. **Ensure service is in proxy network**
4. **Test direct container access**: `docker exec -it container_name wget -O- http://localhost:port`

## 📝 Notes

- **This NPM instance manages the proxy network**
- **All services should join the 'proxy' network**
- **Services should NOT expose ports directly** (except for NPM itself)
- **Use container names as hostnames** in NPM configurations
- **SSL certificates are automatically renewed**

## 🔗 Integration with Other Services

When deploying other stacks:

1. **Ensure they join the proxy network**:
   ```yaml
   networks:
     - proxy
   
   networks:
     proxy:
       external: true
   ```

2. **Remove port exposures** from services (except for debugging)
3. **Configure proxy hosts in NPM** to route traffic to services
4. **Use container names** as forward hostnames in NPM