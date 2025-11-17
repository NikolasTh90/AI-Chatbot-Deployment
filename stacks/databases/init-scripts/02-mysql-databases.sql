-- MySQL Database Initialization
-- Creates databases and users for WordPress sites

-- Create WordPress databases with UTF8MB4 support
CREATE DATABASE IF NOT EXISTS wp_multisite 
    CHARACTER SET utf8mb4 
    COLLATE utf8mb4_unicode_ci;

CREATE DATABASE IF NOT EXISTS wp_single1 
    CHARACTER SET utf8mb4 
    COLLATE utf8mb4_unicode_ci;

CREATE DATABASE IF NOT EXISTS wp_single2 
    CHARACTER SET utf8mb4 
    COLLATE utf8mb4_unicode_ci;

-- Create WordPress users
CREATE USER IF NOT EXISTS 'wp_multi_user'@'%' 
    IDENTIFIED BY 'WP_MULTI_PASSWORD';

CREATE USER IF NOT EXISTS 'wp_single1_user'@'%' 
    IDENTIFIED BY 'WP_SINGLE1_PASSWORD';

CREATE USER IF NOT EXISTS 'wp_single2_user'@'%' 
    IDENTIFIED BY 'WP_SINGLE2_PASSWORD';

-- Create backup user for automated backups
CREATE USER IF NOT EXISTS 'backup_user'@'%' 
    IDENTIFIED BY 'BACKUP_PASSWORD';

-- Create monitoring user for health checks
CREATE USER IF NOT EXISTS 'monitoring_user'@'%' 
    IDENTIFIED BY 'MONITOR_PASSWORD';

-- Grant privileges on WordPress databases
GRANT ALL PRIVILEGES ON wp_multisite.* TO 'wp_multi_user'@'%';
GRANT ALL PRIVILEGES ON wp_single1.* TO 'wp_single1_user'@'%';
GRANT ALL PRIVILEGES ON wp_single2.* TO 'wp_single2_user'@'%';

-- Grant read permissions to backup user
GRANT SELECT, LOCK TABLES, SHOW VIEW ON wp_multisite.* TO 'backup_user'@'%';
GRANT SELECT, LOCK TABLES, SHOW VIEW ON wp_single1.* TO 'backup_user'@'%';
GRANT SELECT, LOCK TABLES, SHOW VIEW ON wp_single2.* TO 'backup_user'@'%';

-- Grant monitoring permissions
GRANT SELECT, PROCESS, REPLICATION CLIENT ON *.* TO 'monitoring_user'@'%';
GRANT SELECT ON wp_multisite.* TO 'monitoring_user'@'%';
GRANT SELECT ON wp_single1.* TO 'monitoring_user'@'%';
GRANT SELECT ON wp_single2.* TO 'monitoring_user'@'%';

-- Set global variables for WordPress optimization
SET GLOBAL innodb_file_per_table = ON;
SET GLOBAL innodb_file_format = Barracuda;
SET GLOBAL innodb_large_prefix = ON;

-- Create WordPress multisite configuration
USE wp_multisite;

-- Create essential WordPress tables (if not created by WP installer)
CREATE TABLE IF NOT EXISTS wp_multisite_blogs (
    blog_id bigint(20) NOT NULL AUTO_INCREMENT,
    site_id bigint(20) NOT NULL,
    domain varchar(200) NOT NULL,
    path varchar(100) NOT NULL,
    registered datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
    last_updated datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
    public tinyint(2) NOT NULL DEFAULT 1,
    archived tinyint(2) NOT NULL DEFAULT 0,
    mature tinyint(2) NOT NULL DEFAULT 0,
    spam tinyint(2) NOT NULL DEFAULT 0,
    deleted tinyint(2) NOT NULL DEFAULT 0,
    lang_id int(11) NOT NULL DEFAULT 0,
    PRIMARY KEY  (blog_id),
    KEY domain (domain(50),path(5)),
    KEY lang_id (lang_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

FLUSH PRIVILEGES;

COMMIT;