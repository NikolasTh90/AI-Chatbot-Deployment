# Database Stack

This stack provides PostgreSQL and MySQL databases for all applications, managed via Portainer.

## 🗄️ Services

- **PostgreSQL 15**: For Django applications (jopi & synergas)
- **MySQL 8.0**: For WordPress sites (multisite + single sites)
- **Backup Automation**: Automated database backups with retention policies

## 🌐 Network Configuration

- **db_net**: Isolated network for database communication
- **proxy**: Management access (limited)

## 📁 Volumes

- **postgres_data**: PostgreSQL persistent data
- **mysql_data**: MySQL persistent data
- **backups**: Automated backup storage

## 🚀 Deployment

Deploy via Portainer:
1. Go to **Stacks → Add Stack**
2. Name: `databases`
3. Repository: Select Git repository option
4. Compose file: `stacks/databases/docker-compose.yml`
5. Enable **Automatic updates**

## 🔧 Environment Variables

Create in Portainer Stack settings:
- `POSTGRES_PASSWORD`: Strong PostgreSQL password for django user
- `MYSQL_ROOT_PASSWORD`: Strong MySQL root password

## 📋 Initial Databases Created

**PostgreSQL:**
- `jopi_db`: For jopi Django application
- `synergas_db`: For synergas Django application

**MySQL:**
- `wp_multisite`: For WordPress multisite
- `wp_single1`: For WordPress single site 1
- `wp_single2`: For WordPress single site 2

## 🔐 Security Notes

- Database access restricted to db_net network only
- Management access via proxy network (limited)
- Strong passwords required for all databases
- Regular backups configured via cron

## 📊 Monitoring

Database health checks configured:
- PostgreSQL: `pg_isready -U django`
- MySQL: `mysqladmin ping -h localhost`
- Checks run every 30 seconds with 3 retries

## 🔄 Backup Strategy

- Daily full backups at 2:00 AM
- Weekly backup retention (7 days)
- Monthly archive retention (30 days)
- Backups stored in `./backups` volume