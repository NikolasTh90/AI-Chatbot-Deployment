# OpenProject Stack

This stack provides OpenProject project management system with full integration, managed via Portainer.

## 🚀 Features

- **Enterprise Project Management**: Complete project lifecycle management
- **Automated SSL certificates** via Nginx Proxy Manager integration
- **Database persistence** with PostgreSQL
- **File attachments** with dedicated storage
- **Email notifications** with SMTP configuration
- **Security hardening** with HTTPS enforcement

## 🗄️ System Components

- **OpenProject Application**: Main project management system
- **PostgreSQL Database**: Data persistence (shared with databases stack)
- **File Storage**: Persistent volume for attachments and documents

## 🌐 Network Configuration

- **proxy**: External access through Nginx Proxy Manager
- **db_net**: Database connectivity (shared PostgreSQL)

## 📦 Container Features

- **OpenProject Community**: Latest stable version
- **PostgreSQL 15**: Shared database instance
- **Persistent storage**: Data, attachments, and configuration
- **Health monitoring**: Automatic restart and health checks
- **Automatic updates**: Via Portainer GitOps

## 🔧 Environment Variables

Configure in Portainer Stack settings:

**Required Variables:**
- `OPENPROJECT_SECRET_KEY_BASE`: Strong secret key (generate with `openssl rand -hex 64`)
- `OPENPROJECT_HOST_NAME`: Your OpenProject domain (e.g., `openproject.yourdomain.com`)
- `DATABASE_URL`: PostgreSQL connection string

**Optional Variables:**
- `OPENPROJECT_HTTPS=true`: Force HTTPS (recommended)
- `OPENPROJECT_EMAIL_DELIVERY_METHOD`: SMTP configuration
- `SMTP_ADDRESS`: Your SMTP server
- `SMTP_AUTHENTICATION`: SMTP authentication method
- `SMTP_USER_NAME`: SMTP username
- `SMTP_PASSWORD`: SMTP password

## 🚀 Deployment Instructions

### Via Portainer (Recommended):
1. **Stacks → Add Stack**
2. Name: `openproject`
3. Repository: Git repository option
4. Compose file: `stacks/openproject/docker-compose.yml`
5. Add environment variables
6. Enable **Automatic updates**
7. Deploy

### Manual Deployment:
```bash
cd stacks/openproject
docker-compose up -d
```

## 📊 Volume Structure

```
openproject/
├── pgdata/          # Database files (shared with databases stack)
├── assets/          # File attachments and uploads
└── config/          # Configuration files
```

## 🔐 Security Features

- **HTTPS enforcement**: Automatic SSL via Nginx Proxy Manager
- **Database isolation**: Dedicated PostgreSQL database
- **File security**: Proper ownership and permissions
- **Container security**: Non-root execution where possible
- **Session security**: Secure cookie configuration

## 📈 Performance Optimizations

- **Database connection pooling**: Optimize PostgreSQL connections
- **File storage optimization**: Efficient attachment handling
- **Caching**: Built-in caching mechanisms
- **Resource limits**: Memory and CPU constraints

## 🔄 Administration

### Initial Setup:
1. Access OpenProject via configured domain
2. Create admin account
3. Configure basic settings
4. Set up email delivery
5. Import existing projects (optional)

### User Management:
- Create users and teams
- Configure permissions
- Set up project roles
- Manage notifications

### Project Configuration:
- Create project templates
- Configure work packages
- Set up custom fields
- Define workflows

## 🔍 Health Monitoring

Health checks include:
- **Web interface accessibility**: HTTP response validation
- **Database connectivity**: PostgreSQL connection status
- **File system integrity**: Volume mount verification
- **Memory usage**: Resource consumption monitoring

## 🚨 Troubleshooting

### Application not accessible:
1. Check Nginx Proxy Manager configuration
2. Verify domain DNS settings
3. Review container logs in Portainer
4. Confirm SSL certificate status

### Database connection errors:
1. Verify PostgreSQL container is running
2. Check database credentials in Portainer
3. Review connection string format
4. Test database connectivity

### File upload issues:
1. Check volume permissions
2. Verify available disk space
3. Review file size limits
4. Check attachment settings

### Email notification problems:
1. Verify SMTP configuration
2. Test SMTP connectivity
3. Check email delivery settings
4. Review OpenProject email logs

## 📚 Integration with Other Stacks

This OpenProject stack integrates with:
- **Database Stack**: Shared PostgreSQL for data persistence
- **Infrastructure Stack**: Nginx Proxy Manager for SSL and routing
- **Monitoring Stack**: Health checks and performance monitoring
- **Backup Stack**: Automated backup integration

## 🛠️ Customization

### Plugins and Extensions:
- Install via OpenProject admin interface
- Restart container to apply changes
- Test in staging environment first

### Theme Customization:
- Override CSS via configuration files
- Add custom logos and branding
- Test responsive design

### API Integration:
- RESTful API available for automation
- Webhook support for integrations
- API documentation available at `/api`

## 📝 Maintenance

### Regular Tasks:
- **Weekly**: Update plugins and extensions
- **Monthly**: Review user activity and licenses
- **Quarterly**: Performance optimization review
- **Annually**: Security audit and cleanup

### Backup Strategy:
- **Daily**: Automated database backups
- **Weekly**: File archive backups
- **Monthly**: Full system exports
- **Yearly**: Backup restoration testing

## 🌍 Multi-language Support

OpenProject supports multiple languages:
- English (default)
- German, French, Spanish, Italian
- Additional languages available
- Configure per-user preference

## 🔧 Advanced Configuration

### Performance Tuning:
- Adjust worker processes
- Optimize database queries
- Configure caching settings
- Monitor resource usage

### Security Hardening:
- Enable two-factor authentication
- Configure session timeout
- Set up password policies
- Monitor access logs

### Custom Workflows:
- Define project templates
- Create custom work packages
- Configure automated notifications
- Set up approval workflows