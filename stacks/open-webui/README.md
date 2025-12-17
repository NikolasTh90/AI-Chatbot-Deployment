# Open WebUI Docker Stack

This Docker Compose stack provides Open WebUI service with automatic updates via Watchtower, configured for external proxy network usage.

## Services

- **open-webui**: The main Open WebUI application
- **watchtower**: Automatically updates the Open WebUI image when new versions are available

## Prerequisites

1. Docker and Docker Compose installed
2. An external Docker network named `proxy-network` must exist:
   ```bash
   docker network create proxy-network
   ```

## Configuration

### Environment Variables

Create a `.env` file in the same directory as `docker-compose.yml`:

```env
WEBUI_DOCKER_TAG=main
```

## Usage

### Start the stack:
```bash
docker-compose up -d
```

### Stop the stack:
```bash
docker-compose down
```

### View logs:
```bash
docker-compose logs -f open-webui
```

### Update Open WebUI manually:
```bash
docker-compose pull open-webui
docker-compose up -d --force-recreate
```

## Network Configuration

The Open WebUI service is configured to use an external `proxy-network` and does not expose any ports directly on the host machine. This allows you to route traffic through an external reverse proxy (like Nginx Proxy Manager, Traefik, etc.).

The Open WebUI application is accessible on port 8080 within the Docker network.

## Data Persistence

Open WebUI data is persisted using Docker volumes:
- `open-webui`: Stores application data and configurations

## Watchtower Configuration

Watchtower is configured to:
- Check for updates every hour (3600 seconds)
- Automatically update the Open Webui container
- Clean up old images after updates

## Security Notes

- The secret key is set to "1234" as requested, but for production use, you should generate a secure random key
- The service is not exposed directly to the internet and relies on external proxy for access control

## Customization

If you need to build Open WebUI from source instead of using the pre-built image, create a Dockerfile in the same directory and modify the build configuration in docker-compose.yml.