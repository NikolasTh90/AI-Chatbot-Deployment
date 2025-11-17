-- PostgreSQL Database Initialization
-- Creates databases for Django applications

-- Create Django application databases
CREATE DATABASE jopi_db 
    WITH ENCODING='UTF8' 
    LC_COLLATE='C' 
    LC_CTYPE='C' 
    TEMPLATE=template0;

CREATE DATABASE synergas_db 
    WITH ENCODING='UTF8' 
    LC_COLLATE='C' 
    LC_CTYPE='C' 
    TEMPLATE=template0;

-- Create WordPress users (if needed for any WordPress PostgreSQL connections)
CREATE USER wp_multi_user WITH PASSWORD 'WP_MULTI_PASSWORD';
CREATE USER wp_single1_user WITH PASSWORD 'WP_SINGLE1_PASSWORD';
CREATE USER wp_single2_user WITH PASSWORD 'WP_SINGLE2_PASSWORD';

-- Grant privileges on Django databases
GRANT ALL PRIVILEGES ON DATABASE jopi_db TO django;
GRANT ALL PRIVILEGES ON DATABASE synergas_db TO django;

-- Create backup user for automated backups
CREATE USER backup_user WITH PASSWORD 'BACKUP_PASSWORD';
GRANT CONNECT ON DATABASE default_db TO backup_user;
GRANT CONNECT ON DATABASE jopi_db TO backup_user;
GRANT CONNECT ON DATABASE synergas_db TO backup_user;

-- Grant read permissions to backup user
GRANT USAGE ON SCHEMA public TO backup_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO backup_user;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO backup_user;

-- Set default privileges for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO backup_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON SEQUENCES TO backup_user;

-- Create monitoring user for health checks
CREATE USER monitoring_user WITH PASSWORD 'MONITOR_PASSWORD';
GRANT CONNECT ON DATABASE default_db TO monitoring_user;
GRANT CONNECT ON DATABASE jopi_db TO monitoring_user;
GRANT CONNECT ON DATABASE synergas_db TO monitoring_user;
GRANT USAGE ON SCHEMA public TO monitoring_user;
GRANT SELECT ON pg_stat_activity TO monitoring_user;

-- Optimize PostgreSQL configuration for Django/Wagtail
\c jopi_db
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

\c synergas_db
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Create initial indexes for Django performance
\c jopi_db
CREATE INDEX IF NOT EXISTS idx_wagtail_page_path ON wagtail_core_page (path);
CREATE INDEX IF NOT EXISTS idx_wagtail_page_url_path ON wagtail_core_page (url_path);

\c synergas_db
CREATE INDEX IF NOT EXISTS idx_wagtail_page_path ON wagtail_core_page (path);
CREATE INDEX IF NOT EXISTS idx_wagtail_page_url_path ON wagtail_core_page (url_path);

COMMIT;