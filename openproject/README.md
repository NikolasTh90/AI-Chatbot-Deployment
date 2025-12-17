# OpenProject Portable Docker Setup

This is a completely portable Docker Compose setup for OpenProject that includes the enterprise token embedded directly in the configuration, eliminating the need for external file dependencies. It's designed to work behind an nginx proxy manager without exposing ports to the physical machine.

## Features

- **✅ Completely Portable**: No external file dependencies - enterprise token is embedded
- **✅ Enterprise Enabled**: Full OpenProject features via embedded enterprise token
- **✅ Auto-Updates**: Watchtower monitors and updates `16-slim` tag automatically
- **✅ Proxy Manager Ready**: Configured for nginx proxy manager on ports 80/443
- **✅ Internal Networking**: Uses proxy-network for internal communication
- **✅ Self-Contained**: Everything needed is in the docker-compose.yml file
- **✅ Zero External Dependencies**: No files required besides docker-compose.yml

## Quick Start

1. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```

2. Edit the `.env` file if you need to customize any settings (optional)

3. Start the containers:
   ```bash
   docker compose up -d
   ```

4. Configure your nginx proxy manager to route traffic to the `proxy` service (internal container name)

5. **Enterprise token is automatically injected** - no external files needed!

## Configuration

### Proxy Manager Setup
- The service is available internally on the `proxy-network`
- Route traffic from your nginx proxy manager to the `proxy` container
- No ports are exposed to the physical machine

### HTTPS Configuration
Since you're using an nginx proxy manager, HTTPS termination should be handled at the proxy manager level. Configure OpenProject to work behind HTTPS:
```bash
OPENPROJECT_HTTPS=true OPENPROJECT_HOST__NAME=your-domain.com docker compose up -d
```

### Data Persistence
Data is persisted in Docker volumes:
- `pgdata`: PostgreSQL database
- `opdata`: OpenProject assets and attachments

## Enterprise Token

The enterprise token is embedded directly in the docker-compose.yml file and automatically injected into all OpenProject containers (web, worker, cron, seeder) on startup. This enables all enterprise features like KanBan boards without requiring any external files.

The embedded token:
- Enables all enterprise features
- Never expires
- Shows no banners in settings
- Is automatically applied to all services

## Services

- **web**: Main OpenProject web application (internal only)
- **worker**: Background job processor
- **cron**: Scheduled tasks
- **seeder**: Database initialization
- **db**: PostgreSQL database
- **cache**: Memcached for session storage
- **proxy**: nginx reverse proxy (internal, accessible via proxy-network)
- **autoheal**: Container health monitoring

## Network Configuration

This setup uses three networks:
- **frontend**: Internal communication between web and proxy
- **backend**: Database and cache communication
- **proxy-network**: External network for nginx proxy manager (external)

The `proxy-network` should be created separately and shared with your nginx proxy manager:

```bash
docker network create proxy-network
```

## nginx Proxy Manager Configuration

Add a proxy host in your nginx proxy manager with the following settings:
- **Scheme**: http
- **Forward Hostname/IP**: `proxy` (container name)
- **Forward Port**: `80`

Make sure your nginx proxy manager is connected to the same `proxy-network`.

## Troubleshooting

### Logs
View logs for all services:
```bash
docker compose logs
```

View logs for a specific service:
```bash
docker compose logs web
```

### Restart Services
Restart all services:
```bash
docker compose restart
```

Restart a specific service:
```bash
docker compose restart web
```

### Stop and Remove
Stop all containers:
```bash
docker compose down
```

Remove containers and volumes (WARNING: This deletes all data):
```bash
docker compose down -v
```

## Upgrade

To upgrade to a newer version:
```bash
docker compose pull
docker compose up -d --force-recreate
```

## Notes

- This setup uses a simplified nginx proxy instead of the custom build proxy to eliminate build context issues
- The enterprise token is embedded directly in the compose file for maximum portability
- All OpenProject services automatically receive the enterprise token on startup
- The setup is compatible with standard Docker Compose environments