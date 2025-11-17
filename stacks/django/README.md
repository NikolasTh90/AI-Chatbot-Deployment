# Django Applications Stack

This stack manages Django/Wagtail applications (jopi & synergas) with CI/CD integration, fully managed via Portainer.

## 🐍 Applications

- **jopi**: Django/Wagtail application for content management
- **synergas**: Django/Wagtail application for business operations

## 🚀 Features

- **Zero-downtime deployments** via GitHub Actions + Portainer GitOps
- **Health checks** with automatic restart
- **Environment variable management** via Portainer secrets
- **Performance monitoring** with optimized Gunicorn configuration
- **Security hardening** with non-root user execution

## 🌐 Network Configuration

- **proxy**: External access through Nginx Proxy Manager
- **db_net**: Database connectivity (PostgreSQL)

## 📦 Container Features

- **Python 3.12** with latest security patches
- **Gunicorn WSGI server** with 3 workers
- **Health checks** on `/health/` endpoint
- **Automatic updates** via Git repository polling
- **Rollback capability** via GitHub SHA tags

## 🔄 CI/CD Pipeline

1. **Push to GitHub** → Automatic build and push to container registry
2. **Portainer detects change** → Automatic deployment
3. **Health check validation** → Traffic routing
4. **Failed deployment** → Automatic rollback

## 🔧 Environment Variables

Configure in Portainer Stack settings:

**Common Variables:**
- `DOCKER_REGISTRY`: Your container registry URL
- `DJANGO_SETTINGS_MODULE`: `config.settings.production`

**jopi Application:**
- `DJANGO_SECRET_KEY`: Django secret key
- `DATABASE_URL`: PostgreSQL connection string
- `ALLOWED_HOSTS`: Comma-separated domain names

**synergas Application:**
- `DJANGO_SECRET_KEY`: Django secret key
- `DATABASE_URL`: PostgreSQL connection string
- `ALLOWED_HOSTS`: Comma-separated domain names

## 📊 Performance Optimizations

- **Gunicorn workers**: 3 processes with automatic scaling
- **Memory limits**: 1GB per container
- **Connection pooling**: Database connection optimization
- **Static files**: Served via Nginx Proxy Manager

## 🔐 Security Features

- **Non-root execution**: All containers run as non-root user
- **Read-only filesystem**: Except for required writable paths
- **Health monitoring**: Automatic restart on failures
- **Secret management**: Environment variables via Portainer

## 📋 Deployment Instructions

### Via Portainer (Recommended):
1. **Stacks → Add Stack**
2. Name: `django-apps`
3. Repository: Git repository option
4. Compose file: `stacks/django/docker-compose.yml`
5. Add environment variables
6. Enable **Automatic updates**
7. Deploy

### Manual Deployment:
```bash
cd stacks/django
docker-compose up -d
```

## 🔍 Health Monitoring

Each application exposes a `/health/` endpoint:
```python
# config/urls.py
from django.http import JsonResponse

def health_check(request):
    return JsonResponse({
        'status': 'healthy',
        'timestamp': timezone.now().isoformat()
    })
```

## 🚨 Troubleshooting

### Application not starting:
1. Check environment variables in Portainer
2. Verify database connectivity
3. Review container logs in Portainer

### Health checks failing:
1. Ensure `/health/` endpoint is accessible
2. Check database connection
3. Verify static files configuration

### Performance issues:
1. Monitor resource usage in Portainer
2. Check Gunicorn worker configuration
3. Optimize database queries

## 📈 Scaling

### Horizontal Scaling:
```yaml
# In docker-compose.yml
deploy:
  replicas: 3
```

### Vertical Scaling:
Update memory/CPU limits in compose file

## 🔄 Updates

### Automatic Updates:
- Enable Git repository polling in Portainer
- Set polling interval to 60 seconds
- Containers auto-update on GitHub push

### Manual Updates:
1. **Recreating stack** in Portainer
2. **Pull latest images** option
3. Deploy changes

## 📝 Development

### Local Development:
1. Copy `.env.template` to `.env.local`
2. Update database URLs to local PostgreSQL
3. Run `docker-compose up -d`

### Production Deployment:
1. Push changes to main branch
2. GitHub Actions builds new image
3. Portainer auto-deploys latest version
4. Monitor health checks and logs