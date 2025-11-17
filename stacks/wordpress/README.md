# WordPress Stack - Production Deployment

Complete WordPress hosting solution with multisite and single site configurations, optimized for production deployment with health monitoring and automated backups.

## 🌟 Stack Components

### **WordPress Sites**
- **wp_multisite**: WordPress multisite network (primary site + subdomains)
- **wp_single1**: Single WordPress site (portfolio/business)
- **wp_single2**: Single WordPress site (blog/personal)
- **backup-wordpress**: Automated backup service

### **Technical Specifications**
- **WordPress Version**: Latest with PHP 8.2
- **Web Server**: Apache with performance optimization
- **Database**: MySQL 8.0 shared with other stacks
- **Backup**: Daily automated with 30-day retention
- **Health Monitoring**: Built-in health checks and recovery

## 🚀 Quick Start

### **1. Environment Variables**
Set up environment variables in `.env` file or Portainer:

```env
# WordPress Database Passwords
WP_MULTI_PASSWORD=your_multisite_password
WP_SINGLE1_PASSWORD=your_single1_password
WP_SINGLE2_PASSWORD=your_single2_password
MYSQL_ROOT_PASSWORD=your_mysql_root_password

# Optional: WordPress Configuration
WP_MULTISITE_DOMAIN=multisite.yourdomain.com
WP_SINGLE1_DOMAIN=site1.yourdomain.com
WP_SINGLE2_DOMAIN=site2.yourdomain.com
```

### **2. Deploy Stack**

**Via Portainer (Recommended)**:
1. Go to **Stacks → Add stack**
2. Select **Git repository** or **Web editor**
3. Copy/paste [`docker-compose.yml`](docker-compose.yml:1) content
4. Add environment variables
5. Click **Deploy the stack**

**Via CLI**:
```bash
# With environment file
docker-compose --env-file .env up -d

# Or with Portainer
docker stack deploy -c docker-compose.yml wordpress
```

### **3. Access WordPress Sites**
- **Multisite Admin**: `https://multisite.yourdomain.com/wp-admin`
- **Single Site 1 Admin**: `https://site1.yourdomain.com/wp-admin`
- **Single Site 2 Admin**: `https://site2.yourdomain.com/wp-admin`

## 📁 Directory Structure

```
stacks/wordpress/
├── docker-compose.yml           # Main stack configuration
├── README.md                    # This documentation
├── config/
│   └── php.ini                  # Production PHP configuration
├── multisite/
│   └── html/                    # Multisite WordPress files
├── single1/
│   └── html/                    # Single site 1 WordPress files
├── single2/
│   └── html/                    # Single site 2 WordPress files
└── backup-scripts/
    ├── backup-wordpress.sh      # Automated backup script
    └── restore-wordpress.sh     # Restore script
```

## ⚙️ Configuration

### **PHP Configuration** ([`config/php.ini`](config/php.ini:1))
```ini
# Performance Settings
memory_limit = 256M
max_execution_time = 300
max_input_vars = 3000
upload_max_filesize = 64M
post_max_size = 64M

# Security Settings
expose_php = Off
allow_url_fopen = Off
disable_functions = exec,passthru,shell_exec,system
```

### **WordPress Constants**
Add to each site's `wp-config.php`:

```php
// Security
define('WP_DEBUG', false);
define('WP_DEBUG_LOG', false);
define('DISALLOW_FILE_EDIT', true);
define('DISALLOW_FILE_MODS', true);

// Performance
define('WP_MEMORY_LIMIT', '256M');
define('WP_MAX_MEMORY_LIMIT', '512M');

// Multisite Specific (for multisite)
define('WP_ALLOW_MULTISITE', true);
define('MULTISITE', true);
define('SUBDOMAIN_INSTALL', true);
define('DOMAIN_CURRENT_SITE', 'multisite.yourdomain.com');
define('PATH_CURRENT_SITE', '/');
define('SITE_ID_CURRENT_SITE', 1);
define('BLOG_ID_CURRENT_SITE', 1);
```

## 🔧 Management

### **Health Monitoring**
Check stack health:
```bash
# Check individual sites
docker exec wp_multisite curl -f http://localhost
docker exec wp_single1 curl -f http://localhost
docker exec wp_single2 curl -f http://localhost

# Health status
docker-compose ps
```

### **Backup Operations**

**Manual Backup**:
```bash
# Execute backup manually
docker exec backup-wordpress /scripts/backup-wordpress.sh

# List backups
ls -la stacks/wordpress/backups/
```

**Restore from Backup**:
```bash
# Restore specific database
docker exec backup-wordpress /scripts/restore-wordpress.sh multisite backup_file.sql.gz
```

### **Site Management**

**Plugin Management**:
```bash
# Install plugin via WP-CLI (install on all containers)
docker exec wp_multisite wp plugin install plugin-name --activate
docker exec wp_single1 wp plugin install plugin-name --activate
docker exec wp_single2 wp plugin install plugin-name --activate
```

**Theme Updates**:
```bash
# Update themes
docker exec wp_multisite wp theme update --all
docker exec wp_single1 wp theme update --all
docker exec wp_single2 wp theme update --all
```

## 🔄 Migration Procedures

### **From Existing WordPress**

**1. Export Site Data**:
```bash
# On old server
wp db export site_name.sql.gz
tar -czf site_name_files.tar.gz wp-content/
```

**2. Import to New Stack**:
```bash
# Copy files to new server
scp site_name.sql.gz user@server:/stacks/wordpress/backups/
scp site_name_files.tar.gz user@server:/tmp/

# Restore database
docker exec -i mysql-main mysql -u wp_multi_user -p wp_multisite < site_name.sql.gz

# Extract files
tar -xzf /tmp/site_name_files.tar.gz -C stacks/wordpress/multisite/html/
```

**3. Update Configuration**:
- Update `wp-config.php` with new database credentials
- Update site URLs in database:
```bash
docker exec wp_multisite wp search-replace 'old-domain.com' 'new-domain.com'
```

### **WordPress Multisite Setup**

**1. Enable Multisite**:
Add to `wp-config.php`:
```php
define('WP_ALLOW_MULTISITE', true);
```

**2. Network Setup**:
- Visit WordPress Admin → Tools → Network Setup
- Choose subdomain or subdirectory installation
- Copy provided code to `wp-config.php` and `.htaccess`

**3. Add Sites to Network**:
```bash
# Add new site to network
docker exec wp_multisite wp site create --slug=newsite --title="New Site"
```

## 🔒 Security

### **WordPress Security**
- **File Permissions**: Automatically set to secure defaults
- **Database Access**: Limited users with minimal privileges
- **PHP Security**: Disabled dangerous functions and file access
- **Updates**: Automatic WordPress core, plugin, and theme updates

### **Container Security**
- **Non-root User**: WordPress runs as non-root user
- **Read-only Files**: Core WordPress files are read-only
- **Network Isolation**: Database access via dedicated network
- **Health Monitoring**: Automatic recovery from failures

## 📊 Monitoring

### **Performance Metrics**
```bash
# WordPress performance
docker exec wp_multisite wp eval 'echo memory_get_usage(true) / 1024 / 1024 . " MB\n";'

# Database performance
docker exec mysql-main mysql -u root -p -e "SHOW PROCESSLIST;"
```

### **Log Monitoring**
```bash
# WordPress logs
docker-compose logs -f wp_multisite
docker-compose logs -f wp_single1
docker-compose logs -f wp_single2

# Access logs
docker exec wp_multisite tail -f /var/log/apache2/access.log
```

## 🚀 Scaling and Optimization

### **Performance Optimization**

**Caching**:
```bash
# Install Redis plugin for object caching
docker exec wp_multisite wp plugin install redis-cache --activate
```

**CDN Integration**:
- Configure with Cloudflare or similar CDN
- Enable static file caching in Nginx Proxy Manager

**Database Optimization**:
```bash
# Optimize WordPress database
docker exec wp_multisite wp db optimize
```

### **Scaling Considerations**

**High Traffic Preparation**:
- Increase memory limits in `wp-config.php`
- Configure multiple PHP-FPM workers
- Implement load balancing with multiple containers

**Resource Limits**:
Adjust in [`docker-compose.yml`](docker-compose.yml:1):
```yaml
deploy:
  resources:
    limits:
      memory: 1G
      cpus: '0.5'
```

## 🔧 Troubleshooting

### **Common Issues**

**Database Connection Errors**:
```bash
# Check MySQL connectivity
docker exec wp_multisite wp db check

# Reset database credentials
docker exec wp_multisite wp config set DB_PASSWORD 'new_password'
```

**Plugin Conflicts**:
```bash
# Disable all plugins
docker exec wp_multisite wp plugin deactivate --all

# Re-enable one by one
docker exec wp_multisite wp plugin activate plugin-name
```

**File Permission Issues**:
```bash
# Fix WordPress file permissions
docker exec wp_multisite chown -R www-data:www-data /var/www/html
docker exec wp_multisite find /var/www/html -type d -exec chmod 755 {} \;
docker exec wp_multisite find /var/www/html -type f -exec chmod 644 {} \;
```

### **Recovery Procedures**

**Complete Site Restore**:
```bash
# Stop WordPress container
docker-compose stop wp_multisite

# Restore from backup
docker exec backup-wordpress /scripts/restore-wordpress.sh multisite latest_backup

# Restart container
docker-compose start wp_multisite
```

## 🔄 Updates and Maintenance

### **WordPress Updates**

**Automated Updates** (Recommended for security):
```php
// In wp-config.php
define('WP_AUTO_UPDATE_CORE', true);
define('AUTOMATIC_UPDATER_DISABLED', false);
```

**Manual Updates**:
```bash
# Update WordPress core
docker exec wp_multisite wp core update

# Update all plugins
docker exec wp_multisite wp plugin update --all

# Update all themes
docker exec wp_multisite wp theme update --all
```

### **Stack Updates**

**Update Docker Images**:
```bash
# Pull latest images
docker-compose pull

# Recreate containers
docker-compose up -d --force-recreate
```

## 🌐 Domain Configuration

### **Nginx Proxy Manager Configuration**
Create proxy hosts for each WordPress site:

**Multisite Configuration**:
```nginx
server_name multisite.yourdomain.com *.multisite.yourdomain.com
proxy_pass http://wp_multisite:80
```

**Single Site Configuration**:
```nginx
server_name site1.yourdomain.com
proxy_pass http://wp_single1:80
```

### **SSL/TLS**
- Enable SSL in Nginx Proxy Manager
- Configure automatic certificate renewal
- Set up HTTPS redirects

## 📈 Performance Monitoring

### **Key Metrics**
- **Response Time**: Page load time < 2 seconds
- **Uptime**: 99.9% availability target
- **Database Performance**: Query time < 100ms
- **Memory Usage**: < 80% of allocated memory

### **Alerting**
Set up alerts for:
- Container downtime or restarts
- High memory usage (> 90%)
- Database connection failures
- Backup failures

## 💰 Cost Optimization

**Shared Resources**:
- Database shared across WordPress sites
- Backup service consolidates backup operations
- Efficient resource allocation with limits

**Storage Optimization**:
- Automatic backup cleanup with retention policies
- Media file optimization via plugins
- Database cleanup and optimization

---

## 🎯 Ready for Production

This WordPress stack provides:
- **🏢 Enterprise Security**: hardened configuration and isolation
- **⚡ High Performance**: optimized PHP and database settings
- **🔄 Automated Backups**: daily backups with retention policies
- **📊 Health Monitoring**: proactive health checks and recovery
- **🚀 Easy Migration**: comprehensive import/export procedures
- **🔧 Simple Management**: Portainer integration and automated operations

Your WordPress hosting infrastructure is now production-ready with all the security, monitoring, and automation needed for reliable operation.