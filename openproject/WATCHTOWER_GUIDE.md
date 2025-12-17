# Watchtower Auto-Update Guide

This guide explains how Watchtower is configured to automatically update your OpenProject containers when new versions of the `16-slim` tag are released.

## What is Watchtower?

Watchtower is a container-based solution for automating Docker container updates. It monitors running containers and automatically pulls new images and recreates containers when updates are available.

## How It Works

### Monitoring
- **Polling Interval**: Watchtower checks for updates every 3600 seconds (1 hour)
- **Scope**: Only monitors containers with the label `com.centurylinklabs.watchtower.scope=openproject`
- **Watched Services**: web, worker, cron, seeder, proxy, and autoheal containers
- **Excluded Services**: Database and cache are excluded to prevent data loss

### Update Process
1. **Detection**: Watchtower checks if the `openproject/openproject:16-slim` image has a new version
2. **Download**: Downloads the new image if available
3. **Stop**: Gracefully stops the existing container
4. **Recreate**: Creates a new container with the updated image
5. **Cleanup**: Removes the old image (cleanup enabled)
6. **Restart**: Starts the new container with the same configuration

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `WATCHTOWER_CLEANUP` | `true` | Remove old images after update |
| `WATCHTOWER_POLL_INTERVAL` | `3600` | Check for updates every hour |
| `WATCHTOWER_LABEL_ENABLE` | `true` | Only watch labeled containers |
| `WATCHTOWER_SCOPE` | `openproject` | Scope for monitoring |
| `WATCHTOWER_INCLUDE_RESTARTING` | `true` | Include restarting containers |
| `WATCHTOWER_REVIVE_STOPPED` | `true` | Restart stopped containers |
| `WATCHTOWER_TIMEOUT` | `60s` | Timeout for operations |
| `WATCHTOWER_NOTIFICATIONS` | `""` | Notification system (disabled by default) |

### Container Labels

#### Watched Containers (Auto-Updated)
These containers have the following labels and will be automatically updated:
```yaml
labels:
  - "com.centurylinklabs.watchtower.enable=true"
  - "com.centurylinklabs.watchtower.scope=openproject"
```

**Services**: web, worker, cron, seeder, proxy, autoheal

#### Excluded Containers (Never Updated)
These containers have watchtower disabled:
```yaml
labels:
  - "com.centurylinklabs.watchtower.enable=false"
```

**Services**: db, cache, watchtower

### Notification Configuration

To enable notifications, add these environment variables to your `.env` file:

```bash
# Slack notifications
WATCHTOWER_NOTIFICATIONS=slack
WATCHTOWER_NOTIFICATION_SLACK_HOOK_URL=https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK
WATCHTOWER_NOTIFICATION_SLACK_IDENTIFIER=openproject-watchtower
WATCHTOWER_NOTIFICATION_TEMPLATE=Updated container {{.Entry.Image}} to {{.Image}}

# Or disable notifications
WATCHTOWER_NOTIFICATIONS=
```

## Usage

### Starting with Watchtower
```bash
docker compose up -d
```

Watchtower will automatically start monitoring for updates.

### Manual Update Check
To force an immediate update check:
```bash
docker compose exec watchtower /watchtower --run-once --scope openproject
```

### Stopping Auto-Updates
To temporarily stop automatic updates:
```bash
docker compose stop watchtower
```

### Permanently Disabling Updates
To disable updates for a specific container, set:
```yaml
labels:
  - "com.centurylinklabs.watchtower.enable=false"
```

## Update Scenarios

### Scenario 1: Minor Version Update
When OpenProject releases `16-slim` with bug fixes:
- Watchtower detects the new image
- Automatically updates all OpenProject containers
- Zero downtime due to graceful restart
- Database and cache remain unchanged

### Scenario 2: Major Version Upgrade
When OpenProject releases `17-slim`:
- **Manual action required**: Change `TAG` in `.env` file
- Updates won't happen automatically due to different tag
- Follow upgrade procedures in main documentation

### Scenario 3: Container Issues
If a new container fails to start:
- Watchtower will retry based on timeout settings
- Old container remains running if possible
- Check logs for troubleshooting

## Monitoring and Logs

### View Watchtower Logs
```bash
docker compose logs -f watchtower
```

### View Update History
```bash
docker compose logs watchtower | grep "Found new image"
```

### Monitor Container Health
```bash
docker compose ps
```

## Safety Features

### Data Protection
- **Database**: Never automatically updated
- **Volumes**: Persisted across updates
- **Configuration**: Preserved in docker-compose.yml

### Rollback Capability
If an update causes issues:
1. Identify the previous image tag: `docker images openproject/openproject`
2. Update `.env` file: `TAG=16-slim@sha256:<previous-sha>`
3. Restart: `docker compose up -d`

### Graceful Updates
- **Health Checks**: Containers wait for healthy status
- **Dependencies**: Proper start/stop order maintained
- **Timeouts**: Prevents hanging operations

## Best Practices

### 1. Backup Before Updates
```bash
# Create backup before major updates
docker compose down
docker run --rm -v openproject_pgdata:/data -v $(pwd):/backup alpine tar czf /backup/backup-$(date +%Y%m%d).tar.gz -C /data .
docker compose up -d
```

### 2. Monitor Update Windows
- Schedule updates during low-traffic periods
- Monitor logs during first hour after update
- Verify all services are healthy

### 3. Test Updates
- Test updates in staging environment first
- Verify enterprise token functionality
- Check for breaking changes

### 4. Notification Setup
- Configure Slack/email notifications
- Set up monitoring alerts
- Document update procedures

## Troubleshooting

### Common Issues

#### Updates Not Happening
- Verify watchtower is running: `docker compose ps watchtower`
- Check labels: `docker inspect openproject-web-1 | grep Labels`
- Review logs: `docker compose logs watchtower`

#### Container Fails to Start
- Check logs: `docker compose logs web`
- Verify image: `docker images openproject/openproject`
- Check resource availability

#### Database Connection Issues
- Database not updated, verify it's running: `docker compose ps db`
- Check network connectivity: `docker compose exec web ping db`
- Review database logs: `docker compose logs db`

### Recovery Procedures

#### If Update Fails
1. Check logs: `docker compose logs watchtower`
2. Restart services: `docker compose restart`
3. If needed, rollback to previous version

#### If Container Crashes
1. Identify problematic container
2. Check logs for error messages
3. Restart individual service: `docker compose restart web`

#### Complete System Recovery
1. Stop all services: `docker compose down`
2. Restore from backup if needed
3. Restart: `docker compose up -d`

## Advanced Configuration

### Custom Update Schedule
To update only at specific times, modify the Watchtower service:
```yaml
watchtower:
  image: containrrr/watchtower:latest
  command: --schedule "0 2 * * *"  # Daily at 2 AM
  # ... other config
```

### Multiple Image Tags
To track multiple OpenProject versions:
```yaml
web:
  image: openproject/openproject:${TAG:-16-slim}
  labels:
    - "com.centurylinklabs.watchtower.enable=true"
    - "com.centurylinklabs.watchtower.scope=openproject"
```

### Update Windows
To restrict updates to maintenance windows:
```yaml
watchtower:
  command: --monitor-only  # Don't auto-update
  # Then run manual updates during maintenance
```

This Watchtower setup ensures your OpenProject stays current with the latest security patches and bug fixes while maintaining data integrity and system stability.